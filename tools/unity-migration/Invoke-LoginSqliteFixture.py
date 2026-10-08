import argparse
import hashlib
import json
import os
import shutil
import sqlite3
from datetime import datetime, timezone


PRIMARY = (7200057, 1000003, "T00057")
ISOLATION = (1, 1000001, "S8D01")
NOTICE_TITLE = "Unity Login SQLite Notice validation"
NOTICE_MESSAGE = "W8 SQLite /88 authority fixture"


def sha256(path):
    digest = hashlib.sha256()
    with open(path, "rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest().upper()


def load_evidence(path):
    with open(path, "r", encoding="utf-8") as stream:
        return json.load(stream)


def write_evidence(path, payload):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8", newline="\n") as stream:
        json.dump(payload, stream, ensure_ascii=False, indent=2)
        stream.write("\n")


def connect(path):
    return sqlite3.connect(path, timeout=10)


def connect_readonly(path):
    return sqlite3.connect("file:" + path.replace("\\", "/") + "?mode=ro", uri=True, timeout=10)


def file_set(path):
    result = {}
    for suffix, key in (("", "database"), ("-wal", "wal"), ("-shm", "shm")):
        item = path + suffix
        result[key] = {"exists": os.path.isfile(item), "sha256": sha256(item) if os.path.isfile(item) else None}
    return result


def file_set_hash(state):
    value = json.dumps(state, sort_keys=True, separators=(",", ":")).encode("utf-8")
    return hashlib.sha256(value).hexdigest().upper()


def identity_state(connection):
    rows = connection.execute(
        "SELECT u.id,CAST(u.role0 AS INTEGER),r.name "
        "FROM user_info1 u JOIN role_info r ON r.id=CAST(u.role0 AS INTEGER) "
        "WHERE u.id IN (?,?) ORDER BY u.id",
        (ISOLATION[0], PRIMARY[0]),
    ).fetchall()
    actual = [[int(row[0]), int(row[1]), str(row[2])] for row in rows]
    expected = [list(row) for row in sorted((PRIMARY, ISOLATION))]
    if actual != expected:
        raise RuntimeError(f"Unity SQLite Login identities mismatch: expected={expected}, actual={actual}")
    return actual


def snapshot_file_set(database, backup):
    os.makedirs(backup, exist_ok=False)
    base = os.path.join(backup, os.path.basename(database))
    for suffix in ("", "-wal", "-shm"):
        source = database + suffix
        if os.path.isfile(source):
            shutil.copy2(source, base + suffix)
    original = file_set(database)
    copied = file_set(base)
    if original != copied:
        raise RuntimeError("Login SQLite file-set backup did not preserve database/sidecars exactly")
    return original


def install_sanitized_seed_if_missing(database):
    if os.path.exists(database):
        return False, None
    root = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
    seed = os.path.join(root, "server", "sql", "sqlite", "fixtures", "projectx-validation-base.db")
    manifest_path = os.path.join(root, "server", "sql", "sqlite", "fixtures", "projectx-validation-base.manifest.json")
    with open(manifest_path, "r", encoding="utf-8") as stream:
        manifest = json.load(stream)
    seed_hash = sha256(seed)
    if seed_hash != str(manifest.get("sha256", "")).upper():
        raise RuntimeError("Sanitized Unity SQLite Login seed does not match its checked-in hash manifest")
    os.makedirs(os.path.dirname(database), exist_ok=True)
    shutil.copy2(seed, database)
    if sha256(database) != seed_hash:
        os.remove(database)
        raise RuntimeError("Sanitized Unity SQLite Login seed copy failed hash verification")
    return True, seed_hash


def restore_file_set(database, backup, expected_state):
    base = os.path.join(backup, os.path.basename(database))
    for suffix in ("", "-wal", "-shm"):
        destination = database + suffix
        if os.path.exists(destination):
            os.remove(destination)
    for suffix, key in (("", "database"), ("-wal", "wal"), ("-shm", "shm")):
        expected = expected_state[key]
        source = base + suffix
        if expected["exists"]:
            if not os.path.isfile(source) or sha256(source) != expected["sha256"]:
                raise RuntimeError(f"Login SQLite backup component changed: {key}")
            shutil.copy2(source, database + suffix)


def assert_integrity(path):
    connection = connect_readonly(path)
    try:
        result = connection.execute("PRAGMA integrity_check").fetchone()[0]
        if result != "ok":
            raise RuntimeError(f"Unity Login SQLite integrity_check failed: {result}")
        return result
    finally:
        connection.close()


def setup(database, backup, evidence, user_id, role_id):
    if os.path.exists(backup) or os.path.exists(evidence):
        raise RuntimeError("Login SQLite fixture backup/evidence already exists; restore and clean the prior lifecycle first")
    created_by_fixture, seed_hash = install_sanitized_seed_if_missing(database)
    before_files = None
    try:
        connection = connect_readonly(database)
        try:
            before_identities = identity_state(connection)
            before_notice_count = int(connection.execute("SELECT COUNT(*) FROM notice_login").fetchone()[0])
        finally:
            connection.close()
        before_files = snapshot_file_set(database, backup)
        before_file_hash = file_set_hash(before_files)
        now = int(datetime.now(timezone.utc).timestamp())
        connection = connect(database)
        try:
            row = connection.execute("SELECT COALESCE(MAX(id),0)+1 FROM notice_login").fetchone()
            notice_id = int(row[0])
            connection.execute(
                "INSERT INTO notice_login(id,title,msg,showType,jumpType,beginTime,endTime) "
                "VALUES(?,?,?,?,?,?,?)",
                (notice_id, NOTICE_TITLE, NOTICE_MESSAGE, 0, 0, now - 60, now + 3600),
            )
            connection.commit()
            after_identities = identity_state(connection)
        finally:
            connection.close()
        if before_identities != after_identities:
            raise RuntimeError("Login SQLite Notice setup changed fixed-account identities")
        write_evidence(evidence, {
            "schemaVersion": 1,
            "action": "Setup",
            "backend": "sqlite",
            "database": database,
            "backup": backup,
            "userId": user_id,
            "roleId": role_id,
            "identities": before_identities,
            "noticeId": notice_id,
            "noticeTitle": NOTICE_TITLE,
            "noticeMessage": NOTICE_MESSAGE,
            "noticeBeginTime": now - 60,
            "noticeEndTime": now + 3600,
            "noticeCountBefore": before_notice_count,
            "databaseCreatedByFixture": created_by_fixture,
            "sourceSeedHash": seed_hash,
            "snapshotFiles": before_files,
            "snapshotHash": before_file_hash,
            "fixtureHash": sha256(database),
            "createdUtc": datetime.now(timezone.utc).isoformat(),
        })
    except Exception:
        if before_files is not None and os.path.isdir(backup):
            restore_file_set(database, backup, before_files)
        if os.path.isdir(backup):
            shutil.rmtree(backup)
        if created_by_fixture:
            for suffix in ("", "-wal", "-shm"):
                if os.path.exists(database + suffix):
                    os.remove(database + suffix)
        raise


def verify_fixture(database, evidence):
    connection = connect_readonly(database)
    try:
        identities = identity_state(connection)
        row = connection.execute(
            "SELECT id,title,msg,showType,jumpType,beginTime,endTime FROM notice_login WHERE id=?",
            (int(evidence["noticeId"]),),
        ).fetchone()
        count = int(connection.execute(
            "SELECT COUNT(*) FROM notice_login WHERE title=? AND msg=?",
            (evidence["noticeTitle"], evidence["noticeMessage"]),
        ).fetchone()[0])
        integrity = connection.execute("PRAGMA integrity_check").fetchone()[0]
    finally:
        connection.close()
    expected = (
        int(evidence["noticeId"]), evidence["noticeTitle"], evidence["noticeMessage"],
        0, 0, int(evidence["noticeBeginTime"]), int(evidence["noticeEndTime"]),
    )
    actual = tuple(row) if row is not None else None
    if identities != evidence["identities"] or actual != expected or count != 1 or integrity != "ok":
        raise RuntimeError(f"Login SQLite Notice fixture assertion failed: identities={identities}, notice={actual}, count={count}, integrity={integrity}")
    return {"identities": identities, "notice": list(actual), "integrity": integrity}


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--action", required=True)
    parser.add_argument("--database", required=True)
    parser.add_argument("--backup", required=True)
    parser.add_argument("--evidence", required=True)
    parser.add_argument("--user-id", required=True, type=int)
    parser.add_argument("--role-id", required=True, type=int)
    args = parser.parse_args()
    database, backup, evidence = map(os.path.abspath, (args.database, args.backup, args.evidence))
    if (args.user_id, args.role_id) != PRIMARY[:2]:
        raise RuntimeError("Login Unity SQLite adapter only accepts fixed identity 7200057/1000003")

    if args.action == "Setup":
        setup(database, backup, evidence, args.user_id, args.role_id)
        return

    snapshot = load_evidence(evidence)
    if snapshot.get("backend") != "sqlite" or snapshot.get("database") != database:
        raise RuntimeError("Login SQLite fixture evidence does not match the requested database")
    if args.action == "AssertSetup":
        snapshot["assertedSetup"] = verify_fixture(database, snapshot)
        backup_files = file_set(os.path.join(backup, os.path.basename(database)))
        if file_set_hash(backup_files) != snapshot["snapshotHash"]:
            raise RuntimeError("Login SQLite immutable database/sidecar backup changed")
        write_evidence(evidence, snapshot)
    elif args.action == "AssertReloginHash":
        connection = connect_readonly(database)
        try:
            current = identity_state(connection)
        finally:
            connection.close()
        if current != snapshot["identities"]:
            raise RuntimeError(f"Login SQLite fixed identity relogin hash mismatch: {current}")
        snapshot["postLoginIdentities"] = current
        write_evidence(evidence, snapshot)
    elif args.action == "Restore":
        backup_files = file_set(os.path.join(backup, os.path.basename(database)))
        if file_set_hash(backup_files) != snapshot["snapshotHash"]:
            raise RuntimeError("Login SQLite snapshot changed before restore")
        restore_file_set(database, backup, snapshot["snapshotFiles"])
    elif args.action == "AssertRestored":
        integrity = assert_integrity(database)
        actual_files = file_set(database)
        actual = file_set_hash(actual_files)
        if actual != snapshot["snapshotHash"]:
            raise RuntimeError("Login SQLite restored database/sidecar SHA-256 mismatch")
        if actual_files != snapshot["snapshotFiles"]:
            raise RuntimeError("Login SQLite restored file set differs from its exact pre-test snapshot")
        snapshot["restoredHash"] = actual
        snapshot["restoredIntegrity"] = integrity
        write_evidence(evidence, snapshot)
    elif args.action == "Cleanup":
        if file_set_hash(file_set(database)) != snapshot["snapshotHash"]:
            raise RuntimeError("Login SQLite Cleanup requires an already restored database file set")
        if snapshot.get("databaseCreatedByFixture"):
            for suffix in ("", "-wal", "-shm"):
                path = database + suffix
                if os.path.exists(path):
                    os.remove(path)
        if os.path.isdir(backup):
            shutil.rmtree(backup)
        elif os.path.exists(backup):
            raise RuntimeError("Login SQLite fixture backup path is not a directory")
    elif args.action == "AssertCleanup":
        if os.path.exists(backup):
            raise RuntimeError("Login SQLite fixture backup remains after cleanup")
        if snapshot.get("databaseCreatedByFixture"):
            residue = 0
            database_clean = not any(os.path.exists(database + suffix) for suffix in ("", "-wal", "-shm"))
        else:
            connection = connect_readonly(database)
            try:
                residue = int(connection.execute(
                    "SELECT COUNT(*) FROM notice_login WHERE title=? AND msg=?",
                    (snapshot["noticeTitle"], snapshot["noticeMessage"]),
                ).fetchone()[0])
            finally:
                connection.close()
            database_clean = file_set_hash(file_set(database)) == snapshot["snapshotHash"]
        if residue != 0 or not database_clean:
            raise RuntimeError(f"Login SQLite cleanup assertion failed: noticeResidue={residue}")
        snapshot["residualCount"] = residue
        write_evidence(evidence, snapshot)
    else:
        raise RuntimeError(f"Unsupported Login SQLite fixture action: {args.action}")


if __name__ == "__main__":
    main()
