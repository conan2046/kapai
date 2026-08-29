import argparse
import hashlib
import json
import os
import shutil
import sqlite3
import struct
import zlib
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
    return digest.hexdigest()


def write_json(path, payload):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8", newline="\n") as stream:
        json.dump(payload, stream, ensure_ascii=False, indent=2)
        stream.write("\n")


def read_json(path):
    with open(path, "r", encoding="utf-8") as stream:
        return json.load(stream)


def checkpoint(path):
    connection = sqlite3.connect(path)
    try:
        connection.execute("PRAGMA wal_checkpoint(TRUNCATE)")
    finally:
        connection.close()


def copy_database(source, destination):
    for suffix in ("-wal", "-shm"):
        sidecar = destination + suffix
        if os.path.exists(sidecar):
            os.remove(sidecar)
    shutil.copy2(source, destination)


def expand(value):
    return bytearray(zlib.decompress(bytes.fromhex(value)))


def compress(value):
    return zlib.compress(bytes(value), 9).hex()


def read_u8(data, cursor):
    value = data[cursor[0]]
    cursor[0] += 1
    return value


def read_u16(data, cursor):
    value = struct.unpack_from("<H", data, cursor[0])[0]
    cursor[0] += 2
    return value


def read_u32(data, cursor):
    value = struct.unpack_from("<I", data, cursor[0])[0]
    cursor[0] += 4
    return value


def skip_stage_section(data, cursor):
    read_u32(data, cursor)
    read_u32(data, cursor)
    for _ in range(read_u16(data, cursor)):
        read_u32(data, cursor)
        read_u16(data, cursor)
        node_count = read_u8(data, cursor)
        cursor[0] += 5 * node_count
        fix_count = read_u8(data, cursor)
        cursor[0] += 4 * fix_count
        state_count = read_u8(data, cursor)
        cursor[0] += 5 * state_count


def story_offset(data):
    cursor = [0]
    skip_stage_section(data, cursor)
    skip_stage_section(data, cursor)
    attack_count = read_u16(data, cursor)
    cursor[0] += 5 * attack_count
    reset_count = read_u16(data, cursor)
    cursor[0] += 5 * reset_count
    trial_count = read_u8(data, cursor)
    cursor[0] += 13 * trial_count
    if cursor[0] + 9 > len(data):
        raise RuntimeError("guan_qia has no complete FengShenStory tail")
    return cursor[0]


def patch_story(value, count, chapter, node):
    data = expand(value)
    offset = story_offset(data)
    struct.pack_into("<BII", data, offset, count, chapter, node)
    return compress(data)


def story_state(value):
    data = expand(value)
    offset = story_offset(data)
    count, chapter, node = struct.unpack_from("<BII", data, offset)
    return {"count": count, "chapterIndex": chapter, "nodeId": node}


def patch_pet_levels(value, level):
    data = expand(value)
    count, extension_count = data[0], data[1]
    position = 2
    for _ in range(count):
        pet_id = struct.unpack_from("<H", data, position)[0]
        position += 2
        if pet_id == 0:
            continue
        struct.pack_into("<H", data, position, level)
        position += 2 + 4 + 2
        name_length = data[position]
        position += 1 + name_length
        if extension_count:
            position += 1
            entry_count = data[position]
            position += 1 + 3 * entry_count
    if position > len(data):
        raise RuntimeError("pet payload layout is invalid")
    return compress(data)


def stable_hash(connection, user_id, role_id):
    row = connection.execute(
        "SELECT r.guan_qia,r.pet,r.package,r.save_data,r.save_val,r.mission,r.money,r.exp,r.level,u.money,u.bd_money "
        "FROM role_info r JOIN user_info1 u ON u.id=? AND CAST(u.role0 AS INTEGER)=r.id WHERE r.id=?",
        (user_id, role_id),
    ).fetchone()
    if row is None:
        raise RuntimeError(f"identity {user_id}/{role_id} is missing")
    payload = "|".join("" if value is None else str(value) for value in row)
    return hashlib.sha256(payload.encode("utf-8")).hexdigest()


def clone_row(connection, table, source_id, target_id, replacements):
    columns = [row[1] for row in connection.execute(f"PRAGMA table_info({table})")]
    source = connection.execute(f"SELECT * FROM {table} WHERE id=?", (source_id,)).fetchone()
    if source is None:
        raise RuntimeError(f"{table} source id={source_id} is missing")
    values = list(source)
    values[columns.index("id")] = target_id
    for name, value in replacements.items():
        values[columns.index(name)] = value
    placeholders = ",".join("?" for _ in columns)
    connection.execute(
        f"INSERT INTO {table} ({','.join(columns)}) VALUES ({placeholders})", values
    )


def setup(args):
    if os.path.exists(args.backup):
        raise RuntimeError("FengShenStory SQLite backup already exists; restore it before rerun")
    checkpoint(args.database)
    os.makedirs(os.path.dirname(args.backup), exist_ok=True)
    shutil.copy2(args.database, args.backup)
    snapshot_hash = file_hash(args.backup)
    connection = sqlite3.connect(args.database)
    try:
        connection.execute("BEGIN IMMEDIATE")
        link = connection.execute("SELECT role0 FROM user_info1 WHERE id=?", (args.user_id,)).fetchone()
        if link is None or int(link[0]) != args.role_id:
            raise RuntimeError("FengShenStory primary SQLite identity mismatch")
        connection.execute("DELETE FROM user_info1 WHERE id=?", (ISOLATION_USER_ID,))
        connection.execute("DELETE FROM role_info WHERE id=?", (ISOLATION_ROLE_ID,))
        clone_row(connection, "role_info", args.role_id, ISOLATION_ROLE_ID,
                  {"name": "T67076", "guan_qia": patch_story(connection.execute(
                      "SELECT guan_qia FROM role_info WHERE id=?", (args.role_id,)).fetchone()[0], 5, 0, 40011),
                   "level": "99"})
        clone_row(connection, "user_info1", args.user_id, ISOLATION_USER_ID,
                  {"role0": str(ISOLATION_ROLE_ID), "name": "local-isolation"})
        role = connection.execute("SELECT guan_qia,pet FROM role_info WHERE id=?", (args.role_id,)).fetchone()
        connection.execute(
            "UPDATE role_info SET guan_qia=?,pet=?,level='99' WHERE id=?",
            (patch_story(role[0], 5, 6, 40074), patch_pet_levels(role[1], 100), args.role_id),
        )
        connection.commit()
        primary = story_state(connection.execute("SELECT guan_qia FROM role_info WHERE id=?", (args.role_id,)).fetchone()[0])
        isolation = story_state(connection.execute("SELECT guan_qia FROM role_info WHERE id=?", (ISOLATION_ROLE_ID,)).fetchone()[0])
        stable = stable_hash(sqlite3.connect(args.backup), args.user_id, args.role_id)
    except Exception:
        connection.rollback()
        connection.close()
        copy_database(args.backup, args.database)
        raise
    finally:
        if connection:
            connection.close()
    checkpoint(args.database)
    write_json(args.evidence, {
        "action": "Setup", "dataBackend": "sqlite", "database": args.database,
        "userId": args.user_id, "roleId": args.role_id,
        "isolationUserId": ISOLATION_USER_ID, "isolationRoleId": ISOLATION_ROLE_ID,
        "snapshotHash": snapshot_hash, "stableHash": stable,
        "injected": primary, "isolation": isolation, "createdUtc": utc_now(),
    })


def assert_setup(args):
    connection = sqlite3.connect(args.database)
    try:
        primary = story_state(connection.execute("SELECT guan_qia FROM role_info WHERE id=?", (args.role_id,)).fetchone()[0])
        isolation = story_state(connection.execute("SELECT guan_qia FROM role_info WHERE id=?", (ISOLATION_ROLE_ID,)).fetchone()[0])
        link = connection.execute("SELECT role0 FROM user_info1 WHERE id=?", (ISOLATION_USER_ID,)).fetchone()
        if primary != {"count": 5, "chapterIndex": 6, "nodeId": 40074}:
            raise RuntimeError(f"primary FengShenStory state mismatch: {primary}")
        if isolation != {"count": 5, "chapterIndex": 0, "nodeId": 40011} or int(link[0]) != ISOLATION_ROLE_ID:
            raise RuntimeError("isolation FengShenStory state mismatch")
    finally:
        connection.close()


def restore(args):
    if not os.path.exists(args.backup):
        raise RuntimeError("FengShenStory SQLite backup is missing")
    copy_database(args.backup, args.database)


def assert_restored(args):
    snapshot = read_json(args.evidence)
    checkpoint(args.database)
    actual = file_hash(args.database)
    if actual != snapshot["snapshotHash"]:
        raise RuntimeError(f"FengShenStory SQLite restore hash mismatch: {actual}")
    connection = sqlite3.connect(args.database)
    try:
        if connection.execute("SELECT COUNT(*) FROM user_info1 WHERE id=?", (ISOLATION_USER_ID,)).fetchone()[0] != 0:
            raise RuntimeError("FengShenStory isolation user remained after restore")
    finally:
        connection.close()
    snapshot.update({"action": "AssertRestored", "restoredHash": actual, "restored": True, "assertedUtc": utc_now()})
    write_json(args.evidence, snapshot)


def assert_relogin(args):
    snapshot = read_json(args.evidence)
    connection = sqlite3.connect(args.database)
    try:
        actual = stable_hash(connection, args.user_id, args.role_id)
    finally:
        connection.close()
    if actual != snapshot["stableHash"]:
        raise RuntimeError(f"FengShenStory stable relogin hash mismatch: {actual}")


def cleanup(args):
    if os.path.exists(args.backup):
        os.remove(args.backup)


def assert_cleanup(args):
    if os.path.exists(args.backup):
        raise RuntimeError("FengShenStory SQLite backup residue remains")
    assert_restored(args)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--action", required=True)
    parser.add_argument("--database", required=True)
    parser.add_argument("--backup", required=True)
    parser.add_argument("--evidence", required=True)
    parser.add_argument("--user-id", type=int, required=True)
    parser.add_argument("--role-id", type=int, required=True)
    args = parser.parse_args()
    if args.action == "Setup": setup(args)
    elif args.action == "AssertSetup": assert_setup(args)
    elif args.action == "Restore": restore(args)
    elif args.action == "AssertRestored": assert_restored(args)
    elif args.action == "AssertReloginHash": assert_relogin(args)
    elif args.action == "Cleanup": cleanup(args)
    elif args.action == "AssertCleanup": assert_cleanup(args)
    else: raise RuntimeError(f"unsupported action: {args.action}")
    print(f"FengShenStory SQLite fixture {args.action} passed")


if __name__ == "__main__":
    main()
