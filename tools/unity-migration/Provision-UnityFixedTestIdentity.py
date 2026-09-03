import argparse
import hashlib
import json
import os
import shutil
import sqlite3
from datetime import datetime, timezone


def sha256(path):
    digest = hashlib.sha256()
    with open(path, "rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest().upper()


def checkpoint(path):
    connection = sqlite3.connect(path)
    try:
        connection.execute("PRAGMA wal_checkpoint(TRUNCATE)")
    finally:
        connection.close()


def clone_row(connection, table, source_id, target_id, replacements):
    columns = [row[1] for row in connection.execute(f"PRAGMA table_info({table})")]
    source = connection.execute(f"SELECT * FROM {table} WHERE id=?", (source_id,)).fetchone()
    if source is None:
        raise RuntimeError(f"Source {table} id={source_id} is missing")
    values = list(source)
    values[columns.index("id")] = target_id
    for name, value in replacements.items():
        values[columns.index(name)] = value
    connection.execute(
        f"INSERT INTO {table} ({','.join(columns)}) VALUES ({','.join('?' for _ in columns)})",
        values,
    )


def identity(connection, user_id, role_id):
    row = connection.execute(
        "SELECT u.id,CAST(u.role0 AS INTEGER),r.id,r.name,CAST(r.level AS INTEGER) "
        "FROM user_info1 u JOIN role_info r ON r.id=CAST(u.role0 AS INTEGER) "
        "WHERE u.id=? AND r.id=?",
        (user_id, role_id),
    ).fetchone()
    return None if row is None else {
        "userId": int(row[0]), "linkedRoleId": int(row[1]), "roleId": int(row[2]),
        "roleName": str(row[3]), "level": int(row[4]),
    }


def write_evidence(path, payload):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8", newline="\n") as stream:
        json.dump(payload, stream, ensure_ascii=False, indent=2)
        stream.write("\n")


def provision(args):
    checkpoint(args.database)
    if os.path.exists(args.backup):
        raise RuntimeError(f"Recovery snapshot already exists: {args.backup}")
    os.makedirs(os.path.dirname(args.backup), exist_ok=True)
    shutil.copy2(args.database, args.backup)
    before_hash = sha256(args.backup)
    connection = sqlite3.connect(args.database)
    try:
        if identity(connection, args.user_id, args.role_id) is not None:
            raise RuntimeError("Target fixed identity already exists")
        if connection.execute("SELECT COUNT(*) FROM user_info1 WHERE id=?", (args.user_id,)).fetchone()[0]:
            raise RuntimeError("Target user id exists with a different role")
        if connection.execute("SELECT COUNT(*) FROM role_info WHERE id=?", (args.role_id,)).fetchone()[0]:
            raise RuntimeError("Target role id already exists")
        connection.execute("BEGIN IMMEDIATE")
        clone_row(connection, "role_info", args.source_role_id, args.role_id,
                  {"name": "T00057", "level": "99"})
        clone_row(connection, "user_info1", args.source_user_id, args.user_id,
                  {"role0": str(args.role_id), "name": "local-primary"})
        connection.commit()
        if connection.execute("PRAGMA integrity_check").fetchone()[0] != "ok":
            raise RuntimeError("SQLite integrity_check failed after provisioning")
        current = identity(connection, args.user_id, args.role_id)
        if current is None:
            raise RuntimeError("Fixed identity was not created")
    except Exception:
        connection.rollback()
        connection.close()
        shutil.copy2(args.backup, args.database)
        raise
    finally:
        if connection:
            connection.close()
    checkpoint(args.database)
    write_evidence(args.evidence, {
        "action": "Provision", "database": args.database, "backup": args.backup,
        "sourceUserId": args.source_user_id, "sourceRoleId": args.source_role_id,
        "identity": current, "beforeSha256": before_hash,
        "afterSha256": sha256(args.database), "createdUtc": datetime.now(timezone.utc).isoformat(),
    })
    print(json.dumps(current, ensure_ascii=False))


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--database", required=True)
    parser.add_argument("--backup", required=True)
    parser.add_argument("--evidence", required=True)
    parser.add_argument("--source-user-id", type=int, default=1)
    parser.add_argument("--source-role-id", type=int, default=1000001)
    parser.add_argument("--user-id", type=int, default=7200057)
    parser.add_argument("--role-id", type=int, default=1000003)
    provision(parser.parse_args())


if __name__ == "__main__":
    main()
