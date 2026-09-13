import argparse
import json
import os
import sqlite3
from datetime import datetime, timezone


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--database", required=True)
    parser.add_argument("--seed", required=True)
    parser.add_argument("--backup-dir", required=True)
    parser.add_argument("--evidence", required=True)
    args = parser.parse_args()

    database = os.path.abspath(args.database)
    seed_path = os.path.abspath(args.seed)
    backup_dir = os.path.abspath(args.backup_dir)
    evidence_path = os.path.abspath(args.evidence)
    if not os.path.isfile(database):
        raise RuntimeError(f"SQLite database is missing: {database}")
    if not os.path.isfile(seed_path):
        raise RuntimeError(f"Question seed is missing: {seed_path}")

    os.makedirs(backup_dir, exist_ok=True)
    stamp = datetime.now().strftime("%Y%m%d-%H%M%S")
    backup_path = os.path.join(backup_dir, f"question-bank-projectx-{stamp}.db")

    connection = sqlite3.connect(database, timeout=30)
    try:
        connection.execute("PRAGMA wal_checkpoint(TRUNCATE)")
        before_count = int(connection.execute("SELECT COUNT(*) FROM question").fetchone()[0])
        backup = sqlite3.connect(backup_path)
        try:
            connection.backup(backup)
        finally:
            backup.close()

        with open(seed_path, "r", encoding="utf-8-sig") as stream:
            seed_sql = stream.read()
        try:
            connection.executescript("BEGIN IMMEDIATE;\n" + seed_sql + "\nCOMMIT;")
        except Exception:
            if connection.in_transaction:
                connection.rollback()
            raise

        after_count = int(connection.execute("SELECT COUNT(*) FROM question").fetchone()[0])
        placeholder_count = int(
            connection.execute("SELECT COUNT(*) FROM question WHERE question LIKE 'Local test question %'").fetchone()[0]
        )
        chinese_count = int(
            connection.execute("SELECT COUNT(*) FROM question WHERE question GLOB '*[一-龥]*'").fetchone()[0]
        )
        integrity = connection.execute("PRAGMA integrity_check").fetchone()[0]
        first_question = connection.execute("SELECT question FROM question ORDER BY id LIMIT 1").fetchone()[0]
        last_question = connection.execute("SELECT question FROM question ORDER BY id DESC LIMIT 1").fetchone()[0]
        if after_count != 38 or placeholder_count != 0 or chinese_count != 38 or integrity != "ok":
            raise RuntimeError(
                f"Question bank verification failed: rows={after_count}, placeholders={placeholder_count}, "
                f"Chinese={chinese_count}, integrity={integrity}"
            )
    finally:
        connection.close()

    evidence = {
        "schemaVersion": 1,
        "database": database,
        "seed": seed_path,
        "backup": backup_path,
        "beforeCount": before_count,
        "afterCount": after_count,
        "placeholderCount": placeholder_count,
        "chineseQuestionCount": chinese_count,
        "firstQuestion": first_question,
        "lastQuestion": last_question,
        "integrity": integrity,
        "installedUtc": datetime.now(timezone.utc).isoformat(),
    }
    os.makedirs(os.path.dirname(evidence_path), exist_ok=True)
    with open(evidence_path, "w", encoding="utf-8", newline="\n") as stream:
        json.dump(evidence, stream, ensure_ascii=False, indent=2)
        stream.write("\n")
    print(json.dumps(evidence, ensure_ascii=False))


if __name__ == "__main__":
    main()
