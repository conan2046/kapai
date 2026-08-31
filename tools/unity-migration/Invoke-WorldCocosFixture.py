import argparse
import hashlib
import json
import os
import shutil
import sqlite3
import struct
import time
import zlib
from datetime import datetime, timezone


ISOLATION_USER_ID = 705213
ISOLATION_ROLE_ID = 1000006
TARGET_MAP_ID = 1003
ADJACENT_MAP_ID = 1002
TARGET_STAGE_ID = 10023
TARGET_BOX_IDS = (10031, 20031)
COCOS_ROLE_LEVEL = 99
COCOS_EXP = 0
COCOS_ZHANDOU_LI = 17240
COCOS_VISUAL_STAMINA = 101
COCOS_RETURN_STAMINA = 96
COCOS_PET = "78da6362b464606400014606ce17ddfd4f5b573cddbf8081c1012ecaf6b279e2933dcb181800ccdb0b2b"
COCOS_ZHENFA = "78da63606464606465b264c00e581112000bde0082"
COCOS_PET_EQUIP = "78da63616064c8ad7bc9cc00041dc20c0c8c8c8cfc0c4c40a15760211060646006f25f23f15980fc37487c262443185991b433b28155c8310000a4f10c00"
COCOS_BATTLE_INPUT_HASHES = {
    "pet": "B13004157E15D4552C70417374B83B634375F2B1C5E58C9D55FE77489E1DB0DE",
    "zhenfa": "36458EA415215A038A4DF0D7249C41871AB0A5971DF53774C4E64820032C8B8E",
    "petEquip": "EE59CD635C68D2975617F6B34F9D6D4E832E572993F164C3281F9A134290C1D3",
}


def utc_now():
    return datetime.now(timezone.utc).isoformat()


def file_hash(path):
    digest = hashlib.sha256()
    with open(path, "rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest().upper()


def value_hash(value):
    return hashlib.sha256((value or "").encode("utf-8")).hexdigest().upper()


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


def remove_sidecars(path):
    for suffix in ("-wal", "-shm"):
        sidecar = path + suffix
        if os.path.exists(sidecar):
            os.remove(sidecar)


def copy_database(source, destination):
    remove_sidecars(destination)
    shutil.copy2(source, destination)


def read_u8(data, cursor):
    if cursor[0] >= len(data):
        raise RuntimeError("World guan_qia overran u8")
    value = data[cursor[0]]
    cursor[0] += 1
    return value


def read_u16(data, cursor):
    if cursor[0] + 2 > len(data):
        raise RuntimeError("World guan_qia overran u16")
    value = struct.unpack_from("<H", data, cursor[0])[0]
    cursor[0] += 2
    return value


def read_u32(data, cursor):
    if cursor[0] + 4 > len(data):
        raise RuntimeError("World guan_qia overran u32")
    value = struct.unpack_from("<I", data, cursor[0])[0]
    cursor[0] += 4
    return value


def read_section(data, cursor):
    section = {"curMapId": read_u32(data, cursor), "curNodeId": read_u32(data, cursor), "maps": []}
    for _ in range(read_u16(data, cursor)):
        item = {"mapId": read_u32(data, cursor), "sumStar": read_u16(data, cursor),
                "nodeStars": {}, "fixIds": [], "fixStates": {}}
        for _ in range(read_u8(data, cursor)):
            node_id = read_u32(data, cursor)
            item["nodeStars"][node_id] = read_u8(data, cursor)
        for _ in range(read_u8(data, cursor)):
            item["fixIds"].append(read_u32(data, cursor))
        for _ in range(read_u8(data, cursor)):
            fix_id = read_u32(data, cursor)
            item["fixStates"][fix_id] = read_u8(data, cursor)
        section["maps"].append(item)
    return section


def write_section(section):
    output = bytearray(struct.pack("<IIH", section["curMapId"], section["curNodeId"], len(section["maps"])))
    for item in sorted(section["maps"], key=lambda value: value["mapId"]):
        nodes = sorted(item["nodeStars"].items())
        fix_ids = sorted(set(item["fixIds"]))
        states = sorted(item["fixStates"].items())
        if max(len(nodes), len(fix_ids), len(states)) > 255:
            raise RuntimeError(f"World map {item['mapId']} exceeds persisted byte count")
        output.extend(struct.pack("<IHB", item["mapId"], item["sumStar"], len(nodes)))
        for node_id, stars in nodes:
            output.extend(struct.pack("<IB", node_id, stars))
        output.extend(struct.pack("<B", len(fix_ids)))
        for fix_id in fix_ids:
            output.extend(struct.pack("<I", fix_id))
        output.extend(struct.pack("<B", len(states)))
        for fix_id, state in states:
            output.extend(struct.pack("<IB", fix_id, state))
    return output


def decode_world(value):
    data = zlib.decompress(bytes.fromhex(value))
    cursor = [0]
    primary = read_section(data, cursor)
    secondary = read_section(data, cursor)
    if cursor[0] >= len(data):
        raise RuntimeError("World guan_qia has no post-chapter state")
    return primary, secondary, data[cursor[0]:]


def patch_world(value):
    primary, secondary, tail = decode_world(value)
    matches = [item for item in primary["maps"] if item["mapId"] == TARGET_MAP_ID]
    if len(matches) > 1:
        raise RuntimeError("World target chapter is duplicated")
    if matches:
        chapter = matches[0]
    else:
        chapter = {"mapId": TARGET_MAP_ID, "sumStar": 0, "nodeStars": {}, "fixIds": [], "fixStates": {}}
        primary["maps"].append(chapter)
    if not any(item["mapId"] == ADJACENT_MAP_ID for item in primary["maps"]):
        primary["maps"].append({"mapId": ADJACENT_MAP_ID, "sumStar": 0,
                                "nodeStars": {}, "fixIds": [], "fixStates": {}})
    primary["curMapId"] = TARGET_MAP_ID
    primary["curNodeId"] = TARGET_STAGE_ID
    chapter["sumStar"] = max(int(chapter["sumStar"]), 10)
    chapter["nodeStars"][TARGET_STAGE_ID] = max(int(chapter["nodeStars"].get(TARGET_STAGE_ID, 0)), 3)
    for fix_id in TARGET_BOX_IDS:
        if fix_id not in chapter["fixIds"]:
            chapter["fixIds"].append(fix_id)
        chapter["fixStates"][fix_id] = 1
    raw = bytes(write_section(primary) + write_section(secondary) + tail)
    value = zlib.compress(raw, 9).hex()
    assert_world(value, allow_claimed=False)
    return value


def world_state(value):
    primary, _, raw_tail = decode_world(value)
    chapter = next((item for item in primary["maps"] if item["mapId"] == TARGET_MAP_ID), None)
    if chapter is None:
        return {"chapterPresent": False}
    return {
        "chapterPresent": True,
        "adjacentChapterPresent": any(item["mapId"] == ADJACENT_MAP_ID for item in primary["maps"]),
        "rawBytes": len(zlib.decompress(bytes.fromhex(value))),
        "tailBytes": len(raw_tail),
        "chapterId": TARGET_MAP_ID,
        "stageId": primary["curNodeId"],
        "chapterStars": chapter["sumStar"],
        "stageStars": chapter["nodeStars"].get(TARGET_STAGE_ID, 0),
        "boxStates": {str(fix_id): chapter["fixStates"].get(fix_id, 0) for fix_id in TARGET_BOX_IDS},
    }


def assert_world(value, allow_claimed=True):
    state = world_state(value)
    expected_states = ({1, 2} if allow_claimed else {1})
    if (not state.get("chapterPresent") or not state.get("adjacentChapterPresent")
            or state["stageId"] != TARGET_STAGE_ID
            or state["chapterStars"] < 10 or state["stageStars"] < 3
            or any(value not in expected_states for value in state["boxStates"].values())):
        raise RuntimeError(f"World injected state mismatch: {state}")
    return state


def decode_pet_ids(value):
    data = zlib.decompress(bytes.fromhex(value))
    if len(data) < 2:
        raise RuntimeError("World battle pet payload is truncated")
    cursor = 2
    pets = []
    for _ in range(data[0]):
        if cursor + 11 > len(data):
            raise RuntimeError("World battle pet record is truncated")
        pet_id, level = struct.unpack_from("<HH", data, cursor)
        cursor += 10
        name_length = data[cursor]
        cursor += 1 + name_length
        if data[1] > 0:
            cursor += 1
            if cursor >= len(data):
                raise RuntimeError("World battle pet cultivation data is truncated")
            cultivation_count = data[cursor]
            cursor += 1 + 3 * cultivation_count
        if cursor > len(data):
            raise RuntimeError(f"World battle pet {pet_id} exceeds payload")
        pets.append({"id": pet_id, "level": level})
    if cursor != len(data):
        raise RuntimeError("World battle pet payload has trailing bytes")
    return pets


def decode_deployed_pet_ids(value):
    data = zlib.decompress(bytes.fromhex(value))
    cursor = 0
    if len(data) < 2:
        raise RuntimeError("World battle formation payload is truncated")
    cursor += 1
    formation_count = data[cursor]
    cursor += 1 + formation_count * 3
    if cursor >= len(data):
        raise RuntimeError("World battle formation definitions are truncated")
    member_count = data[cursor]
    cursor += 1
    deployed = []
    for _ in range(member_count):
        if cursor + 5 > len(data):
            raise RuntimeError("World battle formation member is truncated")
        member_type, member_id = struct.unpack_from("<BI", data, cursor)
        cursor += 5
        if member_type == 2 and member_id > 0:
            deployed.append(member_id)
    if cursor >= len(data):
        raise RuntimeError("World battle formation combat list is missing")
    combat_count = data[cursor]
    cursor += 1 + combat_count * 2
    if cursor != len(data):
        raise RuntimeError("World battle formation payload has trailing bytes")
    return deployed


def battle_input_state(connection, role_id):
    row = connection.execute(
        "SELECT level,exp,zhanDouLi,pet,zhenfa,pet_equip FROM role_info WHERE id=?", (role_id,)
    ).fetchone()
    if row is None:
        raise RuntimeError(f"World battle role {role_id} is missing")
    return {
        "level": int(row[0]),
        "exp": int(row[1]),
        "zhanDouLi": int(row[2]),
        "petHashes": {
            "pet": value_hash(row[3]),
            "zhenfa": value_hash(row[4]),
            "petEquip": value_hash(row[5]),
        },
        "pets": decode_pet_ids(row[3]),
        "deployedPetIds": decode_deployed_pet_ids(row[4]),
    }


def assert_battle_input(connection, role_id):
    state = battle_input_state(connection, role_id)
    if (state["level"] != COCOS_ROLE_LEVEL or state["exp"] != COCOS_EXP
            or state["zhanDouLi"] != COCOS_ZHANDOU_LI
            or state["petHashes"] != COCOS_BATTLE_INPUT_HASHES
            or state["pets"] != [{"id": 57, "level": 1}, {"id": 64, "level": 1}]
            or state["deployedPetIds"] != [57]):
        raise RuntimeError(f"World Cocos battle input mismatch: {state}")
    return state


def stable_hash(connection, user_id, role_id):
    row = connection.execute(
        "SELECT r.package,r.save_data,r.user_spirit,r.money,r.exp,r.level,r.pet,r.zhenfa,u.money,u.bd_money "
        "FROM role_info r JOIN user_info1 u ON u.id=? AND CAST(u.role0 AS INTEGER)=r.id WHERE r.id=?",
        (user_id, role_id),
    ).fetchone()
    if row is None:
        raise RuntimeError(f"World identity {user_id}/{role_id} is missing")
    payload = "|".join("" if value is None else str(value) for value in row)
    return hashlib.sha256(payload.encode("utf-8")).hexdigest().upper()


def clone_row(connection, table, source_id, target_id, replacements):
    columns = [row[1] for row in connection.execute(f"PRAGMA table_info({table})")]
    source = connection.execute(f"SELECT * FROM {table} WHERE id=?", (source_id,)).fetchone()
    if source is None:
        raise RuntimeError(f"{table} source id={source_id} is missing")
    values = list(source)
    values[columns.index("id")] = target_id
    for name, value in replacements.items():
        values[columns.index(name)] = value
    connection.execute(
        f"INSERT INTO {table} ({','.join(columns)}) VALUES ({','.join('?' for _ in columns)})", values
    )


def patch_user_spirit(value, stamina):
    data = bytearray(zlib.decompress(bytes.fromhex(value)))
    if len(data) < 6:
        raise RuntimeError("World user_spirit is truncated")
    struct.pack_into("<HI", data, 0, stamina, int(time.time()))
    return zlib.compress(bytes(data), 9).hex()


def read_stamina(value):
    data = zlib.decompress(bytes.fromhex(value))
    if len(data) < 2:
        raise RuntimeError("World user_spirit is truncated")
    return struct.unpack_from("<H", data, 0)[0]


def setup(args, visual=False):
    if os.path.exists(args.backup):
        raise RuntimeError("World SQLite backup already exists; restore and clean it before rerun")
    checkpoint(args.database)
    os.makedirs(os.path.dirname(args.backup), exist_ok=True)
    copy_database(args.database, args.backup)
    snapshot_hash = file_hash(args.backup)
    backup_connection = sqlite3.connect(args.backup)
    try:
        stable = stable_hash(backup_connection, args.user_id, args.role_id)
    finally:
        backup_connection.close()
    connection = sqlite3.connect(args.database)
    try:
        connection.execute("BEGIN IMMEDIATE")
        link = connection.execute("SELECT role0 FROM user_info1 WHERE id=?", (args.user_id,)).fetchone()
        if link is None or int(link[0]) != args.role_id:
            raise RuntimeError("World primary SQLite identity mismatch")
        original = connection.execute(
            "SELECT guan_qia,user_spirit FROM role_info WHERE id=?", (args.role_id,)
        ).fetchone()
        if original is None or not original[0] or not original[1]:
            raise RuntimeError("World primary guan_qia is missing")
        injected = patch_world(original[0])
        connection.execute(
            "UPDATE role_info SET guan_qia=?,level=?,exp=?,pet=?,zhenfa=?,pet_equip=?,zhanDouLi=? WHERE id=?",
            (injected, COCOS_ROLE_LEVEL, COCOS_EXP, COCOS_PET, COCOS_ZHENFA, COCOS_PET_EQUIP,
             COCOS_ZHANDOU_LI, args.role_id),
        )
        if visual:
            connection.execute(
                "UPDATE role_info SET user_spirit=? WHERE id=?",
                (patch_user_spirit(original[1], COCOS_VISUAL_STAMINA), args.role_id),
            )
        connection.execute("DELETE FROM user_info1 WHERE id=?", (ISOLATION_USER_ID,))
        connection.execute("DELETE FROM role_info WHERE id=?", (ISOLATION_ROLE_ID,))
        clone_row(connection, "role_info", args.role_id, ISOLATION_ROLE_ID,
                  {"name": "T67076", "guan_qia": original[0], "level": "99"})
        clone_row(connection, "user_info1", args.user_id, ISOLATION_USER_ID,
                  {"role0": str(ISOLATION_ROLE_ID), "name": "local-isolation"})
        connection.commit()
        injected_state = assert_world(connection.execute(
            "SELECT guan_qia FROM role_info WHERE id=?", (args.role_id,)).fetchone()[0], allow_claimed=False)
        injected_battle_input = assert_battle_input(connection, args.role_id)
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
        "visualMode": visual,
        "visualStamina": COCOS_VISUAL_STAMINA if visual else None,
        "injected": injected_state, "battleInput": injected_battle_input, "createdUtc": utc_now(),
    })


def setup_visual(args):
    setup(args, visual=True)


def assert_setup(args):
    connection = sqlite3.connect(args.database)
    try:
        row = connection.execute("SELECT guan_qia FROM role_info WHERE id=?", (args.role_id,)).fetchone()
        if row is None:
            raise RuntimeError("World primary role disappeared")
        assert_world(row[0], allow_claimed=True)
        assert_battle_input(connection, args.role_id)
        isolation = connection.execute(
            "SELECT u.role0,r.id FROM user_info1 u JOIN role_info r ON r.id=CAST(u.role0 AS INTEGER) WHERE u.id=?",
            (ISOLATION_USER_ID,),
        ).fetchone()
        if isolation is None or int(isolation[0]) != ISOLATION_ROLE_ID or int(isolation[1]) != ISOLATION_ROLE_ID:
            raise RuntimeError("World isolation identity mismatch")
    finally:
        connection.close()


def assert_post_validation(args):
    snapshot = read_json(args.evidence)
    connection = sqlite3.connect(args.database)
    try:
        row = connection.execute("SELECT guan_qia FROM role_info WHERE id=?", (args.role_id,)).fetchone()
        if row is None:
            raise RuntimeError("World primary role disappeared after validation")
        assert_world(row[0], allow_claimed=True)
        state = battle_input_state(connection, args.role_id)
        if (state["level"] != COCOS_ROLE_LEVEL or state["exp"] < COCOS_EXP
                or state["zhanDouLi"] != COCOS_ZHANDOU_LI
                or state["petHashes"] != COCOS_BATTLE_INPUT_HASHES
                or state["pets"] != [{"id": 57, "level": 1}, {"id": 64, "level": 1}]
                or state["deployedPetIds"] != [57]):
            raise RuntimeError(f"World post-validation battle input mismatch: {state}")
        if snapshot.get("visualMode"):
            spirit = connection.execute(
                "SELECT user_spirit FROM role_info WHERE id=?", (args.role_id,)
            ).fetchone()
            if spirit is None or read_stamina(spirit[0]) != COCOS_RETURN_STAMINA:
                raise RuntimeError("World visual return stamina did not match current Cocos 96/100")
        isolation = connection.execute(
            "SELECT u.role0,r.id FROM user_info1 u JOIN role_info r ON r.id=CAST(u.role0 AS INTEGER) WHERE u.id=?",
            (ISOLATION_USER_ID,),
        ).fetchone()
        if isolation is None or int(isolation[0]) != ISOLATION_ROLE_ID or int(isolation[1]) != ISOLATION_ROLE_ID:
            raise RuntimeError("World isolation identity mismatch after validation")
    finally:
        connection.close()
    snapshot.update({"postValidationBattleInput": state, "postValidationAssertedUtc": utc_now()})
    write_json(args.evidence, snapshot)


def restore(args):
    if not os.path.exists(args.backup):
        raise RuntimeError("World SQLite backup is missing")
    copy_database(args.backup, args.database)


def assert_restored(args):
    snapshot = read_json(args.evidence)
    checkpoint(args.database)
    actual = file_hash(args.database)
    if actual != snapshot["snapshotHash"]:
        raise RuntimeError(f"World SQLite restore hash mismatch: {actual}")
    connection = sqlite3.connect(args.database)
    try:
        if connection.execute("SELECT COUNT(*) FROM user_info1 WHERE id=?", (ISOLATION_USER_ID,)).fetchone()[0] != 0:
            raise RuntimeError("World isolation user remained after restore")
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
        raise RuntimeError(f"World SQLite stable relogin hash mismatch: {actual}")
    snapshot.update({"postLoginHashVerified": True, "postLoginStableHash": actual, "postLoginVerifiedUtc": utc_now()})
    write_json(args.evidence, snapshot)


def cleanup(args):
    if os.path.exists(args.backup):
        os.remove(args.backup)
    remove_sidecars(args.backup)


def assert_cleanup(args):
    if os.path.exists(args.backup) or os.path.exists(args.backup + "-wal") or os.path.exists(args.backup + "-shm"):
        raise RuntimeError("World SQLite backup residue remains")
    assert_restored(args)
    if os.path.exists(args.database + "-wal") or os.path.exists(args.database + "-shm"):
        raise RuntimeError("World SQLite database WAL/SHM residue remains")


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
        "Setup": setup, "SetupVisual": setup_visual,
        "AssertSetup": assert_setup, "AssertPostValidation": assert_post_validation,
        "Restore": restore,
        "AssertRestored": assert_restored, "AssertReloginHash": assert_relogin,
        "Cleanup": cleanup, "AssertCleanup": assert_cleanup,
    }
    if args.action not in actions:
        raise RuntimeError(f"unsupported SQLite World action: {args.action}")
    actions[args.action](args)
    print(f"World SQLite fixture {args.action} passed")


if __name__ == "__main__":
    main()
