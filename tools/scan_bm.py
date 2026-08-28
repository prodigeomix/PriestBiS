import re

# Item IDs from BM
bm_item_ids = [
    61018, # Cloak of Elemental Warding
    61019, # Wand of the Eclipse
    61015, # Hollowbone Choker
    61033, # Nightwind Leggings
    50431, # Extremely Well Crafted Cuffs
    61032, # Band of Infinite Possibilities
    61055, # Tome of Riftmancy
    61056, # Arcanoweave Boots
    61700, # Fabric of Time (Trinket)
    50430, # Magic-infused Cloak
    61022, # Dagger of the Currents
    61051, # Blackthorn Band
    61059, # Mossheart's Heart
    61061, # Regenerating Robe
    61025, # Pyreflame Lantern
    61029, # Crocolisk Tooth Necklace
    61030, # The Murkfisher
    61034, # Band of the Marsh Bog
    61701, # Wraps of the Transmogrified
    61031, # Riftweaver
    61027, # Epaulets of the Forgotten Past
    61040, # Gloves of the Unknown
    61043, # Eye of the Abyss
    61039, # Timeless Artificier's Optics
]

print(f"Inspecting {len(bm_item_ids)} candidate items from Black Morass...")

# Let's search AtlasLoot or pfQuest for tooltips/stats of these items
with open(r'C:\Games\Interface\AddOns\AtlasLoot\Database\TooltipStrings.lua', 'r', encoding='utf-8', errors='ignore') as fp:
    tooltip_content = fp.read()

# Let's search pfQuest items-turtle
with open(r'C:\Games\Interface\AddOns\pfQuest-turtle\db\enUS\items-turtle.lua', 'r', encoding='utf-8', errors='ignore') as fp:
    names_content = fp.read()

for item_id in bm_item_ids:
    name_match = re.search(rf'\[{item_id}\]\s*=\s*"([^"]+)"', names_content)
    name = name_match.group(1) if name_match else f"Item {item_id}"
    print(f"[{item_id}] {name}")
