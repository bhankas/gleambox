import gleam/io
import simplifile
import gleam/result
import gleam/dict
import headers
import gleam/list

pub fn main() {
  "/home/payas/Downloads/mboxtest"
  |> simplifile.read
  |> result.unwrap(or: "")
  |> headers.get_headers
  |> dict.to_list
  |> list.map(io.debug)
}
