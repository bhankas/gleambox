import birl.{type Time}
import gleam/dict.{type Dict}
import gleam/io
import gleam/iterator.{type Iterator}
import gleam/list
import gleam/pair
import gleam/regex
import gleam/result
import gleam/string
import simplifile

pub type MBox {
  MBox(headers: Dict(String, String), body: String)
}

pub type Mail {
  Mail(
    from: String,
    to: List(String),
    subject: String,
    message_id: String,
    date: Time,
    body: String,
    headers: Dict(String, String),
  )
  InvalidMail
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

  multi_line_value
  |> regex.scan(s)
  |> list.map(fn(match) { match.content })
  |> list.scan(s, remove_dead_space)
  |> list.first
  |> result.unwrap(or: "bar")
}

fn remove_dead_space(acc: String, matched_content: String) -> String {
  let assert Ok(dead_space) = regex.from_string("\\s+")
  dead_space
  |> regex.split(matched_content)
  |> string.join(" ")
  |> string.replace(acc, matched_content, _)
}

// done
fn mail_date(mail: Mail) -> Time {
  case mail {
    Mail(_, _, _, _, date, _, _) -> date
    InvalidMail -> birl.now()
  }
}

// done
fn mail_from(mail: Mail) -> String {
  case mail {
    Mail(from, _, _, _, _, _, _) -> from
    InvalidMail -> ""
  }
}

// done
fn mail_to(mail: Mail) -> List(String) {
  case mail {
    Mail(_, to, _, _, _, _, _) -> to
    InvalidMail -> list.wrap("")
  }
}

fn mail_body(mail: Mail) -> String {
  case mail {
    Mail(_, _, _, _, _, body, _) -> body
    InvalidMail -> ""
  }
}

// done
pub fn maildir_iterator(mbox_path: String) -> Iterator(String) {
  mbox_path
  |> simplifile.get_files
  |> result.lazy_unwrap(list.new)
  |> iterator.from_list
  |> iterator.map(read_file)
}

// done
fn read_file(file_path: String) -> String {
  file_path
  |> simplifile.read
  |> result.unwrap(or: "")
}

// done
fn mbox_to_mail(mbox: MBox) -> Mail {
  Mail(
    from: mbox |> get_from |> result.unwrap(or: ""),
    to: mbox |> get_to |> result.unwrap(or: "") |> list.wrap,
    message_id: mbox |> get_message_id |> result.unwrap(or: ""),
    subject: mbox |> get_subject |> result.unwrap(or: ""),
    date: mbox
      |> get_date
      |> result.unwrap(or: "")
      |> birl.parse
      |> result.unwrap(or: birl.now()),
    headers: mbox |> get_headers,
    body: mbox |> get_body,
  )
}
