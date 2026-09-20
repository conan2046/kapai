"""Read-only checks for V2 hero and gear runtime/display contracts."""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SERVER = ROOT / "server/config/json"
CLIENT = ROOT / "unityclient/Assets/ProjectX/Resources/Configs"


def read(path):
    return json.loads(path.read_text(encoding="utf-8-sig"))


def main():
    for name in ("fabao", "equip", "suit"):
        assert read(SERVER / f"{name}.json") == read(CLIENT / f"{name}.json"), f"Client/server drift: {name}"
    heroes = read(CLIENT / "hero_build_detail.json")
    gear = read(CLIENT / "hero_build_gear.json")
    assert sorted(h["hero_id"] for h in heroes) == list(range(10, 69))
    assert all(len(h["skills"]) == 4 for h in heroes)
    assert len({(h["hero_id"], s["id"]) for h in heroes for s in h["skills"]}) == 236
    artifacts = {a["id"]: a for a in gear["artifacts"]}
    sets = {s["id"]: s for s in gear["sets"]}
    assert len(artifacts) == 70 and set(sets) == set(range(1, 11))
    runtime_artifacts = {a["id"]: a for a in read(SERVER / "fabao.json") if a["equip"]}
    assert set(runtime_artifacts) == set(artifacts)
    for family in range(1, 15):
        family_rows = [a for a in artifacts.values() if a["family"] == family]
        assert sorted(a["quality"] for a in family_rows) == list(range(3, 8))
    for key, artifact in artifacts.items():
        runtime = runtime_artifacts[key]
        assert runtime["name"] == artifact["name"] and runtime["quality"] == artifact["quality"]
        assert artifact["description"] in runtime["des"]
    for hero in heroes:
        for branch in ("a", "b"):
            assert 1 <= hero[f"artifact_{branch}"] <= 14 and hero[f"set_{branch}"] in sets
            assert hero[f"description_{branch}"].strip() and hero[f"build_{branch}"].strip()
        assert all(skill["name"].strip() and skill["description"].strip() for skill in hero["skills"])
    equipment = read(SERVER / "equip.json")
    for suit in read(SERVER / "suit.json"):
        key = suit["id"]
        assert suit["suit"][1:] == [[], []], f"Legacy 3/4-piece attributes still active: {key}"
        assert suit["two_description"] == sets[key]["two"] and suit["four_description"] == sets[key]["four"]
        pieces = [e for e in equipment if e["suit"] == key]
        assert sorted(e["part"] for e in pieces) == [1, 2, 3, 4]
        assert all(sets[key]["two"] in e["des"] and sets[key]["four"] in e["des"] for e in pieces)
    print("PASS V2 contracts: 59 heroes/236 skill slots/118 branches/70 artifacts/40 set pieces/10 sets; client-server parity and legacy set removal")


if __name__ == "__main__":
    main()
