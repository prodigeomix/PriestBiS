import re

p = r'C:\Games\Interface\AddOns\AtlasLoot\Database\Instances.lua'
with open(p, 'r', encoding='utf-8', errors='ignore') as fp:
    content = fp.read()

for match in re.finditer(r'(LKH\w+)\s*=\s*\{([^}]+)\}', content):
    boss = match.group(1)
    body = match.group(2)
    print(f'=== {boss} ===')
    for line in body.split('\n'):
        item_match = re.search(r'\{\s*(\d+),\s*"[^"]*",\s*"=q\d+=([^"]+)",\s*"([^"]*)"', line)
        if item_match:
            item_id = int(item_match.group(1))
            item_name = item_match.group(2)
            slot_info = item_match.group(3)
            print(f'  [{item_id}] {item_name} ({slot_info})')
