package main

import (
	"fmt"
	"os"
	"strings"

	"golang.org/x/exp/slices"
)

type Token struct {
	data string
	line int
	col  int
}

type Parser struct {
	tokens    []Token
	numTokens int
	index     int
}

func createParser(content []byte) *Parser {
	parser := Parser{make([]Token, 0), 0, 0}
	data := string(content[0])
	line := 1
	col := 1
	oldCol := 1
	for i := 1; i < len(content); i += 1 {
		c := content[i]
		if data[len(data)-1] == '\n' || data[len(data)-1] == '\r' || (isSpecialChar(data[len(data)-1]) != isSpecialChar(c)) || c == '#' || c == '[' || c == '(' || c == '\n' || c == '\r' {
			if !strings.Contains(data, "\r") {
				parser.tokens = append(parser.tokens, Token{data, line, oldCol})
				parser.numTokens += 1
			}
			oldCol = col + 1
			if strings.Contains(data, "\n") {
				line += 1
				col = 0
			}
			data = ""
		}
		data += string(c)
		col += 1
	}
	parser.tokens = append(parser.tokens, Token{data, line, col})
	parser.tokens = append(parser.tokens, Token{"\n", line, col})
	return &parser
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

func (parser *Parser) pop() Token {
	parser.index += 1
	return parser.tokens[parser.index-1]
}

func (parser *Parser) peek() Token {
	return parser.tokens[parser.index]
}

func (parser *Parser) accept(token string) *Token {
	if parser.peek().data == token {
		parser.index += 1
		return &parser.tokens[parser.index-1]
	} else {
		return nil
	}
}

func (parser *Parser) expect(token string) {
	if parser.accept(token) == nil {
		top := parser.peek()
		if isSpecialChar(top.data[0]) {
			fmt.Printf("error: %s:%d:%d expected `%s`, got `%s`\n", os.Args[1], top.line, top.col, token, top.data)
		} else {
			fmt.Printf("error: %s:%d:%d expected `%s`, got text\n", os.Args[1], top.line, top.col, token)
		}
		os.Exit(1)
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
	return &Header{size, parser.parseFormattedText([]string{"\n"})}
}

func (parser *Parser) parseCodeBlock() *CodeBlock {
	text := ""
	for parser.accept("```") == nil {
		text += parser.pop().data
	}
	return &CodeBlock{text}
}

func (parser *Parser) parseImage() *Image {
	parser.expect("[")
	text := parser.pop().data
	parser.expect("]")
	parser.expect("(")
	url := parser.pop().data
	parser.expect(")")
	return &Image{text, url}
}

func (parser *Parser) parseParagraph() *Paragraph {
	return &Paragraph{parser.parseFormattedText([]string{"\n"})}
}

func (parser *Parser) parseFormattedText(bounds []string) []Node {
	children := make([]Node, 0)
	for !slices.Contains(bounds, parser.peek().data) {
		if parser.accept("_") != nil || parser.accept("*") != nil {
			children = append(children, parser.parseItalic(bounds))
		} else if parser.accept("__") != nil || parser.accept("**") != nil {
			children = append(children, parser.parseBold(bounds))
		} else if parser.accept("`") != nil {
			children = append(children, parser.parseCode())
		} else if parser.accept("[") != nil {
			children = append(children, parser.parseLink())
		} else {
			children = append(children, &Text{parser.pop().data})
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
		parser.expect("_")
	}
	return &Italic{children}
}

func (parser *Parser) parseBold(bounds []string) *Bold {
	newBounds := make([]string, len(bounds))
	copy(newBounds, bounds)
	newBounds = append(newBounds, "**", "__")
	children := parser.parseFormattedText(newBounds)
	if parser.accept("**") == nil {
		parser.expect("__")
	}
	return &Bold{children}
}

func (parser *Parser) parseCode() *Code {
	text := ""
	for parser.accept("`") == nil {
		text += parser.pop().data
	}
	return &Code{text}
}

func (parser *Parser) parseLink() *Link {
	text := parser.pop().data
	parser.expect("]")
	parser.expect("(")
	url := parser.pop().data
	parser.expect(")")
	return &Link{text, url}
}
