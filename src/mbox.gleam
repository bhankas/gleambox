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
  let assert Ok(header_pattern) =
    regex.compile("[^:\\s]+: ", regex.Options(True, True))

  filepath
  |> simplifile.read
  |> result.unwrap(or: "foo")
  |> string.split_once("\n\n")
  |> result.unwrap(or: #("", ""))
  |> pair.first
  // get only headers
  |> function.tap(io.println)
  |> regex.scan(header_pattern, _)
  |> list.map(fn(match) -> String {
    match.content
    |> string.drop_right(2)
  })
  |> list.map(io.debug)

  new()
}
