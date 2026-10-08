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
FIXTURE_STAGE_STARS = {
    10021: 3,
    10022: 3,
    10023: 3,
    10024: 1,
    10025: 0,
}
TARGET_BOX_IDS = (10031, 20031)
COCOS_ROLE_LEVEL = 99
COCOS_EXP = 0
COCOS_ZHANDOU_LI = 17240
COCOS_VISUAL_STAMINA = 101
COCOS_RETURN_STAMINA = 96
SPIRIT_FULL = 100
SPIRIT_REGEN_SECONDS = 360
COCOS_PET = "78da6362b464606400014606ce17ddfd4f5b573cddbf8081c1012ecaf6b279e2933dcb181800ccdb0b2b"
COCOS_ZHENFA = "78da63606464606465b264c00e581112000bde0082"
COCOS_PET_EQUIP = "78da63616064c8ad7bc9cc00041dc20c0c8c8c8cfc0c4c40a15760211060646006f25f23f15980fc37487c262443185991b433b28155c8310000a4f10c00"
COCOS_BATTLE_INPUT_HASHES = {
    "pet": "B13004157E15D4552C70417374B83B634375F2B1C5E58C9D55FE77489E1DB0DE",
    "zhenfa": "36458EA415215A038A4DF0D7249C41871AB0A5971DF53774C4E64820032C8B8E",
    "petEquip": "EE59CD635C68D2975617F6B34F9D6D4E832E572993F164C3281F9A134290C1D3",
}
# The authoritative login path invokes CUser::Init/ResetPower and rewrites
# derived power and pet-equipment bytes. Assert those server-normalized values
# after login while keeping the injected pre-login fixture exact.
COCOS_RUNTIME_ZHANDOU_LI = 41640
COCOS_RUNTIME_PET_EQUIP_HASH = "A2E73E786D2B0BAF349B5614D56414EFE4461A645B4950E0B8A2CA2FCA7CC069"


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
    for stage_id, stars in FIXTURE_STAGE_STARS.items():
        chapter["nodeStars"][stage_id] = stars
    chapter["sumStar"] = sum(int(stars) for stars in chapter["nodeStars"].values())
    for fix_id in TARGET_BOX_IDS:
        if fix_id not in chapter["fixIds"]:
            chapter["fixIds"].append(fix_id)
        chapter["fixStates"][fix_id] = 1
    raw = bytes(write_section(primary) + write_section(secondary) + tail)
    value = zlib.compress(raw, 9).hex()
    assert_world(value, allow_claimed=False)
    return value


def patch_chapter_unlock_world(value):
    primary, secondary, tail = decode_world(patch_world(value))
    chapter = next(item for item in primary["maps"] if item["mapId"] == TARGET_MAP_ID)
    for stage_id in range(10021, 10030):
        chapter["nodeStars"][stage_id] = 3
    chapter["nodeStars"][10030] = 0
    chapter["sumStar"] = sum(int(stars) for stars in chapter["nodeStars"].values())
    primary["curMapId"] = TARGET_MAP_ID
    primary["curNodeId"] = 10030
    patched = zlib.compress(bytes(write_section(primary) + write_section(secondary) + tail), 9).hex()
    assert_chapter_unlock_world(patched)
    return patched


def patch_achievement_unlock_world(value):
    primary, secondary, tail = decode_world(value)
    source_map_id = 1002
    target_map_id = 1003
    target_stage_id = 10020
    primary["maps"] = [item for item in primary["maps"] if item["mapId"] < target_map_id]
    chapter_matches = [item for item in primary["maps"] if item["mapId"] == source_map_id]
    if len(chapter_matches) > 1:
        raise RuntimeError("World achievement-unlock source chapter is duplicated")
    if chapter_matches:
        chapter = chapter_matches[0]
    else:
        chapter = {"mapId": source_map_id, "sumStar": 0, "nodeStars": {}, "fixIds": [], "fixStates": {}}
        primary["maps"].append(chapter)
    if not any(item["mapId"] == 1001 for item in primary["maps"]):
        primary["maps"].append({"mapId": 1001, "sumStar": 0, "nodeStars": {}, "fixIds": [], "fixStates": {}})
    for stage_id in range(10011, 10020):
        chapter["nodeStars"][stage_id] = 3
    chapter["nodeStars"][target_stage_id] = 0
    chapter["sumStar"] = sum(int(stars) for stars in chapter["nodeStars"].values())
    primary["curMapId"] = source_map_id
    primary["curNodeId"] = target_stage_id
    patched = zlib.compress(bytes(write_section(primary) + write_section(secondary) + tail), 9).hex()
    assert_achievement_unlock_world(patched)
    return patched


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
        "fixtureStageStars": {
            str(stage_id): chapter["nodeStars"].get(stage_id)
            for stage_id in FIXTURE_STAGE_STARS
        },
        "computedChapterStars": sum(int(stars) for stars in chapter["nodeStars"].values()),
        "boxStates": {str(fix_id): chapter["fixStates"].get(fix_id, 0) for fix_id in TARGET_BOX_IDS},
    }


def assert_world(value, allow_claimed=True):
    state = world_state(value)
    expected_states = ({1, 2} if allow_claimed else {1})
    if (not state.get("chapterPresent") or not state.get("adjacentChapterPresent")
            or state["stageId"] != TARGET_STAGE_ID
            or state["chapterStars"] != state["computedChapterStars"]
            or state["chapterStars"] < 10 or state["stageStars"] < 3
            or state["fixtureStageStars"] != {
                str(stage_id): stars for stage_id, stars in FIXTURE_STAGE_STARS.items()
            }
            or any(value not in expected_states for value in state["boxStates"].values())):
        raise RuntimeError(f"World injected state mismatch: {state}")
    return state


def assert_chapter_unlock_world(value, completed=False):
    primary, _, _ = decode_world(value)
    chapters = {item["mapId"]: item for item in primary["maps"]}
    chapter = chapters.get(TARGET_MAP_ID)
    if chapter is None:
        raise RuntimeError("World chapter-unlock fixture chapter 1003 is missing")
    previous_stars = {stage_id: chapter["nodeStars"].get(stage_id, 0) for stage_id in range(10021, 10030)}
    target_stars = chapter["nodeStars"].get(10030, 0)
    if (any(stars <= 0 for stars in previous_stars.values())
            or chapter["sumStar"] != sum(int(stars) for stars in chapter["nodeStars"].values())):
        raise RuntimeError(f"World chapter-unlock prerequisite progress mismatch: {previous_stars}")
    if completed:
        if target_stars <= 0 or 1004 not in chapters:
            raise RuntimeError(f"World final-stage victory did not unlock chapter 1004: targetStars={target_stars}, chapters={sorted(chapters)}")
    elif primary["curMapId"] != TARGET_MAP_ID or primary["curNodeId"] != 10030 or target_stars != 0:
        raise RuntimeError(f"World chapter-unlock target stage is not ready: map={primary['curMapId']}, node={primary['curNodeId']}, stars={target_stars}")
    return {
        "chapterId": TARGET_MAP_ID,
        "targetStageId": 10030,
        "targetStageStars": target_stars,
        "previousStagesPassed": len(previous_stars),
        "chapterUnlocked": 1004 in chapters,
        "currentMapId": primary["curMapId"],
        "currentNodeId": primary["curNodeId"],
    }


def assert_achievement_unlock_world(value, completed=False):
    primary, _, _ = decode_world(value)
    chapters = {item["mapId"]: item for item in primary["maps"]}
    chapter = chapters.get(1002)
    if chapter is None:
        raise RuntimeError("World achievement-unlock fixture chapter 1002 is missing")
    previous_stars = {stage_id: chapter["nodeStars"].get(stage_id, 0) for stage_id in range(10011, 10020)}
    target_stars = chapter["nodeStars"].get(10020, 0)
    if (any(stars <= 0 for stars in previous_stars.values())
            or chapter["sumStar"] != sum(int(stars) for stars in chapter["nodeStars"].values())):
        raise RuntimeError(f"World achievement-unlock prerequisite progress mismatch: {previous_stars}")
    if completed:
        if target_stars <= 0 or 1003 not in chapters:
            raise RuntimeError(f"World final-stage victory did not unlock chapter 1003: targetStars={target_stars}, chapters={sorted(chapters)}")
    elif primary["curMapId"] != 1002 or primary["curNodeId"] != 10020 or target_stars != 0 or 1003 in chapters:
        raise RuntimeError(f"World achievement-unlock target stage is not ready: map={primary['curMapId']}, node={primary['curNodeId']}, stars={target_stars}, chapters={sorted(chapters)}")
    return {
        "chapterId": 1002,
        "targetStageId": 10020,
        "targetStageStars": target_stars,
        "previousStagesPassed": len(previous_stars),
        "achievementChapterId": 1003,
        "achievementChapterUnlocked": 1003 in chapters,
        "currentMapId": primary["curMapId"],
        "currentNodeId": primary["curNodeId"],
    }


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


def assert_battle_input(connection, role_id, runtime_normalized=False, allow_progress=False):
    state = battle_input_state(connection, role_id)
    expected_power = COCOS_RUNTIME_ZHANDOU_LI if runtime_normalized else COCOS_ZHANDOU_LI
    expected_pet_equip = (COCOS_RUNTIME_PET_EQUIP_HASH if runtime_normalized
                          else COCOS_BATTLE_INPUT_HASHES["petEquip"])
    expected_exp = state["exp"] >= COCOS_EXP if allow_progress else state["exp"] == COCOS_EXP
    if (state["level"] != COCOS_ROLE_LEVEL or not expected_exp
            or state["zhanDouLi"] != expected_power
            or state["petHashes"]["pet"] != COCOS_BATTLE_INPUT_HASHES["pet"]
            or state["petHashes"]["zhenfa"] != COCOS_BATTLE_INPUT_HASHES["zhenfa"]
            or state["petHashes"]["petEquip"] != expected_pet_equip
            or state["pets"] != [{"id": 57, "level": 1}, {"id": 64, "level": 1}]
            or state["deployedPetIds"] != [57]):
        raise RuntimeError(f"World Cocos battle input mismatch: {state}")
    return state


STABLE_COLUMNS = (
    "package", "save_data", "user_spirit", "role_money", "exp", "level",
    "pet", "zhenfa", "user_money", "bd_money",
)


def stable_state(connection, user_id, role_id):
    row = connection.execute(
        "SELECT r.package,r.save_data,r.user_spirit,r.money,r.exp,r.level,r.pet,r.zhenfa,u.money,u.bd_money "
        "FROM role_info r JOIN user_info1 u ON u.id=? AND CAST(u.role0 AS INTEGER)=r.id WHERE r.id=?",
        (user_id, role_id),
    ).fetchone()
    if row is None:
        raise RuntimeError(f"World identity {user_id}/{role_id} is missing")
    values = ["" if value is None else str(value) for value in row]
    spirit = zlib.decompress(bytes.fromhex(values[2]))
    if len(spirit) < 6:
        raise RuntimeError("World stable-state user_spirit is truncated")
    return {
        "hash": hashlib.sha256("|".join(values).encode("utf-8")).hexdigest().upper(),
        "fieldHashes": {
            name: hashlib.sha256(value.encode("utf-8")).hexdigest().upper()
            for name, value in zip(STABLE_COLUMNS, values)
        },
        "userSpirit": {
            "value": struct.unpack_from("<H", spirit, 0)[0],
            "lastTime": struct.unpack_from("<I", spirit, 2)[0],
        },
    }


def stable_hash(connection, user_id, role_id):
    return stable_state(connection, user_id, role_id)["hash"]


def relogin_spirit_matches(expected, current):
    expected_value = int(expected["value"])
    expected_time = int(expected["lastTime"])
    current_value = int(current["value"])
    current_time = int(current["lastTime"])
    if expected_value == current_value and expected_time == current_time:
        return True, "exact"
    if expected_value >= SPIRIT_FULL:
        return False, "invalid-clock"
    # The game server canonicalizes a naturally refilled spirit blob to
    # value=SPIRIT_FULL,lastTime=0.  Zero no longer carries the elapsed interval,
    # so prove the cap from the original timestamp and the current wall clock.
    if current_value == SPIRIT_FULL and current_time == 0:
        cap_time = expected_time + (SPIRIT_FULL - expected_value) * SPIRIT_REGEN_SECONDS
        matched = int(time.time()) >= cap_time
        return matched, "normalized-passive-regeneration-cap" if matched else "premature-full-normalization"
    if current_time < expected_time:
        return False, "invalid-clock"
    elapsed = current_time - expected_time
    if elapsed % SPIRIT_REGEN_SECONDS != 0:
        return False, "non-integral-regeneration"
    regenerated = elapsed // SPIRIT_REGEN_SECONDS
    predicted = min(SPIRIT_FULL, expected_value + regenerated)
    if predicted >= SPIRIT_FULL:
        matched = current_value == SPIRIT_FULL and current_time in (
            0, expected_time + regenerated * SPIRIT_REGEN_SECONDS,
        )
    else:
        matched = current_value == predicted
    return matched, "normalized-passive-regeneration" if matched else "unexpected-spirit-change"


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


def setup(args, visual=False, chapter_unlock=False, achievement_unlock=False):
    if chapter_unlock and achievement_unlock:
        raise RuntimeError("World fixture cannot set up two chapter-unlock scenarios at once")
    if os.path.exists(args.backup):
        raise RuntimeError("World SQLite backup already exists; restore and clean it before rerun")
    checkpoint(args.database)
    os.makedirs(os.path.dirname(args.backup), exist_ok=True)
    copy_database(args.database, args.backup)
    snapshot_hash = file_hash(args.backup)
    backup_connection = sqlite3.connect(args.backup)
    try:
        stable_snapshot = stable_state(backup_connection, args.user_id, args.role_id)
        stable = stable_snapshot["hash"]
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
        if chapter_unlock:
            injected = patch_chapter_unlock_world(original[0])
        elif achievement_unlock:
            injected = patch_achievement_unlock_world(original[0])
        else:
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
        injected_value = connection.execute(
            "SELECT guan_qia FROM role_info WHERE id=?", (args.role_id,)).fetchone()[0]
        if chapter_unlock:
            injected_state = assert_chapter_unlock_world(injected_value)
        elif achievement_unlock:
            injected_state = assert_achievement_unlock_world(injected_value)
        else:
            injected_state = assert_world(injected_value, allow_claimed=False)
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
        "snapshotHash": snapshot_hash, "stableHash": stable, "stableState": stable_snapshot,
        "visualMode": visual,
        "scenario": ("achievement-unlock-1003" if achievement_unlock
                     else "chapter-unlock" if chapter_unlock else "standard"),
        "visualStamina": COCOS_VISUAL_STAMINA if visual else None,
        "injected": injected_state, "battleInput": injected_battle_input, "createdUtc": utc_now(),
    })


def setup_visual(args):
    setup(args, visual=True)


def setup_chapter_unlock(args):
    setup(args, chapter_unlock=True)


def setup_achievement_unlock(args):
    setup(args, achievement_unlock=True)


def assert_setup(args, runtime_normalized=False):
    snapshot = read_json(args.evidence)
    connection = sqlite3.connect(args.database)
    try:
        row = connection.execute("SELECT guan_qia FROM role_info WHERE id=?", (args.role_id,)).fetchone()
        if row is None:
            raise RuntimeError("World primary role disappeared")
        if snapshot.get("scenario") == "chapter-unlock":
            assert_chapter_unlock_world(row[0])
        elif snapshot.get("scenario") == "achievement-unlock-1003":
            assert_achievement_unlock_world(row[0])
        else:
            assert_world(row[0], allow_claimed=True)
        battle_input = assert_battle_input(connection, args.role_id, runtime_normalized=runtime_normalized)
        isolation = connection.execute(
            "SELECT u.role0,r.id FROM user_info1 u JOIN role_info r ON r.id=CAST(u.role0 AS INTEGER) WHERE u.id=?",
            (ISOLATION_USER_ID,),
        ).fetchone()
        if isolation is None or int(isolation[0]) != ISOLATION_ROLE_ID or int(isolation[1]) != ISOLATION_ROLE_ID:
            raise RuntimeError("World isolation identity mismatch")
    finally:
        connection.close()
    if runtime_normalized:
        snapshot = read_json(args.evidence)
        snapshot.update({"postLoginBattleInput": battle_input,
                         "postLoginBattleInputAssertedUtc": utc_now()})
        write_json(args.evidence, snapshot)


def assert_runtime_setup(args):
    assert_setup(args, runtime_normalized=True)


def assert_post_validation(args):
    snapshot = read_json(args.evidence)
    connection = sqlite3.connect(args.database)
    try:
        row = connection.execute("SELECT guan_qia FROM role_info WHERE id=?", (args.role_id,)).fetchone()
        if row is None:
            raise RuntimeError("World primary role disappeared after validation")
        if snapshot.get("scenario") == "chapter-unlock":
            state = assert_chapter_unlock_world(row[0], completed=True)
        elif snapshot.get("scenario") == "achievement-unlock-1003":
            state = assert_achievement_unlock_world(row[0], completed=True)
        else:
            assert_world(row[0], allow_claimed=True)
            state = None
        battle_input = assert_battle_input(connection, args.role_id, runtime_normalized=True, allow_progress=True)
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
    snapshot.update({"postValidationBattleInput": battle_input, "postValidationAssertedUtc": utc_now()})
    if state is not None:
        snapshot["chapterUnlockResult"] = state
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
    # Exact database hash proves every original row is restored. This baseline
    # already contains user 705213 linked to role 1000004, so absence is not a
    # valid oracle for cleanup of the temporary role 1000006.
    snapshot.update({"action": "AssertRestored", "restoredHash": actual, "restored": True, "assertedUtc": utc_now()})
    write_json(args.evidence, snapshot)


def assert_relogin(args):
    snapshot = read_json(args.evidence)
    connection = sqlite3.connect(args.database)
    try:
        actual_state = stable_state(connection, args.user_id, args.role_id)
        actual = actual_state["hash"]
    finally:
        connection.close()
    expected_state = snapshot.get("stableState", {})
    expected_hashes = expected_state.get("fieldHashes", {})
    current_hashes = actual_state.get("fieldHashes", {})
    changed_fields = [
        name for name in STABLE_COLUMNS
        if expected_hashes.get(name) != current_hashes.get(name)
    ]
    spirit_matches, spirit_oracle = relogin_spirit_matches(
        expected_state.get("userSpirit", {}), actual_state.get("userSpirit", {}),
    )
    normalized_match = changed_fields in ([], ["user_spirit"]) and spirit_matches
    if actual != snapshot["stableHash"] and not normalized_match:
        snapshot["reloginMismatch"] = {
            "expectedHash": snapshot["stableHash"],
            "actualHash": actual,
            "changedFields": changed_fields,
            "spiritOracle": spirit_oracle,
            "expectedState": expected_state,
            "actualState": actual_state,
            "diagnosedUtc": utc_now(),
        }
        write_json(args.evidence, snapshot)
        raise RuntimeError(f"World SQLite stable relogin hash mismatch: {actual}")
    snapshot.update({
        "postLoginHashVerified": True,
        "postLoginStableHash": actual,
        "postLoginChangedFields": changed_fields,
        "postLoginSpiritOracle": spirit_oracle,
        "postLoginVerifiedUtc": utc_now(),
    })
    write_json(args.evidence, snapshot)


def cleanup(args):
    if os.path.exists(args.backup):
        os.remove(args.backup)
    remove_sidecars(args.backup)


def assert_cleanup(args):
    if os.path.exists(args.backup) or os.path.exists(args.backup + "-wal") or os.path.exists(args.backup + "-shm"):
        raise RuntimeError("World SQLite backup residue remains")
    snapshot = read_json(args.evidence)
    if not snapshot.get("restored") or not snapshot.get("postLoginHashVerified"):
        raise RuntimeError("World cleanup requires successful restore and post-login hash assertions")
    connection = sqlite3.connect(args.database)
    try:
        actual_state = stable_state(connection, args.user_id, args.role_id)
        if actual_state["hash"] != snapshot["stableHash"]:
            raise RuntimeError(f"World stable relogin hash mismatch during cleanup: {actual_state['hash']}")
        isolation_user = connection.execute(
            "SELECT role0 FROM user_info1 WHERE id=?", (ISOLATION_USER_ID,)
        ).fetchone()
        isolation_role = connection.execute(
            "SELECT 1 FROM role_info WHERE id=?", (ISOLATION_ROLE_ID,)
        ).fetchone()
        if (isolation_user is not None and int(isolation_user[0]) == ISOLATION_ROLE_ID) \
                or isolation_role is not None:
            raise RuntimeError("World fixture isolation identity remains after restore")
        checkpoint_result = connection.execute("PRAGMA wal_checkpoint(TRUNCATE)").fetchone()
        if checkpoint_result is not None and int(checkpoint_result[0]) != 0:
            raise RuntimeError(f"World SQLite checkpoint is busy: {checkpoint_result}")
    finally:
        connection.close()
    remove_sidecars(args.database)
    if os.path.exists(args.database + "-wal") or os.path.exists(args.database + "-shm"):
        raise RuntimeError("World SQLite database WAL/SHM residue remains")
    snapshot.update({
        "cleanupAsserted": True,
        "cleanupStableHash": actual_state["hash"],
        "cleanupIsolationIdentityAbsent": True,
        "cleanupAssertedUtc": utc_now(),
    })
    write_json(args.evidence, snapshot)


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
        "SetupChapterUnlock": setup_chapter_unlock,
        "SetupAchievementUnlock": setup_achievement_unlock,
        "AssertSetup": assert_setup, "AssertRuntimeSetup": assert_runtime_setup,
        "AssertPostValidation": assert_post_validation,
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
