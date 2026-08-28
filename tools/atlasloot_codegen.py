#!/usr/bin/env python3
"""
AtlasLoot Integration Tool for UpgradeAlert Addon

Generates Lua code for trash drops, boss drops, and database items from AtlasLoot data.
Cross-references with existing UpgradeAlert.lua to identify gaps and conflicts.

Usage:
    python atlasloot_codegen.py
"""
import re
import json
import os
import sys

ATLASLOOT_PATH = r"C:\Games\Interface\AddOns\AtlasLoot\Database\Instances.lua"
UPGRADEALERT_PATH = r"C:\Games\Interface\AddOns\UpgradeAlert\UpgradeAlert.lua"
TOOLS_DIR = r"C:\Games\Interface\AddOns\UpgradeAlert\Tools"

CLOTH_ARMOR_TAG = "#a1#"
PRIEST_CLASS_TAG = "#c5#"
PRIEST_WEAPONS = {"#w12#", "#w9#", "#w6#", "#h2#"}  # wands, staves, maces, offhand

# Armor class mapping from TextParsing.lua
ARMOR_MAP = {"1": "Cloth", "2": "Leather", "3": "Mail", "4": "Plate"}

# Priest class tag
# c1=Warrior, c2=Paladin, c3=Hunter, c4=Rogue, c5=Priest,
# c6=Death Knight, c7=Shaman, c8=Mage, c9=Warlock, c11=Druid

SLOT_MAP = {
    "s1": "Head", "s3": "Shoulder", "s4": "Back", "s5": "Chest",
    "s8": "Wrists", "s9": "Hands", "s10": "Waist", "s11": "Legs",
    "s12": "Boots", "s13": "Ring", "s14": "Trinket",
    "s15": "Relic", "s16": "Libram",
}

# Currently equipped items from CURRENT_GEAR for gap analysis
CURRENT_GEAR = {
    16817: {"name": "Girdle of Prophecy", "slot": "Waist", "instance": "MC"},
    16814: {"name": "Pants of Prophecy", "slot": "Legs", "instance": "MC"},
    16819: {"name": "Vambraces of Prophecy", "slot": "Wrists", "instance": "MC"},
    16812: {"name": "Gloves of Prophecy", "slot": "Hands", "instance": "MC"},
    55286: {"name": "Ring of Holy Light", "slot": "Ring", "instance": "UKH"},
}

# Items known NOT to be priest-appropriate (wrong stats/class)
EXCLUDED_ITEMS = {
    19436: "Cloak of Draconic Might - +19 Str/+19 Agi, not priest stats",
    19354: "Draconic Avenger - offhand axe, priests can't use axes",
    55277: "The End of All Ambitions - offhand sword, priests can't use swords",
    55508: "Brand of Karazaran - +17 Strength ring, not priest stats",
    19362: "Doom's Edge - offhand axe, priests can't use axes",
    19921: "Zulian Hacker - axe, priests can't use axes",
    19727: "Blood Scythe - sword, priests can't use swords",
}


def parse_ds_string(ds_str):
    """Parse AtlasLoot =ds= format string."""
    props = {
        "slot": None, "armor": None, "is_cloth": False,
        "is_priest_class_restricted": False,
        "is_priest_usable_weapon": False, "weapon_type": None,
        "is_jewelry": False, "is_trinket": False, "is_ring": False,
        "is_back": False,
    }
    armor_match = re.search(r'#a(\d)#', ds_str)
    if armor_match:
        armor_num = armor_match.group(1)
        props["armor"] = ARMOR_MAP.get(armor_num)
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
        props["is_jewelry"] = True; props["is_ring"] = True; props["slot"] = "Ring"
    elif re.search(r'#s4#', ds_str) and not re.search(r'#a\d#', ds_str):
        props["is_jewelry"] = True; props["is_back"] = True; props["slot"] = "Back"
    if re.search(r'#s14#', ds_str):
        props["is_jewelry"] = True; props["is_trinket"] = True; props["slot"] = "Trinket"

    return props


def is_priest_appropriate(ds_str):
    """Check if an item is appropriate for a Holy Priest based on DS format.
    
    Class restriction format: =q9=#c5# means Priest-only
                              =q10=#c3# means Hunter-only
    If a class restriction is present and it's NOT c5 (Priest), the item
    is class-specific to another class and should be excluded.
    """
    if PRIEST_CLASS_TAG in ds_str:
        return True  # Explicitly priest-only

    # Check for other class restrictions
    class_restrictions = re.findall(r'#c(\d)#', ds_str)
    for cls_num in class_restrictions:
        if cls_num != "5":
            # This item is class-restricted to another class
            return False

    props = parse_ds_string(ds_str)

    if props["is_jewelry"]:
        return True  # Rings, trinkets, cloaks are wearable by all

    if props["is_cloth"]:
        return True

    if props["is_priest_usable_weapon"]:
        return True

    return False


def get_weapon_hand(ds_str):
    """Determine mainhand/offhand from DS string."""
    if re.search(r'#h1#', ds_str):
        return "Mainhand"
    elif re.search(r'#h2#', ds_str):
        return "Offhand"
    elif re.search(r'#w6#', ds_str):  # One-handed mace
        return "Mainhand"
    elif re.search(r'#w9#', ds_str):  # Staff (two-handed)
        return "Twohand"
    elif re.search(r'#w12#', ds_str):  # Wands
        return "Ranged"
    return None


def parse_item_from_line(line):
    """Parse a single AtlasLoot item line."""
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
    is_priest = is_priest_appropriate(ds_raw)
    is_excluded = item_id in EXCLUDED_ITEMS

    # Override slot for weapons
    if props.get("is_priest_usable_weapon"):
        hand = get_weapon_hand(ds_raw)
        if hand:
            props["slot"] = hand

    return {
        "id": item_id,
        "name": item_name,
        "ds": ds_raw,
        "drop_rate": drop_rate,
        "is_priest_appropriate": is_priest and not is_excluded,
        "is_excluded": is_excluded,
        "exclusion_reason": EXCLUDED_ITEMS.get(item_id, ""),
        **props,
    }


def extract_table(content, table_name):
    """Extract all item entries from a named table in Instances.lua."""
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


def get_existing_db_ids(ua_content):
    """Extract all item IDs from UPGRADE_DATABASE."""
    existing = {}
    for match in re.finditer(r'\[(\d+)\]\s*=\s*\{\s*name\s*=\s*"([^"]*)"', ua_content):
        existing[int(match.group(1))] = match.group(2)
    return existing


def get_current_gear_ids(ua_content):
    """Extract item IDs from CURRENT_GEAR section."""
    ids = set()
    section_match = re.search(r'UA\.CURRENT_GEAR\s*=\s*\{(.+?)\}', ua_content, re.DOTALL)
    if section_match:
        for match in re.finditer(r'id\s*=\s*(\d+)', section_match.group(1)):
            ids.add(int(match.group(1)))
    return ids


def check_db_duplicates(ua_content):
    """Find duplicate item IDs in the database."""
    duplicates = []
    seen = {}
    for match in re.finditer(r'\[(\d+)\]\s*=\s*\{\s*name\s*=\s*"([^"]*)".*?drop\s*=\s*"([^"]*)"', ua_content, re.DOTALL):
        item_id = int(match.group(1))
        if item_id in seen:
            duplicates.append((item_id, seen[item_id], match.group(2)))
        else:
            seen[item_id] = match.group(2)
    return duplicates


def generate_trash_section(trash_tables, existing_db):
    """Generate Lua code for TRASH_DROPS table and database entries."""
    lines = []
    lines.append("    -- TRASH_DROPS = {")
    lines.append("    --     [\"TableName\"] = { itemID1, itemID2, ... },")
    lines.append("    -- }")

    all_trash_items = []
    for table_name, instance in trash_tables:
        items = extract_table(content, table_name)
        priest_trash = [i for i in items if i["is_priest_appropriate"]]
        all_trash_items.extend([(table_name, instance, i) for i in priest_trash])

        item_ids = [str(i["id"]) for i in priest_trash]
        lines.append(f'    -- {instance} ({table_name})')
        lines.append(f'    ["{table_name}"] = {{ {", ".join(item_ids)} }},')

    return all_trash_items, "\n".join(lines)


def main():
    global content

    with open(ATLASLOOT_PATH, "r", encoding="utf-8") as f:
        content = f.read()
    with open(UPGRADEALERT_PATH, "r", encoding="utf-8") as f:
        ua_content = f.read()

    existing_db = get_existing_db_ids(ua_content)
    current_gear = get_current_gear_ids(ua_content)

    print(f"Existing database items: {len(existing_db)}")
    print(f"Currently equipped: {len(current_gear)}")

    # Check for duplicates
    print(f"\n{'='*70}")
    print("DATABASE KEY COLLISIONS (DUPLICATE IDs):")
    print(f"{'='*70}")
    duplicates = check_db_duplicates(ua_content)
    if duplicates:
        for item_id, name1, name2 in duplicates:
            print(f"  [{item_id}]: '{name1}' overwritten by '{name2}'")
    else:
        print("  None found")

    # Trash tables to scan
    trash_tables = [
        ("MCTrashMobs", "MC"),
        ("BWLTrashMobs", "BWL"),
        ("UKHTrash", "UKH"),
        ("ZGTrash1", "ZG"),
        ("ZGTrash2", "ZG"),
        ("LKHTrash", "LKH"),
    ]

    print(f"\n{'='*70}")
    print("TRASH DROP ANALYSIS:")
    print(f"{'='*70}")

    all_trash = []
    for table_name, instance in trash_tables:
        items = extract_table(content, table_name)
        priest_trash = [i for i in items if i["is_priest_appropriate"]]
        excluded = [i for i in items if i["is_excluded"]]
        not_priest = [i for i in items if not i["is_priest_appropriate"] and not i["is_excluded"]]

        print(f"\n  {instance} ({table_name}): {len(items)} total")
        print(f"    Priest-appropriate: {len(priest_trash)}")
        print(f"    Excluded (not priest-stats): {len(excluded)}")
        print(f"    Other classes only: {len(not_priest)}")

        for item in priest_trash:
            status = "EQUIPPED" if item["id"] in current_gear else (
                "IN_DB" if item["id"] in existing_db else "MISSING"
            )
            print(f"      [{item['id']}] {item['name']} ({item['drop_rate']}) - {item.get('slot','?')} - {status}")
            all_trash.append((table_name, instance, item, status))

        for item in excluded:
            print(f"      [SKIP] [{item['id']}] {item['name']} - {item['exclusion_reason']}")

        for item in not_priest[:5]:  # Show first 5
            print(f"      [--] [{item['id']}] {item['name']} - not priest-appropriate")
        if len(not_priest) > 5:
            print(f"      ... and {len(not_priest) - 5} more non-priest items")

    # Summary of MISSING items
    print(f"\n{'='*70}")
    print("MISSING TRASH DROPS (priest-appropriate, not in DB):")
    print(f"{'='*70}")
    missing = [(t, i, item) for t, i, item, s in all_trash if s == "MISSING"]
    if missing:
        for table_name, instance, item in missing:
            print(f"  [{item['id']}] {item['name']} - {instance} ({item['drop_rate']})")
    else:
        print("  All priest-appropriate trash drops are in the database!")

    # Generate Lua code snippet
    print(f"\n{'='*70}")
    print("GENERATED LUA CODE FOR TRASH_DROPS TABLE:")
    print(f"{'='*70}")
    trash_code_lines = ["UA.TRASH_DROPS = {"]
    for table_name, instance in trash_tables:
        items = extract_table(content, table_name)
        priest_trash = [i for i in items if i["is_priest_appropriate"]]
        item_ids = [str(i["id"]) for i in priest_trash]
        trash_code_lines.append(f'    -- {instance} ({table_name})')
        trash_code_lines.append(f'    ["{table_name}"] = {{ {", ".join(item_ids)} }},')
    trash_code_lines.append("}")
    print("\n".join(trash_code_lines))

    # Save to file in tools directory
    output_path = os.path.join(TOOLS_DIR, "analysis_results.json")
    os.makedirs(TOOLS_DIR, exist_ok=True)
    with open(output_path, "w", encoding="utf-8") as f:
        json.dump({
            "duplicates": duplicates,
            "trash_drops": [{"table": t, "instance": i, "item": item, "status": s}
                          for t, i, item, s in all_trash],
            "missing_items": [{"id": item["id"], "name": item["name"], "instance": inst,
                             "drop_rate": item["drop_rate"], "slot": item.get("slot","?")}
                            for t, inst, item, s in all_trash if s == "MISSING"],
        }, f, indent=2, ensure_ascii=False)
    print(f"\nAnalysis saved to {output_path}")


if __name__ == "__main__":
    main()
