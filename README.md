# mbox

Read mbox files.

WARNING: This library is a personal project to learn Gleam. It is *extremely* incomplete, barely works, highly *un* - optimized, and is NOT guaranteed to work, in present or future. I do intend to make it useable and utilise in another project, but right now, if you use it and it breaks stuff, you get to keep all the pieces. Be warned and prosper.

[![Package Version](https://img.shields.io/hexpm/v/mbox)](https://hex.pm/packages/mbox)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/mbox/)

```sh
gleam add mbox
```
```gleam
import mbox
import simplifile

pub fn main() {
  let mboxcontents =
    "/path/to/file"
    |> simplifile.read
    |> result.unwrap(or: "")

  mboxcontents
  |> mbox.get_headers
  |> dict.to_list
  |> list.map(io.debug)

  mboxcontents
  |> mbox.get_body
  |> io.println
}
```

Further documentation can be found at <https://hexdocs.pm/mbox>.

## Development

```sh
gleam run   # Run the project
gleam test  # Run the tests
gleam shell # Run an Erlang shell
```
