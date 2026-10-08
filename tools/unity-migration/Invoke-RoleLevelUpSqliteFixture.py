import argparse
import hashlib
import importlib.util
import json
import os
import shutil
import sqlite3
from datetime import datetime, timezone
from pathlib import Path


# Keep the fixed SQLite role eligible for the already-accepted function_id=3
# FengShenStory route (level 32+) and one point below the formal level-60 threshold.
TEST_LEVEL = 60
TEST_EXPERIENCE = 48149
STORY_FIXTURE_MODULE = "Invoke-FengShenStorySqliteFixture.py"
STORY_FIXTURE_CHAPTER = 6
STORY_FIXTURE_NODE = 40074


def patch_story_fixture(value):
    helper_path = Path(__file__).with_name(STORY_FIXTURE_MODULE)
    spec = importlib.util.spec_from_file_location("feng_shen_story_fixture", helper_path)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"FengShenStory fixture helper is unavailable: {helper_path}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    patched = module.patch_story(value, 5, STORY_FIXTURE_CHAPTER, STORY_FIXTURE_NODE)
    return patched, module.story_state(patched)


def now():
    return datetime.now(timezone.utc).isoformat()


def sha256(path):
    digest = hashlib.sha256()
    with open(path, "rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def read_evidence(args):
    if not os.path.isfile(args.evidence):
        raise RuntimeError(f"RoleLevelUp fixture evidence is missing: {args.evidence}")
    with open(args.evidence, "r", encoding="utf-8") as stream:
        return json.load(stream)


def connect(path, readonly=False):
    if readonly:
        uri = "file:" + path.replace("\\", "/") + "?mode=ro"
        return sqlite3.connect(uri, uri=True, timeout=5)
    return sqlite3.connect(path, timeout=5)


def assert_integrity(connection):
    result = connection.execute("PRAGMA integrity_check").fetchone()[0]
    if result != "ok":
        raise RuntimeError(f"RoleLevelUp SQLite integrity_check failed: {result}")


def role_state(connection, role_id):
    row = connection.execute(
        "SELECT id,name,level,exp,money,zhanDouLi FROM role_info WHERE id=?", (role_id,)
    ).fetchone()
    if row is None:
        raise RuntimeError(f"RoleLevelUp SQLite role id={role_id} is missing")
    user = connection.execute(
        "SELECT id,CAST(role0 AS INTEGER),money,bd_money FROM user_info1 WHERE id=?", (7200057,)
    ).fetchone()
    if user is None or int(user[1]) != role_id:
        raise RuntimeError(f"RoleLevelUp SQLite user/role link mismatch: user={user}, expected role={role_id}")
    return {
        "roleId": int(row[0]), "name": str(row[1]), "level": int(row[2]), "experience": int(row[3]),
        "gold": int(row[4]), "power": int(row[5]), "userId": int(user[0]),
        "linkedRoleId": int(user[1]), "premium": int(user[2]), "boundPremium": int(user[3]),
    }


def stable(state):
    return {key: state[key] for key in (
        "roleId", "name", "level", "experience", "gold", "power", "userId",
        "linkedRoleId", "premium", "boundPremium",
    )}


def data_preflight(args):
    if not os.path.isfile(args.database):
        raise RuntimeError(f"RoleLevelUp SQLite database is missing: {args.database}")
    if os.path.exists(args.backup) or os.path.exists(args.evidence):
        raise RuntimeError("RoleLevelUp fixture backup/evidence already exists; restore and clean it before reuse")
    for suffix in ("-wal", "-shm"):
        if os.path.exists(args.database + suffix):
            raise RuntimeError(f"RoleLevelUp fixture requires a checkpointed SQLite database; found {suffix}")
    connection = connect(args.database, readonly=True)
    try:
        assert_integrity(connection)
        before = role_state(connection, args.role_id)
    finally:
        connection.close()
    print(json.dumps({"action": "DataPreflightOnly", "database": args.database, "state": before,
                      "target": {"level": TEST_LEVEL, "experience": TEST_EXPERIENCE},
                      "backupExists": False, "walSidecars": False}, ensure_ascii=False))


def setup(args):
    if not os.path.isfile(args.database):
        raise RuntimeError(f"RoleLevelUp SQLite database is missing: {args.database}")
    if os.path.exists(args.backup) or os.path.exists(args.evidence):
        raise RuntimeError("RoleLevelUp fixture backup/evidence already exists; restore and clean it before reuse")
    os.makedirs(os.path.dirname(args.backup), exist_ok=True)
    source = connect(args.database, readonly=True)
    try:
        assert_integrity(source)
        before = role_state(source, args.role_id)
        story_row = source.execute(
            "SELECT guan_qia FROM role_info WHERE id=?", (args.role_id,)
        ).fetchone()
        if story_row is None:
            raise RuntimeError(f"RoleLevelUp SQLite story state for role id={args.role_id} is missing")
        patched_story, fixture_story_state = patch_story_fixture(story_row[0])
    finally:
        source.close()
    shutil.copy2(args.database, args.backup)
    backup_hash = sha256(args.backup)
    connection = connect(args.database)
    try:
        connection.execute("BEGIN IMMEDIATE")
        cursor = connection.execute(
            "UPDATE role_info SET level=?,exp=?,guan_qia=? WHERE id=?",
            (str(TEST_LEVEL), str(TEST_EXPERIENCE), patched_story, args.role_id),
        )
        if cursor.rowcount != 1:
            raise RuntimeError(f"RoleLevelUp fixture changed {cursor.rowcount} role rows")
        connection.commit()
        assert_integrity(connection)
        configured = role_state(connection, args.role_id)
        if configured["level"] != TEST_LEVEL or configured["experience"] != TEST_EXPERIENCE:
            raise RuntimeError(f"RoleLevelUp fixture setup mismatch: {configured}")
    except Exception:
        connection.rollback()
        connection.close()
        shutil.copy2(args.backup, args.database)
        raise
    finally:
        try:
            connection.close()
        except Exception:
            pass
    evidence = {
        "schemaVersion": 1, "module": "RoleLevelUp", "dataBackend": "sqlite",
        "database": args.database, "backup": args.backup, "userId": 7200057,
        "roleId": args.role_id, "snapshotHash": backup_hash, "fixtureHash": sha256(args.database),
        "primaryBefore": before, "primaryStable": stable(before), "fixtureState": configured,
        "targetLevel": TEST_LEVEL, "targetExperience": TEST_EXPERIENCE,
        "fixtureStoryState": fixture_story_state, "createdUtc": now(),
    }
    os.makedirs(os.path.dirname(args.evidence), exist_ok=True)
    with open(args.evidence, "x", encoding="utf-8") as stream:
        json.dump(evidence, stream, ensure_ascii=False, indent=2)
        stream.write("\n")
    print(json.dumps({"action": "Setup", "snapshotHash": backup_hash,
                      "fixtureHash": evidence["fixtureHash"], "fixtureState": configured,
                      "fixtureStoryState": fixture_story_state}, ensure_ascii=False))


def assert_setup(args):
    evidence = read_evidence(args)
    if sha256(args.backup) != evidence["snapshotHash"] or sha256(args.database) != evidence["fixtureHash"]:
        raise RuntimeError("RoleLevelUp fixture Setup hashes do not match the recorded snapshot")
    connection = connect(args.database, readonly=True)
    try:
        assert_integrity(connection)
        actual = role_state(connection, args.role_id)
    finally:
        connection.close()
    if actual["level"] != TEST_LEVEL or actual["experience"] != TEST_EXPERIENCE:
        raise RuntimeError(f"RoleLevelUp fixture state is incorrect: {actual}")
    connection = connect(args.database, readonly=True)
    try:
        story_row = connection.execute(
            "SELECT guan_qia FROM role_info WHERE id=?", (args.role_id,)
        ).fetchone()
        if story_row is None:
            raise RuntimeError(f"RoleLevelUp SQLite story state for role id={args.role_id} is missing")
        actual_story_state = patch_story_fixture(story_row[0])[1]
    finally:
        connection.close()
    if actual_story_state != evidence["fixtureStoryState"]:
        raise RuntimeError(f"RoleLevelUp FengShenStory fixture state is incorrect: {actual_story_state}")
    print(json.dumps({"action": "AssertSetup", "state": actual,
                      "storyState": actual_story_state}, ensure_ascii=False))


def restore(args):
    evidence = read_evidence(args)
    if not os.path.isfile(args.backup) or sha256(args.backup) != evidence["snapshotHash"]:
        raise RuntimeError("RoleLevelUp fixture backup is missing or its SHA-256 changed")
    for suffix in ("-wal", "-shm"):
        if os.path.exists(args.database + suffix):
            os.remove(args.database + suffix)
    shutil.copy2(args.backup, args.database)
    actual = sha256(args.database)
    if actual != evidence["snapshotHash"]:
        raise RuntimeError("RoleLevelUp fixture Restore did not reproduce the original SQLite bytes")
    evidence["restoredHash"] = actual
    evidence["restoredUtc"] = now()
    with open(args.evidence, "w", encoding="utf-8") as stream:
        json.dump(evidence, stream, ensure_ascii=False, indent=2)
        stream.write("\n")
    print(json.dumps({"action": "Restore", "restoredHash": actual}, ensure_ascii=False))


def assert_restored(args):
    evidence = read_evidence(args)
    if sha256(args.database) != evidence["snapshotHash"]:
        raise RuntimeError("RoleLevelUp fixture database is not byte-identical to its original snapshot")
    connection = connect(args.database, readonly=True)
    try:
        assert_integrity(connection)
        actual = role_state(connection, args.role_id)
    finally:
        connection.close()
    if stable(actual) != evidence["primaryStable"]:
        raise RuntimeError(f"RoleLevelUp fixture restored role state mismatch: {actual}")
    print(json.dumps({"action": "AssertRestored", "state": actual}, ensure_ascii=False))


def assert_relogin(args):
    evidence = read_evidence(args)
    connection = connect(args.database, readonly=True)
    try:
        actual = role_state(connection, args.role_id)
    finally:
        connection.close()
    if stable(actual) != evidence["primaryStable"]:
        raise RuntimeError(f"RoleLevelUp relogin changed the restored authoritative role state: {actual}")
    evidence["reloginStable"] = stable(actual)
    evidence["reloginVerifiedUtc"] = now()
    with open(args.evidence, "w", encoding="utf-8") as stream:
        json.dump(evidence, stream, ensure_ascii=False, indent=2)
        stream.write("\n")
    print(json.dumps({"action": "AssertReloginHash", "state": stable(actual)}, ensure_ascii=False))


def cleanup(args):
    evidence = read_evidence(args)
    if sha256(args.database) != evidence["snapshotHash"]:
        raise RuntimeError("RoleLevelUp fixture cleanup refused: database is not restored to the snapshot")
    for suffix in ("-wal", "-shm"):
        sidecar = args.database + suffix
        if not os.path.exists(sidecar):
            continue
        if suffix == "-wal" and os.path.getsize(sidecar) > 32:
            raise RuntimeError("RoleLevelUp fixture cleanup refused: SQLite WAL still contains frames")
        os.remove(sidecar)
    if os.path.exists(args.backup):
        os.remove(args.backup)
    evidence["residualCount"] = 0
    evidence["cleanupUtc"] = now()
    with open(args.evidence, "w", encoding="utf-8") as stream:
        json.dump(evidence, stream, ensure_ascii=False, indent=2)
        stream.write("\n")
    print(json.dumps({"action": "Cleanup", "residualCount": 0}, ensure_ascii=False))


def assert_cleanup(args):
    evidence = read_evidence(args)
    if evidence.get("residualCount") != 0 or os.path.exists(args.backup):
        raise RuntimeError("RoleLevelUp fixture cleanup is incomplete")
    if sha256(args.database) != evidence["snapshotHash"]:
        raise RuntimeError("RoleLevelUp fixture cleanup database no longer matches its original snapshot")
    for suffix in ("-wal", "-shm"):
        if os.path.exists(args.database + suffix):
            raise RuntimeError(f"RoleLevelUp fixture cleanup found residual SQLite sidecar: {suffix}")
    print(json.dumps({"action": "AssertCleanup", "residualCount": 0}, ensure_ascii=False))


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--action", required=True, choices=(
        "DataPreflightOnly", "Setup", "AssertSetup", "Restore", "AssertRestored",
        "AssertReloginHash", "Cleanup", "AssertCleanup"))
    parser.add_argument("--database", required=True)
    parser.add_argument("--backup", required=True)
    parser.add_argument("--evidence", required=True)
    parser.add_argument("--user-id", type=int, required=True)
    parser.add_argument("--role-id", type=int, required=True)
    args = parser.parse_args()
    args.database, args.backup, args.evidence = map(os.path.abspath, (args.database, args.backup, args.evidence))
    if args.user_id != 7200057 or args.role_id != 1000003:
        raise RuntimeError("RoleLevelUp fixture identity must remain 7200057/1000003")
    actions = {
        "DataPreflightOnly": data_preflight, "Setup": setup, "AssertSetup": assert_setup,
        "Restore": restore, "AssertRestored": assert_restored, "AssertReloginHash": assert_relogin,
        "Cleanup": cleanup, "AssertCleanup": assert_cleanup,
    }
    actions[args.action](args)


if __name__ == "__main__":
    main()
