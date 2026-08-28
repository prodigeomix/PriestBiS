upgrades = [
    {'slot': 'Ring 1', 'item': 'Rosewine Circle', 'dungeon': 'LBRS (Urok Doomhowl)', 'ep': 42.0, 'current': 13.0, 'set_penalty': 0, 'desc': '+29 Heal, +5 MP5, +9 Int'},
    {'slot': 'Boots', 'item': 'Boots of the Full Moon', 'dungeon': 'DM North (Captain Kromcrush)', 'ep': 53.0, 'current': 35.0, 'set_penalty': 0, 'desc': '+44 Heal, +12 Int, +9 Spi'},
    {'slot': 'Ring 1 (Alt)', 'item': 'Emerald Flame Ring', 'dungeon': 'DM West (Prince Tortheldrin)', 'ep': 29.5, 'current': 13.0, 'set_penalty': 0, 'desc': '+22 Heal, +12 Int, +7 Spi'},
    {'slot': 'Legs', 'item': 'Padre\'s Trousers', 'dungeon': 'DM West (Illyanna Ravenoak)', 'ep': 57.8, 'current': 39.0, 'set_penalty': 15, 'desc': '+42 Heal, +6 MP5, +12 Int (Breaks 3pc T1 -15 EP)'},
    {'slot': 'Belt', 'item': 'Whipvine Cord', 'dungeon': 'DM East (Alzzin the Wildshaper)', 'ep': 38.0, 'current': 26.0, 'set_penalty': 15, 'desc': '+31 Heal, +13 Int, +6 Spi (Breaks 3pc T1 -15 EP)'},
]

print(f"{'Slot':<12} | {'Item':<24} | {'Dungeon / Boss':<30} | {'Raw EP':<7} | {'Net Gain':<9} | Notes")
print("-" * 115)
for u in upgrades:
    net = u['ep'] - (u['current'] + u['set_penalty'])
    print(f"{u['slot']:<12} | {u['item']:<24} | {u['dungeon']:<30} | {u['ep']:>5.1f} EP | {net:>+7.1f} EP | {u['desc']}")
