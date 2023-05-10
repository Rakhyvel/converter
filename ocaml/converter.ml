(* To run: ocamlc converter.ml && ./a.out
Pros:
  - Nice record syntax/typing
  - Pattern matching
Cons:
  - No line comments
  - `let in` everywhere
  - Really poor divergence
  - No generic print function
  - `else-if`
  - Poor standard library support (but maybe Lists aren't really the best option in OCaml)
  - Non-mutally recursive functions (fairly lame!)
*)

let explode s = List.init (String.length s) (String.get s)
let implode l = String.of_seq (List.to_seq l)

let rec last = function
  | x::[] -> x
  | _::xs -> last xs
  | []    -> failwith "no element"

let read_whole_file filename =
  (* open_in_bin works correctly on Unix and Windows *)
  let ch = open_in_bin filename in
  let s = really_input_string ch (in_channel_length ch) in
  close_in ch;
  s

type token = {data: string; line: int; col: int}

type node = 
  | Header of int * node list
  | Paragraph of node list
  | CodeBlock of string
  | Image of string * string
  | Text of string
  | Italic of node list
  | Bold of node list
  | Code of string
  | Link of string * string

let is_special_char c = String.contains "_*`#[]()!" c

let rec tokenize contents token line col oldCol = 
  match contents with
  | []      -> [{data = (implode token); line = line; col = col}]
  | c::rest -> 
    let oldC = last(token) in
    if c == '\n' 
      then {data = (implode token); line = line; col = oldCol} :: tokenize rest [c] (line + 1) 0 (col + 1)
    else if oldC == '\n' || (String.contains "#[(!" c) || (is_special_char c != is_special_char oldC) 
      then {data = (implode token); line = line; col = oldCol} :: tokenize rest [c] (line + 1) 0 (col + 1)
    else tokenize rest (token @ [c]) line (col + 1) oldCol

let rec get_header_size tokens acc =
  match tokens with
  | [] -> failwith "Expected a header."
  | head::tail -> 
    if String.equal head.data "#" then
      get_header_size tail (acc + 1)
    else
      acc, head::tail

let rec take_until tokens sentinel acc =
  match tokens with
  | [] -> failwith "Expected sentinel."
  | top::rest ->
    if String.equal top.data sentinel then
      (acc, rest)
    else
      take_until rest sentinel (acc ^ top.data)

let parse_code tokens =
  let (text, rest) = take_until tokens "`" "" in
  (Code text), rest

let parse_link tokens =
  match tokens with
  | {data = text; _}::{data = "]"; _}::{data = "("; _}::{data = url; _}::{data = ")"; _}::rest -> 
    Link(text, url), rest
  | _ -> failwith "Expected link text."

let rec parse_formatted_text tokens bounds acc =
  match tokens with
  | [] -> failwith "Expected formatted text."
  | top::rest ->
    if List.mem (top.data) bounds then 
      acc, rest
    else if (String.equal top.data "*") || (String.equal top.data "_") then
      let (children, new_rest) = parse_formatted_text rest ("*"::"_"::bounds) [] in
      parse_formatted_text new_rest bounds (acc @ [Italic children])
    else if (String.equal top.data "**") || (String.equal top.data "__") then
      let (children, new_rest) = parse_formatted_text rest ("**"::"__"::bounds) [] in
      parse_formatted_text new_rest bounds (acc @ [Bold children])
    else if (String.equal top.data "`") then
      let (node, new_rest) = parse_code rest in
      parse_formatted_text new_rest bounds (acc @ [node])
    else if (String.equal top.data "[") then
      let (node, new_rest) = parse_link rest in
      parse_formatted_text new_rest bounds (acc @ [node])
    else
      parse_formatted_text rest bounds (acc @[Text top.data])

let parse_header tokens =
  let (size, rest) = get_header_size tokens 1 in
  let (children, rest2) = parse_formatted_text rest ["\n"] [] in
  Some (Header(size, children)), rest2

let parse_paragraph tokens =
  let (children, rest) = parse_formatted_text tokens ["\n"] [] in
  Some (Paragraph(children)), rest

let parse_codeblock tokens =
  let (text, rest) = take_until tokens "```" "" in
  Some (CodeBlock(text)), rest

let parse_image tokens =
  match tokens with
  | {data = "["; _}::{data = text; _}::{data = "]"; _}::{data = "("; _}::{data = url; _}::{data = ")"; _}::rest -> 
    Some (Image(text, url)), rest
  | _ -> failwith "Expected link text."

let parse_node contents =
  match contents with
  | []        -> (None, [])
  | top::rest -> 
    match top.data with
    | "#"   -> parse_header rest
    | "```" -> parse_codeblock rest
    | "!"   -> parse_image rest
    | "\n"  -> (None, rest)
    | _     -> parse_paragraph ([top] @ rest)

let rec parse_document tokens acc =
  match tokens with
  | [] -> acc
  | _  ->
    let (maybe_node, rest) = parse_node tokens in
    match maybe_node with
    | None      -> parse_document rest acc
    | Some node -> parse_document rest (acc @ [node])

let rec get_HTML node =
  match node with
  | Header (size, children) -> 
    let child = get_HTML_list_header children in
    Printf.sprintf "<h%d>%s</h%d>\n" size child size
  | Paragraph children -> Printf.sprintf "<p>%s</p>\n\n" (get_HTML_list children "")
  | CodeBlock text -> Printf.sprintf "<pre><code>%s</code></pre>\n\n" text
  | Image (text, url) -> Printf.sprintf "<img src=\"%s\" alt=\"%s\" />" url text
  | Text text -> text
  | Italic children -> Printf.sprintf "<em>%s</em>" (get_HTML_list children "")
  | Bold children -> Printf.sprintf "<strong>%s</strong>" (get_HTML_list children "")
  | Code text -> Printf.sprintf "<code>%s</code>" text
  | Link (text, url) -> Printf.sprintf "<a href=\"%s\">%s</a>" url text

and get_HTML_list tokens acc =
  match tokens with
  | [] -> acc
  | top::rest -> get_HTML_list rest (acc ^ (get_HTML top))

and get_HTML_list_header tokens =
  match tokens with
  | [] -> failwith "Expected something in the header, tbh"
  | top::rest -> get_HTML_list rest (String.trim (get_HTML top))

let () =
  let input = explode (read_whole_file "../input.md") in
  match input with
  | [] -> ()
  | first::contents ->
    let tokens = tokenize contents [first] 1 1 1 in
    let document = parse_document tokens [] in
    let output_str = get_HTML_list document "" in
    let oc = open_out "output.html" in
    Printf.fprintf oc "%s\n" output_str;
    close_out oc;