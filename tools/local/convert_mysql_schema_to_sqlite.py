from __future__ import annotations

import argparse
import hashlib
import json
import re
import sqlite3
from pathlib import Path


TABLE_RE = re.compile(
    r"^CREATE TABLE IF NOT EXISTS `(?P<name>[^`]+)` \((?P<body>.*?)^\) ENGINE=.*?;\r?$",
    re.MULTILINE | re.DOTALL,
)
COLUMN_RE = re.compile(r"^`(?P<name>[^`]+)`\s+(?P<type>[a-zA-Z]+(?:\(\d+\))?)(?P<rest>.*)$")
PRIMARY_RE = re.compile(r"^PRIMARY KEY \((?P<columns>.+)\)$", re.IGNORECASE)
KEY_RE = re.compile(r"^(?P<unique>UNIQUE\s+)?KEY `(?P<name>[^`]+)` \((?P<columns>.+)\)$", re.IGNORECASE)


def normalize_type(mysql_type: str) -> str:
    base = mysql_type.lower().split("(", 1)[0]
    if base in {"tinyint", "smallint", "mediumint", "int", "bigint"}:
        return "INTEGER"
    if base in {"float", "double", "decimal"}:
        return "REAL"
    if base in {"blob", "mediumblob", "longblob"}:
        return "BLOB"
    if base in {"char", "varchar", "text", "mediumtext", "longtext", "timestamp", "datetime", "date"}:
        return "TEXT"
    raise ValueError(f"unsupported MySQL type: {mysql_type}")


def split_body(body: str) -> list[str]:
    return [line.strip().removesuffix(",") for line in body.splitlines() if line.strip()]


def convert_column(line: str, auto_column: str | None) -> tuple[str, str, str]:
    match = COLUMN_RE.match(line)
    if not match:
        raise ValueError(f"unsupported column declaration: {line}")
    name = match.group("name")
    source_type = match.group("type")
    target_type = normalize_type(source_type)
    rest = match.group("rest")
    rest = re.sub(r"\s+CHARACTER SET\s+\w+", "", rest, flags=re.IGNORECASE)
    rest = re.sub(r"\s+COLLATE\s+\w+", "", rest, flags=re.IGNORECASE)
    rest = re.sub(r"\s+AUTO_INCREMENT", "", rest, flags=re.IGNORECASE)
    rest = re.sub(r"\s+COMMENT\s+'(?:''|[^'])*'", "", rest, flags=re.IGNORECASE)
    rest = re.sub(r"\s+", " ", rest).strip()
    if name == auto_column:
        converted = f"`{name}` INTEGER PRIMARY KEY AUTOINCREMENT"
    else:
        converted = f"`{name}` {target_type}" + (f" {rest}" if rest else "")
    return converted, name, source_type


def parse_tables(source: str) -> list[dict]:
    tables: list[dict] = []
    for table_match in TABLE_RE.finditer(source):
        name = table_match.group("name")
        entries = split_body(table_match.group("body"))
        auto_columns = []
        primary = None
        indexes = []
        for entry in entries:
            column_match = COLUMN_RE.match(entry)
            if column_match and "AUTO_INCREMENT" in column_match.group("rest").upper():
                auto_columns.append(column_match.group("name"))
            primary_match = PRIMARY_RE.match(entry)
            if primary_match:
                primary = primary_match.group("columns")
            key_match = KEY_RE.match(entry)
            if key_match:
                indexes.append(
                    {
                        "name": key_match.group("name"),
                        "columns": key_match.group("columns"),
                        "unique": bool(key_match.group("unique")),
                    }
                )
        if len(auto_columns) > 1:
            raise ValueError(f"table {name} has multiple AUTO_INCREMENT columns: {auto_columns}")
        auto_column = auto_columns[0] if auto_columns else None
        columns = []
        declarations = []
        for entry in entries:
            if COLUMN_RE.match(entry):
                declaration, column_name, source_type = convert_column(entry, auto_column)
                declarations.append(declaration)
                columns.append({"name": column_name, "sourceType": source_type})
            elif PRIMARY_RE.match(entry):
                if auto_column is None:
                    declarations.append(f"PRIMARY KEY ({primary})")
            elif KEY_RE.match(entry):
                continue
            else:
                raise ValueError(f"unsupported table entry in {name}: {entry}")
        tables.append(
            {
                "name": name,
                "columns": columns,
                "autoColumn": auto_column,
                "primary": primary,
                "indexes": indexes,
                "declarations": declarations,
            }
        )
    return tables


def build_sql(source: str, source_sha256: str, tables: list[dict]) -> str:
    lines = [
        "-- Generated from server/sql/local_min_schema.sql. Do not edit by hand.",
        f"-- Source SHA-256: {source_sha256}",
        "PRAGMA foreign_keys=ON;",
        "BEGIN IMMEDIATE;",
        "",
    ]
    for table in tables:
        lines.append(f"CREATE TABLE IF NOT EXISTS `{table['name']}` (")
        for index, declaration in enumerate(table["declarations"]):
            suffix = "," if index + 1 < len(table["declarations"]) else ""
            lines.append(f"  {declaration}{suffix}")
        lines.append(");")
        for index in table["indexes"]:
            unique = "UNIQUE " if index["unique"] else ""
            sqlite_name = f"idx_{table['name']}_{index['name']}"
            lines.append(
                f"CREATE {unique}INDEX IF NOT EXISTS `{sqlite_name}` ON `{table['name']}` ({index['columns']});"
            )
        lines.append("")
    lines.extend(
        [
            "CREATE TABLE IF NOT EXISTS `schema_version` (",
            "  `version` INTEGER PRIMARY KEY,",
            "  `name` TEXT NOT NULL,",
            "  `source_sha256` TEXT NOT NULL,",
            "  `applied_utc` TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP",
            ");",
            "INSERT OR IGNORE INTO `schema_version` (`version`,`name`,`source_sha256`)",
            f"VALUES (1,'initial-schema','{source_sha256}');",
            "",
        ]
    )
    seed_marker = "-- Local-only first-charge UI fallback."
    marker_index = source.find(seed_marker)
    if marker_index < 0:
        raise ValueError("local seed marker was not found")
    seeds = source[marker_index:]
    seeds = re.sub(r"\s+FROM DUAL\s*\n", "\n", seeds, flags=re.IGNORECASE)
    seeds = re.sub(r"\bNOW\(\)", "CURRENT_TIMESTAMP", seeds, flags=re.IGNORECASE)
    lines.append(seeds.strip())
    lines.extend(["", "COMMIT;", ""])
    return "\n".join(lines)


def validate(sql_text: str, tables: list[dict]) -> dict:
    connection = sqlite3.connect(":memory:")
    try:
        connection.executescript(sql_text)
        connection.executescript(sql_text)
        actual_tables = {
            row[0]
            for row in connection.execute(
                "select name from sqlite_master where type='table' and name not like 'sqlite_%'"
            )
        }
        expected_tables = {table["name"] for table in tables} | {"schema_version"}
        if actual_tables != expected_tables:
            raise ValueError(
                f"table catalog mismatch missing={sorted(expected_tables - actual_tables)} "
                f"unexpected={sorted(actual_tables - expected_tables)}"
            )
        for table in tables:
            actual_columns = [row[1] for row in connection.execute(f"pragma table_info(`{table['name']}`)")]
            expected_columns = [column["name"] for column in table["columns"]]
            if actual_columns != expected_columns:
                raise ValueError(
                    f"column catalog mismatch table={table['name']} expected={expected_columns} actual={actual_columns}"
                )
        explicit_indexes = connection.execute(
            "select count(*) from sqlite_master where type='index' and sql is not null"
        ).fetchone()[0]
        version = connection.execute(
            "select version,name,source_sha256 from schema_version"
        ).fetchall()
        integrity = connection.execute("pragma integrity_check").fetchone()[0]
        if integrity != "ok":
            raise ValueError(f"integrity_check failed: {integrity}")
        return {
            "tableCount": len(actual_tables),
            "sourceTableCount": len(tables),
            "columnCount": sum(len(table["columns"]) for table in tables),
            "explicitIndexCount": explicit_indexes,
            "schemaVersionRows": version,
            "integrityCheck": integrity,
            "idempotentExecutions": 2,
        }
    finally:
        connection.close()


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--manifest", type=Path, required=True)
    args = parser.parse_args()

    source_bytes = args.input.read_bytes()
    source = source_bytes.decode("utf-8-sig")
    source_sha256 = hashlib.sha256(source_bytes).hexdigest().upper()
    tables = parse_tables(source)
    if len(tables) != 173:
        raise ValueError(f"expected 173 source tables, found {len(tables)}")
    sql_text = build_sql(source, source_sha256, tables)
    validation = validate(sql_text, tables)
    output_bytes = sql_text.encode("utf-8")
    manifest = {
        "schemaVersion": 1,
        "source": args.input.as_posix(),
        "sourceSha256": source_sha256,
        "output": args.output.as_posix(),
        "outputSha256": hashlib.sha256(output_bytes).hexdigest().upper(),
        "validation": validation,
        "tables": [
            {
                "name": table["name"],
                "columnCount": len(table["columns"]),
                "autoColumn": table["autoColumn"],
                "primary": table["primary"],
                "indexCount": len(table["indexes"]),
            }
            for table in tables
        ],
    }
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.manifest.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_bytes(output_bytes)
    args.manifest.write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(
        "sqlite_schema_generation=passed "
        f"tables={validation['sourceTableCount']} columns={validation['columnCount']} "
        f"indexes={validation['explicitIndexCount']} sha256={manifest['outputSha256']}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
