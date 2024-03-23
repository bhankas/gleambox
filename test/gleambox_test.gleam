import gleeunit
import gleeunit/should
import gleambox
import simplifile
import gleam/result
import gleam/dict
import gleam/list

pub fn main() {
  gleeunit.main()
}

pub fn get_from_test() {
  "./test/mboxtest"
  |> simplifile.read
  |> result.unwrap(or: "")
  |> gleambox.parse
  |> gleambox.get_from
  |> result.unwrap(or: "ERROR")
  |> should.equal("Anonymous Courage <from@gmail.com>")
}

pub fn get_to_test() {
  "./test/mboxtest"
  |> simplifile.read
  |> result.unwrap(or: "")
  |> gleambox.parse
  |> gleambox.get_to
  |> result.unwrap(or: "ERROR")
  |> should.equal("Anonymous Coward <to@gmail.com>")
}

pub fn get_headers_test() {
  "./test/mboxtest"
  |> simplifile.read
  |> result.unwrap(or: "")
  |> gleambox.parse
  |> gleambox.get_headers
  |> dict.size
  |> should.equal(13)
}

pub fn get_references_test() {
  "./test/mboxtest"
  |> simplifile.read
  |> result.unwrap(or: "")
  |> gleambox.parse
  |> gleambox.get_references
  |> list.fold(0, fn(count, _) { count + 1 })
  |> should.equal(2)
}
