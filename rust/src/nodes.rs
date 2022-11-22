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

impl Node for Header {
    fn get_string(&self)->String {
        let mut text = format!("<h{}>", self.size);
        let mut i = 0;
        for child in self.children.iter() {
            if i == 0 {
                text += &child.get_string().trim();
            } else {
                text += &child.get_string();
            }
            i += 1;
        }
        format!("{}</h{}>\n", text, self.size)
    }
}

impl Node for Paragraph {
    fn get_string(&self)->String {
        let mut text = String::from("<p>");
        for child in self.children.iter() {
            text += &child.get_string();
        }
        text + "</p>\n"
    }
}

impl Node for CodeBlock {
    fn get_string(&self)->String {
        format!("<pre><code>{}</code></pre>\n", self.text)
    }
}

impl Node for Image {
    fn get_string(&self)->String {
        format!("<img src=\"{}\" alt=\"{}\" />\n", self.url, self.text)
    }
}

impl Node for Text {
    fn get_string(&self)->String {
        self.text.replace("\r", "")
    }
}

impl Node for Italic {
    fn get_string(&self)->String {
        let mut text = String::from("<em>");
        for child in self.children.iter() {
            text += &child.get_string();
        }
        text + "</em>"
    }
}

impl Node for Bold {
    fn get_string(&self)->String {
        let mut text = String::from("<strong>");
        for child in self.children.iter() {
            text += &child.get_string();
        }
        text + "</strong>"
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