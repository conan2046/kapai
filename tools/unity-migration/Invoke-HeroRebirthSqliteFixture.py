import argparse
import hashlib
import importlib.util
import json
import os
import shutil
import sqlite3
import struct
from datetime import datetime, timezone


_base_path = os.path.join(os.path.dirname(__file__), "Invoke-HeroSqliteFixture.py")
_spec = importlib.util.spec_from_file_location("hero_fixture", _base_path)
hero_fixture = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(hero_fixture)

HEROES = (
    (24, "姬发", 30, 0, 1, 0, 0),
    (57, "苏全忠", 30, 0, 1, 0, 0),
    (64, "郑伦", 100, 0, 1, 15, 20),
    (60, "吕岳", 20, 0, 1, 5, 5),
    (40, "土行孙", 2, 0, 1, 0, 0),
    (41, "邓婵玉", 1, 0, 1, 1, 0),
    (49, "罗宣", 1, 0, 1, 0, 1),
    (42, "比干", 2, 0, 1, 0, 0),
    (47, "崇黑虎", 2, 0, 1, 0, 0),
    (62, "张奎", 1, 0, 1, 0, 0),
)
DEPLOYED_IDS = (24, 57)
ELIGIBLE_IDS = (64, 60, 40, 41, 49, 42, 47)
MAX_PROGRESS_ID = 64
INELIGIBLE_ID = 62
ROLE_LEVEL = 99
SUCCESS_MONEY = 100_000
SUCCESS_BOUND_MONEY = 100_000
REBIRTH_COST = 50
EXPECTED_ROLE_MONEY_REFUND = 150_000


def utc_now():
    return datetime.now(timezone.utc).isoformat()


def file_sha256(path):
    digest = hashlib.sha256()
    with open(path, "rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def value_sha256(value):
    return hashlib.sha256(value.encode("utf-8")).hexdigest()


def make_pet(pet_id, name, level, exp, star, break_level, xiu_lian, ext_num):
    name_bytes = name.encode("utf-8")
    record = bytearray(struct.pack("<HHIBBB", pet_id, level, exp, star, break_level, len(name_bytes)))
    record.extend(name_bytes)
    if ext_num > 0:
        record.extend((xiu_lian, 0))
    return bytes(record)


def rebirth_pet_blob(value):
    ext_num, _ = hero_fixture.parse_pets(value)
    if ext_num < 1:
        raise RuntimeError("HeroRebirth requires pet ext version >= 1 for cultivation data")
    output = bytearray((len(HEROES), ext_num))
    for pet in HEROES:
        output.extend(make_pet(*pet, ext_num))
    return hero_fixture.compress(output)


def parse_pet_states(value):
    data = hero_fixture.expand(value)
    if len(data) < 2:
        raise RuntimeError("HeroRebirth pet payload is truncated")
    position = 2
    states = []
    for _ in range(data[0]):
        start = position
        if position + 11 > len(data):
            raise RuntimeError("HeroRebirth pet record is truncated")
        pet_id, level, exp = struct.unpack_from("<HHI", data, position)
        position += 8
        star = data[position]
        break_level = data[position + 1]
        position += 2
        name_length = data[position]
        position += 1
        name = bytes(data[position:position + name_length]).decode("utf-8")
        position += name_length
        xiu_lian = 0
        if data[1] > 0:
            xiu_lian = data[position]
            position += 1
            counter_count = data[position]
            position += 1 + counter_count * 3
        if position > len(data):
            raise RuntimeError(f"HeroRebirth pet {pet_id} exceeds payload")
        states.append({
            "id": pet_id, "name": name, "level": level, "exp": exp, "star": star,
            "breakLevel": break_level, "xiuLianLevel": xiu_lian,
            "recordSha256": hashlib.sha256(bytes(data[start:position])).hexdigest(),
        })
    if position != len(data):
        raise RuntimeError("HeroRebirth pet payload has trailing bytes")
    return states


def rebirth_formation_blob(value):
    original = hero_fixture.expand(value)
    position = 0
    if len(original) < 6:
        raise RuntimeError("HeroRebirth formation payload is truncated")
    active_index = original[position]
    position += 1
    formation_count = original[position]
    position += 1
    definitions_end = position + formation_count * 3
    definitions = bytes(original[position:definitions_end])
    position = definitions_end
    member_count = original[position]
    position += 1 + member_count * 5
    if position >= len(original):
        raise RuntimeError("HeroRebirth formation combat count is missing")
    combat_count = original[position]
    if member_count != combat_count or member_count < len(DEPLOYED_IDS):
        raise RuntimeError("HeroRebirth formation cannot host the deployed fixture heroes")
    output = bytearray((active_index, formation_count))
    output.extend(definitions)
    output.append(member_count)
    for index in range(member_count):
        pet_id = DEPLOYED_IDS[index] if index < len(DEPLOYED_IDS) else 0
        output.extend(struct.pack("<BI", 2 if pet_id else 0, pet_id))
    output.append(combat_count)
    combat = list(DEPLOYED_IDS) + [0] * (combat_count - len(DEPLOYED_IDS))
    output.extend(struct.pack("<" + "H" * combat_count, *combat))
    return hero_fixture.compress(output)


def database_state(connection, user_id, role_id):
    user = connection.execute(
        "SELECT role0,money,bd_money FROM user_info1 WHERE id=?", (user_id,)).fetchone()
    role = connection.execute(
        "SELECT level,money,pet,zhenfa,package FROM role_info WHERE id=?", (role_id,)).fetchone()
    if user is None or int(user[0]) != role_id or role is None:
        raise RuntimeError(f"HeroRebirth SQLite identity is missing: {user_id}/{role_id}")
    pets = parse_pet_states(role[2])
    _, members, combat = hero_fixture.parse_formation(role[3])
    deployed = [pet_id for pet_id in combat if pet_id > 0]
    eligible = [pet["id"] for pet in pets
                if pet["id"] not in deployed
                and (pet["level"] > 1 or pet["breakLevel"] > 0 or pet["xiuLianLevel"] > 0)]
    semantic = {
        "linkedRoleId": int(user[0]),
        "userMoney": int(user[1]),
        "boundMoney": int(user[2]),
        "roleLevel": int(role[0]),
        "roleMoney": int(role[1]),
        "pets": pets,
        "formationMembers": [pet_id if member_type == 2 else 0 for member_type, pet_id in members],
        "combatHeroes": combat,
        "eligibleHeroIds": eligible,
        "packageSha256": value_sha256(role[4]),
        "integrity": connection.execute("PRAGMA integrity_check").fetchone()[0],
    }
    semantic["semanticSha256"] = value_sha256(
        json.dumps(semantic, ensure_ascii=False, sort_keys=True, separators=(",", ":")))
    return semantic


def assert_setup(connection, user_id, role_id):
    state = database_state(connection, user_id, role_id)
    by_id = {pet["id"]: pet for pet in state["pets"]}
    max_pet = by_id.get(MAX_PROGRESS_ID, {})
    if (state["linkedRoleId"] != role_id or state["roleLevel"] != ROLE_LEVEL
            or state["userMoney"] != SUCCESS_MONEY or state["boundMoney"] != SUCCESS_BOUND_MONEY
            or set(by_id) != {pet[0] for pet in HEROES}
            or state["combatHeroes"][:2] != list(DEPLOYED_IDS)
            or state["formationMembers"] != state["combatHeroes"]
            or set(state["eligibleHeroIds"]) != set(ELIGIBLE_IDS)
            or INELIGIBLE_ID in state["eligibleHeroIds"]
            or max_pet.get("level") != 100 or max_pet.get("breakLevel") != 15
            or max_pet.get("xiuLianLevel") != 20 or state["integrity"] != "ok"):
        raise RuntimeError(f"HeroRebirth SQLite fixture assertion failed: {state}")
    return state


def assert_success(connection, user_id, role_id, fixture):
    state = database_state(connection, user_id, role_id)
    by_id = {pet["id"]: pet for pet in state["pets"]}
    reborn = by_id.get(MAX_PROGRESS_ID, {})
    fixture_by_id = {pet["id"]: pet for pet in fixture["pets"]}
    unchanged_ids = set(fixture_by_id) - {MAX_PROGRESS_ID}
    unchanged = all(by_id.get(pet_id, {}).get("recordSha256")
                    == fixture_by_id[pet_id]["recordSha256"] for pet_id in unchanged_ids)
    expected_eligible = set(ELIGIBLE_IDS) - {MAX_PROGRESS_ID}
    if (state["linkedRoleId"] != role_id or state["roleLevel"] != ROLE_LEVEL
            or state["userMoney"] != SUCCESS_MONEY
            or state["boundMoney"] != SUCCESS_BOUND_MONEY - REBIRTH_COST
            or set(by_id) != set(fixture_by_id) or not unchanged
            or reborn.get("level") != 1 or reborn.get("exp") != 0
            or reborn.get("star") != fixture_by_id[MAX_PROGRESS_ID]["star"]
            or reborn.get("breakLevel") != 0 or reborn.get("xiuLianLevel") != 0
            or state["formationMembers"] != fixture["formationMembers"]
            or state["combatHeroes"] != fixture["combatHeroes"]
            or set(state["eligibleHeroIds"]) != expected_eligible
            or state["roleMoney"] != fixture["roleMoney"] + EXPECTED_ROLE_MONEY_REFUND
            or state["packageSha256"] == fixture["packageSha256"]
            or state["integrity"] != "ok"):
        raise RuntimeError(f"HeroRebirth SQLite success assertion failed: {state}")
    return state


def read_json(path):
    with open(path, "r", encoding="utf-8") as stream:
        return json.load(stream)


def write_json(path, payload):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8", newline="\n") as stream:
        json.dump(payload, stream, ensure_ascii=False, indent=2)
        stream.write("\n")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--action", required=True)
    parser.add_argument("--database", required=True)
    parser.add_argument("--backup", required=True)
    parser.add_argument("--evidence", required=True)
    parser.add_argument("--user-id", required=True, type=int)
    parser.add_argument("--role-id", required=True, type=int)
    args = parser.parse_args()
    database = os.path.abspath(args.database)
    backup = os.path.abspath(args.backup)
    evidence = os.path.abspath(args.evidence)

    if args.action == "Setup":
        if not os.path.isfile(database):
            raise RuntimeError(f"HeroRebirth SQLite database is missing: {database}")
        if os.path.exists(backup):
            raise RuntimeError("HeroRebirth SQLite backup already exists; restore/cleanup before setup")
        connection = sqlite3.connect(database)
        try:
            connection.execute("PRAGMA wal_checkpoint(TRUNCATE)")
            before = database_state(connection, args.user_id, args.role_id)
        finally:
            connection.close()
        os.makedirs(os.path.dirname(backup), exist_ok=True)
        shutil.copy2(database, backup)
        snapshot_hash = file_sha256(backup)
        connection = sqlite3.connect(database)
        try:
            pet, formation = connection.execute(
                "SELECT pet,zhenfa FROM role_info WHERE id=?", (args.role_id,)).fetchone()
            connection.execute(
                "UPDATE role_info SET level=?,pet=?,zhenfa=? WHERE id=?",
                (ROLE_LEVEL, rebirth_pet_blob(pet), rebirth_formation_blob(formation), args.role_id))
            connection.execute(
                "UPDATE user_info1 SET money=?,bd_money=? WHERE id=? AND role0=?",
                (SUCCESS_MONEY, SUCCESS_BOUND_MONEY, args.user_id, args.role_id))
            connection.commit()
            fixture = assert_setup(connection, args.user_id, args.role_id)
        finally:
            connection.close()
        write_json(evidence, {
            "schemaVersion": 1, "module": "HeroRebirth", "action": "Setup", "backend": "sqlite",
            "database": database, "backup": backup, "userId": args.user_id, "roleId": args.role_id,
            "snapshotHash": snapshot_hash, "fixtureHash": file_sha256(database), "before": before,
            "fixture": fixture,
            "profiles": {
                "success": {"userMoney": SUCCESS_MONEY, "boundMoney": SUCCESS_BOUND_MONEY},
                "insufficient": {"userMoney": 0, "boundMoney": 0,
                                 "action": "SetInsufficientCurrency"},
            },
            "coverage": {
                "deployedRejectionHeroIds": list(DEPLOYED_IDS),
                "eligibleScrollableHeroIds": list(ELIGIBLE_IDS),
                "maxRefundHeroId": MAX_PROGRESS_ID,
                "ineligibleInitialHeroId": INELIGIBLE_ID,
            },
            "createdUtc": utc_now(), "restored": False, "cleanupPassed": False,
        })
        return

    snapshot = read_json(evidence)
    if (snapshot.get("module") != "HeroRebirth" or snapshot.get("backend") != "sqlite"
            or snapshot.get("userId") != args.user_id or snapshot.get("roleId") != args.role_id):
        raise RuntimeError("HeroRebirth SQLite fixture evidence identity mismatch")

    if args.action == "AssertSetup":
        connection = sqlite3.connect(database)
        try:
            assert_setup(connection, args.user_id, args.role_id)
        finally:
            connection.close()
    elif args.action == "AssertSuccess":
        connection = sqlite3.connect("file:" + database + "?mode=ro", uri=True)
        try:
            assert_success(connection, args.user_id, args.role_id, snapshot["fixture"])
        finally:
            connection.close()
    elif args.action in ("SetInsufficientCurrency", "SetSuccessCurrency"):
        values = (0, 0) if args.action == "SetInsufficientCurrency" else (SUCCESS_MONEY, SUCCESS_BOUND_MONEY)
        connection = sqlite3.connect(database)
        try:
            connection.execute(
                "UPDATE user_info1 SET money=?,bd_money=? WHERE id=? AND role0=?",
                (values[0], values[1], args.user_id, args.role_id))
            connection.commit()
        finally:
            connection.close()
    elif args.action == "AssertInsufficientCurrency":
        connection = sqlite3.connect("file:" + database + "?mode=ro", uri=True)
        try:
            state = database_state(connection, args.user_id, args.role_id)
            if (state["userMoney"] != 0 or state["boundMoney"] != 0
                    or set(state["eligibleHeroIds"]) != set(ELIGIBLE_IDS)):
                raise RuntimeError(f"HeroRebirth insufficient-currency state failed: {state}")
        finally:
            connection.close()
    elif args.action == "CaptureMutationHash":
        connection = sqlite3.connect("file:" + database + "?mode=ro", uri=True)
        try:
            mutation = database_state(connection, args.user_id, args.role_id)
        finally:
            connection.close()
        snapshot["mutation"] = mutation
        snapshot["mutationHash"] = mutation["semanticSha256"]
        snapshot["mutationDatabaseHash"] = file_sha256(database)
        snapshot["mutationCapturedUtc"] = utc_now()
        write_json(evidence, snapshot)
    elif args.action == "AssertMutationReloginHash":
        connection = sqlite3.connect("file:" + database + "?mode=ro", uri=True)
        try:
            current = database_state(connection, args.user_id, args.role_id)
        finally:
            connection.close()
        if current["semanticSha256"] != snapshot.get("mutationHash"):
            raise RuntimeError("HeroRebirth mutation semantic hash changed after relogin")
    elif args.action == "Restore":
        if file_sha256(backup) != snapshot["snapshotHash"]:
            raise RuntimeError("HeroRebirth immutable SQLite backup hash changed")
        for suffix in ("-wal", "-shm"):
            sidecar = database + suffix
            if os.path.exists(sidecar):
                os.remove(sidecar)
        shutil.copy2(backup, database)
        snapshot["restored"] = True
        snapshot["restoredHash"] = file_sha256(database)
        snapshot["restoredUtc"] = utc_now()
        write_json(evidence, snapshot)
    elif args.action == "AssertRestored":
        if file_sha256(database) != snapshot["snapshotHash"]:
            raise RuntimeError("HeroRebirth restored SQLite database hash mismatch")
        connection = sqlite3.connect("file:" + database + "?mode=ro", uri=True)
        try:
            if connection.execute("PRAGMA integrity_check").fetchone()[0] != "ok":
                raise RuntimeError("HeroRebirth restored SQLite integrity failed")
        finally:
            connection.close()
    elif args.action == "AssertReloginHash":
        connection = sqlite3.connect("file:" + database + "?mode=ro", uri=True)
        try:
            current = database_state(connection, args.user_id, args.role_id)
        finally:
            connection.close()
        if current["semanticSha256"] != snapshot["before"]["semanticSha256"]:
            raise RuntimeError(f"HeroRebirth restored business state changed after relogin: {current}")
        snapshot["postLoginBusinessStateVerified"] = current
        snapshot["postLoginDatabaseHash"] = file_sha256(database)
        snapshot["postLoginVerifiedUtc"] = utc_now()
        write_json(evidence, snapshot)
    elif args.action == "Cleanup":
        if os.path.exists(backup):
            os.remove(backup)
        snapshot["cleanupPassed"] = True
        snapshot["cleanedUtc"] = utc_now()
        write_json(evidence, snapshot)
    elif args.action == "AssertCleanup":
        if os.path.exists(backup):
            raise RuntimeError("HeroRebirth SQLite fixture backup remains")
        if (not snapshot.get("restored") or not snapshot.get("cleanupPassed")
                or snapshot.get("restoredHash") != snapshot.get("snapshotHash")):
            raise RuntimeError("HeroRebirth SQLite fixture evidence does not prove restore and cleanup")
    else:
        raise RuntimeError(f"Unsupported HeroRebirth SQLite fixture action: {args.action}")


if __name__ == "__main__":
    main()
