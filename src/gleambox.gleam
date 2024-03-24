import gleam/result
import gleam/dict.{type Dict}
import gleam/list
import gleam/string
import gleam/pair
import gleam/regex

pub type MBox {
  MBox(headers: Dict(String, String), body: String)
}

pub fn parse(mboxcontents: String) -> MBox {
  MBox(headers: parse_headers(mboxcontents), body: parse_body(mboxcontents))
}

pub fn get_headers(mbox: MBox) -> Dict(String, String) {
  mbox.headers
}

pub fn get_header(mbox: MBox, key: String) -> Result(String, Nil) {
  mbox.headers
  |> dict.get(key)
}

pub fn get_body(mbox: MBox) -> String {
  mbox.body
}

pub fn get_from(mbox: MBox) -> Result(String, Nil) {
  get_header(mbox, "From")
}

pub fn get_to(mbox: MBox) -> Result(String, Nil) {
  get_header(mbox, "To")
}

pub fn get_date(mbox: MBox) -> Result(String, Nil) {
  get_header(mbox, "Date")
}

pub fn get_subject(mbox: MBox) -> Result(String, Nil) {
  get_header(mbox, "Subject")
}

pub fn get_message_id(mbox: MBox) -> Result(String, Nil) {
  get_header(mbox, "Message-ID")
}

pub fn get_references(mbox: MBox) -> List(String) {
  get_header(mbox, "References")
  |> result.unwrap(or: "Error")
  |> string.split(" ")
}

fn parse_body(mboxcontents: String) -> String {
  mboxcontents
  // split headers from body
  |> string.split_once("\n\n")
  |> result.unwrap(or: #("", ""))
  // get only body
  |> pair.second
}

fn parse_headers(mboxcontents: String) -> Dict(String, String) {
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
    regex.compile(": [^\n]+\n\\s+[^\n]+$", regex.Options(True, True))

  s
  |> regex.scan(multi_line_value, _)
  |> list.map(fn(match) { match.content })
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
