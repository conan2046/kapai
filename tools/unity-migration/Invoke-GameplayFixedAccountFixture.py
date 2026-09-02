import argparse
import hashlib
import json
import os
import shutil
import sqlite3
from datetime import datetime, timezone


ISOLATION_USER_ID = 705213
ISOLATION_ROLE_ID = 1000006


def utc_now():
    return datetime.now(timezone.utc).isoformat()


def file_hash(path):
    digest = hashlib.sha256()
    with open(path, "rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest().upper()


def write_json(path, payload):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8", newline="\n") as stream:
        json.dump(payload, stream, ensure_ascii=False, indent=2)
        stream.write("\n")


def read_json(path):
    with open(path, "r", encoding="utf-8") as stream:
        return json.load(stream)


def remove_sidecars(path):
    for suffix in ("-wal", "-shm"):
        sidecar = path + suffix
        if os.path.exists(sidecar):
            os.remove(sidecar)


def checkpoint(path):
    connection = sqlite3.connect(path)
    try:
        connection.execute("PRAGMA wal_checkpoint(TRUNCATE)")
    finally:
        connection.close()


def copy_database(source, destination):
    remove_sidecars(destination)
    shutil.copy2(source, destination)


def assert_integrity(connection):
    result = connection.execute("PRAGMA integrity_check").fetchone()[0]
    if result != "ok":
        raise RuntimeError(f"Gameplay SQLite integrity_check failed: {result}")


def clone_row(connection, table, source_id, target_id, replacements):
    columns = [row[1] for row in connection.execute(f"PRAGMA table_info({table})")]
    source = connection.execute(f"SELECT * FROM {table} WHERE id=?", (source_id,)).fetchone()
    if source is None:
        raise RuntimeError(f"Gameplay {table} source id={source_id} is missing")
    values = list(source)
    values[columns.index("id")] = target_id
    for name, value in replacements.items():
        values[columns.index(name)] = value
    placeholders = ",".join("?" for _ in columns)
    connection.execute(
        f"INSERT INTO {table} ({','.join(columns)}) VALUES ({placeholders})", values
    )


def identity(connection, user_id, role_id):
    row = connection.execute(
        "SELECT u.id,CAST(u.role0 AS INTEGER),r.id,r.name,CAST(r.level AS INTEGER) "
        "FROM user_info1 u JOIN role_info r ON r.id=CAST(u.role0 AS INTEGER) "
        "WHERE u.id=? AND r.id=?",
        (user_id, role_id),
    ).fetchone()
    if row is None:
        raise RuntimeError(f"Gameplay SQLite identity {user_id}/{role_id} is missing")
    return {
        "userId": int(row[0]), "linkedRoleId": int(row[1]), "roleId": int(row[2]),
        "roleName": str(row[3]), "level": int(row[4]),
    }


def identity_hash(value):
    keys = ("userId", "linkedRoleId", "roleId", "roleName", "level")
    return hashlib.sha256("|".join(str(value[key]) for key in keys).encode("utf-8")).hexdigest().upper()


def setup(args):
    if os.path.exists(args.backup):
        raise RuntimeError("Gameplay SQLite backup already exists; restore it before rerun")
    checkpoint(args.database)
    os.makedirs(os.path.dirname(args.backup), exist_ok=True)
    shutil.copy2(args.database, args.backup)
    snapshot_hash = file_hash(args.backup)
    backup_connection = sqlite3.connect("file:" + args.backup + "?mode=ro", uri=True)
    try:
        primary_before = identity(backup_connection, args.user_id, args.role_id)
        original_isolation_users = backup_connection.execute(
            "SELECT COUNT(*) FROM user_info1 WHERE id=?", (ISOLATION_USER_ID,)
        ).fetchone()[0]
        original_isolation_roles = backup_connection.execute(
            "SELECT COUNT(*) FROM role_info WHERE id=?", (ISOLATION_ROLE_ID,)
        ).fetchone()[0]
        assert_integrity(backup_connection)
    finally:
        backup_connection.close()

    connection = sqlite3.connect(args.database)
    try:
        connection.execute("BEGIN IMMEDIATE")
        connection.execute("DELETE FROM user_info1 WHERE id=?", (ISOLATION_USER_ID,))
        connection.execute("DELETE FROM role_info WHERE id=?", (ISOLATION_ROLE_ID,))
        clone_row(connection, "role_info", args.role_id, ISOLATION_ROLE_ID,
                  {"name": "T67076", "level": str(primary_before["level"])})
        clone_row(connection, "user_info1", args.user_id, ISOLATION_USER_ID,
                  {"role0": str(ISOLATION_ROLE_ID), "name": "local-isolation"})
        connection.commit()
        assert_integrity(connection)
        primary = identity(connection, args.user_id, args.role_id)
        isolation = identity(connection, ISOLATION_USER_ID, ISOLATION_ROLE_ID)
    except Exception:
        connection.rollback()
        connection.close()
        connection = None
        copy_database(args.backup, args.database)
        raise
    finally:
        if connection:
            connection.close()
    checkpoint(args.database)
    write_json(args.evidence, {
        "schemaVersion": 1, "module": "Gameplay", "action": "Setup", "dataBackend": "sqlite",
        "database": args.database, "backup": args.backup, "userId": args.user_id, "roleId": args.role_id,
        "isolationUserId": ISOLATION_USER_ID, "isolationRoleId": ISOLATION_ROLE_ID,
        "snapshotHash": snapshot_hash, "fixtureHash": file_hash(args.database),
        "primaryIdentity": primary, "primaryIdentityHash": identity_hash(primary),
        "isolationIdentity": isolation,
        "originalIsolationUserRows": original_isolation_users,
        "originalIsolationRoleRows": original_isolation_roles,
        "createdUtc": utc_now(),
    })


def assert_setup(args):
    snapshot = read_json(args.evidence)
    connection = sqlite3.connect(args.database)
    try:
        primary = identity(connection, args.user_id, args.role_id)
        isolation = identity(connection, ISOLATION_USER_ID, ISOLATION_ROLE_ID)
        assert_integrity(connection)
    finally:
        connection.close()
    if identity_hash(primary) != snapshot["primaryIdentityHash"]:
        raise RuntimeError("Gameplay primary SQLite identity changed")
    # The local test server intentionally promotes a disposable account to
    # level 99 on its first real login. Accept that documented login mutation
    # while keeping identity/name strict; exact whole-database restore below
    # remains the residue guard.
    allowed_isolation_levels = (primary["level"], 99)
    if isolation["roleName"] != "T67076" or isolation["level"] not in allowed_isolation_levels:
        raise RuntimeError(f"Gameplay isolation SQLite identity mismatch: {isolation}")


def restore(args):
    if not os.path.exists(args.backup):
        raise RuntimeError("Gameplay SQLite backup is missing")
    copy_database(args.backup, args.database)


def assert_restored(args):
    snapshot = read_json(args.evidence)
    checkpoint(args.database)
    actual = file_hash(args.database)
    if actual != snapshot["snapshotHash"]:
        raise RuntimeError(f"Gameplay SQLite restore hash mismatch: {actual}")
    connection = sqlite3.connect(args.database)
    try:
        user_rows = connection.execute(
            "SELECT COUNT(*) FROM user_info1 WHERE id=?", (ISOLATION_USER_ID,)
        ).fetchone()[0]
        role_rows = connection.execute(
            "SELECT COUNT(*) FROM role_info WHERE id=?", (ISOLATION_ROLE_ID,)
        ).fetchone()[0]
        assert_integrity(connection)
    finally:
        connection.close()
    if user_rows != snapshot["originalIsolationUserRows"] or role_rows != snapshot["originalIsolationRoleRows"]:
        raise RuntimeError("Gameplay SQLite isolation rows remained after restore")
    snapshot.update({
        "action": "AssertRestored", "restored": True, "restoredHash": actual,
        "residualCount": 0, "assertedUtc": utc_now(),
    })
    write_json(args.evidence, snapshot)


def assert_relogin(args):
    snapshot = read_json(args.evidence)
    connection = sqlite3.connect(args.database)
    try:
        current = identity(connection, args.user_id, args.role_id)
    finally:
        connection.close()
    if identity_hash(current) != snapshot["primaryIdentityHash"]:
        raise RuntimeError("Gameplay primary identity changed after relogin")


def cleanup(args):
    if os.path.exists(args.backup):
        os.remove(args.backup)
    remove_sidecars(args.backup)


def assert_cleanup(args):
    if os.path.exists(args.backup) or any(os.path.exists(args.backup + suffix) for suffix in ("-wal", "-shm")):
        raise RuntimeError("Gameplay SQLite fixture backup residue remains")
    assert_restored(args)


def inspect_identity(args):
    connection = sqlite3.connect(args.database)
    try:
        current = identity(connection, args.user_id, args.role_id)
        assert_integrity(connection)
    finally:
        connection.close()
    print(json.dumps({
        "dataBackend": "sqlite",
        "identity": current,
        "identityHash": identity_hash(current),
        "integrity": "ok",
    }, ensure_ascii=False, separators=(",", ":")))


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--action", required=True)
    parser.add_argument("--database", required=True)
    parser.add_argument("--backup", required=True)
    parser.add_argument("--evidence", required=True)
    parser.add_argument("--user-id", required=True, type=int)
    parser.add_argument("--role-id", required=True, type=int)
    args = parser.parse_args()
    args.database, args.backup, args.evidence = map(
        os.path.abspath, (args.database, args.backup, args.evidence)
    )
    actions = {
        "Setup": setup, "AssertSetup": assert_setup, "Restore": restore,
        "AssertRestored": assert_restored, "Cleanup": cleanup,
        "AssertCleanup": assert_cleanup, "AssertReloginHash": assert_relogin,
        "InspectIdentity": inspect_identity,
    }
    if args.action not in actions:
        raise RuntimeError(f"Unsupported Gameplay SQLite fixture action: {args.action}")
    actions[args.action](args)


if __name__ == "__main__":
    main()
