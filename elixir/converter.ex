# To run:
#   iex
#   c("converter.ex")
#   Converter.main "../input.md"
# Pros:
#   - Modules
#   - Atoms, which seem like enums? Maybe
#   - Pattern matching functions
#   - Delta operator
#   - cond is cool
#   - Debugging is easy because everything is printable. I usually knew what was going on through the 'state' of my program
#   - Default values for function parameters
#   - 'when' clause for functions
# Cons:
#   - Functional programming is different than what I'm used to. Not much of a con but it makes it's a new way of solving problems
#   - Can't define functions in other functions (likely because this would mess with overloaded methods. Haskell allows inner functions because it has static function typing)

defmodule Converter do
  defmodule Token, do: defstruct data: "", line: 0, col: 0

  defmodule Header, do: defstruct size: 0, children: []

  defmodule Paragraph, do: defstruct children: []

  defmodule CodeBlock, do: defstruct text: ""

  defmodule Image, do: defstruct text: "", url: ""

  defmodule Text, do: defstruct text: ""

  defmodule Italic, do: defstruct children: []

  defmodule Bold, do: defstruct children: []

  defmodule Code, do: defstruct text: ""

  defmodule Link, do: defstruct text: "", url: ""

  def main(filename) do
    # Open input file, read contents
    contents = File.read!(filename)

    # Create parser, parse documents
    IO.binwrite(File.open!("output.html", [:write]),
    String.graphemes(String.slice(contents, 1, String.length contents))
      |>tokenize(String.first(contents), 1, 1, 1)
      |>parse_document([])
      |>get_HTML_list(""))
  end

  def string_contains(str, c), do: (Enum.member?(String.graphemes(str), c))

  def isSpecialChar(c), do: string_contains("_*`#[]()!", c)

  def tokenize([c | rest], data, line, col, oldCol) do
    oldC = String.last data
    cond do
      string_contains("\r\n", oldC) or
      string_contains("#[(!", c) or
      (isSpecialChar c) != (isSpecialChar oldC) ->  [%Token{data: String.replace(data, "\r", ""), line: line, col: oldCol}] ++ tokenize(rest, c, line, col + 1, col + 1)
      string_contains("\r\n", c) ->                 [%Token{data: String.replace(data, "\r", ""), line: line, col: oldCol}] ++ tokenize(rest, c, line + 1, 0, col + 1)
      true ->                                       tokenize(rest, data <> c, line, col + 1, oldCol)
    end
  end

  def tokenize([], data, line, col, _) do
    [%Token{data: data, line: line, col: col}, %Token{data: "\n", line: line, col: col}]
  end

  def syntax_error(token, msg) do
    IO.puts "error: #{token.line}:#{token.col} #{msg}, got `#{token.data}`"
    Process.exit(self, :normal)
  end

  def getHeaderSize([head | tail], acc \\ 1) do
    if head.data == "#" do
      getHeaderSize(tail, acc + 1)
    else
      {acc, [head] ++ tail}
    end
  end

  # -> (list of nodes, rest of tokens)
  def parse_formatted_text([top | rest], bounds, acc \\ []) do
    cond do
      Enum.member?(bounds, top.data)  -> {acc, rest}
      top.data === "*" or
      top.data === "_" -> (
        {children, new_rest} = parse_formatted_text(rest, ["*", "_"] ++ bounds)
        parse_formatted_text(new_rest, bounds, acc ++ [%Italic{children: children}])
      )
      top.data === "**" or
      top.data === "__" -> (
        {children, new_rest} = parse_formatted_text(rest, ["**", "__"] ++ bounds, [])
        parse_formatted_text(new_rest, bounds, acc ++ [%Bold{children: children}])
      )
      top.data === "`" -> (
        {node, new_rest} = parse_code(rest)
        parse_formatted_text(new_rest, bounds, acc ++ [node])
      )
      top.data === "[" -> (
        {node, new_rest} = parse_link(rest)
        parse_formatted_text(new_rest, bounds, acc ++ [node])
      )
      true -> parse_formatted_text(rest, bounds, acc ++ [%Text{text: top.data}])
    end
  end

  def take_until([top | rest], sentinel, acc) do
    if top.data == sentinel do
      {acc, rest}
    else
      take_until(rest, sentinel, acc <> top.data)
    end
  end

  def parse_document(tokens, acc) when is_list(tokens) and length(tokens) > 0 do
    {node, rest} = parse_node tokens
    if node do
      parse_document(rest, acc ++ [node])
    else
      parse_document(rest, acc)
    end
  end

  def parse_document([], acc), do: acc

  def parse_node([top | rest]) do
    case top.data do
      "#"   -> parse_header(rest)
      "```" -> parse_codeblock(rest)
      "!"   -> parse_image(rest)
      "\n"  -> {nil, rest}
      _     -> parse_paragraph([top] ++ rest)
    end
  end

  def parse_header(tokens) do
    {size, rest} = getHeaderSize tokens
    {children, rest} = parse_formatted_text(rest, ["\n"])
    {%Header{size: size, children: children}, rest}
  end

  def parse_paragraph(tokens) do
    {children, rest} = parse_formatted_text(tokens, ["\n"])
    {%Paragraph{children: children}, rest}
  end

  def parse_codeblock(tokens) do
    {text, rest} = take_until(tokens, "```", "")
    {%CodeBlock{text: text}, rest}
  end

  def parse_image([%Token{data: "["}, %Token{data: text}, %Token{data: "]"}, %Token{data: "("}, %Token{data: url}, %Token{data: ")"} | rest]) do
    {%Image{text: text, url: url}, rest}
  end

  def parse_code(tokens) do
    {text, rest} = take_until(tokens, "`", "")
    {%Code{text: text}, rest}
  end

  def parse_link([%Token{data: text}, %Token{data: "]"}, %Token{data: "("}, %Token{data: url}, %Token{data: ")"} | rest]) do
    {%Link{text: text, url: url}, rest}
  end

  def parse_link([top | _]) do
    syntax_error(top, "expected a link")
  end

  def get_HTML_list_header([top | rest]) do
    get_HTML_list(rest, String.trim(get_HTML(top)))
  end

  def get_HTML_list([top | rest], acc) do
    get_HTML_list(rest, acc <> get_HTML(top))
  end

  def get_HTML_list([], acc), do: acc

  def get_HTML(node) do
    case node do
      %Header{size: size, children: children} -> "<h#{Integer.to_string(size)}>#{get_HTML_list_header(children)}</h#{Integer.to_string(size)}>\n"
      %Paragraph{children: children}          -> "<p>#{get_HTML_list(children, "")}</p>\n\n"
      %CodeBlock{text: text}                  -> "<pre><code>#{text}</code></pre>\n\n"
      %Image{text: text, url: url}            -> "<img src=\"#{url}\" alt=\"#{text}\" />"
      %Text{text: text}                       -> text
      %Italic{children: children}             -> "<em>#{get_HTML_list(children, "")}</em>"
      %Bold{children: children}               -> "<strong>#{get_HTML_list(children, "")}</strong>"
      %Code{text: text}                       -> "<code>#{text}</code>"
      %Link{text: text, url: url}             -> "<a href=\"#{url}\">#{text}</a>"
    end
  end
end
