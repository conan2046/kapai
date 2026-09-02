import argparse
import hashlib
import json
import os
import shutil
import sqlite3
import struct
from datetime import datetime, timezone


SCENE_ID = 2
SCENE_ROW = (
    2, "1", "3", "0", "1600", "2", "5|6|7|8", "黄河滩", "3", "3008", "1", "454", "344", 0,
)
MONSTER_ROWS = (
    (13, "480", "798", "5030", "30", "5025", "5", "510|742|511|851|378|809|", "45", "2"),
    (14, "1398", "1393", "5036", "30", "5031", "6", "1383|1329|1305|1433|1501|1437|", "45", "2"),
    (15, "2271", "543", "5042", "30", "5037", "7", "2185|492|2271|543|2382|531|", "45", "2"),
    (16, "907", "1340", "5048", "30", "5043", "8", "937|1265|796|1342|964|1406|", "45", "2"),
)


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


def stable_hash(connection, user_id, role_id):
    row = connection.execute(
        "SELECT u.id,u.role0,r.id,r.name,r.level,r.pet,r.zhenfa "
        "FROM user_info1 u JOIN role_info r ON r.id=CAST(u.role0 AS INTEGER) "
        "WHERE u.id=? AND r.id=?",
        (user_id, role_id),
    ).fetchone()
    if row is None:
        raise RuntimeError(f"BattleMeetMonster identity {user_id}/{role_id} is missing")
    return hashlib.sha256("|".join(str(value or "") for value in row).encode("utf-8")).hexdigest().upper()


def scene_slot(save_data):
    data = bytes.fromhex(save_data)
    cursor = 1 + data[0]
    cursor += 1 + data[cursor] * 2
    count32 = data[cursor]
    cursor += 1
    if count32 <= 3 or cursor + count32 * 4 > len(data):
        raise RuntimeError("BattleMeetMonster save_data has no Data32[3]")
    return data, cursor + 3 * 4


def decode_scene_id(save_data):
    data, offset = scene_slot(save_data)
    return struct.unpack_from("<I", data, offset)[0]


def patch_scene_id(save_data):
    data, offset = scene_slot(save_data)
    patched = bytearray(data)
    struct.pack_into("<I", patched, offset, SCENE_ID)
    return patched.hex()


def assert_integrity(connection):
    value = connection.execute("PRAGMA integrity_check").fetchone()[0]
    if value != "ok":
        raise RuntimeError(f"BattleMeetMonster SQLite integrity_check failed: {value}")


def setup(args):
    if os.path.exists(args.backup):
        raise RuntimeError("BattleMeetMonster SQLite backup already exists; restore it before rerun")
    checkpoint(args.database)
    os.makedirs(os.path.dirname(args.backup), exist_ok=True)
    shutil.copy2(args.database, args.backup)
    snapshot_hash = file_hash(args.backup)
    backup_connection = sqlite3.connect(args.backup)
    try:
        stable = stable_hash(backup_connection, args.user_id, args.role_id)
        original_scene_rows = backup_connection.execute(
            "SELECT COUNT(*) FROM game_scene WHERE id=?", (SCENE_ID,)
        ).fetchone()[0]
        original_monster_rows = backup_connection.execute(
            "SELECT COUNT(*) FROM monster_distribution WHERE id BETWEEN 13 AND 16"
        ).fetchone()[0]
    finally:
        backup_connection.close()

    connection = sqlite3.connect(args.database)
    try:
        connection.execute("BEGIN IMMEDIATE")
        link = connection.execute("SELECT role0 FROM user_info1 WHERE id=?", (args.user_id,)).fetchone()
        if link is None or int(link[0]) != args.role_id:
            raise RuntimeError("BattleMeetMonster fixed SQLite identity mismatch")
        save_data = connection.execute("SELECT save_data FROM role_info WHERE id=?", (args.role_id,)).fetchone()
        if save_data is None:
            raise RuntimeError("BattleMeetMonster fixed role is missing")
        connection.execute(
            "INSERT OR REPLACE INTO game_scene "
            "(id,fight_step,fight_type,group_id,height,map_id,monster,name,show_type,width,world_trans,x,y,pai_ming) "
            "VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?)", SCENE_ROW,
        )
        connection.executemany(
            "INSERT OR REPLACE INTO monster_distribution "
            "(id,findPath_x,findPath_y,max_fightId,meetDistance,min_fightId,monster_id,pos,radius,scene_id) "
            "VALUES (?,?,?,?,?,?,?,?,?,?)", MONSTER_ROWS,
        )
        connection.execute(
            "UPDATE role_info SET save_data=? WHERE id=?", (patch_scene_id(save_data[0]), args.role_id),
        )
        connection.commit()
        assert_integrity(connection)
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
        "action": "Setup", "dataBackend": "sqlite", "database": args.database,
        "userId": args.user_id, "roleId": args.role_id,
        "source": "server/sql/_all_sql.sql:198-200,1803-1807",
        "snapshotHash": snapshot_hash, "stableHash": stable,
        "originalSceneRows": original_scene_rows, "originalMonsterRows": original_monster_rows,
        "injectedSceneId": SCENE_ID, "injectedMonsterDistributionIds": [13, 14, 15, 16],
        "createdUtc": utc_now(),
    })


def assert_setup(args):
    connection = sqlite3.connect(args.database)
    try:
        link = connection.execute("SELECT role0 FROM user_info1 WHERE id=?", (args.user_id,)).fetchone()
        scene = connection.execute(
            "SELECT id,name,map_id,monster,fight_type,fight_step,x,y,width,height,world_trans,show_type "
            "FROM game_scene WHERE id=?", (SCENE_ID,)
        ).fetchone()
        monsters = connection.execute(
            "SELECT id,scene_id,monster_id,pos,min_fightId,max_fightId,meetDistance,radius,findPath_x,findPath_y "
            "FROM monster_distribution WHERE id BETWEEN 13 AND 16 ORDER BY id"
        ).fetchall()
        save_data = connection.execute("SELECT save_data FROM role_info WHERE id=?", (args.role_id,)).fetchone()
        if link is None or int(link[0]) != args.role_id:
            raise RuntimeError("BattleMeetMonster setup identity mismatch")
        expected_scene = (2, "黄河滩", "2", "5|6|7|8", "3", "1", "454", "344", "3008", "1600", "1", "3")
        if scene != expected_scene:
            raise RuntimeError(f"BattleMeetMonster scene row mismatch: {scene}")
        expected_monsters = tuple(
            (row[0], row[9], row[6], row[7], row[5], row[3], row[4], row[8], row[1], row[2])
            for row in MONSTER_ROWS
        )
        if tuple(monsters) != expected_monsters:
            raise RuntimeError(f"BattleMeetMonster distribution rows mismatch: {monsters}")
        if save_data is None or decode_scene_id(save_data[0]) != SCENE_ID:
            raise RuntimeError("BattleMeetMonster Data32[3] scene mismatch")
        assert_integrity(connection)
    finally:
        connection.close()


def restore(args):
    if not os.path.exists(args.backup):
        raise RuntimeError("BattleMeetMonster SQLite backup is missing")
    copy_database(args.backup, args.database)


def assert_restored(args):
    snapshot = read_json(args.evidence)
    checkpoint(args.database)
    actual = file_hash(args.database)
    if actual != snapshot["snapshotHash"]:
        raise RuntimeError(f"BattleMeetMonster SQLite restore hash mismatch: {actual}")
    connection = sqlite3.connect(args.database)
    try:
        scene_rows = connection.execute("SELECT COUNT(*) FROM game_scene WHERE id=?", (SCENE_ID,)).fetchone()[0]
        monster_rows = connection.execute(
            "SELECT COUNT(*) FROM monster_distribution WHERE id BETWEEN 13 AND 16"
        ).fetchone()[0]
        if scene_rows != snapshot["originalSceneRows"] or monster_rows != snapshot["originalMonsterRows"]:
            raise RuntimeError("BattleMeetMonster fixture rows remained after restore")
        assert_integrity(connection)
    finally:
        connection.close()
    snapshot.update({
        "action": "AssertRestored", "restored": True, "restoredHash": actual,
        "residueCount": 0, "assertedUtc": utc_now(),
    })
    write_json(args.evidence, snapshot)


def assert_relogin(args):
    snapshot = read_json(args.evidence)
    connection = sqlite3.connect(args.database)
    try:
        actual = stable_hash(connection, args.user_id, args.role_id)
    finally:
        connection.close()
    if actual != snapshot["stableHash"]:
        raise RuntimeError(f"BattleMeetMonster stable relogin hash mismatch: {actual}")


def cleanup(args):
    if os.path.exists(args.backup):
        os.remove(args.backup)
    remove_sidecars(args.backup)


def assert_cleanup(args):
    if os.path.exists(args.backup) or any(os.path.exists(args.backup + suffix) for suffix in ("-wal", "-shm")):
        raise RuntimeError("BattleMeetMonster SQLite backup residue remains")
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
    actions = {
        "Setup": setup, "AssertSetup": assert_setup, "Restore": restore,
        "AssertRestored": assert_restored, "AssertReloginHash": assert_relogin,
        "Cleanup": cleanup, "AssertCleanup": assert_cleanup,
    }
    if args.action not in actions:
        raise RuntimeError(f"unsupported action: {args.action}")
    actions[args.action](args)
    print(f"BattleMeetMonster SQLite fixture {args.action} passed")


if __name__ == "__main__":
    main()
