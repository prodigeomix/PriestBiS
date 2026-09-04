#!/usr/bin/env python3
"""
tools/scan_trinkets_and_tokens.py
=================================
Deep inspection of AtlasLoot and pfQuest databases for:
1. All Trinkets relevant to Priests/Healers in Vanilla & Turtle WoW.
2. Raid Quest items and tokens (e.g. Eye of Divinity, Head of Nefarian, Head of Onyxia, etc.).
3. Audit which items are currently in PriestBiS.ITEM_METADATA and which are missing or score 0.
"""

import os
import re
import sys

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ADDONS_DIR = os.path.dirname(BASE_DIR)
PRIESTBIS_LUA = os.path.join(BASE_DIR, "Data", "ItemDatabase.lua")

ATLASLOOT_DIR = os.path.join(ADDONS_DIR, "AtlasLoot")
PFQUEST_DIR = os.path.join(ADDONS_DIR, "pfQuest")
PFQUEST_TURTLE_DIR = os.path.join(ADDONS_DIR, "pfQuest-turtle")

def load_priestbis_db():
    with open(PRIESTBIS_LUA, "r", encoding="utf-8", errors="ignore") as f:
        content = f.read()

    metadata_match = re.search(r'UA\.ITEM_METADATA\s*=\s*\{(.*?)\n\s*\}', content, re.DOTALL)
    item_metadata = {}
    if metadata_match:
        for line in metadata_match.group(1).splitlines():
            line = line.strip().split('--')[0]
            m = re.search(r'\[(\d+)\]\s*=\s*\{(.*?)\}', line)
            if m:
                item_id = int(m.group(1))
                item_metadata[item_id] = m.group(2)

    boss_drops_match = re.search(r'UA\.BOSS_DROPS\s*=\s*\{(.*?)\n\s*\}', content, re.DOTALL)
    boss_drops = {}
    if boss_drops_match:
        for line in boss_drops_match.group(1).splitlines():
            line = line.strip().split('--')[0]
            m = re.search(r'\["([^"]+)"\]\s*=\s*\{([^}]+)\}', line)
            if m:
                boss = m.group(1)
                ids = [int(x.strip()) for x in m.group(2).split(',') if x.strip().isdigit()]
                boss_drops[boss] = ids

    return item_metadata, boss_drops

def scan_atlasloot():
    instances_file = os.path.join(ATLASLOOT_DIR, "Database", "Instances.lua")
    sets_file = os.path.join(ATLASLOOT_DIR, "Database", "Sets.lua")
    factions_file = os.path.join(ATLASLOOT_DIR, "Database", "Factions.lua")
    
    found_items = {}

    item_re = re.compile(r'\{\s*(\d+)\s*,\s*"[^"]*"\s*,\s*"=q\d=([^"=]+)[^"]*"\s*,\s*"([^"]*)"')

    for filepath, category in [(instances_file, "Instances"), (sets_file, "Sets"), (factions_file, "Factions")]:
        if not os.path.exists(filepath):
            continue
        with open(filepath, "r", encoding="utf-8", errors="ignore") as f:
            content = f.read()

        current_table = "Unknown"
        for line in content.splitlines():
            tm = re.match(r'^\s*([A-Za-z0-9_]+)\s*=\s*\{', line)
            if tm:
                current_table = tm.group(1)
            
            m = item_re.search(line)
            if m:
                item_id = int(m.group(1))
                name = m.group(2).strip()
                ds = m.group(3)
                
                is_trinket = "#s14#" in ds
                is_token = "token" in name.lower() or "primal hakkari" in name.lower() or "head of" in name.lower() or "heart of" in name.lower() or "eye of" in name.lower()
                is_priest = "#c5#" in ds or ("#c" not in ds and ("#a1#" in ds or is_trinket or "#s13#" in ds or "#s4#" in ds))

                if item_id > 0 and (is_trinket or is_token):
                    found_items[item_id] = {
                        "id": item_id,
                        "name": name,
                        "table": current_table,
                        "ds": ds,
                        "is_trinket": is_trinket,
                        "is_token": is_token,
                        "category": category
                    }
    return found_items

def main():
    print("=" * 80)
    print("ATLASLOOT & PFQUEST COMPREHENSIVE TRINKET & TOKEN AUDIT FOR PRIESTBIS")
    print("=" * 80)

    pb_meta, pb_boss = load_priestbis_db()
    print(f"Loaded {len(pb_meta)} items from PriestBiS.ITEM_METADATA.")
    print(f"Loaded {len(pb_boss)} bosses from PriestBiS.BOSS_DROPS.")

    atlas_items = scan_atlasloot()
    print(f"Discovered {len(atlas_items)} trinket/token items in AtlasLoot.")

    # High-value Classic & Turtle WoW Priest Trinkets to verify:
    KNOWN_PRIEST_TRINKETS = [
        (19950, "Zandalarian Hero Charm", "ZG: Hakkar quest", "On-use +204 Heal/Dmg decaying"),
        (19958, "Hazza'rah's Charm of Healing", "ZG: Edge of Madness", "On-use -40% Greater Heal cast time"),
        (19395, "Rejuvenating Gem", "BWL: Drake bosses", "+66 Heal, +9 MP5"),
        (19345, "Aegis of Preservation", "BWL: Razorgore", "On-equip mana proc"),
        (18608, "Benediction", "MC: Domo quest (Eye of Divinity)", "BiS Phase 1/2 Staff"),
        (18646, "The Eye of Divinity", "MC: Majordomo Executus chest", "Quest: Benediction quest starter"),
        (19002, "Head of Onyxia", "Onyxia", "Quest: Shard of the Scale / Dragonslayer"),
        (17064, "Shard of the Scale", "Onyxia Head turn-in", "+16 MP5 Trinket"),
        (19003, "Head of Nefarian", "BWL: Nefarian", "Quest: Pure Elementium Band"),
        (19382, "Pure Elementium Band", "BWL: Nefarian Head turn-in", "BiS Healing Ring (+27 Heal, +10 Int, +9 Spi, +9 Stam)"),
        (18469, "Royal Seal of Eldre'Thalas", "DM: Holy Bologna class book", "Priest Trinket (+10 Fire Res, +33 Heal)"),
        (18471, "Holy Bologna: What the Light Won't Tell You", "DM: Book drop", "Quest for Royal Seal of Eldre'Thalas"),
        (19288, "Darkmoon Card: Blue Dragon", "Darkmoon Faire", "Great proc: 100% mana regen while casting for 15s"),
        (19406, "Drake Fang Talisman", "BWL: Ebonroc", "Melee AP (Marked F in PB)"),
        (19947, "Nat Pagle's Broken Reel", "ZG: Gahz'ranka", "Trinket: +40 Spell Hit (DPS / situational)"),
        (19930, "Mar'li's Eye", "ZG: High Priestess Mar'li", "Trinket: +48 Healing, +6 MP5 for 30s on-use"),
        (23042, "Loatheb's Reflection", "Naxx: Loatheb", "Trinket: +13 shadow res, +1000 all res 8s"),
        (23047, "Eye of the Dead", "Naxx: Sapphiron", "BiS Naxx on-use heal: +450 healing for 20s (2m CD)"),
        (23006, "Warmth of Forgiveness", "Naxx: Four Horsemen", "+10 MP5 & 500 mana on-use"),
        (21625, "Scarab Brooch", "AQ40: Viscidus", "15% of healing converted into absorb shields for 30s"),
        (21626, "Eye of C'Thun", "AQ40: C'Thun", "Quest: Ring of the Devoured or Cloak of the Savior"),
        (21712, "Cloak of the Savior", "AQ40: Eye of C'Thun turn-in", "Epic healing cloak (+40 Heal, +5 MP5)"),
        (21709, "Ring of the Devoured", "AQ40: Eye of C'Thun turn-in", "Epic healing ring"),
        (22268, "Draconic Infused Emblem", "UBRS: Drakkisath", "+100 mana on-use"),
        (11819, "Second Wind", "BRD: Golem Lord Argelmach", "+22 Heal, +300 mana on-use"),
        (12930, "Briarwood Reed", "UBRS: Jed Runewatcher", "+29 Spell Power (Pre-raid caster/hybrid)"),
        (19802, "Heart of Hakkar", "ZG: Hakkar", "Quest: ZHC turn-in"),
        (19841, "Primal Hakkari Shawl", "ZG: Mandokir/Arlokk", "Token: ZG class set"),
        (19842, "Primal Hakkari Sash", "ZG: Mandokir/Arlokk", "Token: ZG class set"),
        (19843, "Primal Hakkari Stanchion", "ZG: Mandokir/Arlokk", "Token: ZG class set"),
        (19724, "Primal Hakkari Idol", "ZG: Jin'do/Mandokir", "Token: ZG Head/Leg Enchant"),
    ]

    print("\n" + "=" * 80)
    print("AUDIT RESULTS FOR CRITICAL HEALER TRINKETS & RAID QUEST DROPS:")
    print("=" * 80)
    
    missing_from_metadata = []
    in_metadata = []

    for item_id, name, source, notes in KNOWN_PRIEST_TRINKETS:
        if item_id in pb_meta:
            in_metadata.append((item_id, name, source, pb_meta[item_id]))
        else:
            missing_from_metadata.append((item_id, name, source, notes))

    print(f"\n[OK] IN PRIESTBIS ITEM_METADATA ({len(in_metadata)} items):")
    for item_id, name, source, meta_str in in_metadata:
        print(f"  * [{item_id}] {name:<32} ({source}) -> {meta_str}")

    print("\n" + "=" * 80)
    print("ALL RARE & EPIC TRINKETS IN ATLASLOOT INSTANCES & SETS:")
    print("=" * 80)
    
    # Check all discovered trinkets in AtlasLoot
    trinkets_audit = []
    for item_id, data in atlas_items.items():
        if data["is_trinket"]:
            in_meta = item_id in pb_meta
            trinkets_audit.append((item_id, data["name"], data["category"], in_meta, pb_meta.get(item_id, "")))

    print(f"Total trinkets found in AtlasLoot: {len(trinkets_audit)}")
    missing_trinkets = [t for t in trinkets_audit if not t[3]]
    print(f"Trinkets missing from ITEM_METADATA: {len(missing_trinkets)}")
    
    print("\nSample of missing trinkets (checking for healer relevance):")
    for item_id, name, cat, in_meta, meta in missing_trinkets[:35]:
        print(f"  ? [{item_id}] {name:<35} ({cat})")

if __name__ == "__main__":
    main()
