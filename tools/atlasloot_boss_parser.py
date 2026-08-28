#!/usr/bin/env python3
"""
AtlasLoot Enhanced Boss Parser for PriestBiS Addon
Scans boss loot tables in Instances.lua and identifies priest-appropriate drops
that are missing from the PriestBiS database.
"""
import re
import json
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
        "id": item_id, "name": item_name, "ds": ds_raw,
        "drop_rate": drop_rate, **props,
        "is_priest_appropriate": is_priest_appropriate(ds_raw),
    }


def find_all_tables(content):
    tables = {}
    for match in re.finditer(r'(\w+)\s*=\s*\{', content):
        table_name = match.group(1)
        start = match.end()
        depth = 1
        pos = start
        while depth > 0 and pos < len(content):
            if content[pos] == '{': depth += 1
            elif content[pos] == '}': depth -= 1
            pos += 1
        table_end_pos = pos
        table_content = content[start:table_end_pos - 1]
        line_start = content.rfind('\n', 0, match.start()) + 1
        preceding_line = content[line_start:match.start()].strip()
        tables[table_name] = {
            'content': table_content,
            'name': preceding_line,
        }
    return tables


def extract_items_from_table(table_content):
    items = []
    for line in table_content.split('\n'):
        line = line.strip()
        if re.match(r'\{\s*\d+\s*,', line):
            parsed = parse_item_from_line(line)
            if parsed:
                items.append(parsed)
    return items


def get_existing_db_ids(ua_content):
    existing = set()
    for match in re.finditer(r'\[(\d+)\]\s*=\s*\{\s*name\s*=\s*"', ua_content):
        existing.add(int(match.group(1)))
    return existing


def main():
    with open(ATLASLOOT_PATH, "r", encoding="utf-8") as f:
        content = f.read()
    with open(PRIESTBIS_PATH, "r", encoding="utf-8") as f:
        ua_content = f.read()

    existing_db = get_existing_db_ids(ua_content)
    print(f"Existing database items: {len(existing_db)}")

    tables = find_all_tables(content)

    # Identify boss tables (not trash, not utility tables)
    trash_keywords = ['trash', 'trashmobs']
    skip_prefixes = ['TableRegister', 'Instances', 'TextParsing', 'TooltipStrings',
                     'AddonMessagePrefix', 'L', 'ALC', 'AH', 'NPCMinion',
                     'CraftMaterial', 'CraftRecipe', 'CraftRecipe', 'Item',
                     'Achievement', 'PVP', 'Dungeon', 'Heroic', 'Raid']

    boss_tables = {}
    for table_name, table_data in tables.items():
        lower_name = table_name.lower()
        if any(kw in lower_name for kw in trash_keywords):
            continue
        if any(sp in table_name for sp in skip_prefixes):
            continue
        # Boss tables typically have loot entries with item IDs
        boss_tables[table_name] = table_data

    print(f"\nFound {len(boss_tables)} potential boss tables")

    # Scan boss tables for priest-appropriate items not in database
    print(f"\n{'='*70}")
    print("BOSS TABLES WITH PRIEST-APPROPRIATE ITEMS NOT IN DATABASE:")
    print(f"{'='*70}")

    missing_items = {}
    for table_name, table_data in sorted(boss_tables.items()):
        items = extract_items_from_table(table_data['content'])
        priest_items = [i for i in items if i['is_priest_appropriate']]
        missing = [i for i in priest_items if i['id'] not in existing_db]

        if missing:
            missing_items[table_name] = missing
            print(f"\n  {table_name} ({table_data['name']}): {len(missing)} missing")
            for item in missing:
                print(f"    [{item['id']}] {item['name']} ({item['drop_rate']}) - {item.get('slot','?')}")

    # Summary
    print(f"\n{'='*70}")
    print("SUMMARY: All missing priest-appropriate boss drops")
    print(f"{'='*70}")
    total_missing = 0
    by_slot = {}
    for table_name, items in missing_items.items():
        for item in items:
            total_missing += 1
            slot = item.get('slot', 'Unknown')
            if slot not in by_slot:
                by_slot[slot] = []
            by_slot[slot].append(item)

    print(f"\nTotal missing items: {total_missing}")
    for slot, items in sorted(by_slot.items()):
        print(f"\n  {slot}: {len(items)} items")
        for item in items:
            print(f"    [{item['id']}] {item['name']}")

    # Save output
    output_path = os.path.join(BASE_DIR, "tools", "boss_drops_output.json")
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    with open(output_path, "w", encoding="utf-8") as f:
        json.dump(missing_items, f, indent=2, ensure_ascii=False)
    print(f"\nResults saved to {output_path}")


if __name__ == "__main__":
    main()
