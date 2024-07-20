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
  InvalidMBox(path: String)
}

pub type Mail {
  Mail(
    from: Result(String, Nil),
    to: Result(String, Nil), // TODO: convert to List(String)
    subject: Result(String, Nil),
    message_id: Result(String, Nil),
    date: Result(Time, Nil),
    body: Result(String, Nil),
    headers: Result(Dict(String, String), Nil),
  )
  InvalidMail(path: String)
}

pub fn parse(mboxcontents: String) -> MBox {
  let headers = parse_headers(mboxcontents)
  let body = parse_body(mboxcontents)

  case headers, body {

  }

  MBox(headers: parse_headers(mboxcontents), body: parse_body(mboxcontents))
}

pub fn get_headers(mbox: MBox) -> Result(Dict(String, String), Nil) {
  case mbox {
    InvalidMBox(_) -> Error(Nil)
    MBox(headers, _) -> Ok(headers)
  }
}

pub fn get_header(mbox: MBox, key: String) -> Result(String, Nil) {
  case mbox {
    MBox(headers, _) -> headers |> dict.get(key)
    InvalidMBox(_) -> Error(Nil)
  }
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
fn mail_date(mail: Mail) -> Result(Time, Nil) {
  case mail {
    Mail(_, _, _, _, date, _, _) -> date
    InvalidMail(_) -> Error(Nil)
  }
}

// done
fn mail_from(mail: Mail) -> Result(String, Nil) {
  case mail {
    Mail(from, _, _, _, _, _, _) -> from
    InvalidMail(_) -> Error(Nil)
  }
}

// done
fn mail_to(mail: Mail) -> Result(String, Nil) {
  case mail {
    Mail(_, to, _, _, _, _, _) -> to
    InvalidMail(_) -> Error(Nil)
  }
}

fn mail_body(mail: Mail) -> Result(String, Nil) {
  case mail {
    Mail(_, _, _, _, _, body, _) -> body
    InvalidMail(_) -> Error(Nil)
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
  case mbox {
    InvalidMBox(path) -> InvalidMail(path)
    MBox(headers, body) ->
      Mail(
        from: dict.get(headers, "From"),
        to: dict.get(headers, "To"),
        message_id: dict.get(headers, "Message-ID"),
        subject: dict.get(headers, "Subject"),
        date: case dict.get(headers, "Date") {
          Ok(date_str) -> birl.parse(date_str)
          Error(_) -> Error(Nil)
        },
        headers: mbox |> get_headers,
        body: Ok(body),
      )
  }
}
