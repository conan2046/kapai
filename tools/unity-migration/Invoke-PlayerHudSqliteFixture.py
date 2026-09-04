import argparse
import hashlib
import json
import os
import shutil
import sqlite3
from datetime import datetime, timezone


ISOLATION_USER_ID = 705213
ISOLATION_ROLE_ID = 1000006
EXPECTED_PREMIUM = 100200
EXPECTED_BOUND_PREMIUM = 100000
EXPECTED_GOLD = 4810000


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
        raise RuntimeError(f"PlayerHud SQLite integrity_check failed: {result}")


def number(value):
    return int(float(value or 0))


def hud_state(connection, user_id, role_id):
    row = connection.execute(
        "SELECT u.id,CAST(u.role0 AS INTEGER),r.id,r.name,r.level,r.exp,r.money,r.zhanDouLi,"
        "u.money,u.bd_money,LENGTH(r.user_spirit) "
        "FROM user_info1 u JOIN role_info r ON r.id=CAST(u.role0 AS INTEGER) "
        "WHERE u.id=? AND r.id=?",
        (user_id, role_id),
    ).fetchone()
    if row is None:
        raise RuntimeError(f"PlayerHud SQLite identity {user_id}/{role_id} is missing")
    return {
        "userId": number(row[0]),
        "linkedRoleId": number(row[1]),
        "roleId": number(row[2]),
        "roleName": str(row[3]),
        "level": number(row[4]),
        "experience": number(row[5]),
        "gold": number(row[6]),
        "power": number(row[7]),
        "premium": number(row[8]),
        "boundPremium": number(row[9]),
        "spiritBytes": number(row[10]),
    }


def assert_primary(state):
    if state["userId"] != 7200057 or state["roleId"] != 1000003 or state["roleName"] != "T00057":
        raise RuntimeError(f"PlayerHud SQLite fixed identity mismatch: {state}")
    if state["premium"] != EXPECTED_PREMIUM or state["boundPremium"] != EXPECTED_BOUND_PREMIUM:
        raise RuntimeError(f"PlayerHud SQLite premium/bound-premium separation failed: {state}")
    if state["gold"] != EXPECTED_GOLD or state["spiritBytes"] <= 0:
        raise RuntimeError(f"PlayerHud SQLite deterministic HUD data mismatch: {state}")


def stable_hud_state(state):
    return {key: state[key] for key in (
        "userId", "linkedRoleId", "roleId", "roleName", "level", "experience",
        "gold", "premium", "boundPremium", "spiritBytes",
    )}


def clone_row(connection, table, source_id, target_id, replacements):
    columns = [row[1] for row in connection.execute(f"PRAGMA table_info({table})")]
    source = connection.execute(f"SELECT * FROM {table} WHERE id=?", (source_id,)).fetchone()
    if source is None:
        raise RuntimeError(f"PlayerHud {table} source id={source_id} is missing")
    values = list(source)
    values[columns.index("id")] = target_id
    for name, value in replacements.items():
        values[columns.index(name)] = value
    placeholders = ",".join("?" for _ in columns)
    connection.execute(f"INSERT INTO {table} ({','.join(columns)}) VALUES ({placeholders})", values)


def setup(args):
    if not os.path.isfile(args.database):
        raise RuntimeError(f"PlayerHud SQLite database is missing: {args.database}")
    if os.path.exists(args.backup):
        raise RuntimeError("PlayerHud SQLite backup already exists; restore it before rerun")
    checkpoint(args.database)
    os.makedirs(os.path.dirname(args.backup), exist_ok=True)
    shutil.copy2(args.database, args.backup)
    snapshot_hash = file_hash(args.backup)
    backup_connection = sqlite3.connect("file:" + args.backup + "?mode=ro", uri=True)
    try:
        primary_before = hud_state(backup_connection, args.user_id, args.role_id)
        assert_primary(primary_before)
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
        clone_row(connection, "role_info", args.role_id, ISOLATION_ROLE_ID, {
            "name": "T67076", "money": "2718281",
        })
        clone_row(connection, "user_info1", args.user_id, ISOLATION_USER_ID, {
            "role0": str(ISOLATION_ROLE_ID), "name": "local-isolation",
            "money": "1200", "bd_money": "3400",
        })
        connection.commit()
        assert_integrity(connection)
        primary = hud_state(connection, args.user_id, args.role_id)
        isolation = hud_state(connection, ISOLATION_USER_ID, ISOLATION_ROLE_ID)
        assert_primary(primary)
        if isolation["premium"] == isolation["boundPremium"]:
            raise RuntimeError(f"PlayerHud isolation currencies are not distinct: {isolation}")
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
        "schemaVersion": 1,
        "module": "PlayerHud",
        "action": "Setup",
        "dataBackend": "sqlite",
        "database": args.database,
        "backup": args.backup,
        "userId": args.user_id,
        "roleId": args.role_id,
        "isolationUserId": ISOLATION_USER_ID,
        "isolationRoleId": ISOLATION_ROLE_ID,
        "snapshotHash": snapshot_hash,
        "fixtureHash": file_hash(args.database),
        "primaryBefore": primary_before,
        "primaryStable": stable_hud_state(primary),
        "isolation": isolation,
        "originalIsolationUserRows": original_isolation_users,
        "originalIsolationRoleRows": original_isolation_roles,
        "createdUtc": utc_now(),
    })


def assert_setup(args):
    snapshot = read_json(args.evidence)
    connection = sqlite3.connect(args.database)
    try:
        primary = hud_state(connection, args.user_id, args.role_id)
        isolation = hud_state(connection, ISOLATION_USER_ID, ISOLATION_ROLE_ID)
        assert_integrity(connection)
    finally:
        connection.close()
    assert_primary(primary)
    if stable_hud_state(primary) != snapshot["primaryStable"]:
        raise RuntimeError(f"PlayerHud primary state changed after setup/login: {primary}")
    if isolation["roleName"] != "T67076" or isolation["premium"] == isolation["boundPremium"]:
        raise RuntimeError(f"PlayerHud isolation SQLite state mismatch: {isolation}")


def restore(args):
    snapshot = read_json(args.evidence)
    if not os.path.isfile(args.backup) or file_hash(args.backup) != snapshot["snapshotHash"]:
        raise RuntimeError("PlayerHud SQLite immutable backup is missing or changed")
    copy_database(args.backup, args.database)


def assert_restored(args):
    snapshot = read_json(args.evidence)
    checkpoint(args.database)
    actual = file_hash(args.database)
    if actual != snapshot["snapshotHash"]:
        raise RuntimeError(f"PlayerHud SQLite restore hash mismatch: {actual}")
    connection = sqlite3.connect(args.database)
    try:
        primary = hud_state(connection, args.user_id, args.role_id)
        user_rows = connection.execute(
            "SELECT COUNT(*) FROM user_info1 WHERE id=?", (ISOLATION_USER_ID,)
        ).fetchone()[0]
        role_rows = connection.execute(
            "SELECT COUNT(*) FROM role_info WHERE id=?", (ISOLATION_ROLE_ID,)
        ).fetchone()[0]
        assert_integrity(connection)
    finally:
        connection.close()
    if stable_hud_state(primary) != stable_hud_state(snapshot["primaryBefore"]):
        raise RuntimeError(f"PlayerHud primary state changed after restore: {primary}")
    if user_rows != snapshot["originalIsolationUserRows"] or role_rows != snapshot["originalIsolationRoleRows"]:
        raise RuntimeError("PlayerHud isolation rows remained after restore")
    snapshot.update({"restoredHash": actual, "residualCount": 0, "restoredUtc": utc_now()})
    write_json(args.evidence, snapshot)


def assert_relogin(args):
    snapshot = read_json(args.evidence)
    connection = sqlite3.connect(args.database)
    try:
        current = hud_state(connection, args.user_id, args.role_id)
        assert_integrity(connection)
    finally:
        connection.close()
    assert_primary(current)
    if stable_hud_state(current) != snapshot["primaryStable"]:
        raise RuntimeError(f"PlayerHud primary HUD state changed after terminal relogin: {current}")


def cleanup(args):
    if os.path.exists(args.backup):
        os.remove(args.backup)
    remove_sidecars(args.backup)


def assert_cleanup(args):
    if os.path.exists(args.backup) or any(os.path.exists(args.backup + suffix) for suffix in ("-wal", "-shm")):
        raise RuntimeError("PlayerHud SQLite fixture backup residue remains")
    assert_restored(args)


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
        "Setup": setup,
        "AssertSetup": assert_setup,
        "Restore": restore,
        "AssertRestored": assert_restored,
        "AssertReloginHash": assert_relogin,
        "Cleanup": cleanup,
        "AssertCleanup": assert_cleanup,
    }
    if args.action not in actions:
        raise RuntimeError(f"Unsupported PlayerHud SQLite fixture action: {args.action}")
    actions[args.action](args)


if __name__ == "__main__":
    main()
