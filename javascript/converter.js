// To run: node converter.js ../input.md
// Pros: 
//  - No setup required, just a .js file
//  - Don't always need semicolons
//  - Nice way to import stuff
//  - Optionals (for typescript)
//  - JSON for every object, can print out an object and have it be formatted pretty well, great for debugging
//  - Implicit undefined return along with being able to check for undefined as a boolean is concise
//  - Prototypical classes are basically just HashMaps that can contain functions. HashMaps + first class functions + syntactic sugar = prototypical classes
//  - Lambdas and closures
//  - Spread operator
// Cons:
//  - Need parens around if conditions
//  - Couldn't get TypeScript working because of dependency issues (often the case!)
//  - Undefined values if values aren't passed to a function. No warning, no error. (for JavaScript)
//  - Dynamically typed
//  - explicit `this`
//  - weird distinction between `of` and `in` for foreach loops
//  - Weird triple eq thing. Makes sense for web development i suppose. == and === should have been flipped IMO
//  - No static checking unfortunately

fs = require('fs')

class Header {
    constructor (size, children) {
        this.size = size
        this.children = children
    }

    getHTML() {
        let text = '<h' + this.size + '>'
        for (let child of this.children) {
            text += child.getHTML()
        }
        return text + '</h' + this.size + '>\n'
    }
}

class Paragraph {
    constructor (children) {
        this.children = children
    }

    getHTML() {
        let text = '<p>'
        for (let child of this.children) {
            text += child.getHTML()
        }
        return text + '</p>\n\n'
    }
}

class CodeBlock {
    constructor (text) {
        this.text = text
    }

    getHTML() {
        return '<pre><code>' + this.text + '</code></pre>\n\n'
    }
}

class Image {
    constructor (text, url) {
        this.text = text
        this.url = url
    }

    getHTML() {
        return '<img src="' + this.url + '" alt="' + this.text + '" />\n'
    }
}

class Text {
    constructor (text) {
        this.text = text
    }

    getHTML() {
        return this.text
    }
}

class Italic {
    constructor (children) {
        this.children = children
    }

    getHTML() {
        let text = '<em>'
        for (let child of this.children) {
            text += child.getHTML()
        }
        return text + '</em>'
    }
}

class Bold {
    constructor (children) {
        this.children = children
    }

    getHTML() {
        let text = '<strong>'
        for (let child of this.children) {
            text += child.getHTML()
        }
        return text + '</strong>'
    }
}

class Code {
    constructor (text) {
        this.text = text
    }

    getHTML() {
        return '<code>' + this.text + '</code>'
    }
}

class Link {
    constructor (text, url) {
        this.text = text
        this.url = url
    }

    getHTML() {
        return '<a href="' + this.url + '">' + this.text + '</a>'
    }
}

class Token {
    constructor (data, line, col) {
        this.data = data
        this.line = line
        this.col = col
    }
}

function isSpecialChar(c) {
    return c == '_' ||
        c == '*' ||
        c == '`' ||
        c == '#' ||
        c == '[' ||
        c == ']' ||
        c == '(' ||
        c == ')' ||
        c == '!'
}

class Parser {
    constructor (contents) {
        this.tokens = []
        this.index = 0

        let data = contents[0]
        let line = 1
        let col = 1
        let oldCol = 1
        let oldC = contents[0]
        for (let c of contents.substring(1)) {
            if (oldC == '\n' || oldC == '\r' || (isSpecialChar(oldC) != isSpecialChar(c)) || c == '#' || c == '[' || c == '(' || c == '!' || c == '\n' || c == '\r') {
                if (!data.includes('\r')) {
                    this.tokens.push(new Token(data, line, oldCol))
                }
                oldCol = col + 1
                if (c == '\n') {
                    line ++
                    col = 0
                }
                data = ''
            }
            if (oldC != '#' || !(/\s/g.test(c))) {
                data += c
            }
            col++
            oldC = c
        }
        this.tokens.push(new Token(data, line, col))
        this.tokens.push(new Token('\n', line, col))
    }

    pop() {
        this.index++
        return this.tokens[this.index - 1]
    }

    peek() {
        return this.tokens[this.index]
    }

    accept(data) {
        if (this.peek().data === data) {
            return this.pop()
        }
    }

    expect(data) {
        if (!this.accept(data)) {
            let top = this.peek()
            if (isSpecialChar(top.data[0])) {
                console.log("error: %d:%d expected `%s`, got `%s`\n", top.line, top.col, token, top.data)
            } else {
                console.log("error: %d:%d expected `%s`, got text\n", top.line, top.col, token)
            }
            process.exit(1)
        }
    }

    parseDocument() {
        let retval = []
        while (this.index < this.tokens.length - 1) {
            let node = this.parseNode()
            if (node) {
                retval.push(node)
            }
        }
        return retval
    }

    parseNode() {
        if (this.accept('#')) {
            return this.parseHeader()
        } else if (this.accept('```')) {
            return this.parseCodeBlock()
        } else if (this.accept('!')) {
            return this.parseImage()
        } else if (!this.accept('\n')) {
            return this.parseParagraph()
        }
    }

    parseHeader() {
        let size = 1
        while (this.accept('#')) {
            size++
        }
        return new Header(size, this.parseFormattedText(['\n']))
    }

    parseParagraph() {
        return new Paragraph(this.parseFormattedText(['\n']))
    }

    parseCodeBlock() {
        let text = ''
        while (!this.accept('```')) {
            text += this.pop().data
        }
        return new CodeBlock(text)
    }

    parseImage() {
        this.expect('[')
        let text = this.pop().data
        this.expect(']')
        this.expect('(')
        let url = this.pop().data
        this.expect(')')
        return new Image(text, url)
    }

    parseFormattedText(bounds) {
        let retval = []
        while (!bounds.find(item => { return item === this.peek().data } )) {
            if (this.accept('_') || this.accept('*')) {
                retval.push(this.parseItalic(bounds))
            } else if (this.accept('__') || this.accept('**')) {
                retval.push(this.parseBold(bounds))
            } else if (this.accept('`')) {
                retval.push(this.parseCode(bounds))
            } else if (this.accept('[')) {
                retval.push(this.parseLink(bounds))
            } else {
                retval.push(new Text(this.pop().data))
            }
        }
        return retval
    }

    parseItalic(bounds) {
        let children = this.parseFormattedText([...bounds, '*', '_'])
        if (!this.accept('*')) {
            this.expect('_')
        }
        return new Italic(children)
    }

    parseBold(bounds) {
        let children = this.parseFormattedText([...bounds, '**', '__'])
        if (!this.accept('**')) {
            this.expect('__')
        }
        return new Bold(children)
    }

    parseCode() {
        let text = ''
        while (!this.accept('`')) {
            text += this.pop().data
        }
        return new Code(text)
    }

    parseLink() {
        let text = this.pop().data
        this.expect(']')
        this.expect('(')
        let url = this.pop().data
        this.expect(')')
        return new Link(text, url)
    }
}

if (process.argv.length != 3) {
    console.log('usage: node converter.js <markdown-filename>')
} else {
    // Open input file, read contents
    try {  
        var contents = fs.readFileSync(process.argv[2], 'utf8'); 
    } catch(e) {
        console.log('Error:', e.stack);
        process.exit(1)
    }

    // Create parser, parse Markdown document
    let parser = new Parser(contents)
    let document = parser.parseDocument()

    // Open output file, write HTML document
    let output = ''
    for (let node of document) {
        output += node.getHTML()
    }
    try {
        fs.writeFileSync('output.html', output)
    } catch (err) {
        console.error(err);
        process.exit(1);
    }
}