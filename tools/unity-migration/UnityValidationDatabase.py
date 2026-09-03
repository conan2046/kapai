import argparse
import hashlib
import json
import os
import shutil
import sqlite3
from datetime import datetime, timezone


PRIMARY_IDENTITIES = ((1, 1000001, "S8D01"), (7200057, 1000003, "T00057"))
PRIMARY_USER_IDS = tuple(item[0] for item in PRIMARY_IDENTITIES)
PRIMARY_ROLE_IDS = tuple(item[1] for item in PRIMARY_IDENTITIES)
SANITIZED_TABLES = (
    "arena_paihang",
    "arena_paihang_save",
    "bang_pai",
    "login_log_8",
    "login_log_9",
    "online_user_num",
)


def utc_now():
    return datetime.now(timezone.utc).isoformat()


def sha256(path):
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


def load_json(path):
    with open(path, "r", encoding="utf-8") as stream:
        return json.load(stream)


def connect_readonly(path, immutable=True):
    query = "?mode=ro&immutable=1" if immutable else "?mode=ro"
    return sqlite3.connect("file:" + os.path.abspath(path).replace("\\", "/") + query, uri=True)


def integrity(path):
    connection = connect_readonly(path)
    try:
        return connection.execute("PRAGMA integrity_check").fetchone()[0]
    finally:
        connection.close()


def identity_rows(connection):
    return connection.execute(
        "SELECT u.id,CAST(u.role0 AS INTEGER),r.name,r.level "
        "FROM user_info1 u JOIN role_info r ON r.id=CAST(u.role0 AS INTEGER) "
        "WHERE u.id IN (?,?) ORDER BY u.id",
        PRIMARY_USER_IDS,
    ).fetchall()


def assert_identities(connection):
    rows = identity_rows(connection)
    actual = [(int(row[0]), int(row[1]), str(row[2])) for row in rows]
    expected = [(user_id, role_id, name) for user_id, role_id, name in PRIMARY_IDENTITIES]
    if actual != expected:
        raise RuntimeError(f"validation identities mismatch: expected={expected}, actual={actual}")
    return rows


def sqlite_backup(source, destination):
    os.makedirs(os.path.dirname(destination), exist_ok=True)
    temporary = destination + ".tmp"
    if os.path.exists(temporary):
        os.remove(temporary)
    source_connection = connect_readonly(source, immutable=False)
    target_connection = sqlite3.connect(temporary)
    try:
        source_connection.backup(target_connection)
        target_connection.commit()
        target_connection.execute("PRAGMA journal_mode=DELETE").fetchone()
    finally:
        target_connection.close()
        source_connection.close()
    if integrity(temporary) != "ok":
        os.remove(temporary)
        raise RuntimeError("SQLite backup integrity check failed")
    os.replace(temporary, destination)


def remove_sidecars(path):
    for suffix in ("-wal", "-shm"):
        sidecar = path + suffix
        if os.path.exists(sidecar):
            os.remove(sidecar)


def build_seed(args):
    if not os.path.isfile(args.source):
        raise RuntimeError(f"source database is missing: {args.source}")
    source_connection = connect_readonly(args.source, immutable=False)
    try:
        assert_identities(source_connection)
    finally:
        source_connection.close()

    output = os.path.abspath(args.output)
    os.makedirs(os.path.dirname(output), exist_ok=True)
    working = output + ".building"
    if os.path.exists(working):
        os.remove(working)
    sqlite_backup(args.source, working)

    connection = sqlite3.connect(working)
    try:
        connection.execute("PRAGMA foreign_keys=OFF")
        connection.execute("BEGIN IMMEDIATE")
        connection.execute("DELETE FROM user_info1 WHERE id NOT IN (?,?)", PRIMARY_USER_IDS)
        connection.execute("DELETE FROM role_info WHERE id NOT IN (?,?)", PRIMARY_ROLE_IDS)
        for table in ("role_simple_list", "role_simple_list_save"):
            connection.execute(f"DELETE FROM {table} WHERE id NOT IN (?,?)", PRIMARY_ROLE_IDS)
        for table in ("rank_list", "rank_list_save"):
            connection.execute(f"DELETE FROM {table} WHERE role_id NOT IN (?,?)", PRIMARY_ROLE_IDS)
        for table in SANITIZED_TABLES:
            connection.execute(f"DELETE FROM {table}")
        connection.execute(
            "UPDATE sqlite_sequence SET seq=(SELECT MAX(id) FROM role_info) WHERE name='role_info'"
        )
        connection.execute(
            "UPDATE sqlite_sequence SET seq=(SELECT MAX(id) FROM user_info1) WHERE name='user_info1'"
        )
        connection.commit()
        assert_identities(connection)
        connection.execute("PRAGMA journal_mode=DELETE")
        connection.execute("VACUUM")
    except Exception:
        connection.rollback()
        raise
    finally:
        connection.close()

    if integrity(working) != "ok":
        raise RuntimeError("generated validation seed failed integrity_check")
    os.replace(working, output)
    remove_sidecars(output)
    verify = connect_readonly(output)
    try:
        rows = assert_identities(verify)
        user_count = verify.execute("SELECT COUNT(*) FROM user_info1").fetchone()[0]
        role_count = verify.execute("SELECT COUNT(*) FROM role_info").fetchone()[0]
    finally:
        verify.close()
    manifest = {
        "schemaVersion": 1,
        "purpose": "sanitized Unity fixed-account validation seed",
        "database": os.path.basename(output),
        "sha256": sha256(output),
        "bytes": os.path.getsize(output),
        "integrityCheck": "ok",
        "identities": [
            {"userId": int(row[0]), "roleId": int(row[1]), "roleName": str(row[2]), "level": int(row[3])}
            for row in rows
        ],
        "userCount": int(user_count),
        "roleCount": int(role_count),
        "sanitizedTables": list(SANITIZED_TABLES),
        "generatedUtc": utc_now(),
    }
    write_json(args.manifest, manifest)
    print(json.dumps(manifest, ensure_ascii=False))


def verify_seed(seed, manifest_path):
    if not os.path.isfile(seed):
        raise RuntimeError(f"validation seed is missing: {seed}")
    manifest = load_json(manifest_path)
    actual_hash = sha256(seed)
    if actual_hash != str(manifest.get("sha256", "")).upper():
        raise RuntimeError(f"validation seed SHA-256 mismatch: {actual_hash}")
    if integrity(seed) != "ok":
        raise RuntimeError("validation seed integrity_check failed")
    connection = connect_readonly(seed)
    try:
        rows = assert_identities(connection)
    finally:
        connection.close()
    return manifest, rows


def verify_action(args):
    manifest, rows = verify_seed(args.seed, args.manifest)
    print(json.dumps({
        "action": "Verify",
        "database": args.seed,
        "sha256": manifest["sha256"],
        "integrityCheck": "ok",
        "identities": [[int(row[0]), int(row[1])] for row in rows],
    }, ensure_ascii=False))


def install(args):
    manifest, rows = verify_seed(args.seed, args.manifest)
    target = os.path.abspath(args.database)
    backup = os.path.abspath(args.backup)
    os.makedirs(os.path.dirname(target), exist_ok=True)
    if os.path.exists(backup):
        raise RuntimeError(f"refusing to overwrite validation database backup: {backup}")
    previous_hash = None
    if os.path.exists(target):
        sqlite_backup(target, backup)
        previous_hash = sha256(backup)
    temporary = target + ".installing"
    if os.path.exists(temporary):
        os.remove(temporary)
    shutil.copy2(args.seed, temporary)
    if integrity(temporary) != "ok":
        os.remove(temporary)
        raise RuntimeError("installed validation database failed integrity_check")
    remove_sidecars(target)
    os.replace(temporary, target)
    actual_hash = sha256(target)
    if actual_hash != manifest["sha256"]:
        raise RuntimeError("installed validation database SHA-256 mismatch")
    payload = {
        "action": "Install",
        "database": target,
        "backup": backup if previous_hash else None,
        "backupSha256": previous_hash,
        "installedSha256": actual_hash,
        "integrityCheck": "ok",
        "identities": [[int(row[0]), int(row[1])] for row in rows],
        "installedUtc": utc_now(),
    }
    if args.evidence:
        write_json(args.evidence, payload)
    print(json.dumps(payload, ensure_ascii=False))


def restore(args):
    backup = os.path.abspath(args.backup)
    target = os.path.abspath(args.database)
    if not os.path.isfile(backup):
        raise RuntimeError(f"validation database backup is missing: {backup}")
    if integrity(backup) != "ok":
        raise RuntimeError("validation database backup integrity_check failed")
    os.makedirs(os.path.dirname(target), exist_ok=True)
    temporary = target + ".restoring"
    if os.path.exists(temporary):
        os.remove(temporary)
    shutil.copy2(backup, temporary)
    remove_sidecars(target)
    os.replace(temporary, target)
    payload = {
        "action": "Restore",
        "database": target,
        "backup": backup,
        "restoredSha256": sha256(target),
        "integrityCheck": integrity(target),
        "restoredUtc": utc_now(),
    }
    if args.evidence:
        write_json(args.evidence, payload)
    print(json.dumps(payload, ensure_ascii=False))


def main():
    parser = argparse.ArgumentParser()
    subparsers = parser.add_subparsers(dest="action", required=True)

    build = subparsers.add_parser("build-seed")
    build.add_argument("--source", required=True)
    build.add_argument("--output", required=True)
    build.add_argument("--manifest", required=True)
    build.set_defaults(handler=build_seed)

    verify = subparsers.add_parser("verify")
    verify.add_argument("--seed", required=True)
    verify.add_argument("--manifest", required=True)
    verify.set_defaults(handler=verify_action)

    install_parser = subparsers.add_parser("install")
    install_parser.add_argument("--seed", required=True)
    install_parser.add_argument("--manifest", required=True)
    install_parser.add_argument("--database", required=True)
    install_parser.add_argument("--backup", required=True)
    install_parser.add_argument("--evidence", default="")
    install_parser.set_defaults(handler=install)

    restore_parser = subparsers.add_parser("restore")
    restore_parser.add_argument("--database", required=True)
    restore_parser.add_argument("--backup", required=True)
    restore_parser.add_argument("--evidence", default="")
    restore_parser.set_defaults(handler=restore)

    args = parser.parse_args()
    args.handler(args)


if __name__ == "__main__":
    main()
