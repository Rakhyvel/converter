pub trait Node {
    fn get_string(&self)->String;
}

pub struct Header {
    pub size: i32,
    pub children: Vec<Box<dyn Node>>
}

pub struct Paragraph {
    pub children: Vec<Box<dyn Node>>
}

pub struct CodeBlock {
    pub text: String
}

pub struct Image {
    pub text: String,
    pub url: String
}

pub struct Text {
    pub text: String
}

pub struct Italic {
    pub children: Vec<Box<dyn Node>>
}

pub struct Bold {
    pub children: Vec<Box<dyn Node>>
}

pub struct Code {
    pub text: String
}

pub struct Link {
    pub text: String,
    pub url: String
}

fn get_child_html_vec(children:&Vec<Box<dyn Node>>)->Vec<String> {
    children.iter().map(|child| child.get_string()).collect()
}

impl Node for Header {
    fn get_string(&self)->String {
        format!("<h{}>{}</h{}>\n", self.size, get_child_html_vec(&self.children).join(""), self.size)
    }
}

impl Node for Paragraph {
    fn get_string(&self)->String {
        format!("<p>{}</p>\n\n", get_child_html_vec(&self.children).join(""))
    }
}

impl Node for CodeBlock {
    fn get_string(&self)->String {
        format!("<pre><code>{}</code></pre>\n\n", self.text)
    }
}

impl Node for Image {
    fn get_string(&self)->String {
        format!("<img src=\"{}\" alt=\"{}\" />\n\n", self.url, self.text)
    }
}

impl Node for Text {
    fn get_string(&self)->String {
        self.text.replace("\r", "")
    }
}

impl Node for Italic {
    fn get_string(&self)->String {
        format!("<em>{}</em>", get_child_html_vec(&self.children).join(""))
    }
}

impl Node for Bold {
    fn get_string(&self)->String {
        format!("<strong>{}</strong>", get_child_html_vec(&self.children).join(""))
    }
}

impl Node for Code {
    fn get_string(&self)->String {
        format!("<code>{}</code>", self.text)
    }
}

impl Node for Link {
    fn get_string(&self)->String {
        format!("<a href=\"{}\">{}</a>", self.url, self.text)
    }
}