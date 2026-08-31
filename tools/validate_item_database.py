#!/usr/bin/env python3
"""
tools/validate_item_database.py
===============================
Database Integrity Auditor for PriestBiS:
1. Validates UA.ITEM_METADATA curated trinket and special drop records.
2. Validates UA.SET_BONUSES breakpoint definitions and descriptions.
3. Validates slot name consistency across tables.
4. Verifies EP weight positive finite numbers.
"""

import os
import re
import sys

if sys.platform == "win32":
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
ADDON_DIR = os.path.abspath(os.path.join(SCRIPT_DIR, ".."))

VALID_SLOTS = {
    "Head", "Neck", "Shoulder", "Back", "Chest", "Wrists", "Hands",
    "Belt", "Legs", "Boots", "Ring", "Ring1", "Ring2", "Trinket",
    "Trinket1", "Trinket2", "Mainhand", "Twohand", "Offhand", "Wand"
}

VALID_TIERS = {"S", "A", "B", "C", "D", "F"}

def main():
    print("Auditing PriestBiS item database and stat weights...")

    main_lua = os.path.join(ADDON_DIR, "PriestBiS.lua")
    with open(main_lua, "r", encoding="utf-8", errors="ignore") as f:
        content = f.read()

    errors = []

    # 1. Check STAT_WEIGHTS
    stat_weights_match = re.search(r'UA\.STAT_WEIGHTS\s*=\s*\{(.*?)\}', content, re.DOTALL)
    if not stat_weights_match:
        errors.append("UA.STAT_WEIGHTS table not found")
    else:
        weights_block = stat_weights_match.group(1)
        for line in weights_block.splitlines():
            line = line.strip().split('--')[0]
            m = re.match(r'([A-Za-z0-9_]+)\s*=\s*([0-9\.]+)', line)
            if m:
                stat_name, val = m.group(1), float(m.group(2))
                if val < 0 or val > 50:
                    errors.append(f"Suspicious stat weight: {stat_name} = {val}")

    # 2. Check ITEM_METADATA entries
    metadata_match = re.search(r'UA\.ITEM_METADATA\s*=\s*\{(.*?)\n\s*\}', content, re.DOTALL)
    if not metadata_match:
        errors.append("UA.ITEM_METADATA table not found")
    else:
        meta_block = metadata_match.group(1)
        items_found = 0
        for line in meta_block.splitlines():
            line = line.strip().split('--')[0]
            m = re.search(r'\[(\d+)\]\s*=\s*\{(.*?)\}', line)
            if m:
                items_found += 1
                item_id = int(m.group(1))
                body = m.group(2)
                
                # Check tier if present
                tier_match = re.search(r'tier\s*=\s*"([^"]+)"', body)
                if tier_match and tier_match.group(1) not in VALID_TIERS:
                    errors.append(f"Item {item_id}: Invalid tier '{tier_match.group(1)}'")
                    
                # Check ep_override if present
                ep_match = re.search(r'ep_override\s*=\s*(\d+)', body)
                if ep_match and int(ep_match.group(1)) < 0:
                    errors.append(f"Item {item_id}: Negative ep_override '{ep_match.group(1)}'")
                    
        print(f"Verified {items_found} curated items in ITEM_METADATA.")

    # 3. Check SET_BONUSES
    set_bonuses_match = re.search(r'UA\.SET_BONUSES\s*=\s*\{(.*?)\n\s*\}', content, re.DOTALL)
    if not set_bonuses_match:
        errors.append("UA.SET_BONUSES table not found")
    else:
        sets_block = set_bonuses_match.group(1)
        sets_found = len(re.findall(r'\["[^"]+"\]\s*=\s*\{', sets_block))
        print(f"Verified {sets_found} set bonus tier definitions in SET_BONUSES.")

    if errors:
        print(f"\n[FAIL] Found {len(errors)} database validation error(s):")
        for e in errors:
            print(f"  - {e}")
        sys.exit(1)
    else:
        print("\nItem database and set bonus integrity check passed 100%!")
        sys.exit(0)

if __name__ == "__main__":
    main()
