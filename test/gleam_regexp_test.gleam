import gleam/option.{None, Some}
import gleam/regexp.{type Match, Match, Options}
import gleeunit
import gleeunit/should

pub fn main() {
  gleeunit.main()
}

pub fn from_string_test() {
  let assert Ok(re) = regexp.from_string("[0-9]")

  regexp.check(re, "abc123")
  |> should.be_true

  regexp.check(re, "abcxyz")
  |> should.be_false

  let assert Error(_) = regexp.from_string("[0-9")
}

pub fn compile_test() {
  let options = Options(case_insensitive: True, multi_line: False)
  let assert Ok(re) = regexp.compile("[A-B]", options)

  regexp.check(re, "abc123")
  |> should.be_true

  let options = Options(case_insensitive: False, multi_line: True)
  let assert Ok(re) = regexp.compile("^[0-9]", options)

  regexp.check(re, "abc\n123")
  |> should.be_true

  // On target Erlang this test will only pass if unicode and ucp flags are set
  let assert Ok(re) = regexp.compile("\\s", options)
  // Em space == U+2003 == " " == used below
  regexp.check(re, " ")
  |> should.be_true
}

pub fn check_test() {
  let assert Ok(re) = regexp.from_string("^f.o.?")

  regexp.check(re, "foo")
  |> should.be_true

  regexp.check(re, "boo")
  |> should.be_false

  re
  |> regexp.check(content: "foo")
  |> should.be_true

  "boo"
  |> regexp.check(with: re)
  |> should.be_false

  // On target JavaScript internal `regexpp` objects are stateful when they
  // have the global or sticky flags set (e.g., /foo/g or /foo/y).
  // These following tests make sure that our implementation circumvents this.
  let assert Ok(re) = regexp.from_string("^-*[0-9]+")

  regexp.check(re, "1")
  |> should.be_true

  regexp.check(re, "12")
  |> should.be_true

  regexp.check(re, "123")
  |> should.be_true
}

pub fn split_test() {
  let assert Ok(re) = regexp.from_string(" *, *")

  regexp.split(re, "foo,32, 4, 9  ,0")
  |> should.equal(["foo", "32", "4", "9", "0"])
}

pub fn matching_split_test() {
  let assert Ok(re) = regexp.from_string("([+-])( *)(d)*")

  regexp.split(re, "abc+ def+ghi+  abc")
  |> should.equal([
    "abc", "+", " ", "d", "ef", "+", "", "", "ghi", "+", "  ", "", "abc",
  ])
}

pub fn scan_test() {
  let assert Ok(re) = regexp.from_string("Gl\\w+")

  regexp.scan(re, "!Gleam")
  |> should.equal([Match(content: "Gleam", submatches: [])])

  regexp.scan(re, "हGleam")
  |> should.equal([Match(content: "Gleam", submatches: [])])

  regexp.scan(re, "𐍈Gleam")
  |> should.equal([Match(content: "Gleam", submatches: [])])

  let assert Ok(re) = regexp.from_string("[oi]n a(.?) (\\w+)")

  regexp.scan(re, "I am on a boat in a lake.")
  |> should.equal([
    Match(content: "on a boat", submatches: [None, Some("boat")]),
    Match(content: "in a lake", submatches: [None, Some("lake")]),
  ])

  let assert Ok(re) = regexp.from_string("answer (\\d+)")
  regexp.scan(re, "Is the answer 42?")
  |> should.equal([Match(content: "answer 42", submatches: [Some("42")])])

  let assert Ok(re) = regexp.from_string("(\\d+)")
  regexp.scan(re, "hello 42")
  |> should.equal([Match(content: "42", submatches: [Some("42")])])

  regexp.scan(re, "你好 42")
  |> should.equal([Match(content: "42", submatches: [Some("42")])])

  regexp.scan(re, "你好 42 世界")
  |> should.equal([Match(content: "42", submatches: [Some("42")])])

  let assert Ok(re) = regexp.from_string("([+|\\-])?(\\d+)(\\w+)?")
  regexp.scan(re, "+36kg")
  |> should.equal([
    Match(content: "+36kg", submatches: [Some("+"), Some("36"), Some("kg")]),
  ])

  regexp.scan(re, "36kg")
  |> should.equal([
    Match(content: "36kg", submatches: [None, Some("36"), Some("kg")]),
  ])

  regexp.scan(re, "36")
  |> should.equal([Match(content: "36", submatches: [None, Some("36")])])

  regexp.scan(re, "-36")
  |> should.equal([Match(content: "-36", submatches: [Some("-"), Some("36")])])

  regexp.scan(re, "-kg")
  |> should.equal([])

  let assert Ok(re) =
    regexp.from_string("var\\s*(\\w+)\\s*(int|string)?\\s*=\\s*(.*)")
  regexp.scan(re, "var age int = 32")
  |> should.equal([
    Match(content: "var age int = 32", submatches: [
      Some("age"),
      Some("int"),
      Some("32"),
    ]),
  ])

  regexp.scan(re, "var age = 32")
  |> should.equal([
    Match(content: "var age = 32", submatches: [Some("age"), None, Some("32")]),
  ])

  let assert Ok(re) = regexp.from_string("let (\\w+) = (\\w+)")
  regexp.scan(re, "let age = 32")
  |> should.equal([
    Match(content: "let age = 32", submatches: [Some("age"), Some("32")]),
  ])

  regexp.scan(re, "const age = 32")
  |> should.equal([])
}

pub fn replace_0_test() {
  let assert Ok(re) = regexp.from_string(",")
  regexp.replace(in: "a,b,c,d", each: re, with: " ")
  |> should.equal("a b c d")
}

pub fn replace_1_test() {
  let assert Ok(re) = regexp.from_string("\\d")
  regexp.replace(in: "Hell1o, World!1", each: re, with: "")
  |> should.equal("Hello, World!")
}

pub fn replace_2_test() {
  let assert Ok(re) = regexp.from_string("🐈")
  regexp.replace(in: "🐈🐈 are great!", each: re, with: "🐕")
  |> should.equal("🐕🐕 are great!")
}

pub fn replace_3_test() {
  let assert Ok(re) = regexp.from_string("🐈")
  regexp.replace(re, "🐈🐈 are great!", "🐕")
  |> should.equal("🐕🐕 are great!")
}

pub fn match_map_0_test() {
  let replace = fn(match: Match) {
    case match.content {
      "1" -> "one"
      "2" -> "two"
      "3" -> "three"
      n -> n
    }
  }
  let assert Ok(re) = regexp.from_string("1|2|3")
  regexp.match_map(re, "1, 2, 3, 4", replace)
  |> should.equal("one, two, three, 4")
}

pub fn match_map_1_test() {
  let replace = fn(match: Match) {
    case match.submatches {
      [Some("1")] -> "one"
      [Some("2")] -> "two"
      [Some("3")] -> "three"
      _ -> match.content
    }
  }
  let assert Ok(re) = regexp.from_string("'(1|2|3)'")
  regexp.match_map(re, "'1', '2', '3', '4'", replace)
  |> should.equal("one, two, three, '4'")
}

// https://github.com/gleam-lang/regexp/issues/4
pub fn last_index_bug_test() {
  let assert Ok(re) = regexp.from_string("(b)")
  let assert [Match("b", [Some("b")])] = regexp.scan(re, "b")
  let assert True = regexp.check(re, "b")
  let assert [Match("b", [Some("b")])] = regexp.scan(re, "b")
}
