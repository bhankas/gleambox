import birl.{type Time}
import gleam/dict.{type Dict}
// import gleam/io
import gleam/iterator.{type Iterator}
import gleam/list
import gleam/pair
import gleam/regex
import gleam/result
import gleam/string
import simplifile

pub type MBox {
  MBox(headers: Dict(String, String), body: String)
  InvalidMBox
}

pub type Mail {
  Mail(
    from: Result(String, Nil),
    to: Result(String, Nil),
    // TODO: convert to List(String)
    subject: Result(String, Nil),
    message_id: Result(String, Nil),
    date: Result(Time, Nil),
    body: Result(String, Nil),
    headers: Result(Dict(String, String), Nil),
  )
  InvalidMail
}

pub fn parse(mboxcontents: String) -> MBox {
  let headers = parse_headers(mboxcontents)
  let body = parse_body(mboxcontents)

  case headers, body {
    Ok(parsed_headers), Ok(parsed_body) ->
      MBox(headers: parsed_headers, body: parsed_body)
    _, _ -> InvalidMBox
  }
}

pub fn get_headers(mbox: MBox) -> Result(Dict(String, String), Nil) {
  case mbox {
    InvalidMBox -> Error(Nil)
    MBox(headers, _) -> Ok(headers)
  }
}

pub fn get_header(mbox: MBox, key: String) -> Result(String, Nil) {
  case mbox {
    MBox(headers, _) -> headers |> dict.get(key)
    InvalidMBox -> Error(Nil)
  }
}

fn parse_body(mboxcontents: String) -> Result(String, Nil) {
  // split headers from body
  case string.split_once(mboxcontents, "\n\n") {
    Ok(pair) -> pair.second(pair) |> Ok
    Error(_) -> Error(Nil)
  }
}

fn parse_headers(mboxcontents: String) -> Result(Dict(String, String), Nil) {
  case string.split_once(mboxcontents, "\n\n") {
    Ok(pair) ->
      pair.first(pair)
      // fix multi-line header values
      |> fix_multiline_values
      |> string.split("\n")
      // convert to dict of headers
      |> list.map(get_header_dict)
      |> dict.from_list
      |> Ok
    Error(_) -> Error(Nil)
  }
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

pub fn maildir_iterator(mbox_path: String) -> Iterator(String) {
  mbox_path
  |> simplifile.get_files
  |> result.lazy_unwrap(list.new)
  |> iterator.from_list
  |> iterator.map(read_file)
}

// TODO: better error
pub fn maildir_iterate(maildir_path: String) -> Iterator(#(String, String)) {
  case simplifile.get_files(maildir_path) {
    Ok(maillist) -> iterator.from_list(maillist) |> iterator.map(fn(path) { #(path, read_file(path)) })
    Error(_) -> #("", "") |> list.wrap |> iterator.from_list
  }
}

// pub fn main() {
//   maildir_iterate("/home/payas/.mail/Gmail/[Gmail]/All Mail/cur")
//   |> iterator.each(fn(mboxpair) {
//     case parse(pair.second(mboxpair)) {
//       InvalidMBox -> io.debug("ERR MBOX: " <> pair.first(mboxpair))
//       MBox(headers, body) ->
//         case mbox_to_mail(MBox(headers, body)) {
//           InvalidMail -> io.debug("ERR MAIL: " <> pair.first(mboxpair))
//           _ -> io.debug("SUCCESS: " <> pair.first(mboxpair))
//         }
//     }
//   })
// }

fn read_file(file_path: String) -> String {
  file_path
  |> simplifile.read
  |> result.unwrap(or: "")
}

fn mbox_to_mail(mbox: MBox) -> Mail {
  case mbox {
    InvalidMBox -> InvalidMail
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
