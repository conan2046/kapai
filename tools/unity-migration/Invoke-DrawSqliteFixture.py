import argparse
import hashlib
import json
import os
import shutil
import sqlite3
import struct
import zlib
from datetime import datetime, timezone

TARGET_HERO = 64
RETAINED_HERO = 57
ITEMS = {834: 10, 1000: 20, 1001: 10, 1002: 200}


def sha256(path):
    digest = hashlib.sha256()
    with open(path, "rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def compress(data):
    return zlib.compress(bytes(data)).hex()


def expand(value):
    return zlib.decompress(bytes.fromhex(value or ""))


def make_package():
    data = bytearray()
    for item_id, quantity in sorted(ITEMS.items()):
        data.extend(struct.pack("<HH", item_id, quantity))
    for _ in range(500 - len(ITEMS)):
        data.extend(struct.pack("<H", 0))
    return compress(data)


def package_counts(value):
    data = expand(value)
    position, result = 0, {}
    for _ in range(500):
        if position + 2 > len(data):
            break
        item_id = struct.unpack_from("<H", data, position)[0]
        position += 2
        if item_id:
            if position + 2 > len(data):
                raise RuntimeError("Draw package quantity is truncated")
            quantity = struct.unpack_from("<H", data, position)[0]
            position += 2
            result[item_id] = result.get(item_id, 0) + quantity
    return result


def make_pet(profile):
    heroes = [(RETAINED_HERO, "苏全忠")]
    if profile == "DuplicateFragment":
        heroes.append((TARGET_HERO, "郑伦"))
    data = bytearray((len(heroes), 1))
    for hero_id, hero_name in heroes:
        name = hero_name.encode("utf-8")
        data.extend(struct.pack("<HHI", hero_id, 1, 0))
        data.extend(bytes((1, 0, len(name))))
        data.extend(name)
        data.extend(bytes((0, 0)))
    return compress(data)


def pet_ids(value):
    data = expand(value)
    if len(data) < 2:
        raise RuntimeError("Draw pet payload is incomplete")
    count, ext, position, result = data[0], data[1], 2, []
    for _ in range(count):
        pet_id = struct.unpack_from("<H", data, position)[0]
        position += 2
        result.append(pet_id)
        if not pet_id:
            continue
        position += 2 + 4 + 2
        name_length = data[position]
        position += 1 + name_length
        if ext:
            position += 1
            entry_count = data[position]
            position += 1 + 3 * entry_count
        if position > len(data):
            raise RuntimeError("Draw pet payload is truncated")
    return result


def make_draw_pools():
    data = bytearray((3,))
    for kind, free_count in ((1, 3), (2, 1), (3, 0)):
        data.append(kind)
        data.extend(struct.pack("<II", 0, 0))
        data.append(free_count)
    return compress(data)


def pool_state(value):
    data, position, result = expand(value), 0, {}
    count = data[position]
    position += 1
    for _ in range(count):
        kind = data[position]
        position += 1
        total, cooldown = struct.unpack_from("<II", data, position)
        position += 8
        free_count = data[position]
        position += 1
        result[kind] = {"total": total, "cooldown": cooldown, "free": free_count}
    return result


def business_state(connection, user_id, role_id):
    link = connection.execute("SELECT role0 FROM user_info1 WHERE id=?", (user_id,)).fetchone()
    role = connection.execute(
        "SELECT level,money,package,pet,chou_ka,zhenfa,save_data,zhanDouLi,petZhanDouLi FROM role_info WHERE id=?",
        (role_id,)).fetchone()
    if link is None or role is None:
        raise RuntimeError(f"Draw SQLite identity is missing: {user_id}/{role_id}")
    state = {
        "linkedRoleId": int(link[0]),
        "level": int(role[0] or 0),
        "money": int(role[1] or 0),
        "items": {str(key): value for key, value in package_counts(role[2]).items()},
        "petIds": pet_ids(role[3]),
        "pools": {str(key): value for key, value in pool_state(role[4]).items()},
        "integrity": connection.execute("PRAGMA integrity_check").fetchone()[0],
    }
    # Login legitimately refreshes unrelated role_info columns (for example save_data and
    # combat-power caches). Draw residue is defined only by the explicit contract above.
    serialized = json.dumps({key: state[key] for key in ("linkedRoleId", "level", "money", "items", "petIds", "pools")},
                            ensure_ascii=False, sort_keys=True, separators=(",", ":"))
    state["businessSha256"] = hashlib.sha256(serialized.encode("utf-8")).hexdigest()
    return state


def assert_setup(connection, user_id, role_id, profile):
    current = business_state(connection, user_id, role_id)
    high = current["pools"].get("2", {})
    target_owned = TARGET_HERO in current["petIds"]
    target_state_valid = target_owned if profile == "DuplicateFragment" else not target_owned
    if (current["linkedRoleId"] != role_id or current["level"] < 60 or current["integrity"] != "ok"
            or not target_state_valid or RETAINED_HERO not in current["petIds"]
            or high.get("total") != 0 or high.get("free") != 1
            or any(current["items"].get(str(item_id), 0) < quantity for item_id, quantity in ITEMS.items())):
        raise RuntimeError(f"Draw deterministic SQLite fixture assertion failed: profile={profile}, state={current}")
    return current


def read_json(path):
    with open(path, "r", encoding="utf-8") as stream:
        return json.load(stream)


def write_json(path, payload):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8", newline="\n") as stream:
        json.dump(payload, stream, ensure_ascii=False, indent=2)
        stream.write("\n")


def remove_sidecars(database):
    for suffix in ("-wal", "-shm"):
        path = database + suffix
        if os.path.exists(path):
            os.remove(path)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--action", required=True)
    parser.add_argument("--database", required=True)
    parser.add_argument("--backup", required=True)
    parser.add_argument("--evidence", required=True)
    parser.add_argument("--user-id", type=int, required=True)
    parser.add_argument("--role-id", type=int, required=True)
    parser.add_argument("--profile", choices=("NewHero", "DuplicateFragment"), default="NewHero")
    args = parser.parse_args()
    database, backup, evidence = map(os.path.abspath, (args.database, args.backup, args.evidence))
    if args.action == "Setup":
        if not os.path.isfile(database):
            raise RuntimeError(f"Draw SQLite database is missing: {database}")
        connection = sqlite3.connect(database)
        try:
            connection.execute("PRAGMA wal_checkpoint(TRUNCATE)")
            before = business_state(connection, args.user_id, args.role_id)
        finally:
            connection.close()
        os.makedirs(os.path.dirname(backup), exist_ok=True)
        shutil.copy2(database, backup)
        connection = sqlite3.connect(database)
        try:
            connection.execute("UPDATE user_info1 SET role0=? WHERE id=?", (args.role_id, args.user_id))
            connection.execute(
                "UPDATE role_info SET level='60',money='1000000',package=?,pet=?,chou_ka=?,zhanDouLi='0',petZhanDouLi='0' WHERE id=?",
                (make_package(), make_pet(args.profile), make_draw_pools(), args.role_id))
            connection.commit()
            fixture = assert_setup(connection, args.user_id, args.role_id, args.profile)
        finally:
            connection.close()
        write_json(evidence, {"schemaVersion": 1, "module": "Draw", "backend": "sqlite", "action": "Setup",
            "profile": args.profile,
            "database": database, "backup": backup, "userId": args.user_id, "roleId": args.role_id,
            "snapshotHash": sha256(backup), "fixtureHash": sha256(database), "before": before, "fixture": fixture,
            "restored": False, "reloginVerified": False, "databaseIntegrity": fixture["integrity"], "residualCount": 1,
            "createdUtc": datetime.now(timezone.utc).isoformat()})
        return

    snapshot = read_json(evidence)
    if snapshot.get("backend") != "sqlite" or snapshot.get("userId") != args.user_id or snapshot.get("roleId") != args.role_id:
        raise RuntimeError("Draw SQLite fixture evidence identity mismatch")
    if args.action == "AssertSetup":
        connection = sqlite3.connect("file:" + database + "?mode=ro", uri=True)
        try:
            assert_setup(connection, args.user_id, args.role_id, snapshot.get("profile", args.profile))
        finally:
            connection.close()
    elif args.action == "Restore":
        if sha256(backup) != snapshot["snapshotHash"]:
            raise RuntimeError("Draw immutable SQLite backup hash changed")
        remove_sidecars(database)
        shutil.copy2(backup, database)
        snapshot["restored"] = True
        snapshot["restoredUtc"] = datetime.now(timezone.utc).isoformat()
        write_json(evidence, snapshot)
    elif args.action == "AssertRestored":
        if sha256(database) != snapshot["snapshotHash"]:
            raise RuntimeError("Draw restored SQLite database hash mismatch")
        connection = sqlite3.connect("file:" + database + "?mode=ro", uri=True)
        try:
            integrity = connection.execute("PRAGMA integrity_check").fetchone()[0]
        finally:
            connection.close()
        if integrity != "ok":
            raise RuntimeError("Draw restored SQLite integrity failed")
        snapshot["databaseIntegrity"] = integrity
        write_json(evidence, snapshot)
    elif args.action == "AssertReloginHash":
        connection = sqlite3.connect("file:" + database + "?mode=ro", uri=True)
        try:
            current = business_state(connection, args.user_id, args.role_id)
        finally:
            connection.close()
        if current["integrity"] != "ok" or current["businessSha256"] != snapshot["before"]["businessSha256"]:
            raise RuntimeError(f"Draw restored business state changed after relogin: {current}")
        snapshot["reloginVerified"] = True
        snapshot["postLoginBusinessState"] = current
        snapshot["postLoginVerifiedUtc"] = datetime.now(timezone.utc).isoformat()
        write_json(evidence, snapshot)
    elif args.action == "Cleanup":
        if os.path.exists(backup):
            os.remove(backup)
        snapshot["residualCount"] = 0 if not os.path.exists(backup) else 1
        snapshot["cleanupUtc"] = datetime.now(timezone.utc).isoformat()
        write_json(evidence, snapshot)
    elif args.action == "AssertCleanup":
        if os.path.exists(backup) or snapshot.get("residualCount") != 0:
            raise RuntimeError("Draw SQLite fixture residue remains")
    else:
        raise RuntimeError(f"Unsupported Draw SQLite fixture action: {args.action}")


if __name__ == "__main__":
    main()
