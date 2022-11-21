package main

import (
	"fmt"
	"strings"
)

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
