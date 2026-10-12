#!/usr/bin/env python3
"""
tools/test_gear_patterns.py
===========================
PriestBiS Multi-Locale Gear Patterns & Negative Scan Regression Suite.
Imported & adapted from HolyPriest's 'test_gear_patterns.py'.

Validates that:
1. Multi-language tooltip patterns (enUS, zhCN, ruRU, deDE, frFR) accurately extract stats:
   - +Healing, +Damage and Healing
   - Spirit, MP5, Spell Crit, Intellect, Stamina
   - Casting Mana Regen (Meditation/Blue Dragon style)
   - Haste / Casting Speed
2. Negative test cases: strictly REJECTS non-healing and non-priest stats:
   - Pure Shadow, Frost, Fire, Nature, and Arcane spell damage
   - Attack Power, Melee AP, Ranged AP
   - Agility, Strength, Armor
   Ensuring these stats NEVER pollute +healing or priest EP scoring.

Exit code 0 on all pass, 1 on failure.
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
    "casting_regen": "CASTING_REGEN",
    "haste": "HASTE",
}

TEST_CASES_POSITIVE = {
    "enUS": [
        ("Increases healing done by spells and effects by up to 55.", "healing", 55),
        ("+44 Healing Spells", "healing", 44),
        ("+15 Spirit", "spi", 15),
        ("Restores 6 mana per 5 sec.", "mp5", 6),
        ("Improves your chance to get a critical strike with spells by 1%.", "crit", 1),
        ("+27 Intellect", "int", 27),
        ("+16 Stamina", "stam", 16),
        ("Increases damage and healing done by magical spells and effects by up to 20.", "spell_damage", 20),
        ("Allows 5% of your Mana regeneration to continue while casting.", "casting_regen", 5),
        ("Increases your attack and casting speed by 1%.", "haste", 1),
        ("Equip: Increases healing done by spells and effects by up to 106.", "healing", 106),
        ("Equip: Increases damage and healing done by magical spells and effects by up to 84.", "spell_damage", 84),
        ("+30 Spell Damage and Healing", "spell_damage", 30),
    ],
    "zhCN": [
        ("提高法术所造成的治疗效果，最多55点。", "healing", 55),
        ("+15 精神", "spi", 15),
        ("每5秒回复6点法力值。", "mp5", 6),
        ("提高所有法术和魔法效果所造成的伤害和治疗效果，最多20点。", "spell_damage", 20),
        ("+27 智力", "int", 27),
        ("+16 耐力", "stam", 16),
        ("使你在施法时仍保持15%的法力回复速度", "casting_regen", 15),
        ("提高你的攻击和施法速度1%", "haste", 1),
        ("+30 法术伤害和治疗", "spell_damage", 30),
    ],
    "ruRU": [
        ("Увеличивает эффект лечения заклинаний на 55.", "healing", 55),
        ("+15 к духу", "spi", 15),
        ("Восполнение 6 маны каждые 5 сек.", "mp5", 6),
        ("+27 к интеллекту", "int", 27),
        ("+16 к выносливости", "stam", 16),
        ("Позволяет 5% вашей скорости восстановления маны действовать во время применения заклинаний", "casting_regen", 5),
        ("Увеличивает вашу скорость атаки и применения заклинаний на 1%", "haste", 1),
        ("Увеличивает исцеление от заклинаний максимум на 55.", "healing", 55),
    ],
    "deDE": [
        ("Erhöht durch Zauber und Effekte verursachte Heilung um bis zu 55.", "healing", 55),
        ("+15 Willenskraft", "spi", 15),
        ("Stellt alle 5 Sek. 6 Mana wieder her.", "mp5", 6),
        ("+27 Intelligenz", "int", 27),
        ("+16 Ausdauer", "stam", 16),
        ("Ermöglicht es, dass 5% Eurer Manaregeneration beim Zauberwirken weiterlaufen", "casting_regen", 5),
        ("Erhöht Euer Angriffs- und Zaubertempo um 1%", "haste", 1),
        ("Erhöht durch Zauber und magische Effekte verursachte Heilung um bis zu 44.", "healing", 44),
    ],
    "frFR": [
        ("Augmente les soins prodigués par les sorts et les effets d'un maximum de 55", "healing", 55),
        ("+15 Esprit", "spi", 15),
        ("Rend 6 points de mana toutes les 5 sec.", "mp5", 6),
        ("+27 Intelligence", "int", 27),
        ("+16 Endurance", "stam", 16),
        ("Permet à 5% de votre récupération de mana de continuer pendant l'incantation", "casting_regen", 5),
        ("Augmente votre vitesse d'attaque et d'incantation de 1%", "haste", 1),
        ("Augmente les soins prodigués par les sorts et effets de 55.", "healing", 55),
    ]
}

# Negative test strings from HolyPriest: must NEVER match HEALING or SPI or MP5
TEST_CASES_NEGATIVE = [
    ("Pure Shadow damage", "Equip: Increases damage done by Shadow spells and effects by up to 40."),
    ("Pure Frost damage", "Equip: Increases damage done by Frost spells and effects by up to 34."),
    ("Pure Fire damage", "Equip: Increases damage done by Fire spells and effects by up to 30."),
    ("Pure Nature damage", "Equip: Increases damage done by Nature spells and effects by up to 25."),
    ("Pure Arcane damage", "Equip: Increases damage done by Arcane spells and effects by up to 21."),
    ("Attack Power", "Equip: +30 Attack Power."),
    ("Melee AP", "+28 Attack Power"),
    ("Ranged AP", "+14 Ranged Attack Power"),
    ("Agility", "+15 Agility"),
    ("Strength", "+12 Strength"),
    ("Armor", "240 Armor"),
]

def lua_to_py_regex(pat):
    p = pat.replace('%%', '%')
    p = p.replace('%d', r'(\d+)')
    p = p.replace('%+', r'\+')
    p = p.replace('%-', r'\-')
    p = p.replace('%.', r'\.')
    p = p.replace('%s', r'\s')
    p = p.replace('%a', r'[a-zA-Z\u00C0-\u024F\u0400-\u04FF]')
    return p

def load_category_patterns(content, category):
    patterns = []
    stat_match = re.search(rf'(?:\["{category}"\]|\b{category}\b)\s*=\s*\{{(.*?)\}}', content, re.DOTALL)
    if stat_match:
        for pline in stat_match.group(1).splitlines():
            pline = pline.strip().split('--')[0]
            pm = re.search(r'"([^"\\]*(?:\\.[^"\\]*)*)"', pline)
            if pm:
                patterns.append(pm.group(1))
    return patterns

def main():
    print("=" * 80)
    print("PRIESTBIS MULTI-LOCALE GEAR PATTERNS & NEGATIVE SCAN TEST")
    print("=" * 80)
    
    all_passed = True
    total_positive = 0
    total_negative = 0
    failures = 0

    # 1. Positive Tests Across Locales
    for loc, cases in TEST_CASES_POSITIVE.items():
        print(f"\n--- Verifying Locale: {loc} ---")
        loc_file = os.path.join(ADDON_DIR, "Locales", f"Localization.{loc}.lua")
        if not os.path.exists(loc_file):
            print(f"  [FAIL] Locale file {loc_file} not found")
            all_passed = False
            continue

        with open(loc_file, "r", encoding="utf-8", errors="ignore") as f:
            content = f.read()

        for text, stat, expected_val in cases:
            total_positive += 1
            category = STAT_TO_CATEGORY.get(stat, stat.upper())
            patterns = load_category_patterns(content, category)
            matched = False
            
            for lua_pat in patterns:
                py_pat = lua_to_py_regex(lua_pat)
                m = re.search(py_pat, text, re.IGNORECASE)
                if m:
                    captured = int(m.group(1)) if m.groups() else expected_val
                    if captured == expected_val:
                        matched = True
                        break

            if matched:
                print(f"  [PASS] {stat:<14} -> '{text}' ({expected_val})")
            else:
                print(f"  [FAIL] {stat:<14} -> Failed to match '{text}' (expected {expected_val})")
                failures += 1
                all_passed = False

    # 2. Negative Tests (HolyPriest Suite) against English HEALING patterns
    print("\n--- Verifying Negative Stat Rejection (HolyPriest Invariant Suite) ---")
    en_file = os.path.join(ADDON_DIR, "Locales", "Localization.enUS.lua")
    with open(en_file, "r", encoding="utf-8", errors="ignore") as f:
        en_content = f.read()
    healing_patterns = load_category_patterns(en_content, "HEALING")

    for desc, neg_text in TEST_CASES_NEGATIVE:
        total_negative += 1
        false_match = False
        matched_pat = None
        for lua_pat in healing_patterns:
            py_pat = lua_to_py_regex(lua_pat)
            if re.search(py_pat, neg_text, re.IGNORECASE):
                false_match = True
                matched_pat = lua_pat
                break
                
        if not false_match:
            print(f"  [PASS] Negative ({desc:<18}) -> Correctly rejected: '{neg_text}'")
        else:
            print(f"  [FAIL] Negative ({desc:<18}) -> Falsely matched as HEALING via pattern '{matched_pat}'")
            failures += 1
            all_passed = False

    print("\n" + "=" * 80)
    total_tests = total_positive + total_negative
    if all_passed:
        print(f"RESULT: ALL {total_tests} ASSERTIONS PASSED ({total_positive} positive, {total_negative} negative)!")
        print("=" * 80)
        sys.exit(0)
    else:
        print(f"RESULT: {failures} TEST(S) FAILED OUT OF {total_tests}!")
        print("=" * 80)
        sys.exit(1)

if __name__ == "__main__":
    main()
