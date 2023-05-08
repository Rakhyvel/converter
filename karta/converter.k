; To run: karta converter.k
; Pros:
;   - Very terse
;   - Lambdas, with closures
;   - String interpolation
;   - `$` for parens until end of line
;   - `concatMap`, `readFile`, `elem`, `if` in prelude
;   - `where`, `let ... in`, which are lazily evaluated
;   - Pattern matching
; Cons:
;   - Doesn't exist... yet!

getHTMLMap = concatMap getHTML
getHTML =
    \ .Header, children, size -> "<h#{size}>#{getHTMLMap children}</h#{size}>"
    | .Paragraph, children -> "<p>#{getHTMLMap children}</p>"
    | .CodeBlock, text -> "<pre><code>#{text}</code></pre>"
    | .Image, text, url -> "<img src=\"#{url}\" alt=\"#{text}\" />"
    | .Text, text -> text
    | .Italic, children -> "<em>#{getHTMLMap children}</em>"
    | .Bold, children -> "<strong>#{getHTMLMap children}</strong>"
    | .Code, text -> "<code>#{text}</code>"
    | .Link, text, url -> "<a href=\"#{url}\">#{text}</a>"

main = writeFile "output.html" $ getHTMLMap $ parseDocument (tokenize, contents, [first], 1, 1, 1) []
    where (first:contents) = readFile "../input.md"

isSpecialChar = \c -> elem c, "_*`#[]()!"

tokenize =
    \ [], token, line, col, _ = [(token, line, col), (Token "\n", line, col)]
    | (c:rest), token, line, col, oldCol -> (
            \ elem c, "\n" -> token, line, oldCol : tokenize rest, [c], (line + 1), 0, (col + 1)
            | (elem oldC, "\n") or (elem c, "#[(!") or (isSpecialChar c != isSpecialChar oldC) -> token, line, oldCol : tokenize rest, [c], line, (col + 1), (col + 1)
            | true         -> tokenize rest, (token ++ [c]), line, (col + 1), oldCol
        ) (true)
        where oldC = last token

getHeaderSize =
    \ (head:tail), acc ->
        if tokenData head == "#"
        , getHeaderSize tail, (acc + 1)
        , (acc, head:tail)
    
parseFormattedText =
    \ (top:rest), bounds, acc -> (
            \ elem topData, bounds               -> (acc, rest)
            | topData =="*" or topData == "_"    -> parseFormattedText italicRest, bounds, (acc ++ (.Italic, italicChildren))
            | topData == "**" or topData == "__" -> parseFormattedText boldRest, bounds, (acc ++ (.Bold, boldChildren))
            | topData == "`"                     -> parseFormattedText codeRest, bounds, (acc ++ (.Code, codeText))
            | topData == "["                     -> parseFormattedText linkRest, bounds, (acc ++ (.Link, linkText, linkUrl))
            | true                               -> parseFormattedText rest, bounds, (acc ++ [.Text topData])
        ) (true)
        where
            topData                      = tokenData top
            (italicChildren, italicRest) = parseFormattedText rest, ("*":"_":bound), []
            (boldChildren, boldRest)     = parseFormattedText rest, ("**":"__":bound), []
            (codeText, codeRest)         = takeUntil rest, "`", ""
            ((linkText, _, _) : ("]", _, _) : ("(", _, _) : (linkUrl, _, _) : (")", _, _) : linkRest) = rest

takeUntil = 
    \ (top:rest), sentinel, acc ->
        if tokenData top == sentinel
        , (acc, rest)
        , (takeUntil rest, sentinel (acc ++ tokenData top))
            
parseDocument =
    \ [], acc     -> acc
    | tokens, acc -> 
        if maybeNode
        , parseDocument rest, (acc ++ [maybeNode])
        , parseDocument rest, acc
        where (maybeNode, rest) = parseNode tokens

parseNode =
    \ []         -> (nil, [])
    | (top:rest) -> (
            \ "#"   -> (.Header headerSize, headerChildren), newHeaderRest
            | "```" -> (.CodeBlock, codeBlockText), codeBlockRest
            | "!"   -> (.Image, imageText, url), imageRest
            | "\n"  -> nil, rest
            | _     -> (.Paragraph, paragraphChildren), paragraphRest
        ) (tokenData top)
        where
            (paragraphChildren, paragraphRest) = parseFormattedText (top:rest), ["\n"], []
            (codeBlockText, codeBlockRest)     = takeUntil rest, "```", ""
            (("[", _, _) : (imageText, _, _) : ("]", _, _) : ("(", _, _) : (url, _, _) : (")", _, _) : imageRest) = rest
            (headerSize, headerRest)           = getHeaderSize rest, 1
            (headerChildren, newHeaderRest)    = parseFormattedText headerRest, ["\n"], []