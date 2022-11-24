use std::collections::HashSet;

use crate::nodes::*;

#[derive(Clone, Debug)]
pub struct Token {
    pub data : String,
    line : i32,
    col  : i32
}

pub struct Parser {
    pub tokens  : Vec<Token>,
    index   : usize
}

pub fn create_parser(contents: String)->Parser {
    let mut parser: Parser = Parser{tokens:Vec::new(), index:0 };
    
    let mut data = String::from("");
    data.push(contents.chars().next().unwrap());
    let mut line = 1;
    let mut col = 1;
    let mut old_col = 1;
    let mut old_c:char = contents.chars().next().unwrap();
    for c in contents.chars().skip(1) {
        if old_c == '\n' || old_c == '\r' || (is_special_char(old_c) != is_special_char(c)) || c == '#' || c == '[' || c == '(' || c == '!' || c == '\n' || c == '\r' {
            parser.tokens.push(Token{data:data, line:line, col:old_col});
            old_col = col + 1;
            if c == '\n' {
                line += 1;
                col = 0;
            }
            data = String::from("");
        }
        if old_c != '#' || !c.is_whitespace() {
            data.push(c);
        }
        col += 1;
        old_c = c;
    }
    parser.tokens.push(Token{data:data, line:line, col:col});
    parser.tokens.push(Token{data:String::from("\n"), line:line, col:col});

    return parser;
}

impl Parser {
    fn pop(&mut self)->Token {
        self.index += 1;
        self.tokens[self.index - 1].clone()
    }

    fn peek(&self)->Token {
        self.tokens[self.index].clone()
    }

    fn accept(&mut self, data:&String)->Option<Token> {
        if self.tokens[self.index].data == *data {
            Some(self.pop())
        } else {
            None
        }
    }

    fn expect(&mut self, data:String) {
        let res = self.accept(&data); 
        match res {
            Some(_) => (),
            None => {
                let top = self.peek();
                if is_special_char(top.data.chars().next().unwrap()) {
                    panic!("error: {}:{} expected `{}` got `{}`", top.line, top.col, data, top.data)
                } else {
                    panic!("error: {}:{} expected `{}` got text", top.line, top.col, data)
                }
            }
        }
    }

    pub fn parse_document(&mut self)->Vec<Box<dyn Node>> {
        let mut retval: Vec<Box<dyn Node>> = Vec::new();
        while self.index < self.tokens.len() - 1 {
            let node = self.parse_node();
            match node {
                Some(n) => retval.push(n),
                None => ()
            }
        }
        retval
    }

    fn parse_node(&mut self)->Option<Box<dyn Node>> {
        if self.accept(&String::from("#")).is_some() {
            Some(Box::new(self.parse_header()))
        } else if self.accept(&String::from("```")).is_some() {
            Some(Box::new(self.parse_code_block()))
        } else if self.accept(&String::from("!")).is_some() {
            Some(Box::new(self.parse_image()))
        } else if self.accept(&String::from("\n")).is_some() {
            None
        } else {
            Some(Box::new(self.parse_paragraph()))
        }
    }

    fn parse_header(&mut self)->Header {
        let mut size = 1;
        while self.accept(&String::from("#")).is_some() {
            size += 1;
        }
        let bounds: HashSet<String> = vec![String::from("\n")].into_iter().collect();
        Header{size:size, children:self.parse_formatted_text(&bounds)}
    }

    fn parse_paragraph(&mut self)->Paragraph {
        let bounds: HashSet<String> = vec![String::from("\n")].into_iter().collect();
        Paragraph{children:self.parse_formatted_text(&bounds)}
    }

    fn parse_code_block(&mut self)->CodeBlock {
        let mut text = String::from("");
        while self.accept(&String::from("```")).is_none() {
            text += &self.pop().data;
        }
        CodeBlock{text}
    }

    fn parse_image(&mut self)->Image {
        self.expect(String::from("["));
        let text = self.pop().data;
        self.expect(String::from("]"));
        self.expect(String::from("("));
        let url = self.pop().data;
        self.expect(String::from(")"));
        Image{text, url}
    }

    fn parse_formatted_text(&mut self, bounds:&HashSet<String>)->Vec<Box<dyn Node>> {
        let mut retval: Vec<Box<dyn Node>> = Vec::new();
        while !bounds.contains(&self.peek().data) {
            if self.accept(&String::from("_")).is_some() || self.accept(&String::from("*")).is_some() {
                retval.push(Box::new(self.parse_italic(bounds)))
            } else if self.accept(&String::from("__")).is_some() || self.accept(&String::from("**")).is_some() {
                retval.push(Box::new(self.parse_bold(bounds)))
            } else if self.accept(&String::from("`")).is_some() {
                retval.push(Box::new(self.parse_code()))
            } else if self.accept(&String::from("[")).is_some() {
                retval.push(Box::new(self.parse_link()))
            } else {
                retval.push(Box::new(Text{text:self.pop().data}))
            }
        }
        retval
    }

    fn parse_italic(&mut self, bounds:&HashSet<String>)->Italic {
        let mut new_bounds = bounds.clone();
        new_bounds.insert(String::from("*"));
        new_bounds.insert(String::from("_"));
        let children = self.parse_formatted_text(&new_bounds);
        if self.accept(&String::from("*")).is_none() {
            self.expect(String::from("_"));
        }
        Italic{children}
    }

    fn parse_bold(&mut self, bounds:&HashSet<String>)->Bold {
        let mut new_bounds = bounds.clone();
        new_bounds.insert(String::from("**"));
        new_bounds.insert(String::from("__"));
        let children = self.parse_formatted_text(&new_bounds);
        if self.accept(&String::from("**")).is_none() {
            self.expect(String::from("__"));
        }
        Bold{children}
    }

    fn parse_code(&mut self)->Code {
        let mut text = String::from("");
        while self.accept(&String::from("`")).is_none() {
            text += &self.pop().data;
        }
        Code{text}
    }

    fn parse_link(&mut self)->Link{
        let text = self.pop().data;
        self.expect(String::from("]"));
        self.expect(String::from("("));
        let url = self.pop().data;
        self.expect(String::from(")"));
        Link{text, url}
    }
}

fn is_special_char(c:char)->bool {
    return c == '_' ||
		c == '*' ||
		c == '`' ||
		c == '#' ||
		c == '[' ||
		c == ']' ||
		c == '(' ||
		c == ')' ||
		c == '!';
}