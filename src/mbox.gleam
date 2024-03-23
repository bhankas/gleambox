import gleam/io
import gleam/dict.{type Dict, new}
import simplifile
import gleam/result
import gleam/string
import gleam/list
import gleam/pair
import gleam/regex
import gleam/function

pub fn main() {
  io.println("Hello from mbox!")

  get_header_keys("/home/payas/Downloads/mboxtest")
}

pub fn get_header_keys(filepath: String) -> Dict(String, String) {
  let assert Ok(header_key_pattern) =
    regex.compile("[^:\\s]+: ", regex.Options(True, True))

  filepath
  |> simplifile.read
  |> result.unwrap(or: "foo")
  // split headers from body
  |> string.split_once("\n\n")
  |> result.unwrap(or: #("", ""))
  // get only headers
  |> pair.first
  |> function.tap(print)
  // handle multi-line header values
  |> function.tap(fix_multiline_values)
  // |> list.map(
  //   fn(s: String) -> String {
  //     regex.split(dead_space, s)
  //     |> string.join("|")
  //   },
  // )
  // |> string.join(" ")
  // |> print
  |> regex.scan(header_key_pattern, _)
  // get headers
  |> list.map(fn(match) -> String {
    match.content
    |> string.replace(": ", "")
  })
  |> list.map(print)

  new()
}

fn print(s: String) -> Nil {
  io.println("------\n" <> s <> "\n----------")
}

fn fix_multiline_values(s: String) -> String {
  let assert Ok(multi_line_value) =
    regex.compile(": [^\n]+\n\\s+[^\n]+$", regex.Options(True, True))

  let assert Ok(dead_space) = regex.compile("\\s+", regex.Options(True, True))

  s
  |> regex.scan(multi_line_value, _)
  |> list.map(fn(match: regex.Match) -> String {
    match.content
    // |> string.drop_left(2)
    |> regex.split(dead_space, _)
    |> string.join(" ")
    |> string.replace(s, match.content, _)
  })
  |> io.debug
  |> list.map(regex.scan(dead_space, _))
  |> list.flatten
  |> list.map(fn(match: regex.Match) -> String { match.content })
  |> io.debug
  |> string.join("||")
}
