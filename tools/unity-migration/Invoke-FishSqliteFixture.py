import argparse
import hashlib
import json
import os
import shutil
import sqlite3
from datetime import datetime, timezone


FIXTURE_LEVEL = 10
FIXTURE_MONEY = 1000
EXPECTED_FISH_IDS = (580, 581, 582, 10580, 10581, 10582, 10583, 10584, 10585, 10586)


def sha256(path):
    digest = hashlib.sha256()
    with open(path, "rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def read_json(path):
    with open(path, "r", encoding="utf-8-sig") as stream:
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


def table_exists(connection, table):
    return connection.execute(
        "SELECT 1 FROM sqlite_master WHERE type='table' AND name=?", (table,)
    ).fetchone() is not None


def load_expected(settings_path, rewards_path, position_path):
    settings_rows = read_json(settings_path)
    rewards = read_json(rewards_path)
    position_rows = read_json(position_path)
    if len(settings_rows) != 1 or len(position_rows) != 1 or len(rewards) != 10:
        raise RuntimeError("Fish config must contain one settings row, one position row and ten reward rows")
    settings = settings_rows[0]
    position = position_rows[0]
    reward_ids = tuple(int(row["item_id"]) for row in rewards)
    if reward_ids != EXPECTED_FISH_IDS:
        raise RuntimeError(f"Fish reward item order mismatch: {reward_ids}")
    if {
        "gold_cost": int(settings["gold_cost"]),
        "cycle_min_seconds": int(settings["cycle_min_seconds"]),
        "cycle_max_seconds": int(settings["cycle_max_seconds"]),
        "basket_capacity": int(settings["basket_capacity"]),
        "fish_stack_limit": int(settings["fish_stack_limit"]),
        "auto_continue": int(settings["auto_continue"]),
    } != {
        "gold_cost": 100,
        "cycle_min_seconds": 10,
        "cycle_max_seconds": 20,
        "basket_capacity": 9999,
        "fish_stack_limit": 999,
        "auto_continue": 1,
    }:
        raise RuntimeError(f"Fish settings mismatch: {settings}")
    if tuple(int(position[key]) for key in ("scene_id", "map_id", "x", "y", "dir", "flip", "fishing_shape_id")) != (54, 33, 1086, 619, 2, 1, 2000):
        raise RuntimeError(f"Fish position mismatch: {position}")
    return {"settings": settings, "rewards": rewards, "position": position}


def ensure_schema(connection):
    connection.executescript(
        """
        CREATE TABLE IF NOT EXISTS fish_settings (
          id INTEGER PRIMARY KEY,gold_cost INTEGER NOT NULL,cycle_min_seconds INTEGER NOT NULL,
          cycle_max_seconds INTEGER NOT NULL,basket_capacity INTEGER NOT NULL,
          fish_stack_limit INTEGER NOT NULL,auto_continue INTEGER NOT NULL);
        CREATE TABLE IF NOT EXISTS fish_reward (
          id INTEGER PRIMARY KEY,item_id INTEGER NOT NULL,weight INTEGER NOT NULL,
          enabled INTEGER NOT NULL,sort INTEGER NOT NULL,use_reward_id INTEGER NOT NULL);
        CREATE UNIQUE INDEX IF NOT EXISTS idx_fish_reward_item_id ON fish_reward(item_id);
        CREATE TABLE IF NOT EXISTS fish_position (
          id INTEGER PRIMARY KEY,scene_id INTEGER NOT NULL,map_id INTEGER NOT NULL,
          x INTEGER NOT NULL,y INTEGER NOT NULL,dir INTEGER NOT NULL,flip INTEGER NOT NULL,
          fishing_shape_id INTEGER NOT NULL);
        CREATE TABLE IF NOT EXISTS fish_basket_slots (
          role_id INTEGER NOT NULL,slot_index INTEGER NOT NULL,item_id INTEGER NOT NULL,
          quantity INTEGER NOT NULL,PRIMARY KEY(role_id,slot_index),
          CHECK(slot_index >= 0 AND slot_index < 9999),CHECK(quantity > 0 AND quantity <= 999));
        CREATE INDEX IF NOT EXISTS idx_fish_basket_role_item
          ON fish_basket_slots(role_id,item_id,slot_index);
        """
    )


def seed_config(connection, expected):
    settings = expected["settings"]
    connection.execute(
        "INSERT INTO fish_settings VALUES(?,?,?,?,?,?,?) ON CONFLICT(id) DO UPDATE SET "
        "gold_cost=excluded.gold_cost,cycle_min_seconds=excluded.cycle_min_seconds,"
        "cycle_max_seconds=excluded.cycle_max_seconds,basket_capacity=excluded.basket_capacity,"
        "fish_stack_limit=excluded.fish_stack_limit,auto_continue=excluded.auto_continue",
        tuple(int(settings[key]) for key in ("id", "gold_cost", "cycle_min_seconds", "cycle_max_seconds", "basket_capacity", "fish_stack_limit", "auto_continue")),
    )
    position = expected["position"]
    connection.execute(
        "INSERT INTO fish_position VALUES(?,?,?,?,?,?,?,?) ON CONFLICT(id) DO UPDATE SET "
        "scene_id=excluded.scene_id,map_id=excluded.map_id,x=excluded.x,y=excluded.y,"
        "dir=excluded.dir,flip=excluded.flip,fishing_shape_id=excluded.fishing_shape_id",
        tuple(int(position[key]) for key in ("id", "scene_id", "map_id", "x", "y", "dir", "flip", "fishing_shape_id")),
    )
    connection.execute("DELETE FROM fish_reward")
    connection.executemany(
        "INSERT INTO fish_reward(id,item_id,weight,enabled,sort,use_reward_id) VALUES(?,?,?,?,?,?)",
        [tuple(int(row[key]) for key in ("id", "item_id", "weight", "enabled", "sort", "use_reward_id")) for row in expected["rewards"]],
    )


def business_state(connection, user_id, role_id):
    link = connection.execute("SELECT role0 FROM user_info1 WHERE id=?", (user_id,)).fetchone()
    role = connection.execute("SELECT level,money FROM role_info WHERE id=?", (role_id,)).fetchone()
    if link is None or role is None:
        raise RuntimeError(f"Fish SQLite identity is missing: {user_id}/{role_id}")
    state = {
        "linkedRoleId": int(link[0] or 0),
        "level": int(role[0] or 0),
        "money": int(role[1] or 0),
        "settings": [],
        "rewards": [],
        "position": [],
        "basket": [],
        "integrity": connection.execute("PRAGMA integrity_check").fetchone()[0],
    }
    if table_exists(connection, "fish_settings"):
        state["settings"] = [list(row) for row in connection.execute(
            "SELECT id,gold_cost,cycle_min_seconds,cycle_max_seconds,basket_capacity,fish_stack_limit,auto_continue FROM fish_settings ORDER BY id")]
    if table_exists(connection, "fish_reward"):
        state["rewards"] = [list(row) for row in connection.execute(
            "SELECT id,item_id,weight,enabled,sort,use_reward_id FROM fish_reward ORDER BY sort,id")]
    if table_exists(connection, "fish_position"):
        state["position"] = [list(row) for row in connection.execute(
            "SELECT id,scene_id,map_id,x,y,dir,flip,fishing_shape_id FROM fish_position ORDER BY id")]
    if table_exists(connection, "fish_basket_slots"):
        state["basket"] = [list(row) for row in connection.execute(
            "SELECT slot_index,item_id,quantity FROM fish_basket_slots WHERE role_id=? ORDER BY slot_index", (role_id,))]
    payload = json.dumps({key: state[key] for key in state if key != "integrity"}, ensure_ascii=False, sort_keys=True, separators=(",", ":"))
    state["businessSha256"] = hashlib.sha256(payload.encode("utf-8")).hexdigest()
    player_payload = json.dumps({
        key: state[key] for key in ("linkedRoleId", "level", "money", "basket")
    }, ensure_ascii=False, sort_keys=True, separators=(",", ":"))
    state["playerBusinessSha256"] = hashlib.sha256(player_payload.encode("utf-8")).hexdigest()
    return state


def expected_rows(expected):
    settings = expected["settings"]
    position = expected["position"]
    return {
        "settings": [[int(settings[key]) for key in ("id", "gold_cost", "cycle_min_seconds", "cycle_max_seconds", "basket_capacity", "fish_stack_limit", "auto_continue")]],
        "rewards": [[int(row[key]) for key in ("id", "item_id", "weight", "enabled", "sort", "use_reward_id")] for row in expected["rewards"]],
        "position": [[int(position[key]) for key in ("id", "scene_id", "map_id", "x", "y", "dir", "flip", "fishing_shape_id")]],
    }


def assert_setup(connection, user_id, role_id, expected):
    current = business_state(connection, user_id, role_id)
    rows = expected_rows(expected)
    if (current["linkedRoleId"] != role_id or current["level"] != FIXTURE_LEVEL
            or current["money"] != FIXTURE_MONEY or current["integrity"] != "ok"
            or current["settings"] != rows["settings"] or current["rewards"] != rows["rewards"]
            or current["position"] != rows["position"] or current["basket"]):
        raise RuntimeError(f"Fish deterministic SQLite fixture assertion failed: {current}")
    return current


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--action", required=True)
    parser.add_argument("--database", required=True)
    parser.add_argument("--backup", required=True)
    parser.add_argument("--evidence", required=True)
    parser.add_argument("--settings", required=True)
    parser.add_argument("--rewards", required=True)
    parser.add_argument("--position", required=True)
    parser.add_argument("--user-id", type=int, required=True)
    parser.add_argument("--role-id", type=int, required=True)
    args = parser.parse_args()
    database, backup, evidence = map(os.path.abspath, (args.database, args.backup, args.evidence))
    expected = load_expected(args.settings, args.rewards, args.position)

    if args.action == "Setup":
        if not os.path.isfile(database):
            raise RuntimeError(f"Fish SQLite database is missing: {database}")
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
            ensure_schema(connection)
            seed_config(connection, expected)
            connection.execute("UPDATE user_info1 SET role0=? WHERE id=?", (args.role_id, args.user_id))
            connection.execute("UPDATE role_info SET level=?,money=? WHERE id=?", (FIXTURE_LEVEL, FIXTURE_MONEY, args.role_id))
            connection.execute("DELETE FROM fish_basket_slots WHERE role_id=?", (args.role_id,))
            connection.commit()
            fixture = assert_setup(connection, args.user_id, args.role_id, expected)
        finally:
            connection.close()
        write_json(evidence, {
            "schemaVersion": 1, "module": "Fish", "backend": "sqlite", "action": "Setup",
            "database": database, "backup": backup, "userId": args.user_id, "roleId": args.role_id,
            "snapshotHash": sha256(backup), "fixtureHash": sha256(database), "before": before,
            "fixture": fixture, "expected": expected, "restored": False, "reloginVerified": False,
            "databaseIntegrity": fixture["integrity"], "residualCount": 1,
            "createdUtc": datetime.now(timezone.utc).isoformat(),
        })
        return

    snapshot = read_json(evidence)
    if snapshot.get("module") != "Fish" or snapshot.get("userId") != args.user_id or snapshot.get("roleId") != args.role_id:
        raise RuntimeError("Fish SQLite fixture evidence identity mismatch")
    if args.action == "AssertSetup":
        connection = sqlite3.connect("file:" + database + "?mode=ro", uri=True)
        try:
            current = assert_setup(connection, args.user_id, args.role_id, snapshot["expected"])
        finally:
            connection.close()
        if sha256(backup) != snapshot["snapshotHash"]:
            raise RuntimeError("Fish immutable SQLite backup hash changed")
        snapshot["assertedFixture"] = current
        write_json(evidence, snapshot)
    elif args.action == "AssertMutated":
        connection = sqlite3.connect("file:" + database + "?mode=ro", uri=True)
        try:
            current = business_state(connection, args.user_id, args.role_id)
        finally:
            connection.close()
        delta = FIXTURE_MONEY - current["money"]
        total_fish = sum(int(row[2]) for row in current["basket"])
        valid_ids = set(EXPECTED_FISH_IDS)
        if (current["integrity"] != "ok" or delta != 300 or total_fish != 1
                or any(int(row[1]) not in valid_ids or int(row[2]) < 1 or int(row[2]) > 999 for row in current["basket"])):
            raise RuntimeError(f"Fish completion mutation assertion failed: delta={delta}, state={current}")
        snapshot["mutated"] = current
        snapshot["mutatedUtc"] = datetime.now(timezone.utc).isoformat()
        write_json(evidence, snapshot)
    elif args.action == "Restore":
        if sha256(backup) != snapshot["snapshotHash"]:
            raise RuntimeError("Fish immutable SQLite backup hash changed")
        remove_sidecars(database)
        shutil.copy2(backup, database)
        snapshot["restored"] = True
        snapshot["restoredUtc"] = datetime.now(timezone.utc).isoformat()
        write_json(evidence, snapshot)
    elif args.action == "AssertRestored":
        if sha256(database) != snapshot["snapshotHash"]:
            raise RuntimeError("Fish restored SQLite database hash mismatch")
        connection = sqlite3.connect("file:" + database + "?mode=ro", uri=True)
        try:
            integrity = connection.execute("PRAGMA integrity_check").fetchone()[0]
        finally:
            connection.close()
        if integrity != "ok":
            raise RuntimeError("Fish restored SQLite integrity failed")
        snapshot["databaseIntegrity"] = integrity
        write_json(evidence, snapshot)
    elif args.action == "AssertReloginHash":
        connection = sqlite3.connect("file:" + database + "?mode=ro", uri=True)
        try:
            current = business_state(connection, args.user_id, args.role_id)
        finally:
            connection.close()
        if (current["integrity"] != "ok"
                or current["playerBusinessSha256"] != snapshot["before"]["playerBusinessSha256"]):
            raise RuntimeError(f"Fish relogin business hash mismatch: {current}")
        snapshot["reloginVerified"] = True
        snapshot["reloginUtc"] = datetime.now(timezone.utc).isoformat()
        write_json(evidence, snapshot)
    elif args.action == "Cleanup":
        if os.path.exists(backup):
            os.remove(backup)
        snapshot["residualCount"] = 0
        write_json(evidence, snapshot)
    elif args.action == "AssertCleanup":
        if os.path.exists(backup) or snapshot.get("residualCount") != 0:
            raise RuntimeError("Fish SQLite fixture cleanup failed")
    else:
        raise RuntimeError(f"Unsupported Fish fixture action: {args.action}")


if __name__ == "__main__":
    main()
