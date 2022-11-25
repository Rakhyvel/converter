<?php
// To run: php converter.php --enable-intl ../input.md
// Pros:
//  - String interpolation is cool
//  - Foreach
//  - Arrays are copied by value (maybe slow but cool!)
//  - Stacktraces and source code position for runtime errors
// Cons:
//  - Uninformative CLI syntax error messages
//  - Dollar sign prefixing
//  - Arrow syntax to access fields/methods
//  - Semicolons for an interpreted language
//  - Parens around if, while, for
//  - WEAKLY DYNAMICALLY TYPED!!! (worst combo)
//  - Horrible support for extensions. Have to COMPILE php to use an extension
//  - Weird difference between == and === like in JS
//  - No static error checking
//  - No checks if function doesn't return something

interface Node {
    public function getHTML();
}

class Header implements Node {
    private $size;
    private $children;

    function __construct($size, $children) {
        $this->size = $size;
        $this->children = $children;
    }

    public function getHTML() {
        $text = "<h$this->size>";
        foreach ($this->children as $child) {
            $text .= $child->getHTML();
        }
        $text .= "</h$this->size>\n";
        return $text;
    }
}

class Paragraph implements Node {
    private $children;

    function __construct($children) {
        $this->children = $children;
    }

    public function getHTML() {
        $text = "<p>";
        foreach ($this->children as $child) {
            $text .= $child->getHTML();
        }
        $text .= "</p>\n\n";
        return $text;
    }
}

class CodeBlock implements Node {
    private $text;

    function __construct($text) {
        $this->text = $text;
    }

    public function getHTML() {
        return "<pre><code>$this->text</code></pre>\n\n";
    }
}

class Image implements Node {
    private $text;
    private $url;

    function __construct($text, $url) {
        $this->text = $text;
        $this->url = $url;
    }

    public function getHTML() {
        return "<img src=\"$this->url\" alt=\"$this->text\" />";
    }
}

class Text implements Node {
    private $text;

    function __construct($text) {
        $this->text = $text;
    }

    public function getHTML() {
        return "$this->text";
    }
}

class Italic implements Node {
    private $children;

    function __construct($children) {
        $this->children = $children;
    }

    public function getHTML() {
        $text = "<em>";
        foreach ($this->children as $child) {
            $text .= $child->getHTML();
        }
        $text .= "</em>";
        return $text;
    }
}

class Bold implements Node {
    private $children;

    function __construct($children) {
        $this->children = $children;
    }

    public function getHTML() {
        $text = "<strong>";
        foreach ($this->children as $child) {
            $text .= $child->getHTML();
        }
        $text .= "</strong>";
        return $text;
    }
}

class Code implements Node {
    private $text;

    function __construct($text) {
        $this->text = $text;
    }

    public function getHTML() {
        return "<code>$this->text</code>";
    }
}

class Link implements Node {
    private $text;
    private $url;

    function __construct($text, $url) {
        $this->text = $text;
        $this->url = $url;
    }

    public function getHTML() {
        return "<a href=\"$this->url\">$this->text</a>";
    }
}

class Token {
    public $data;
    public $line;
    public $col;

    function __construct($data, $line, $col) {
        $this->data = $data;
        $this->line = $line;
        $this->col = $col;
    }
}

class Parser {
    private $tokens;
    private $index;

    function __construct($contents) {
        $this->tokens = array();
        $this->index = 0;

        $data = $contents[0];
        $line = 1;
        $col = 1;
        $oldCol = 1;
        $oldC = $contents[0];
        for ($i = 1; $i < strlen($contents); $i++) {
            $c = $contents[$i];
            if ($oldC == "\n" || $oldC == "\r" || (isSpecialChar($oldC) != isSpecialChar($c)) || $c == "#" || $c == "[" || $c == "(" || $c == "!" || $c == "\n" || $c == "\r") {
                if (strpos($data, "\r") === false) {
                    array_push($this->tokens, new Token($data, $line, $oldCol));
                }
                $oldCol = $col + 1;
                if ($c == "\n") {
                    $line++;
                    $col = 0;
                }
                $data = "";
            }
            if ($oldC != "#" || !ctype_space($c)) {
                $data .= $c;
            }
            $col++;
            $oldC = $c;
        }
        array_push($this->tokens, new Token($data, $line, $col));
        array_push($this->tokens, new Token("\n", $line, $col));
    }

    function pop() {
        $this->index++;
        return $this->tokens[$this->index - 1];
    }

    function peek() {
        return $this->tokens[$this->index];
    }

    function accept($data) {
        if ($this->peek()->data === $data) {
            return $this->pop();
        } else {
            return null;
        }
    }

    function expect($data) {
        if ($this->accept($data) === null) {
            $top = $this->peek();
            if (isSpecialChar($top->data[0])) {
                echo "error: $top->line:$top->col expected `$data`, got `$top->data`";
            } else {
                echo "error: $top->line:$top->col expected `$data`, got text";
            }
            die();
        }
    }

    function takeUntil($sentinel) {
        $data = "";
        while (!$this->accept($sentinel)) {
            $data .= $this->pop()->data;
        }
        return $data;
    }

    public function parseDocument() {
        $retval = array();
        while ($this->index < sizeof($this->tokens) - 1) {
            $node = $this->parseNode();
            if ($node !== null) {
                array_push($retval, $node);
            }
        }
        return $retval;
    }

    function parseNode() {
        if ($this->accept("#") !== null) {
            return $this->parseHeader();
        } else if ($this->accept("```") !== null) {
            return $this->parseCodeBlock();
        } else if ($this->accept("!") !== null) {
            return $this->parseImage();
        } else if ($this->accept("\n") === null) {
            return $this->parseParagraph();
        }
    }

    function parseHeader() {
        $size = 1;
        while ($this->accept("#") !== null) {
            $size++;
        }
        return new Header($size, $this->parseFormattedText(["\n"]));
    }

    function parseParagraph() {
        return new Paragraph($this->parseFormattedText(["\n"]));
    }

    function parseCodeBlock() {
        return new CodeBlock($this->takeUntil("```"));
    }

    function parseImage() {
        $this->expect("[");
        $text = $this->pop()->data;
        $this->expect("]");
        $this->expect("(");
        $url = $this->pop()->data;
        $this->expect(")");
        return new Image($text, $url);
    }

    function parseFormattedText($bounds) {
        $retval = array();
        while (in_array($this->peek()->data, $bounds) !== true) {
            if ($this->accept("_") !== null || $this->accept("*") !== null) {
                array_push($retval, $this->parseItalic($bounds));
            } else if ($this->accept("__") !== null || $this->accept("**") !== null) {
                array_push($retval, $this->parseBold($bounds));
            } else if ($this->accept("`") !== null) {
                array_push($retval, $this->parseCode());
            } else if ($this->accept("[") !== null) {
                array_push($retval, $this->parseLink());
            } else {
                array_push($retval, new Text($this->pop()->data));
            }
        }
        return $retval;
    }

    function parseItalic($bounds) {
        array_push($bounds, "*");
        array_push($bounds, "_");
        $children = $this->parseFormattedText($bounds);
        if ($this->accept("_") === null) {
            $this->expect("*");
        }
        return new Italic($children);
    }

    function parseBold($bounds) {
        array_push($bounds, "**");
        array_push($bounds, "__");
        $children = $this->parseFormattedText($bounds);
        if ($this->accept("__") === null) {
            $this->expect("**");
        }
        return new Bold($children);
    }

    function parseCode() {
        return new Code($this->takeUntil("`"));
    }

    function parseLink() {
        $text = $this->pop()->data;
        $this->expect("]");
        $this->expect("(");
        $url = $this->pop()->data;
        $this->expect(")");
        return new Image($text, $url);
    }
}

function isSpecialChar($c) {
    return $c == "_" ||
        $c == "*" ||
        $c == "`" ||
        $c == "#" ||
        $c == "[" ||
        $c == "]" ||
        $c == "(" ||
        $c == ")" ||
        $c == "!";
}

if ($argc != 2) {
    die("usage: php converter.php <markdown-filename>");
} else {
    // Open input file, get contents as string
    $myfile = fopen($argv[1], "r") or die("Unable to open input file!");
    $contents = fread($myfile, filesize($argv[1]));
    fclose($myfile);

    // Create parser, parse document
    $parser = new Parser($contents);
    $document = $parser->parseDocument();

    // Write out document
    $output = fopen("output.html", "w") or die("Unable to open output file!");
    $output_text = "";
    foreach($document as $node) {
        $output_text .= $node->getHTML();
    }
    fwrite($output, $output_text);
    fclose($output);
}

?>