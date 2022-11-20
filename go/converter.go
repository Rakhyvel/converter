package main

import (
	"fmt"
	"os"
	"strings"

	"golang.org/x/exp/slices"
)

type Parser struct {
	tokens    []string
	numTokens int
	index     int
}

type Header struct {
	size     int
	children []Node
}

type Paragraph struct {
	children []Node
}
type CodeBlock struct {
	text string
}

type Image struct {
	text string
	url  string
}

type Text struct {
	text string
}

type Italic struct {
	children []Node
}

type Bold struct {
	children []Node
}

type Code struct {
	text string
}

type Link struct {
	text string
	url  string
}

type Node interface {
	str() string
}

// Interface implementations
func (header *Header) str() string {
	text := fmt.Sprintf("<h%d>", header.size)
	for i := 0; i < len(header.children); i += 1 {
		var child string
		if i == 0 {
			child = strings.Trim(header.children[i].str(), " ")
		} else {
			child = header.children[i].str()
		}
		if child[len(child)-1] == 13 {
			text += child[:len(child)-1]
		} else {
			text += child
		}
	}
	return text + fmt.Sprintf("</h%d>\n", header.size)
}

func (paragraph *Paragraph) str() string {
	text := "<p>"
	for i := 0; i < len(paragraph.children); i += 1 {
		child := paragraph.children[i].str()
		if child[len(child)-1] == 13 {
			text += child[:len(child)-1]
		} else {
			text += child
		}
	}
	return text + "</p>\n"
}

func (codeBlock *CodeBlock) str() string {
	return "<pre><code>" + codeBlock.text + "</code></pre>\n"
}

func (image *Image) str() string {
	return "<img src=\"" + image.url + "\" alt=\"" + image.text + "\" />\n"
}

func (text *Text) str() string {
	return text.text
}

func (italic *Italic) str() string {
	text := "<em>"
	for i := 0; i < len(italic.children); i += 1 {
		child := italic.children[i].str()
		if child[len(child)-1] == 13 {
			text += child[:len(child)-1]
		} else {
			text += child
		}
	}
	return text + "</em>"
}

func (bold *Bold) str() string {
	text := "<strong>"
	for i := 0; i < len(bold.children); i += 1 {
		child := bold.children[i].str()
		if child[len(child)-1] == 13 {
			text += child[:len(child)-1]
		} else {
			text += child
		}
	}
	return text + "</strong>"
}

func (code *Code) str() string {
	return "<code>" + code.text + "</code>"
}

func (link *Link) str() string {
	return "<a href=\"" + link.url + "\">" + link.text + "</a>"
}

// Parser stuff
func (parser *Parser) pop() string {
	parser.index += 1
	return parser.tokens[parser.index-1]
}

func (parser *Parser) accept(token string) *string {
	if parser.tokens[parser.index] == token {
		parser.index += 1
		return &parser.tokens[parser.index-1]
	} else {
		return nil
	}
}

func (parser *Parser) parseDocument() []Node {
	retval := make([]Node, 0)
	for parser.index < parser.numTokens-1 {
		if node := parser.parseNode(); node != nil {
			retval = append(retval, node)
		}
	}
	return retval
}

func (parser *Parser) parseNode() Node {
	if parser.accept("#") != nil {
		return parser.parseHeader()
	} else if parser.accept("```") != nil {
		return parser.parseCodeBlock()
	} else if parser.accept("!") != nil {
		return parser.parseImage()
	} else if parser.accept("\n") != nil {
		return nil
	} else {
		return parser.parseParagraph()
	}
}

func (parser *Parser) parseHeader() *Header {
	size := 1
	for parser.accept("#") != nil {
		size += 1
	}
	return &Header{1, parser.parseFormattedText([]string{"\n"})}
}

func (parser *Parser) parseCodeBlock() *CodeBlock {
	text := ""
	for parser.accept("```") == nil {
		text += parser.pop()
	}
	return &CodeBlock{text}
}

func (parser *Parser) parseImage() *Image {
	parser.accept("[")
	text := parser.pop()
	parser.accept("]")
	parser.accept("(")
	url := parser.pop()
	parser.accept(")")
	return &Image{text, url}
}

func (parser *Parser) parseParagraph() *Paragraph {
	return &Paragraph{parser.parseFormattedText([]string{"\n"})}
}

func (parser *Parser) parseFormattedText(bounds []string) []Node {
	children := make([]Node, 0)
	for !slices.Contains(bounds, parser.tokens[parser.index]) {
		if parser.accept("_") != nil || parser.accept("*") != nil {
			children = append(children, parser.parseItalic(bounds))
		} else if parser.accept("__") != nil || parser.accept("**") != nil {
			children = append(children, parser.parseBold(bounds))
		} else if parser.accept("`") != nil {
			children = append(children, parser.parseCode(bounds))
		} else if parser.accept("[") != nil {
			children = append(children, parser.parseLink(bounds))
		} else {
			children = append(children, &Text{parser.pop()})
		}
	}
	return children
}

func (parser *Parser) parseItalic(bounds []string) *Italic {
	newBounds := make([]string, len(bounds))
	copy(newBounds, bounds)
	newBounds = append(newBounds, "*", "_")
	children := parser.parseFormattedText(newBounds)
	if parser.accept("*") == nil {
		parser.accept("_")
	}
	return &Italic{children}
}

func (parser *Parser) parseBold(bounds []string) *Bold {
	newBounds := make([]string, len(bounds))
	copy(newBounds, bounds)
	newBounds = append(newBounds, "**", "__")
	children := parser.parseFormattedText(newBounds)
	if parser.accept("**") == nil {
		parser.accept("__")
	}
	return &Bold{children}
}

func (parser *Parser) parseCode(bounds []string) *Code {
	text := ""
	for parser.accept("`") == nil {
		text += parser.pop()
	}
	return &Code{text}
}

func (parser *Parser) parseLink(bounds []string) *Link {
	text := parser.pop()
	parser.accept("]")
	parser.accept("(")
	url := parser.pop()
	parser.accept(")")
	return &Link{text, url}
}

func isSpecialChar(char byte) bool {
	return char == '_' ||
		char == '*' ||
		char == '`' ||
		char == '#' ||
		char == '[' ||
		char == ']' ||
		char == '(' ||
		char == ')' ||
		char == '!'
}

func createParser(content []byte) *Parser {
	parser := Parser{make([]string, 0), 0, 0}
	token := string(content[0])
	for i := 1; i < len(content); i += 1 {
		c := content[i]
		if token[len(token)-1] == '\n' || (isSpecialChar(token[len(token)-1]) != isSpecialChar(c)) || c == '#' || c == '[' || c == '(' || c == '\n' {
			parser.tokens = append(parser.tokens, token)
			parser.numTokens += 1
			token = ""
		}
		token += string(c)
	}
	parser.tokens = append(parser.tokens, token)
	parser.tokens = append(parser.tokens, string('\n'))
	return &parser
}

func main() {
	content, err := os.ReadFile(os.Args[1]) // the file is inside the local directory
	if err != nil {
		fmt.Println("Err")
	}
	parser := createParser(content)
	nodes := parser.parseDocument()
	f, err := os.Create("output.html") // creates a file at current directory
	if err != nil {
		fmt.Println(err)
	}
	for i := 0; i < len(nodes); i += 1 {
		f.WriteString(nodes[i].str())
	}
}

// To run: go run . ../input.md
// Pros:
//	- Has defer (but runs at end of function)
//	- I like the "declared but not used" errors actually
//	- Can put functions anywhere
//	- Type inference
//	- Functions must return value in all control paths
//	- I think the compiler comes with a formatter, which is neat
//	- == to compare string equality
//	- Multiple return is still pretty cool
//	- Cool compile warnings about loops where the condition doesn't change
//	- Sensical if-let, for-let idiom
//	- immutable strings
//	- slices function like lists, have good support
//	- implicit dereference through dots
//	- Methods are defined outside of struct definitions
// 	- Good string concat syntax
//	- Interfaces are good!
//	- Package manager is actually pretty sick when you can just say `import "url.com"` and it'll import it into your project no fiddling required
// Cons:
//	- Build system is a little clunky, don't like that I NEED to have a package setup
//  - Seems really slow to compile
//  - I don't like the public/private model based on case
//	- Weird way to get the command line arguments, like in Python
// 	- Checking return values is not my cup of tea for error handling, doesn't gaurantee error handling
//	- Disharmonious variable declaration syntax
//	- Defer can only be used to call functions, called at the end of this function
//	- Lol no generics
//	- Cannot chain expressions over more than one line the mathematically correct way
//	- Nil values rather than optionals
//	- HORRIBLE C pointer type syntax
//	- Slices don't have a length field like they should
//
//
// Not a language thing but the VS lang server for Go is too eager with marking things as errors as I'm typing, and the formatting is annoying
