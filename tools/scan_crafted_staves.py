import re

p = r'C:\Games\Interface\AddOns\AtlasLoot\Database\Crafting.lua'
with open(p, 'r', encoding='utf-8', errors='ignore') as fp:
    lines = fp.readlines()

crafted_weapons = []
for idx, line in enumerate(lines):
    if '#w9#' in line or '#w6#' in line or '#w4#' in line or 'Staff' in line or 'Rod' in line or 'Baton' in line:
        m = re.search(r'\{\s*"?([^\",]+)"?,\s*"[^"]*",\s*"=q\d+=([^"=]+)"', line)
        if m:
            item_id = m.group(1).replace('s', '')
            item_name = m.group(2)
            crafted_weapons.append((item_id, item_name, line.strip()))

print(f"Total crafted weapons found: {len(crafted_weapons)}")
for id, name, raw in crafted_weapons:
    print(f"[{id}] {name:<35} | {raw}")
