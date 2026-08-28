#!/usr/bin/env python3
"""
AtlasLoot Enhanced Parser for PriestBiS Addon
Extracts trash drop items from AtlasLoot Instances.lua and identifies priest-appropriate items.
"""
import re
import json
import sys
import os

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ATLASLOOT_PATH = os.path.join(os.path.dirname(BASE_DIR), "AtlasLoot", "Database", "Instances.lua")
PRIESTBIS_PATH = os.path.join(BASE_DIR, "PriestBiS.lua")

CLOTH_ARMOR_TAG = "#a1#"
PRIEST_CLASS_TAG = "#c5#"
PRIEST_WEAPONS = {"#w12#", "#w9#", "#w6#", "#h2#"}

SLOT_MAP = {
    "s1": "Head", "s3": "Shoulder", "s4": "Back", "s5": "Chest",
    "s8": "Wrists", "s9": "Hands", "s10": "Waist", "s11": "Legs",
    "s12": "Boots", "s13": "Ring", "s14": "Trinket",
    "s15": "Relic", "s16": "Libram",
}


def parse_ds_string(ds_str):
    props = {
        "slot": None, "armor": None, "is_cloth": False,
        "is_priest_class_restricted": False,
        "is_priest_usable_weapon": False, "weapon_type": None,
        "is_jewelry": False,
    }
    armor_match = re.search(r'#a(\d)#', ds_str)
    if armor_match:
        armor_num = armor_match.group(1)
        props["armor"] = {"1": "Cloth", "2": "Leather", "3": "Mail", "4": "Plate"}.get(armor_num)
        if armor_num == "1":
            props["is_cloth"] = True
    if PRIEST_CLASS_TAG in ds_str:
        props["is_priest_class_restricted"] = True
    for tag in PRIEST_WEAPONS:
        if tag in ds_str:
            props["is_priest_usable_weapon"] = True
            props["weapon_type"] = tag
            break
    slot_match = re.search(r'#s(\d+)#', ds_str)
    if slot_match:
        slot_key = "s" + slot_match.group(1)
        props["slot"] = SLOT_MAP.get(slot_key, slot_key)
    if re.search(r'#s13#', ds_str):
        props["is_jewelry"] = True; props["slot"] = "Ring"
    elif re.search(r'#s4#', ds_str) and not re.search(r'#a\d#', ds_str):
        props["is_jewelry"] = True; props["slot"] = "Back"
    if re.search(r'#s14#', ds_str):
        props["is_jewelry"] = True; props["slot"] = "Trinket"
    return props


def is_priest_appropriate(ds_str):
    props = parse_ds_string(ds_str)
    if props["is_jewelry"]:
        return True
    if props["is_cloth"]:
        other_classes = re.findall(r'#c(\d)#', ds_str)
        for cls_num in other_classes:
            if cls_num != "5":
                return False
        return True
    if props["is_priest_usable_weapon"]:
        return True
    return False


def parse_item_from_line(line):
    pattern = r'\{\s*(\d+)\s*,\s*"[^"]*"\s*,\s*"(=q\d=[^"]*)"\s*,\s*("(?:=ds=)[^"]*")'
    match = re.search(pattern, line)
    if not match:
        return None
    item_id = int(match.group(1))
    name_field = match.group(2)
    ds_raw = match.group(3)
    name_match = re.search(r'=q\d=([^"=]+)', name_field)
    item_name = name_match.group(1).strip() if name_match else name_field
    rate_match = re.search(r'"(\d+(?:\.\d+)?%)"', line)
    drop_rate = rate_match.group(1) if rate_match else "unknown"
    props = parse_ds_string(ds_raw)
    return {
        "id": item_id,
        "name": item_name,
        "ds": ds_raw,
        "drop_rate": drop_rate,
        **props,
        "is_priest_appropriate": is_priest_appropriate(ds_raw),
    }


def extract_table(content, table_name):
    pattern = rf'{re.escape(table_name)}\s*=\s*\{{'
    match = re.search(pattern, content)
    if not match:
        return []
    start = match.end()
    depth = 1
    pos = start
    while depth > 0 and pos < len(content):
        if content[pos] == '{':
            depth += 1
        elif content[pos] == '}':
            depth -= 1
        pos += 1
    table_content = content[start:pos - 1]
    items = []
    for line in table_content.split('\n'):
        line = line.strip()
        if re.match(r'\{\s*\d+\s*,', line):
            parsed = parse_item_from_line(line)
            if parsed:
                items.append(parsed)
    return items


def get_current_gear_ids(content):
    ids = set()
    section_match = re.search(r'UA\.CURRENT_GEAR\s*=\s*\{(.+?)\}', content, re.DOTALL)
    if section_match:
        for match in re.finditer(r'id\s*=\s*(\d+)', section_match.group(1)):
            ids.add(int(match.group(1)))
    return ids


def get_existing_db_ids(content):
    existing = set()
    for match in re.finditer(r'\[(\d+)\]\s*=\s*\{\s*name\s*=\s*"', content):
        existing.add(int(match.group(1)))
    return existing


def main():
    with open(ATLASLOOT_PATH, "r", encoding="utf-8") as f:
        content = f.read()
    with open(PRIESTBIS_PATH, "r", encoding="utf-8") as f:
        ua_content = f.read()

    current_gear = get_current_gear_ids(ua_content)
    existing_db = get_existing_db_ids(ua_content)

    trash_tables = [
        ("MCTrashMobs", "MC"),
        ("BWLTrashMobs", "BWL"),
        ("UKHTrash", "UKH"),
        ("ZGTrash1", "ZG"),
        ("ZGTrash2", "ZG"),
        ("LKHTrash", "LKH"),
    ]

    results = {}
    all_trash_items = []

    for table_name, instance in trash_tables:
        items = extract_table(content, table_name)
        priest_items = [i for i in items if i["is_priest_appropriate"]]
        results[f"{instance}_{table_name}"] = {
            "table_name": table_name, "instance": instance,
            "total_items": len(items), "priest_appropriate": len(priest_items),
            "items": priest_items,
        }
        print(f"\n{instance} ({table_name}): {len(items)} total, {len(priest_items)} priest-appropriate")
        for item in priest_items:
            is_equipped = item['id'] in current_gear
            is_in_db = item['id'] in existing_db
            status = "EQUIPPED" if is_equipped else ("IN_DB" if is_in_db else "MISSING")
            print(f"  [{item['id']}] {item['name']} ({item['drop_rate']}) - {item.get('slot','?')} - {status}")
            if not is_equipped:
                all_trash_items.append({**item, "instance": instance})

    # Save JSON output
    output_path = os.path.join(BASE_DIR, "tools", "trash_drops_output.json")
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    with open(output_path, "w", encoding="utf-8") as f:
        json.dump(results, f, indent=2, ensure_ascii=False)
    print(f"\nResults saved to {output_path}")

    # Summary
    print(f"\n{'='*60}")
    print("TRASH DROPS THAT ARE UPGRADES (not already equipped):")
    print(f"{'='*60}")
    for item in all_trash_items:
        in_db = item['id'] in existing_db
        print(f"  [{'IN_DB' if in_db else 'MISSING'}] [{item['id']}] {item['name']} - {item['instance']} ({item['drop_rate']}) - {item.get('slot','?')}")


if __name__ == "__main__":
    main()
