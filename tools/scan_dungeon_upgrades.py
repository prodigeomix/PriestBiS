import re

target_items = [
    "Hands of the Exalted",
    "Padre's Trousers",
    "Whipvine Cord",
    "Boots of the Full Moon",
    "Rosewine Circle",
    "Brightly Glowing Stone",
    "Tome of Divine Right",
    "Sublime Wristguards",
    "Emerald Flame Ring",
    "Bonecreeper Stylus"
]

p = r'C:\Games\Interface\AddOns\AtlasLoot\Database\Instances.lua'
with open(p, 'r', encoding='utf-8', errors='ignore') as fp:
    lines = fp.readlines()

for target in target_items:
    found = False
    for idx, line in enumerate(lines):
        if target in line:
            boss = 'Unknown'
            for j in range(idx, max(0, idx-50), -1):
                m = re.match(r'^\s*([A-Za-z0-9_]+)\s*=\s*\{', lines[j])
                if m:
                    boss = m.group(1)
                    break
            print(f'{target} -> Boss Table: {boss} | Line: {line.strip()}')
            found = True
            break
