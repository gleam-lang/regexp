import { Error, List, Ok } from "./gleam.mjs";
import {
  CompileError as RegexCompileError,
  Match as RegexMatch,
} from "./gleam/regexp.mjs";
import { Some, None } from "../gleam_stdlib/gleam/option.mjs";
import * as $string from "../gleam_stdlib/gleam/string.mjs";

export function check(regex, string) {
  regex.lastIndex = 0;
  return regex.test(string);
}

export function compile(pattern, options) {
  try {
    let flags = "gu";
    if (options.case_insensitive) flags += "i";
    if (options.multi_line) flags += "m";
    return new Ok(new RegExp(pattern, flags));
  } catch (error) {
    const number = (error.columnNumber || 0) | 0;
    return new Error(new RegexCompileError(error.message, number));
  }
}

export function split(regex, string) {
  return List.fromArray(
    string.split(regex).map((item) => (item === undefined ? "" : item)),
  );
}

export function scan(regex, string) {
  const matches = Array.from(string.matchAll(regex)).map((match) => {
    const content = match[0];
    const submatches = [];
    for (let n = match.length - 1; n > 0; n--) {
      if (match[n]) {
        submatches[n - 1] = new Some(match[n]);
        continue;
      }
      if (submatches.length > 0) {
        submatches[n - 1] = new None();
      }
    }
    return new RegexMatch(content, List.fromArray(submatches));
  });
  return List.fromArray(matches);
}

export function replace(regex, original_string, replacement) {
  return original_string.replaceAll(regex, replacement);
}

export function replace_map(regex, original_string, replacement) {
  let replace = (match, ...args) => {
    const hasNamedGroups = typeof args.at(-1) === "object";
    const groups = args.slice(0, hasNamedGroups ? -3 : -2);
    let regexMatch = new RegexMatch(match, toSubmatches(groups));
    return replacement(regexMatch);
  };
  return original_string.replaceAll(regex, replace);
}

function toSubmatches(groups) {
  const submatches = [];
  for (let n = 0; n < groups.length; n++) {
    if (groups[n]) {
      submatches[n] = new Some(groups[n]);
      continue;
    }
    if (submatches.length > 0) {
      submatches[n] = new None();
    }
  }
  return List.fromArray(submatches);
}
