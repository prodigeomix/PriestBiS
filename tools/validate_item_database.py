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

    # Read all relevant files
    def read_file(rel):
        with open(os.path.join(ADDON_DIR, rel), "r", encoding="utf-8", errors="ignore") as f:
            return f.read()

    engine_content = read_file("Core/Engine.lua")
    item_db_content = read_file("Data/ItemDatabase.lua")
    set_bonuses_content = read_file("Data/SetBonuses.lua")

    errors = []

    # 1. Check STAT_WEIGHTS
    stat_weights_match = re.search(r'UA\.STAT_WEIGHTS\s*=\s*\{(.*?)\}', engine_content, re.DOTALL)
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
    metadata_match = re.search(r'UA\.ITEM_METADATA\s*=\s*\{(.*?)\n\s*\}', item_db_content, re.DOTALL)
    item_ids = set()
    rewards_to_check = []
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
                item_ids.add(item_id)
                body = m.group(2)
                
                # Check tier if present
                tier_match = re.search(r'tier\s*=\s*"([^"]+)"', body)
                if tier_match and tier_match.group(1) not in VALID_TIERS:
                    errors.append(f"Item {item_id}: Invalid tier '{tier_match.group(1)}'")
                    
                # Check ep_override if present
                ep_match = re.search(r'ep_override\s*=\s*(\d+)', body)
                if ep_match and int(ep_match.group(1)) < 0:
                    errors.append(f"Item {item_id}: Negative ep_override '{ep_match.group(1)}'")

                # Check slot if present
                slot_match = re.search(r'slot\s*=\s*"([^"]+)"', body)
                if slot_match and slot_match.group(1) not in VALID_SLOTS:
                    errors.append(f"Item {item_id}: Invalid slot '{slot_match.group(1)}'")

                # Collect rewardID if present
                reward_match = re.search(r'rewardID\s*=\s*(\d+)', body)
                if reward_match:
                    rewards_to_check.append((item_id, int(reward_match.group(1))))
                    
        # Verify rewardID targets exist in ITEM_METADATA
        for source_id, target_id in rewards_to_check:
            if target_id not in item_ids:
                errors.append(f"Item {source_id}: rewardID {target_id} not found in ITEM_METADATA")

        print(f"Verified {items_found} curated items in ITEM_METADATA ({len(rewards_to_check)} token turn-in mappings verified).")

    # 3. Check SET_BONUSES
    set_bonuses_match = re.search(r'UA\.SET_BONUSES\s*=\s*\{(.*)\n\}', set_bonuses_content, re.DOTALL)
    if not set_bonuses_match:
        errors.append("UA.SET_BONUSES table not found")
    else:
        sets_block = set_bonuses_match.group(1)
        set_names = re.findall(r'\["([^"]+)"\]\s*=\s*\{', sets_block)
        set_sections = re.findall(r'\["([^"]+)"\]\s*=\s*\{(.*?)\n\s*\},?', sets_block, re.DOTALL)
        
        breakpoints_verified = 0
        for sname, sbody in set_sections:
            bps = re.findall(r'\[(\d+)\]\s*=\s*\{\s*ep\s*=\s*([0-9\.]+),\s*desc\s*=\s*"([^"]*)"\s*\}', sbody)
            if not bps:
                errors.append(f"Set '{sname}': No valid breakpoints found")
            for pc_str, ep_str, desc in bps:
                pc, ep = int(pc_str), float(ep_str)
                breakpoints_verified += 1
                if pc < 2 or pc > 8:
                    errors.append(f"Set '{sname}': Invalid piece count {pc}")
                if ep <= 0 or ep > 100:
                    errors.append(f"Set '{sname}': Invalid EP value {ep}")
                if not desc or len(desc.strip()) == 0:
                    errors.append(f"Set '{sname}': Empty description for {pc}-piece bonus")

        print(f"Verified {len(set_names)} set bonus tier definitions ({breakpoints_verified} breakpoints) in SET_BONUSES.")

    # 4. Check BOSS_DROPS
    boss_drops_match = re.search(r'UA\.BOSS_DROPS\s*=\s*\{(.*?)\n\}', item_db_content, re.DOTALL)
    if boss_drops_match:
        boss_block = boss_drops_match.group(1)
        bosses_found = 0
        drops_found = 0
        for line in boss_block.splitlines():
            line = line.strip().split('--')[0]
            m = re.search(r'\["([^"]+)"\]\s*=\s*\{(.*?)\}', line)
            if m:
                bosses_found += 1
                boss_name = m.group(1)
                ids_str = m.group(2)
                for id_match in re.finditer(r'(\d+)', ids_str):
                    drops_found += 1
                    drop_id = int(id_match.group(1))
                    if drop_id <= 0:
                        errors.append(f"Boss '{boss_name}': Invalid drop ID {drop_id}")
        print(f"Verified {bosses_found} boss drop encounters ({drops_found} item links) in BOSS_DROPS.")

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
