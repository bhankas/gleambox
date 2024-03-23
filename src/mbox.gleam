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

  get_headers("/home/payas/Downloads/mboxtest")
}

pub fn get_headers(filepath: String) -> Dict(String, String) {
    let assert Ok(header_pattern) = regex.compile("^[^:]+: ", regex.Options(True, True))

    filepath
    |> simplifile.read
    |> result.unwrap(or: "foo")
    |> string.split_once("\n\n")
    |> result.unwrap(or: #("", ""))
    |> pair.first // get only headers
    |> function.tap(io.println)
    |> regex.split(header_pattern, _)
    |> list.map(io.println)

    new()
}
