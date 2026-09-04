-- Data/ItemDatabase.lua
-- Curated item metadata, boss drop mappings, and drop sources for PriestBiS.
-- Author: prodigeomix (Carbon)
-- Strict Lua 5.0 Compliance

local _G = _G or getfenv(0)
local PriestBiS = PriestBiS or _G.PriestBiS or {}
local UA = PriestBiS.UA or PriestBiS
PriestBiS.UA = UA
_G.PriestBiS = PriestBiS
_G.UA = UA

-- ================================================
-- 1. CURATED ITEM METADATA (Trinkets & Special Drops)
-- ================================================

UA.ITEM_METADATA = {
    -- === TRINKETS (Curated with Tier, Role and On-Use EP Overrides) ===
    [19958] = { name = "Hazza'rah's Charm of Healing", role = "HEAL", tier = "S", ep_override = 120, drop = "ZG: Edge of Madness (14%)", priority = 1, note = "BiS: -40% Greater Heal cast time & -5% mana cost for 15s" },
    [19950] = { name = "Zandalarian Hero Charm", role = "HEAL", tier = "S", ep_override = 90, slot = "Trinket", drop = "ZG: Hakkar (Heart quest turn-in)", priority = 2, note = "BiS burst trinket: +204 Heal/Dmg decaying by 17 per cast for 20s (2m CD)" },
    [19802] = { name = "Heart of Hakkar", role = "HEAL", tier = "S", ep_override = 90, slot = "Trinket", rewardID = 19950, drop = "ZG: Hakkar (100%)", priority = 1, note = "Quest: Turn in on Yojamba Isle for Zandalarian Hero Charm" },
    [19288] = { name = "Darkmoon Card: Blue Dragon", role = "HEAL", tier = "S", ep_override = 90, slot = "Trinket", drop = "Darkmoon Faire: Beasts Deck", priority = 2, note = "BiS sustain: 2% chance on cast for 100% mana regen while casting for 15s" },
    [23047] = { name = "Eye of the Dead", role = "HEAL", tier = "S", ep_override = 130, slot = "Trinket", drop = "Naxxramas: Sapphiron (20%)", priority = 1, note = "BiS Naxx: On-use +450 healing decaying & -30 mana cost for 40s (2m CD)" },
    [21625] = { name = "Scarab Brooch", role = "HEAL", tier = "A", ep_override = 80, slot = "Trinket", drop = "AQ40: Viscidus (20%)", priority = 3, note = "On-use: Direct heals grant damage shield for 17.5% of heal for 30s (3m CD)" },
    [19930] = { name = "Mar'li's Eye", role = "HEAL", tier = "B", ep_override = 45, slot = "Trinket", drop = "ZG: High Priestess Mar'li (17%)", priority = 15, note = "On-use: +150 Healing decaying by 30 every 6s for 30s (3m CD)" },
    [18820] = { name = "Talisman of Ephemeral Power", role = "HEAL", tier = "A", ep_override = 70, slot = "Trinket", drop = "MC: Boss shared (4%)", priority = 5, note = "On-use: +175 Spell Damage and Healing for 15s (90s CD)" },
    [17064] = { name = "Shard of the Scale", role = "HEAL", tier = "A", ep_override = 85, slot = "Trinket", drop = "Quest: Head of Onyxia turn-in", priority = 2, note = "Exceptional mana sustain: +16 MP5 passive" },
    [19002] = { name = "Head of Onyxia", role = "HEAL", tier = "A", ep_override = 85, slot = "Trinket", rewardID = 17064, drop = "Onyxia's Lair: Onyxia (100%)", priority = 1, note = "Quest: Turn in for Shard of the Scale (+16 MP5 trinket)" },
    [19382] = { name = "Pure Elementium Band", role = "HEAL", tier = "S", ep_override = 74, slot = "Ring", drop = "Quest: Head of Nefarian turn-in", priority = 1, note = "BiS BWL ring: +33 Heal, +9 Int, +10 Spi, +10 Stam" },
    [19003] = { name = "Head of Nefarian", role = "HEAL", tier = "S", ep_override = 74, slot = "Ring", rewardID = 19382, drop = "BWL: Nefarian (100%)", priority = 1, note = "Quest: Turn in for Pure Elementium Band (+33 Heal, +9 Int, +10 Spi)" },
    [18608] = { name = "Benediction", role = "HEAL", tier = "S", ep_override = 215, slot = "Twohand", drop = "Priest Epic Quest (Eye of Divinity)", priority = 1, note = "Iconic Priest 2H: +106 Heal, +31 Int, +12 Spi, +2% Crit" },
    [18646] = { name = "The Eye of Divinity", role = "HEAL", tier = "S", ep_override = 215, slot = "Twohand", rewardID = 18608, drop = "MC: Majordomo Executus (Cache of the Firelord, 50%)", priority = 1, note = "Quest: Combines with Eye of Shadow to forge Benediction (215 EP)" },
    [19395] = { name = "Rejuvenating Gem", role = "HEAL", tier = "S", ep_override = 105, drop = "BWL: Ebonroc/Firemaw/Flamegor", priority = 1, note = "BiS: +66 Healing & +9 MP5 stat stick" },
    [19345] = { name = "Aegis of Preservation", role = "HEAL", tier = "B", ep_override = 45, drop = "BWL: Razorgore (11%)", priority = 42, note = "Defense + on-equip mana proc" },
    [58231] = { name = "Penchant of Humility", role = "HEAL", tier = "A", ep_override = 65, drop = "Custom Turtle Item", priority = 20, note = "Solid +healing & MP5 trinket" },
    [61700] = { name = "Fabric of Time", role = "HEAL", tier = "A", ep_override = 70, drop = "Custom Turtle Item", priority = 20, note = "Strong +healing trinket" },
    [61451] = { name = "Sliver of Hope", role = "HEAL", tier = "S", ep_override = 60, drop = "LKH: Clawlord Howlfang (14%)", priority = 5, note = "Top pre-Naxx sustain trinket (+44 Heal, +7 MP5)" },
    [55124] = { name = "Pure Jewel of Draenor", role = "HEAL", tier = "B", ep_override = 40, drop = "UKH: Rupturan (14%)", priority = 49, note = "Meta gem trinket" },
    [19406] = { name = "Drake Fang Talisman", role = "MELEE", tier = "F", ep_override = 0, drop = "BWL: Ebonroc (17%)", priority = 99, note = "Melee AP/Hit - not for priest" },
    [55353] = { name = "Remains of Overwhelming Power", role = "MELEE", tier = "F", ep_override = 0, drop = "UKH: Anomalus (25%)", priority = 99, note = "Melee AP - not for priest" },
    [55275] = { name = "Slivers of Nullification", role = "TANK", tier = "F", ep_override = 0, drop = "UKH: Trash (0.25%)", priority = 99, note = "Tank trinket - not for priest" },

    -- === ZUL'GURUB GEAR (Drop & Note Annotations) ===
    [19890] = { drop = "ZG: Jin'do the Hexxer (8%)", priority = 1, note = "BiS Phase 4 1H healing mace (+51 Heal, +1% Crit, +9 Int)" },
    [19884] = { drop = "ZG: Jin'do the Hexxer (14%)", priority = 5, note = "Top caster/healer offhand (+18 Heal/Dmg, +1% Crit, +11 Int, +6 Spi)" },
    [19885] = { drop = "ZG: Jin'do the Hexxer (17%)", priority = 6, note = "Epic healing neck (+44 Heal, +5 Int, +6 Spi, +11 Stam)" },
    [20032] = { drop = "ZG: High Priestess Mar'li (17%)", priority = 2, note = "Epic cloth chest" },
    [19841] = { drop = "ZG: Primal Hakkari Shawl token", priority = 3, note = "Epic T0.5 shoulder" },
    [19842] = { drop = "ZG: Primal Hakkari Sash token", priority = 4, note = "Epic T0.5 belt" },
    [19843] = { drop = "ZG: Primal Hakkari Stanchion token", priority = 5, note = "Rare T0.5 bracers" },
    [19594] = { drop = "ZG: Class set exchange", priority = 6, note = "Epic neck with unique proc" },
    [19927] = { drop = "ZG: Mar'li (17%)", priority = 7, note = "Epic wand" },
    [19967] = { drop = "ZG: Hazzarah (45%)", priority = 8, note = "Rare wand" },
    [19861] = { drop = "ZG: Hakkar (14%)", priority = 9, note = "Epic wand" },
    [22721] = { drop = "ZG: Shared (10%)", priority = 10, note = "Epic ring" },
    [22720] = { drop = "ZG: Shared (10%)", priority = 11, note = "Rare headpiece" },
    [22722] = { role = "MELEE", drop = "ZG: Shared (10%)", priority = 99, note = "Melee ring" },
    [22711] = { drop = "ZG: Shared (10%)", priority = 11, note = "Rare cloak" },
    [13932] = { drop = "ZG: Shared (10%)", priority = 12, note = "Rare cloak" },
    [19897] = { drop = "ZG: Renataki (14%)", priority = 25, note = "Epic cloth boots" },
    [19908] = { drop = "ZG: Trash (0.03%)", priority = 49, note = "Rare 1H healing mace" },
    [20258] = { drop = "ZG: Trash (0.03%)", priority = 49, note = "Rare 2H staff" },

    -- === UPPER / LOWER KARAZHAN (Turtle WoW Drop & Note Annotations) ===
    [55274] = { drop = "UKH: King (13%)", priority = 15, note = "Epic cloak" },
    [55084] = { drop = "UKH: Gnarlmoon (25%)", priority = 14, note = "Epic cloak" },
    [55276] = { drop = "UKH: King (25%)", priority = 49, note = "Epic 1H mace" },
    [61210] = { drop = "UKH: Echo (17%)", priority = 16, note = "Epic cloak" },
    [55081] = { drop = "UKH: Gnarlmoon (25%)", priority = 17, note = "Epic cloth legs" },
    [55278] = { drop = "ZG: Arlokk (20%)", priority = 18, note = "Epic cloth legs" },
    [55279] = { drop = "UKH: Rolfen (10%)", priority = 19, note = "Epic cloth legs" },
    [55106] = { drop = "UKH: Mephistroth (8%)", priority = 20, note = "Epic cloth gloves" },
    [55107] = { drop = "UKH: Gnarlmoon (25%)", priority = 21, note = "Epic cloth gloves" },
    [55285] = { drop = "UKH: Grizikil (25%)", priority = 22, note = "Epic cloth gloves" },
    [21462] = { drop = "AQ20: Ossirian (15%)", priority = 23, note = "Rare cloth gloves" },
    [55110] = { drop = "UKH: Incantagos (25%)", priority = 24, note = "Epic cloth boots" },
    [55123] = { role = "TANK", drop = "UKH: Rupturan (14%)", priority = 99, note = "Tank ring" },
    [55100] = { drop = "UKH: King (8%)", priority = 27, note = "Epic ring" },
    [55094] = { drop = "UKH: Gnarlmoon (25%)", priority = 28, note = "Epic ring" },
    [55103] = { drop = "UKH: King (13%)", priority = 29, note = "Epic ring" },
    [55511] = { drop = "UKH: Kruul (11%)", priority = 32, note = "Epic wand" },
    [58137] = { drop = "UKH: Rupturan", priority = 33, note = "Rare wand" },
    [55284] = { drop = "UKH: Trash (0.25%)", priority = 49, note = "Epic cloth belt" },
    [55286] = { drop = "UKH: Trash (0.25%)", priority = 49, note = "Epic spirit ring" },
    [61254] = { drop = "LKH: Trash (0.15%)", priority = 49, note = "Rare cloth belt" },
    [61288] = { drop = "LKH: Trash (0.15%)", priority = 49, note = "Rare cloth belt" },

    -- === BLACKWING LAIR (Transcendence T2 Set Annotations) ===
    [16926] = { drop = "BWL: Razorgore (11%)", priority = 34, note = "T2 wrists - epic" },
    [16925] = { drop = "BWL: Vaelastrasz (11%)", priority = 35, note = "T2 belt - epic" },
    [16919] = { drop = "BWL: Broodlord Lashlayer (11%)", priority = 36, note = "T2 boots - epic" },
    [16920] = { drop = "BWL: Firemaw/Ebonroc (7%)", priority = 37, note = "T2 gloves - epic" },
    [16918] = { drop = "BWL: Nefarian (7%)", priority = 39, note = "T2 helm - epic" },
    [16922] = { drop = "BWL: Nefarian (7%)", priority = 41, note = "T2 legs - epic" },
    [16923] = { drop = "BWL: Nefarian (7%)", priority = 40, note = "T2 chest - epic" },
    [16921] = { drop = "BWL: Chromaggus (7%)", priority = 38, note = "T2 shoulders - epic" },
    [19398] = { drop = "BWL: Firemaw (13%)", priority = 45, note = "Epic cloak" },
    [19403] = { drop = "BWL: Ebonroc (17%)", priority = 47, note = "Epic ring (+1% crit)" },
    [19355] = { drop = "BWL: Ebonroc/Firemaw", priority = 48, note = "Epic staff" },
    [19434] = { role = "CASTER_DPS", drop = "BWL: Trash (2%)", priority = 49, note = "Shadow ring" },
    [19435] = { drop = "BWL: Trash (2%)", priority = 49, note = "Epic wand" },
    [19437] = { drop = "BWL: Trash (4%)", priority = 49, note = "Epic cloth boots" },
    [19438] = { drop = "BWL: Trash (5%)", priority = 49, note = "Epic cloth boots" },
    [19145] = { drop = "BWL: Nefarian's Tear table", priority = 49, note = "Epic cloth chest (+1% crit)" },
    [18872] = { drop = "BWL: Nefarian's Tear table", priority = 49, note = "Epic cloth legs (+14 MP5)" },

    -- === MOLTEN CORE (Vestments of Prophecy T1 Annotations) ===
    [16817] = { drop = "MC: Trash (0.3%)", priority = 49, note = "Epic T1 belt" },
    [16819] = { drop = "MC: Trash (0.3%)", priority = 49, note = "Epic T1 bracers" },
    [81261] = { drop = "MC: Trash (0.2%)", priority = 49, note = "Epic cloth boots" },
    [16812] = { drop = "MC: Incindus/Gehennas", priority = 33, note = "Epic T1 gloves" },
    [16813] = { drop = "MC: Garr (20%)", priority = 33, note = "Epic T1 helm" },
    [16814] = { drop = "MC: Magmadar (20%)", priority = 33, note = "Epic T1 legs" },
    [16815] = { drop = "MC: Golemagg (25%)", priority = 33, note = "Epic T1 chest" },
    [16816] = { drop = "MC: Sulfuron (33%)", priority = 33, note = "Epic T1 shoulders" },
    [16811] = { drop = "MC: Shazzrah (25%)", priority = 33, note = "Epic T1 boots" },

    -- === OTHER NOTABLE RAID / DUNGEON GEAR ===
    [19132] = { drop = "World: Azuregos (10%)", priority = 2, note = "Epic helm - high +heal" },
    [18723] = { drop = "Strat: Ramstein", priority = 5, note = "Epic neck" },
    [19820] = { drop = "Strat: Archivist Galford", priority = 10, note = "Epic healing offhand" },
    [22406] = { drop = "Scholomance / Dungeon Quest", priority = 10, note = "Rare 2H healing staff (+55 Heal, +15 Int, +15 Spi)" },
    [18510] = { drop = "Crafted / Leatherworking", priority = 5, note = "Epic healing cloak" },
    [13346] = { drop = "Strat: Baron Rivendare", priority = 10, note = "Top pre-raid healing chest" },
    [22247] = { drop = "Dungeon drop", priority = 15, note = "Healing boots" },
    [51047] = { drop = "Turtle Custom Dungeon", priority = 10, note = "High +heal shoulders" },
    [61004] = { drop = "Turtle Custom Item", priority = 15, note = "Healing ring" },
}

-- Backward compatibility alias
UA.UPGRADE_DATABASE = UA.ITEM_METADATA

-- Boss drops mapping for proactive warnings
UA.BOSS_DROPS = {
    ["High Priestess Mar'li"] = { 20032, 19958, 19927, 19930 },
    ["High Priest Venoxis"] = { 19958 },
    ["High Priest Thekal"] = { 19958 },
    ["High Priestess Jeklik"] = { 19958 },
    ["Bloodlord Mandokir"] = { 19841, 19842, 19843 },
    ["Arlokk"] = { 19841, 19842, 19843, 55278 },
    ["Renataki"] = { 19897 },
    ["Jin'do the Hexxer"] = { 19890, 19884, 19885, 19958 },
    ["Jin'do"] = { 19890, 19884, 19885, 19958 },
    ["Gri'lek"] = { 22721 },
    ["Hazza'rah"] = { 19967, 22721 },
    ["Wushoolay"] = { 22721 },
    ["Hakkar"] = { 19802, 19950, 19861, 13932, 22721 },
    ["Edge of Madness"] = { 19958 },

    ["Lucifron"] = { 16817 },
    ["Gehennas"] = { 16819, 16816, 18820 },
    ["Garr"] = { 16813, 16811, 18820 },
    ["Shazzrah"] = { 16811, 18820 },
    ["Sulfuron"] = { 16816 },
    ["Golemagg"] = { 16815 },
    ["Magmadar"] = { 16814, 18820 },
    ["Majordomo Executus"] = { 18646 },

    ["Onyxia"] = { 19002 },

    ["Lord Blackwald II"] = { 55274 },
    ["Clawlord Howlfang"] = { 61451, 61281 },
    ["Gnarlmoon"] = { 55081, 55084, 55107, 55094 },
    ["King"] = { 55276, 55274, 55103, 55100 },
    ["Echo"] = { 61210 },
    ["Mephistroth"] = { 55106 },
    ["Grizikil"] = { 55285 },
    ["Rolfen"] = { 55279 },
    ["Rupturan"] = { 55123, 55124, 58137 },
    ["Incantagos"] = { 55110 },
    ["Kruul"] = { 55511 },

    ["Razorgore"] = { 16926, 19345 },
    ["Vaelastrasz"] = { 16925 },
    ["Broodlord Lashlayer"] = { 16919, 16921 },
    ["Firemaw"] = { 16920, 19398, 19355, 19395 },
    ["Ebonroc"] = { 16920, 19345, 19403, 19395 },
    ["Flamegor"] = { 16920, 19345, 19403, 19395 },
    ["Chromaggus"] = { 16921 },
    ["Nefarian"] = { 16922, 16923, 16918, 19003 },

    ["Viscidus"] = { 21625 },
    ["Sapphiron"] = { 23047 },
}
