-- To run: ghc converter.hs && converter.exe ../input.md
-- Pros:
--      - Lazy evaluation is powerful
-- Cons:
--      - Bad not-equals syntax
--      - Function parameter names and types are not coupled
--      - No default parameters
--      - Record fields are functions that are global namespaced (WTF!)
--      - No way really to name the fields in an enum
--      - It's all well and concicse but its very difficult to work in I think. Syntax is weird

data Token = Token {tokenData::String, line::Int, col::Int}

data Node =
      Header Int [Node]
    | Paragraph [Node]
    | CodeBlock String
    | Image String String
    | Text String
    | Italic [Node]
    | Bold [Node]
    | Code String
    | Link String String

getHTMLMap = concatMap getHTML
getHTML (Header size children) =
    "<h" ++ sizeStr ++ ">" ++ getHTMLMap children ++ "</h" ++ sizeStr ++ ">\n"
    where sizeStr = show size
getHTML (Paragraph children) = "<p>" ++ getHTMLMap children ++ "</p>\n\n"
getHTML (CodeBlock text) = "<pre><code>" ++ text ++ "</code></pre>\n\n"
getHTML (Image text url) = "<img src=\"" ++ url ++ "\" alt=\"" ++ text ++ "\" />\n\n"
getHTML (Text text) = text
getHTML (Italic children) = "<em>" ++ getHTMLMap children ++ "</em>"
getHTML (Bold children) = "<strong>" ++ getHTMLMap children ++ "</strong>"
getHTML (Code text) = "<code>" ++ text ++ "</code>"
getHTML (Link text url) = "<a href=\"" ++ url ++ "\">" ++ text ++ "</a>"

main :: IO ()
main = do
    (first:contents) <- readFile "../input.md" -- Hard coded for now
    writeFile "output.html" $ getHTMLMap $ parseDocument (tokenize contents [first] 1 1 1) []

isSpecialChar c = c `elem` "_*`#[]()!"

tokenize :: [Char] -> [Char] -> Int -> Int -> Int -> [Token]
tokenize (c:rest) token line col oldCol
    |  c `elem` "\n"                           = Token token line oldCol : tokenize rest [c] (line + 1) 0 (col + 1)
    |  oldC `elem` "\n"
    || c `elem` "#[(!"
    || (isSpecialChar c /= isSpecialChar oldC) = Token token line oldCol : tokenize rest [c] line (col + 1) (col + 1)
    |  otherwise                               = tokenize rest (token ++ [c]) line (col + 1) oldCol
    where oldC = last token
tokenize [] token line col _ =
    [Token token line col, Token "\n" line col]

getHeaderSize [] _ = error "error: unexpected end of file"
getHeaderSize (head : tail) acc =
    if tokenData head == "#" then
        getHeaderSize tail (acc + 1)
    else
        (acc, head : tail)

parseFormattedText (top : rest) bounds acc
    |  topData `elem` bounds = (acc, rest)
    |  topData == "*"
    || topData == "_" = parseFormattedText italicRest bounds (acc ++ [Italic italicChildren])
    |  topData == "**"
    || topData == "__" = parseFormattedText boldRest bounds (acc ++ [Bold boldChildren])
    |  topData == "`" = parseFormattedText codeRest bounds (acc ++ [Code codeText])
    |  topData == "[" = parseFormattedText linkRest bounds (acc ++ [Link linkText linkUrl])
    | otherwise = parseFormattedText rest bounds (acc ++ [Text topData])
        where
            topData = tokenData top
            (italicChildren, italicRest)    = parseFormattedText rest ("*" :"_" : bounds) []
            (boldChildren, boldRest)        = parseFormattedText rest ("**" :"__" : bounds) []
            (codeText, codeRest)            = takeUntil rest "`" ""
            ((Token linkText _ _) : (Token "]" _ _) : (Token "(" _ _) : (Token linkUrl _ _) : (Token ")" _ _) : linkRest) = rest
parseFormattedText _ _ _ = error "error: syntax error"

takeUntil (top:rest) sentinel acc =
    if tokenData top == sentinel then
        (acc, rest)
    else
        takeUntil rest sentinel (acc ++ tokenData top)
takeUntil _ _ _ = error "error: syntax error"

parseDocument [] acc = acc
parseDocument tokens acc =
    case maybeNode of
        Nothing   -> parseDocument rest acc
        Just node -> parseDocument rest (acc ++ [node])
    where (maybeNode, rest) = parseNode tokens

parseNode [] = (Nothing, [])
parseNode (top:rest) =
    case tokenData top of
        "#"     -> (Just (Header headerSize headerChildren), newHeaderRest)
        "```"   -> (Just (CodeBlock codeBlockText), codeBlockRest)
        "!"     -> (Just (Image imageText url), imageRest)
        "\n"    -> (Nothing, rest)
        _       -> (Just (Paragraph paragraphChildren), paragraphRest)
    where 
        (paragraphChildren, paragraphRest) = parseFormattedText (top:rest) ["\n"] []
        (codeBlockText, codeBlockRest) = takeUntil rest "```" ""
        ((Token "[" _ _) : (Token imageText _ _) : (Token "]" _ _) : (Token "(" _ _) : (Token url _ _) : (Token ")" _ _) : imageRest) = rest
        (headerSize, headerRest) = getHeaderSize rest 1
        (headerChildren, newHeaderRest) = parseFormattedText headerRest ["\n"] []