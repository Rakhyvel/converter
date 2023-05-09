(* To run:  
Pros:
  - Nice record syntax/typing
  - Pattern matching
Cons:
  - No line comments
  - `let in` everywhere
  - Pretty bad syntax errors. Show me the line!
  - Really poor divergence
  - No generic print function
  - `else-if`
  - Cant just print shit
  - Poor standard library support
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
  | Header of int * int list
  | Paragraph of int list
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

let parse_node contents =
  match contents with
  | []        -> (None, [])
  | top::rest -> 
    match top.data with
    | "#"   -> parse_header(rest)
    | "```" -> parse_codeblock(rest)
    | "!"   -> parse_image(rest)
    | "\n"  -> (None, rest)
    | _     -> parse_paragraph([top] @ rest)

let rec parse_document tokens acc =
  match tokens with
  | [] -> acc
  | _  ->
    let (maybe_node, rest) = parse_node tokens in
    match maybe_node with
    | None      -> parse_document rest acc
    | Some node -> parse_document rest (acc @ [node])


let () =
  let first::contents = explode (read_whole_file "../input.md") in
  let tokens = tokenize contents [first] 1 1 1 in
  ()
  