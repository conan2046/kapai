#!/usr/bin/env python3
"""Convert the simple generated `name = { ... }` Lua config tables to JSON."""

import argparse
import json
import re
from pathlib import Path


TOKEN = re.compile(
    r"\s*(?:(--[^\n]*\n)|([A-Za-z_][A-Za-z0-9_]*)|(-?\d+(?:\.\d+)?)|"
    r'("(?:\\.|[^"\\])*")|([{}=,]))', re.MULTILINE)


class Parser:
    def __init__(self, source: str):
        self.tokens = []
        for match in TOKEN.finditer(source):
            if match.group(1):
                continue
            self.tokens.append(next(value for value in match.groups()[1:] if value is not None))
        self.index = 0

    def peek(self):
        return self.tokens[self.index] if self.index < len(self.tokens) else None

    def take(self, expected=None):
        value = self.peek()
        if value is None or (expected is not None and value != expected):
            raise ValueError(f"Expected {expected!r}, got {value!r} at token {self.index}")
        self.index += 1
        return value

    def value(self):
        token = self.peek()
        if token == "{":
            return self.table()
        self.index += 1
        if token.startswith('"'):
            return json.loads(token)
        if re.fullmatch(r"-?\d+", token):
            return int(token)
        if re.fullmatch(r"-?\d+\.\d+", token):
            return float(token)
        if token == "true":
            return True
        if token == "false":
            return False
        if token == "nil":
            return None
        raise ValueError(f"Unsupported value {token!r} at token {self.index - 1}")

    def table(self):
        self.take("{")
        array = []
        mapping = {}
        keyed = False
        while self.peek() != "}":
            if self.peek() and re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]*", self.peek()) \
                    and self.index + 1 < len(self.tokens) and self.tokens[self.index + 1] == "=":
                keyed = True
                key = self.take()
                self.take("=")
                mapping[key] = self.value()
            else:
                array.append(self.value())
            if self.peek() == ",":
                self.take(",")
        self.take("}")
        if keyed and array:
            raise ValueError("Mixed keyed/array Lua table is not supported by generated configs")
        return mapping if keyed else array

    def root(self):
        self.take()
        self.take("=")
        return self.value()


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("source", type=Path)
    parser.add_argument("destination", type=Path)
    args = parser.parse_args()
    value = Parser(args.source.read_text(encoding="utf-8-sig")).root()
    args.destination.parent.mkdir(parents=True, exist_ok=True)
    args.destination.write_text(json.dumps(value, ensure_ascii=False, separators=(",", ":")), encoding="utf-8")
    print(f"Converted {args.source} -> {args.destination}: {len(value)} records")


if __name__ == "__main__":
    main()
