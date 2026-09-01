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
SPIRIT_FULL = 100
SPIRIT_REGEN_SECONDS = 360


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


def patch_spirit(value, spirit=100):
    data = expand(value)
    if len(data) < 6:
        raise RuntimeError("user_spirit has no complete spirit/time header")
    struct.pack_into("<HI", data, 0, spirit, 0)
    return compress(data)


def spirit_state(value):
    data = expand(value)
    if len(data) < 6:
        raise RuntimeError("user_spirit has no complete spirit/time header")
    spirit, last_time = struct.unpack_from("<HI", data, 0)
    return {"spirit": spirit, "lastSpiritTime": last_time}


def spirit_relogin_state(value):
    data = expand(value)
    if len(data) < 6:
        raise RuntimeError("user_spirit has no complete spirit/time header")
    spirit, last_time = struct.unpack_from("<HI", data, 0)
    return {
        "spirit": spirit,
        "lastSpiritTime": last_time,
        "payloadSha256": hashlib.sha256(str(value).encode("utf-8")).hexdigest(),
        "tailSha256": hashlib.sha256(bytes(data[6:])).hexdigest(),
    }


def relogin_spirit_matches(expected, current):
    if current["payloadSha256"] == expected["payloadSha256"]:
        return True, "exact"
    if current["tailSha256"] != expected["tailSha256"]:
        return False, "unexpected-payload-tail-change"
    expected_spirit = int(expected["spirit"])
    expected_time = int(expected["lastSpiritTime"])
    current_spirit = int(current["spirit"])
    current_time = int(current["lastSpiritTime"])
    if expected_spirit >= SPIRIT_FULL or current_time < expected_time:
        return False, "invalid-clock"
    elapsed = current_time - expected_time
    if elapsed % SPIRIT_REGEN_SECONDS != 0:
        return False, "non-integral-regeneration"
    regenerated = elapsed // SPIRIT_REGEN_SECONDS
    predicted = min(SPIRIT_FULL, expected_spirit + regenerated)
    if predicted >= SPIRIT_FULL:
        matched = current_spirit == SPIRIT_FULL and current_time in (
            0, expected_time + regenerated * SPIRIT_REGEN_SECONDS,
        )
    else:
        matched = current_spirit == predicted
    return matched, "normalized-passive-regeneration" if matched else "unexpected-spirit-change"


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


STABLE_FIELD_NAMES = (
    "role.guan_qia", "role.pet", "role.package", "role.save_data", "role.user_spirit",
    "role.money", "role.exp", "role.level", "user.money", "user.bd_money",
)
RELOGIN_NORMALIZATION_EXCLUSIONS = (
    "role.save_val", "role.mission", "role.guan_qia.trial-counts",
)


def canonicalize_guan_qia(value):
    try:
        data = expand(value)
    except (ValueError, zlib.error) as error:
        raise RuntimeError(f"role.guan_qia is not valid zlib-compressed hex: {error}") from error
    cursor = [0]
    skip_stage_section(data, cursor)
    skip_stage_section(data, cursor)
    attack_count = read_u16(data, cursor)
    cursor[0] += 5 * attack_count
    reset_count = read_u16(data, cursor)
    cursor[0] += 5 * reset_count
    trial_count = read_u8(data, cursor)
    for _ in range(trial_count):
        cursor[0] += 4
        # LoadData/ResetGuanQia recomputes ShiLianGuanQia.cnt from the
        # current weekday openWeek contract. It is unrelated to LieZhuan and
        # is the only bounded guan_qia relogin normalization allowed here.
        data[cursor[0]] = 0
        cursor[0] += 1 + 4 + 4
    return data.hex()


def stable_state(connection, user_id, role_id):
    row = connection.execute(
        "SELECT r.guan_qia,r.pet,r.package,r.save_data,r.user_spirit,r.money,r.exp,r.level,u.money,u.bd_money "
        "FROM role_info r JOIN user_info1 u ON u.id=? AND CAST(u.role0 AS INTEGER)=r.id WHERE r.id=?",
        (user_id, role_id),
    ).fetchone()
    if row is None:
        raise RuntimeError(f"identity {user_id}/{role_id} is missing")
    values = ["" if value is None else str(value) for value in row]
    spirit_relogin = spirit_relogin_state(values[4])
    # The server rewrites guan_qia through its own zlib stream on a clean
    # relogin. Different compressed bytes/lengths are not residue when the
    # complete uncompressed payload is identical, so hash its canonical bytes.
    values[0] = canonicalize_guan_qia(values[0])
    fields = {
        name: {
            "length": len(value),
            "sha256": hashlib.sha256(value.encode("utf-8")).hexdigest(),
        }
        for name, value in zip(STABLE_FIELD_NAMES, values)
    }
    return {
        "hash": hashlib.sha256("|".join(values).encode("utf-8")).hexdigest(),
        "fields": fields,
        "canonicalValues": dict(zip(STABLE_FIELD_NAMES, values)),
        "spiritReloginState": spirit_relogin,
    }


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
        role = connection.execute("SELECT guan_qia,pet,user_spirit FROM role_info WHERE id=?", (args.role_id,)).fetchone()
        connection.execute(
            "UPDATE role_info SET guan_qia=?,pet=?,user_spirit=?,level='99' WHERE id=?",
            (patch_story(role[0], 5, 6, 40074), patch_pet_levels(role[1], 100),
             patch_spirit(role[2], 100), args.role_id),
        )
        connection.commit()
        primary = story_state(connection.execute("SELECT guan_qia FROM role_info WHERE id=?", (args.role_id,)).fetchone()[0])
        primary_spirit = spirit_state(connection.execute("SELECT user_spirit FROM role_info WHERE id=?", (args.role_id,)).fetchone()[0])
        isolation = story_state(connection.execute("SELECT guan_qia FROM role_info WHERE id=?", (ISOLATION_ROLE_ID,)).fetchone()[0])
        backup_connection = sqlite3.connect("file:" + args.backup + "?mode=ro", uri=True)
        try:
            stable = stable_state(backup_connection, args.user_id, args.role_id)
        finally:
            backup_connection.close()
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
        "snapshotHash": snapshot_hash, "stableHash": stable["hash"], "stableFields": stable["fields"],
        "stableCanonicalGuanQia": stable["canonicalValues"]["role.guan_qia"],
        "stableSpiritReloginState": stable["spiritReloginState"],
        "reloginNormalizationExclusions": list(RELOGIN_NORMALIZATION_EXCLUSIONS),
        "injected": primary, "injectedSpirit": primary_spirit,
        "isolation": isolation, "createdUtc": utc_now(),
    })


def assert_setup(args):
    connection = sqlite3.connect(args.database)
    try:
        primary = story_state(connection.execute("SELECT guan_qia FROM role_info WHERE id=?", (args.role_id,)).fetchone()[0])
        isolation = story_state(connection.execute("SELECT guan_qia FROM role_info WHERE id=?", (ISOLATION_ROLE_ID,)).fetchone()[0])
        link = connection.execute("SELECT role0 FROM user_info1 WHERE id=?", (ISOLATION_USER_ID,)).fetchone()
        if primary != {"count": 5, "chapterIndex": 6, "nodeId": 40074}:
            raise RuntimeError(f"primary FengShenStory state mismatch: {primary}")
        spirit = spirit_state(connection.execute(
            "SELECT user_spirit FROM role_info WHERE id=?", (args.role_id,)
        ).fetchone()[0])
        if spirit != {"spirit": 100, "lastSpiritTime": 0}:
            raise RuntimeError(f"primary FengShenStory spirit mismatch: {spirit}")
        if isolation != {"count": 5, "chapterIndex": 0, "nodeId": 40011} or int(link[0]) != ISOLATION_ROLE_ID:
            raise RuntimeError("isolation FengShenStory state mismatch")
    finally:
        connection.close()


def reset_setup(args):
    if not os.path.exists(args.backup):
        raise RuntimeError("FengShenStory SQLite backup is missing; refusing to reset without the original snapshot")
    checkpoint(args.database)
    connection = sqlite3.connect(args.database)
    try:
        connection.execute("BEGIN IMMEDIATE")
        link = connection.execute("SELECT role0 FROM user_info1 WHERE id=?", (args.user_id,)).fetchone()
        if link is None or int(link[0]) != args.role_id:
            raise RuntimeError("FengShenStory primary SQLite identity mismatch")
        role = connection.execute(
            "SELECT guan_qia,user_spirit FROM role_info WHERE id=?", (args.role_id,)
        ).fetchone()
        if role is None:
            raise RuntimeError("FengShenStory primary role is missing")
        connection.execute(
            "UPDATE role_info SET guan_qia=?,user_spirit=? WHERE id=?",
            (patch_story(role[0], 5, 6, 40074), patch_spirit(role[1], 100), args.role_id),
        )
        connection.commit()
        primary = story_state(connection.execute(
            "SELECT guan_qia FROM role_info WHERE id=?", (args.role_id,)
        ).fetchone()[0])
        primary_spirit = spirit_state(connection.execute(
            "SELECT user_spirit FROM role_info WHERE id=?", (args.role_id,)
        ).fetchone()[0])
    except Exception:
        connection.rollback()
        raise
    finally:
        connection.close()
    checkpoint(args.database)
    write_json(args.evidence, {
        "action": "ResetSetup", "dataBackend": "sqlite", "database": args.database,
        "userId": args.user_id, "roleId": args.role_id,
        "preservedBackup": args.backup, "injected": primary,
        "injectedSpirit": primary_spirit, "createdUtc": utc_now(),
    })


def assert_mutated(args):
    connection = sqlite3.connect(args.database)
    try:
        primary = story_state(connection.execute(
            "SELECT guan_qia FROM role_info WHERE id=?", (args.role_id,)
        ).fetchone()[0])
        if primary != {"count": 3, "chapterIndex": 7, "nodeId": 40082}:
            raise RuntimeError(f"primary FengShenStory mutation mismatch: {primary}")
        spirit = spirit_state(connection.execute(
            "SELECT user_spirit FROM role_info WHERE id=?", (args.role_id,)
        ).fetchone()[0])
        if spirit["spirit"] != 60:
            raise RuntimeError(f"primary FengShenStory mutated spirit mismatch: {spirit}")
        isolation = story_state(connection.execute(
            "SELECT guan_qia FROM role_info WHERE id=?", (ISOLATION_ROLE_ID,)
        ).fetchone()[0])
        if isolation != {"count": 5, "chapterIndex": 0, "nodeId": 40011}:
            raise RuntimeError(f"isolation FengShenStory state changed: {isolation}")
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
        actual = stable_state(connection, args.user_id, args.role_id)
    finally:
        connection.close()
    spirit_matches, spirit_oracle = relogin_spirit_matches(
        snapshot["stableSpiritReloginState"], actual["spiritReloginState"]
    )
    if actual["hash"] != snapshot["stableHash"]:
        expected_fields = snapshot.get("stableFields", {})
        changed = [
            name for name in STABLE_FIELD_NAMES
            if expected_fields.get(name) != actual["fields"].get(name)
        ]
        expected_guan_qia = snapshot.get("stableCanonicalGuanQia", "")
        actual_guan_qia = actual["canonicalValues"].get("role.guan_qia", "")
        guan_qia_diff_offsets = [
            index for index, (before, after) in enumerate(zip(
                bytes.fromhex(expected_guan_qia), bytes.fromhex(actual_guan_qia)
            )) if before != after
        ]
        snapshot.update({
            "reloginActualHash": actual["hash"],
            "reloginChangedFields": changed,
            "reloginActualFields": actual["fields"],
            "reloginActualCanonicalGuanQia": actual_guan_qia,
            "reloginGuanQiaDiffOffsets": guan_qia_diff_offsets,
            "reloginSpiritState": actual["spiritReloginState"],
            "reloginSpiritOracle": spirit_oracle,
            "reloginMismatchUtc": utc_now(),
        })
        write_json(args.evidence, snapshot)
        if changed != ["role.user_spirit"] or not spirit_matches:
            raise RuntimeError(
                f"FengShenStory stable relogin hash mismatch: {actual['hash']}; changed={','.join(changed)}; spirit={spirit_oracle}"
            )
    snapshot.update({
        "reloginVerified": True,
        "reloginSpiritState": actual["spiritReloginState"],
        "reloginSpiritOracle": spirit_oracle,
        "reloginVerifiedUtc": utc_now(),
    })
    write_json(args.evidence, snapshot)


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
    elif args.action == "ResetSetup": reset_setup(args)
    elif args.action == "AssertSetup": assert_setup(args)
    elif args.action == "AssertMutated": assert_mutated(args)
    elif args.action == "Restore": restore(args)
    elif args.action == "AssertRestored": assert_restored(args)
    elif args.action == "AssertReloginHash": assert_relogin(args)
    elif args.action == "Cleanup": cleanup(args)
    elif args.action == "AssertCleanup": assert_cleanup(args)
    else: raise RuntimeError(f"unsupported action: {args.action}")
    print(f"FengShenStory SQLite fixture {args.action} passed")


if __name__ == "__main__":
    main()
