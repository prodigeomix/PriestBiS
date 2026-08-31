#!/usr/bin/env python3
"""
tools/test_gear_patterns.py
===========================
Validates multi-language tooltip regex patterns (enUS, zhCN, ruRU, deDE, frFR)
for PriestBiS across Locales/Localization.<locale>.lua against test tooltip strings.
"""

import os
import re
import sys

if sys.platform == "win32":
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
ADDON_DIR = os.path.abspath(os.path.join(SCRIPT_DIR, ".."))

STAT_TO_CATEGORY = {
    "healing": "HEALING",
    "spell_damage": "DAMAGE_HEALING",
    "int": "INT",
    "spi": "SPI",
    "stam": "STAM",
    "mp5": "MP5",
    "crit": "CRIT",
}

TEST_CASES = {
    "enUS": [
        ("Increases healing done by spells and effects by up to 55.", "healing", 55),
        ("+44 Healing Spells", "healing", 44),
        ("+15 Spirit", "spi", 15),
        ("Restores 6 mana per 5 sec.", "mp5", 6),
        ("Improves your chance to get a critical strike with spells by 1%.", "crit", 1),
        ("+27 Intellect", "int", 27),
        ("+16 Stamina", "stam", 16),
        ("Increases damage and healing done by magical spells and effects by up to 20.", "spell_damage", 20),
    ],
    "zhCN": [
        ("提高法术所造成的治疗效果，最多55点。", "healing", 55),
        ("+15 精神", "spi", 15),
        ("每5秒回复6点法力值。", "mp5", 6),
        ("提高所有法术和魔法效果所造成的伤害和治疗效果，最多20点。", "spell_damage", 20),
        ("+27 智力", "int", 27),
        ("+16 耐力", "stam", 16),
    ],
    "ruRU": [
        ("Увеличивает эффект лечения заклинаний на 55.", "healing", 55),
        ("+15 к духу", "spi", 15),
        ("Восполнение 6 маны каждые 5 сек.", "mp5", 6),
        ("+27 к интеллекту", "int", 27),
        ("+16 к выносливости", "stam", 16),
    ],
    "deDE": [
        ("Erhöht durch Zauber und Effekte verursachte Heilung um bis zu 55.", "healing", 55),
        ("+15 Willenskraft", "spi", 15),
        ("Stellt alle 5 Sek. 6 Mana wieder her.", "mp5", 6),
        ("+27 Intelligenz", "int", 27),
        ("+16 Ausdauer", "stam", 16),
    ],
    "frFR": [
        ("Augmente les soins prodigués par les sorts et les effets d'un maximum de 55", "healing", 55),
        ("+15 Esprit", "spi", 15),
        ("Rend 6 points de mana toutes les 5 sec.", "mp5", 6),
        ("+27 Intelligence", "int", 27),
        ("+16 Endurance", "stam", 16),
    ]
}

def lua_to_py_regex(pat):
    p = pat.replace('%%', '%')
    p = p.replace('%d', r'(\d+)')
    p = p.replace('%+', r'\+')
    p = p.replace('%-', r'\-')
    p = p.replace('%.', r'\.')
    p = p.replace('%s', r'\s')
    p = p.replace('%a', r'[a-zA-Z\u00C0-\u024F\u0400-\u04FF]')
    return p

def main():
    print("Testing PriestBiS multi-language regex patterns...")
    all_passed = True
    total_tested = 0

    for loc, cases in TEST_CASES.items():
        print(f"\nVerifying locale: {loc}")
        loc_file = os.path.join(ADDON_DIR, "Locales", f"Localization.{loc}.lua")
        if not os.path.exists(loc_file):
            print(f"  [FAIL] Locale file {loc_file} not found")
            all_passed = False
            continue

        with open(loc_file, "r", encoding="utf-8", errors="ignore") as f:
            content = f.read()

        for text, stat, expected_val in cases:
            total_tested += 1
            category = STAT_TO_CATEGORY.get(stat, stat.upper())
            matched = False
            
            stat_match = re.search(rf'(?:\["{category}"\]|\b{category}\b)\s*=\s*\{{(.*?)\}}', content, re.DOTALL)
            if stat_match:
                pat_lines = stat_match.group(1).splitlines()
                for pline in pat_lines:
                    pline = pline.strip().split('--')[0]
                    pm = re.search(r'"([^"\\]*(?:\\.[^"\\]*)*)"', pline)
                    if pm:
                        lua_pat = pm.group(1)
                        py_pat = lua_to_py_regex(lua_pat)
                        m = re.search(py_pat, text, re.IGNORECASE)
                        if m:
                            captured = int(m.group(1)) if m.groups() else expected_val
                            if captured == expected_val:
                                matched = True
                                break
                                
            if matched:
                print(f"  [PASS] {stat:<12} -> '{text}' ({expected_val})")
            else:
                print(f"  [FAIL] {stat:<12} -> Failed to match '{text}' (expected {expected_val})")
                all_passed = False

    print("\n" + "=" * 60)
    if all_passed:
        print(f"All {total_tested} multi-locale gear pattern tests passed successfully!")
        sys.exit(0)
    else:
        print("Gear pattern tests failed!")
        sys.exit(1)

if __name__ == "__main__":
    main()
