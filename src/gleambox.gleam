import gleam/result
import gleam/dict.{type Dict}
import gleam/list
import gleam/string
import gleam/pair
import gleam/regex.{type Match, Options}

pub fn get_body(mboxcontents: String) -> String {
  mboxcontents
  // split headers from body
  |> string.split_once("\n\n")
  |> result.unwrap(or: #("", ""))
  // get only body
  |> pair.second
}

pub fn get_headers(mboxcontents: String) -> Dict(String, String) {
  mboxcontents
  // split headers from body
  |> string.split_once("\n\n")
  |> result.unwrap(or: #("", ""))
  // get only headers
  |> pair.first
  // fix multi-line header values
  |> fix_multiline_values
  |> string.split("\n")
  // convert to dict of headers
  |> list.map(get_header_dict)
  |> dict.from_list
}

fn get_header_dict(s: String) -> #(String, String) {
  s
  |> string.split_once(": ")
  |> result.unwrap(or: #("", ""))
}

fn fix_multiline_values(s: String) -> String {
  let assert Ok(multi_line_value) =
    regex.compile(": [^\n]+\n\\s+[^\n]+$", Options(True, True))

  s
  |> regex.scan(multi_line_value, _)
  |> list.map(fn(match: Match) -> String { match.content })
  |> list.scan(s, remove_dead_space)
  |> list.first
  |> result.unwrap(or: "bar")
}

fn remove_dead_space(acc: String, matched_content: String) -> String {
  let assert Ok(dead_space) = regex.from_string("\\s+")

  matched_content
  |> regex.split(dead_space, _)
  |> string.join(" ")
  |> string.replace(acc, matched_content, _)
}