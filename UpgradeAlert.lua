-- UpgradeAlert.lua
-- Alerts when items dropped in Raids/Dungeons are upgrades for Holy Priest
-- Author: Carbon (Optimized for Vanilla 1.12.1 / Turtle WoW 1.18.1)
-- Strict Lua 5.0 Compliance

local UA = {}
_G.UA = UA

local format = string.format
local tostring = tostring
local tonumber = tonumber
local getglobal = getglobal or function(name) return _G[name] end

-- ================================================
-- 1. COMPATIBILITY SHIM & LOGGING (Vanilla 1.12.1)
-- ================================================

local function UA_Print(msg)
    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[UpgradeAlert]|r " .. tostring(msg))
    end
end
UA.Print = UA_Print

-- Global print fallback for 1.12.1 if missing
if not _G.print then
    _G.print = function(...)
        local out = ""
        for i = 1, table.getn(arg) do
            out = out .. (i > 1 and " " or "") .. tostring(arg[i])
        end
        if DEFAULT_CHAT_FRAME then
            DEFAULT_CHAT_FRAME:AddMessage(out)
        end
    end
end

-- ================================================
-- 2. STAT WEIGHTS & EQUIVALENCE POINTS (EP)
-- ================================================

-- Holy Priest Stat Weights for Turtle WoW 1.18.1
-- Note: PoH has 0.0 +healing coefficient on Turtle 1.18.1.
-- Holy Priests rely on Flash Heal, Greater Heal R1, Heal R2-4, and Renew.
-- Spiritual Guidance converts 25% of Spirit into +Healing.
-- Meditation grants 15% mana regen while casting.
UA.STAT_WEIGHTS = {
    healing = 1.0,         -- Baseline throughput
    spi = 0.70,            -- 0.25 (Spiritual Guidance) + 0.45 (Meditation FSR regen)
    mp5 = 2.20,            -- 1 MP5 = 12 mana/min (~2.2 EP)
    spell_crit = 8.0,      -- 1% Crit = 8.0 EP (Inspiration armor buff uptime + throughput)
    int = 0.22,            -- Mana pool buffer + crit scaling
    spell_damage = 0.0,    -- Pure shadow/spell damage provides 0 value for Holy
    stamina = 0.05,        -- Small survivability buffer
    armor = 0.0,
}

-- Slot ID mappings for Vanilla 1.12.1 inventory
UA.SLOT_IDS = {
    Head = 1, Neck = 2, Shoulder = 3, Shirt = 4, Chest = 5,
    Belt = 6, Legs = 7, Boots = 8, Wrists = 9, Hands = 10,
    Ring1 = 11, Ring2 = 12, Trinket1 = 13, Trinket2 = 14,
    Back = 15, Mainhand = 16, Offhand = 17, Ranged = 18, Wand = 18, Tabard = 19
}

-- Ordered slot list for character sheet display
UA.GEAR_DISPLAY_ORDER = {
    "Head", "Neck", "Shoulder", "Back", "Chest", "Wrists", "Hands",
    "Belt", "Legs", "Boots", "Ring1", "Ring2", "Trinket1", "Trinket2",
    "Mainhand", "Offhand", "Wand"
}

-- Fallback baseline gear snapshot (Carbon - Holy Priest)
UA.CURRENT_GEAR = {
    Head     = { id = 19132, name = "Crystal Adorned Crown" },
    Neck     = { id = 18723, name = "Animated Chain Necklace" },
    Shoulder = { id = 51047, name = "Sacrosanct Epaulets" },
    Chest    = { id = 13346, name = "Robes of the Exalted" },
    Belt     = { id = 16817, name = "Girdle of Prophecy" },
    Legs     = { id = 16814, name = "Pants of Prophecy" },
    Boots    = { id = 22247, name = "Faith Healer's Boots" },
    Wrists   = { id = 16819, name = "Vambraces of Prophecy" },
    Hands    = { id = 16812, name = "Gloves of Prophecy" },
    Ring1    = { id = 61004, name = "Sandswept Ring of Arcanum" },
    Ring2    = { id = 55286, name = "Ring of Holy Light" },
    Trinket1 = { id = 58231, name = "Penchant of Humility" },
    Trinket2 = { id = 61700, name = "Fabric of Time" },
    Back     = { id = 18510, name = "Hide of the Wild" },
    Mainhand = { id = 22406, name = "Redemption" },
    Offhand  = { id = 19820, name = "Consecrated Caduceus" },
    Wand     = { id = 19927, name = "Mar'li's Touch" },
}

-- ================================================
-- 3. CURATED UPGRADE DATABASE & SPECIAL OVERRIDES
-- ================================================

-- Curated item metadata (special procs, drop locations, on-use EP overrides)
UA.UPGRADE_DATABASE = {
    -- === TRINKETS (Curated with Tier and Role) ===
    [19958] = { name = "Hazza'rah's Charm of Healing", slot = "Trinket", role = "HEAL", tier = "S", ep_override = 120, healing = 0, spi = 0, int = 0, mp5 = 0, crit = 0, drop = "ZG: Edge of Madness (14%)", priority = 1, note = "BiS: -40% Greater Heal cast time & -5% mana cost for 15s" },
    [19395] = { name = "Rejuvenating Gem", slot = "Trinket", role = "HEAL", tier = "S", ep_override = 105, healing = 66, spi = 0, int = 0, mp5 = 9, crit = 0, drop = "BWL: Ebonroc/Firemaw/Flamegor", priority = 1, note = "BiS: +66 Healing & +9 MP5 stat stick" },
    [19345] = { name = "Aegis of Preservation", slot = "Trinket", role = "HEAL", tier = "B", ep_override = 45, healing = 0, spi = 0, int = 0, mp5 = 0, crit = 0, drop = "BWL: Razorgore (11%)", priority = 42, note = "Defense + on-equip mana proc" },
    [58231] = { name = "Penchant of Humility", slot = "Trinket", role = "HEAL", tier = "A", ep_override = 65, healing = 22, spi = 12, int = 0, mp5 = 6, crit = 0, drop = "Custom Turtle Item", priority = 20, note = "Solid +healing & MP5 trinket" },
    [61700] = { name = "Fabric of Time", slot = "Trinket", role = "HEAL", tier = "A", ep_override = 70, healing = 33, spi = 0, int = 15, mp5 = 4, crit = 0, drop = "Custom Turtle Item", priority = 20, note = "Strong +healing trinket" },
    [55124] = { name = "Pure Jewel of Draenor", slot = "Trinket", role = "HEAL", tier = "B", ep_override = 40, healing = 0, spi = 0, int = 0, mp5 = 0, crit = 0, drop = "UKH: Rupturan (14%)", priority = 49, note = "Meta gem trinket" },
    [19406] = { name = "Drake Fang Talisman", slot = "Trinket", role = "MELEE", tier = "F", ep_override = 0, healing = 0, spi = 0, int = 0, mp5 = 0, crit = 0, drop = "BWL: Ebonroc (17%)", priority = 99, note = "Melee AP/Hit - not for priest" },
    [55353] = { name = "Remains of Overwhelming Power", slot = "Trinket", role = "MELEE", tier = "F", ep_override = 0, healing = 0, spi = 0, int = 0, mp5 = 0, crit = 0, drop = "UKH: Anomalus (25%)", priority = 99, note = "Melee AP - not for priest" },
    [55275] = { name = "Slivers of Nullification", slot = "Trinket", role = "TANK", tier = "F", ep_override = 0, healing = 0, spi = 0, int = 0, mp5 = 0, crit = 0, drop = "UKH: Trash (0.25%)", priority = 99, note = "Tank trinket - not for priest" },

    -- === ZUL'GURUB GEAR ===
    [20032] = { name = "Flowing Ritual Robes", slot = "Chest", healing = 22, int = 23, spi = 24, stam = 15, mp5 = 0, crit = 0, drop = "ZG: High Priestess Mar'li (17%)", priority = 2, note = "Epic cloth chest" },
    [19841] = { name = "Zandalar Confessor's Mantle", slot = "Shoulder", healing = 22, int = 12, spi = 15, stam = 11, mp5 = 0, crit = 0, drop = "ZG: Primal Hakkari Shawl token", priority = 3, note = "Epic T0.5 shoulder" },
    [19842] = { name = "Zandalar Confessor's Bindings", slot = "Belt", healing = 26, int = 20, spi = 12, stam = 12, mp5 = 0, crit = 0, drop = "ZG: Primal Hakkari Sash token", priority = 4, note = "Epic T0.5 belt" },
    [19843] = { name = "Zandalar Confessor's Wraps", slot = "Wrists", healing = 24, int = 11, spi = 12, stam = 10, mp5 = 0, crit = 0, drop = "ZG: Primal Hakkari Stanchion token", priority = 5, note = "Rare T0.5 bracers" },
    [19594] = { name = "The All-Seeing Eye of Zuldazar", slot = "Neck", healing = 24, int = 10, spi = 8, stam = 0, mp5 = 0, crit = 0, drop = "ZG: Class set exchange", priority = 6, note = "Epic neck with unique proc" },
    [19927] = { name = "Mar'li's Touch", slot = "Wand", healing = 33, int = 22, spi = 0, stam = 6, mp5 = 0, crit = 0, drop = "ZG: Mar'li (17%)", priority = 7, note = "Epic wand" },
    [19967] = { name = "Thoughtblighter", slot = "Wand", healing = 28, int = 18, spi = 0, stam = 5, mp5 = 0, crit = 0, drop = "ZG: Hazzarah (45%)", priority = 8, note = "Rare wand" },
    [19861] = { name = "Touch of Chaos", slot = "Wand", healing = 42, int = 25, spi = 0, stam = 8, mp5 = 0, crit = 0, drop = "ZG: Hakkar (14%)", priority = 9, note = "Epic wand" },
    [22721] = { name = "Band of Servitude", slot = "Ring", healing = 28, int = 0, spi = 0, stam = 0, mp5 = 0, crit = 0, drop = "ZG: Shared (10%)", priority = 10, note = "Epic ring" },
    [22722] = { name = "Seal of the Gurubashi Berserker", slot = "Ring", healing = 0, int = 0, spi = 0, stam = 0, mp5 = 0, crit = 0, drop = "ZG: Shared (10%)", priority = 99, note = "Melee ring" },
    [22711] = { name = "Cloak of the Hakkari Worshipers", slot = "Back", healing = 26, int = 0, spi = 0, stam = 0, mp5 = 0, crit = 0, drop = "ZG: Shared (10%)", priority = 11, note = "Rare cloak" },
    [13932] = { name = "Might of the Tribe", slot = "Back", healing = 26, int = 0, spi = 0, stam = 0, mp5 = 0, crit = 0, drop = "ZG: Shared (10%)", priority = 12, note = "Rare cloak" },
    [19897] = { name = "Betrayer's Boots", slot = "Boots", healing = 32, int = 18, spi = 12, stam = 0, mp5 = 0, crit = 0, drop = "ZG: Renataki (14%)", priority = 25, note = "Epic cloth boots" },
    [19908] = { name = "Sceptre of Smiting", slot = "Mainhand", healing = 87, int = 0, spi = 0, stam = 0, mp5 = 0, crit = 0, drop = "ZG: Trash (0.03%)", priority = 49, note = "Rare 1H healing mace" },
    [20258] = { name = "Zulian Ceremonial Staff", slot = "Twohand", healing = 71, int = 0, spi = 0, stam = 0, mp5 = 0, crit = 0, drop = "ZG: Trash (0.03%)", priority = 49, note = "Rare 2H staff" },

    -- === UPPER / LOWER KARAZHAN (Turtle WoW Custom Content) ===
    [55274] = { name = "Chain-Cloak of the Rookguard", slot = "Back", healing = 29, int = 14, spi = 0, stam = 8, mp5 = 0, crit = 0, drop = "UKH: King (13%)", priority = 15, note = "Epic cloak" },
    [55084] = { name = "Torn Wings of Midnight", slot = "Back", healing = 28, int = 15, spi = 0, stam = 0, mp5 = 0, crit = 0, drop = "UKH: Gnarlmoon (25%)", priority = 14, note = "Epic cloak" },
    [55276] = { name = "Forgotten Raven's Mallet", slot = "Mainhand", healing = 45, int = 12, spi = 10, stam = 0, mp5 = 4, crit = 0, drop = "UKH: King (25%)", priority = 49, note = "Epic 1H mace" },
    [61210] = { name = "Veil of Nightmare", slot = "Back", healing = 30, int = 0, spi = 0, stam = 10, mp5 = 0, crit = 0, drop = "UKH: Echo (17%)", priority = 16, note = "Epic cloak" },
    [55081] = { name = "Magispark Leggings", slot = "Legs", healing = 41, int = 20, spi = 22, stam = 14, mp5 = 0, crit = 0, drop = "UKH: Gnarlmoon (25%)", priority = 17, note = "Epic cloth legs" },
    [55278] = { name = "Leggings of the Black Blizzard", slot = "Legs", healing = 33, int = 18, spi = 12, stam = 0, mp5 = 0, crit = 0, drop = "ZG: Arlokk (20%)", priority = 18, note = "Epic cloth legs" },
    [55279] = { name = "Leggings of the Misty Marsh", slot = "Legs", healing = 35, int = 16, spi = 18, stam = 10, mp5 = 0, crit = 0, drop = "UKH: Rolfen (10%)", priority = 19, note = "Epic cloth legs" },
    [55106] = { name = "Khadgar's Guidance", slot = "Hands", healing = 35, int = 18, spi = 14, stam = 8, mp5 = 0, crit = 0, drop = "UKH: Mephistroth (8%)", priority = 20, note = "Epic cloth gloves" },
    [55107] = { name = "Gloves of Leyline Convergence", slot = "Hands", healing = 32, int = 16, spi = 10, stam = 0, mp5 = 0, crit = 0, drop = "UKH: Gnarlmoon (25%)", priority = 21, note = "Epic cloth gloves" },
    [55285] = { name = "Crite's Holy Hands", slot = "Hands", healing = 38, int = 12, spi = 0, stam = 0, mp5 = 0, crit = 0, drop = "UKH: Grizikil (25%)", priority = 22, note = "Epic cloth gloves" },
    [21462] = { name = "Gloves of Dark Wisdom", slot = "Hands", healing = 35, int = 20, spi = 13, stam = 10, mp5 = 0, crit = 0, drop = "AQ20: Ossirian (15%)", priority = 23, note = "Rare cloth gloves" },
    [55110] = { name = "Manadrenched Feather Slippers", slot = "Boots", healing = 44, int = 12, spi = 0, stam = 0, mp5 = 0, crit = 0, drop = "UKH: Incantagos (25%)", priority = 24, note = "Epic cloth boots" },
    [55123] = { name = "Loop of Hardened Slate", slot = "Ring", healing = 0, int = 0, spi = 0, stam = 14, mp5 = 0, crit = 0, drop = "UKH: Rupturan (14%)", priority = 99, note = "Tank ring" },
    [55100] = { name = "Mephistroth's Cunning", slot = "Ring", healing = 33, int = 10, spi = 0, stam = 0, mp5 = 0, crit = 0, drop = "UKH: King (8%)", priority = 27, note = "Epic ring" },
    [55094] = { name = "Medivh's Hindsight", slot = "Ring", healing = 22, int = 14, spi = 12, stam = 0, mp5 = 0, crit = 0, drop = "UKH: Gnarlmoon (25%)", priority = 28, note = "Epic ring" },
    [55103] = { name = "Royal Seal of Greymane", slot = "Ring", healing = 26, int = 15, spi = 0, stam = 8, mp5 = 0, crit = 0, drop = "UKH: King (13%)", priority = 29, note = "Epic ring" },
    [55511] = { name = "Hellflame", slot = "Wand", healing = 45, int = 0, spi = 0, stam = 0, mp5 = 0, crit = 0, drop = "UKH: Kruul (11%)", priority = 32, note = "Epic wand" },
    [58137] = { name = "Netherbranch", slot = "Wand", healing = 38, int = 0, spi = 0, stam = 0, mp5 = 0, crit = 0, drop = "UKH: Rupturan", priority = 33, note = "Rare wand" },
    [55284] = { name = "Dragunovi's Sash of Dominion", slot = "Belt", healing = 26, int = 0, spi = 13, stam = 0, mp5 = 0, crit = 0, drop = "UKH: Trash (0.25%)", priority = 49, note = "Epic cloth belt" },
    [55286] = { name = "Ring of Holy Light", slot = "Ring", healing = 0, int = 18, spi = 28, stam = 0, mp5 = 0, crit = 0, drop = "UKH: Trash (0.25%)", priority = 49, note = "Epic spirit ring" },
    [61254] = { name = "Reedmesh Belt", slot = "Belt", healing = 16, int = 14, spi = 14, stam = 0, mp5 = 0, crit = 0, drop = "LKH: Trash (0.15%)", priority = 49, note = "Rare cloth belt" },
    [61288] = { name = "Nightwoven Belt", slot = "Belt", healing = 18, int = 16, spi = 15, stam = 0, mp5 = 0, crit = 0, drop = "LKH: Trash (0.15%)", priority = 49, note = "Rare cloth belt" },

    -- === BLACKWING LAIR (Transcendence T2 Set) ===
    [16926] = { name = "Bindings of Transcendence", slot = "Wrists", healing = 33, int = 13, spi = 16, stam = 9, mp5 = 0, crit = 0, drop = "BWL: Razorgore (11%)", priority = 34, note = "T2 wrists - epic" },
    [16925] = { name = "Belt of Transcendence", slot = "Belt", healing = 27, int = 26, spi = 9, stam = 14, mp5 = 0, crit = 0, drop = "BWL: Vaelastrasz (11%)", priority = 35, note = "T2 belt - epic" },
    [16919] = { name = "Boots of Transcendence", slot = "Boots", healing = 36, int = 17, spi = 17, stam = 17, mp5 = 0, crit = 0, drop = "BWL: Broodlord Lashlayer (11%)", priority = 36, note = "T2 boots - epic" },
    [16920] = { name = "Handguards of Transcendence", slot = "Hands", healing = 29, int = 20, spi = 13, stam = 12, mp5 = 0, crit = 1, drop = "BWL: Firemaw/Ebonroc (7%)", priority = 37, note = "T2 gloves - epic" },
    [16918] = { name = "Halo of Transcendence", slot = "Head", healing = 49, int = 27, spi = 22, stam = 17, mp5 = 0, crit = 0, drop = "BWL: Nefarian (7%)", priority = 39, note = "T2 helm - epic" },
    [16922] = { name = "Leggings of Transcendence", slot = "Legs", healing = 46, int = 21, spi = 21, stam = 16, mp5 = 7, crit = 0, drop = "BWL: Nefarian (7%)", priority = 41, note = "T2 legs - epic" },
    [16923] = { name = "Robes of Transcendence", slot = "Chest", healing = 59, int = 27, spi = 16, stam = 17, mp5 = 0, crit = 0, drop = "BWL: Nefarian (7%)", priority = 40, note = "T2 chest - epic" },
    [16921] = { name = "Pauldrons of Transcendence", slot = "Shoulder", healing = 27, int = 25, spi = 13, stam = 12, mp5 = 0, crit = 0, drop = "BWL: Chromaggus (7%)", priority = 38, note = "T2 shoulders - epic" },
    [19398] = { name = "Cloak of Firemaw", slot = "Back", healing = 34, int = 0, spi = 0, stam = 0, mp5 = 0, crit = 0, drop = "BWL: Firemaw (13%)", priority = 45, note = "Epic cloak" },
    [19403] = { name = "Band of Forced Concentration", slot = "Ring", healing = 21, int = 12, spi = 0, stam = 9, mp5 = 0, crit = 1, drop = "BWL: Ebonroc (17%)", priority = 47, note = "Epic ring (+1% crit)" },
    [19355] = { name = "Shadow Wing Focus Staff", slot = "Twohand", healing = 42, int = 14, spi = 0, stam = 0, mp5 = 0, crit = 0, drop = "BWL: Ebonroc/Firemaw", priority = 48, note = "Epic staff" },
    [19434] = { name = "Band of Dark Dominion", slot = "Ring", healing = 0, int = 0, spi = 0, stam = 0, mp5 = 0, crit = 0, drop = "BWL: Trash (2%)", priority = 49, note = "Shadow ring" },
    [19435] = { name = "Essence Gatherer", slot = "Wand", healing = 25, int = 7, spi = 0, stam = 5, mp5 = 0, crit = 0, drop = "BWL: Trash (2%)", priority = 49, note = "Epic wand" },
    [19437] = { name = "Boots of Pure Thought", slot = "Boots", healing = 62, int = 12, spi = 12, stam = 8, mp5 = 0, crit = 0, drop = "BWL: Trash (4%)", priority = 49, note = "Epic cloth boots" },
    [19438] = { name = "Ringo's Blizzard Boots", slot = "Boots", healing = 33, int = 0, spi = 0, stam = 0, mp5 = 0, crit = 0, drop = "BWL: Trash (5%)", priority = 49, note = "Epic cloth boots" },
    [19145] = { name = "Robe of Volatile Power", slot = "Chest", healing = 23, int = 16, spi = 20, stam = 14, mp5 = 0, crit = 1, drop = "BWL: Nefarian's Tear table", priority = 49, note = "Epic cloth chest (+1% crit)" },
    [18872] = { name = "Manastorm Leggings", slot = "Legs", healing = 25, int = 14, spi = 13, stam = 19, mp5 = 14, crit = 0, drop = "BWL: Nefarian's Tear table", priority = 49, note = "Epic cloth legs (+14 MP5)" },

    -- === MOLTEN CORE (Vestments of Prophecy T1) ===
    [16817] = { name = "Girdle of Prophecy", slot = "Belt", healing = 22, int = 22, spi = 15, stam = 8, mp5 = 0, crit = 0, drop = "MC: Trash (0.3%)", priority = 49, note = "Epic T1 belt" },
    [16819] = { name = "Vambraces of Prophecy", slot = "Wrists", healing = 24, int = 0, spi = 16, stam = 10, mp5 = 6, crit = 0, drop = "MC: Trash (0.3%)", priority = 49, note = "Epic T1 bracers" },
    [81261] = { name = "Boots of Blistering Flames", slot = "Boots", healing = 53, int = 12, spi = 14, stam = 0, mp5 = 0, crit = 0, drop = "MC: Trash (0.2%)", priority = 49, note = "Epic cloth boots" },
    [16812] = { name = "Gloves of Prophecy", slot = "Hands", healing = 18, int = 0, spi = 15, stam = 10, mp5 = 6, crit = 0, drop = "MC: Incindus/Gehennas", priority = 33, note = "Epic T1 gloves" },
    [16813] = { name = "Circlet of Prophecy", slot = "Head", healing = 22, int = 18, spi = 19, stam = 11, mp5 = 0, crit = 0, drop = "MC: Garr (20%)", priority = 33, note = "Epic T1 helm" },
    [16814] = { name = "Pants of Prophecy", slot = "Legs", healing = 22, int = 24, spi = 20, stam = 20, mp5 = 0, crit = 0, drop = "MC: Magmadar (20%)", priority = 33, note = "Epic T1 legs" },
    [16815] = { name = "Robes of Prophecy", slot = "Chest", healing = 22, int = 27, spi = 17, stam = 20, mp5 = 0, crit = 0, drop = "MC: Golemagg (25%)", priority = 33, note = "Epic T1 chest" },
    [16816] = { name = "Mantle of Prophecy", slot = "Shoulder", healing = 35, int = 22, spi = 15, stam = 18, mp5 = 0, crit = 0, drop = "MC: Sulfuron (33%)", priority = 33, note = "Epic T1 shoulders" },
    [16811] = { name = "Boots of Prophecy", slot = "Boots", healing = 27, int = 18, spi = 19, stam = 17, mp5 = 0, crit = 0, drop = "MC: Shazzrah (25%)", priority = 33, note = "Epic T1 boots" },

    -- === OTHER NOTABLE GEAR ===
    [19132] = { name = "Crystal Adorned Crown", slot = "Head", healing = 92, int = 14, spi = 13, stam = 0, mp5 = 0, crit = 0, drop = "World: Azuregos (10%)", priority = 2, note = "Epic helm - high +heal" },
    [18723] = { name = "Animated Chain Necklace", slot = "Neck", healing = 33, int = 0, spi = 6, stam = 7, mp5 = 0, crit = 0, drop = "Strat: Ramstein", priority = 5, note = "Epic neck" },
    [19820] = { name = "Consecrated Caduceus", slot = "Offhand", healing = 31, int = 0, spi = 0, stam = 0, mp5 = 4, crit = 0, drop = "Strat: Archivist Galford", priority = 10, note = "Epic healing offhand" },
    [22406] = { name = "Redemption", slot = "Mainhand", healing = 84, int = 0, spi = 0, stam = 0, mp5 = 0, crit = 0, drop = "Quest / Dungeon", priority = 10, note = "Epic 1H healing mace" },
    [18510] = { name = "Hide of the Wild", slot = "Back", healing = 36, int = 10, spi = 10, stam = 0, mp5 = 0, crit = 0, drop = "Crafted / Leatherworking", priority = 5, note = "Epic healing cloak" },
    [13346] = { name = "Robes of the Exalted", slot = "Chest", healing = 68, int = 11, spi = 0, stam = 0, mp5 = 0, crit = 0, drop = "Strat: Baron Rivendare", priority = 10, note = "Top pre-raid healing chest" },
    [22247] = { name = "Faith Healer's Boots", slot = "Boots", healing = 37, int = 12, spi = 10, stam = 0, mp5 = 0, crit = 0, drop = "Dungeon drop", priority = 15, note = "Healing boots" },
    [51047] = { name = "Sacrosanct Epaulets", slot = "Shoulder", healing = 44, int = 15, spi = 12, stam = 0, mp5 = 0, crit = 0, drop = "Turtle Custom Dungeon", priority = 10, note = "High +heal shoulders" },
    [61004] = { name = "Sandswept Ring of Arcanum", slot = "Ring", healing = 22, int = 10, spi = 10, stam = 0, mp5 = 3, crit = 0, drop = "Turtle Custom Item", priority = 15, note = "Healing ring" },
}

-- Boss drops mapping for proactive warnings
UA.BOSS_DROPS = {
    ["High Priestess Mar'li"] = { 20032, 19958, 19927 },
    ["High Priest Venoxis"] = { 19958 },
    ["High Priest Thekal"] = { 19958 },
    ["High Priestess Jeklik"] = { 19958 },
    ["Bloodlord Mandokir"] = { 19841, 19842, 19843 },
    ["Arlokk"] = { 19841, 19842, 19843, 55278 },
    ["Renataki"] = { 19897 },
    ["Gri'lek"] = { 22721 },
    ["Hazza'rah"] = { 19967, 22721 },
    ["Wushoolay"] = { 22721 },
    ["Hakkar"] = { 19861, 13932, 22721 },
    ["Edge of Madness"] = { 19958 },

    ["Lucifron"] = { 16817 },
    ["Gehennas"] = { 16819, 16816 },
    ["Garr"] = { 16813, 16811 },
    ["Shazzrah"] = { 16811 },
    ["Sulfuron"] = { 16816 },
    ["Golemagg"] = { 16815 },
    ["Magmadar"] = { 16814 },

    ["Lord Blackwald II"] = { 55274 },
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
    ["Nefarian"] = { 16922, 16923, 16918 },
}

-- ================================================
-- 4. DYNAMIC TOOLTIP SCANNING & STAT RESOLUTION
-- ================================================

local scanTooltip = getglobal("UAScanningTooltip") or CreateFrame("GameTooltip", "UAScanningTooltip", UIParent, "GameTooltipTemplate")
scanTooltip:SetOwner(UIParent, "ANCHOR_NONE")

local ITEM_STAT_CACHE = {}

-- Slot string normalization
local EQUIP_SLOT_MAP = {
    ["INVTYPE_HEAD"] = "Head",
    ["INVTYPE_NECK"] = "Neck",
    ["INVTYPE_SHOULDER"] = "Shoulder",
    ["INVTYPE_CHEST"] = "Chest",
    ["INVTYPE_ROBE"] = "Chest",
    ["INVTYPE_WAIST"] = "Belt",
    ["INVTYPE_LEGS"] = "Legs",
    ["INVTYPE_FEET"] = "Boots",
    ["INVTYPE_WRIST"] = "Wrists",
    ["INVTYPE_HAND"] = "Hands",
    ["INVTYPE_FINGER"] = "Ring",
    ["INVTYPE_TRINKET"] = "Trinket",
    ["INVTYPE_CLOAK"] = "Back",
    ["INVTYPE_WEAPON"] = "Mainhand",
    ["INVTYPE_2HWEAPON"] = "Twohand",
    ["INVTYPE_WEAPONMAINHAND"] = "Mainhand",
    ["INVTYPE_WEAPONOFFHAND"] = "Offhand",
    ["INVTYPE_SHIELD"] = "Offhand",
    ["INVTYPE_HOLDABLE"] = "Offhand",
    ["INVTYPE_RANGED"] = "Wand",
    ["INVTYPE_RANGEDRIGHT"] = "Wand",
}

-- Parse item stats dynamically from tooltip
function UA.ScanItemStats(itemID, itemLink)
    if not itemID and not itemLink then return nil end
    local cacheKey = itemID or itemLink
    if ITEM_STAT_CACHE[cacheKey] then
        return ITEM_STAT_CACHE[cacheKey]
    end

    -- Extract raw "item:..." link string if a full escaped link was passed
    local rawLink = nil
    if itemLink then
        local _, _, extracted = string.find(itemLink, "|H(item:[^|]+)|h")
        if extracted then
            rawLink = extracted
        elseif string.find(itemLink, "^item:") then
            rawLink = itemLink
        else
            local _, _, anyItem = string.find(itemLink, "(item:[%d:-]+)")
            if anyItem then
                rawLink = anyItem
            end
        end
    end

    if not rawLink and itemID then
        rawLink = "item:" .. tostring(itemID) .. ":0:0:0"
    end

    if not itemID and rawLink then
        local _, _, parsedID = string.find(rawLink, "item:(%d+):")
        if parsedID then
            itemID = tonumber(parsedID)
        end
    end

    scanTooltip:ClearLines()
    if rawLink then
        pcall(function() scanTooltip:SetHyperlink(rawLink) end)
    end

    local stats = {
        name = "",
        slot = nil,
        healing = 0,
        spell_damage = 0,
        int = 0,
        spi = 0,
        stam = 0,
        mp5 = 0,
        crit = 0,
        role = "HEAL",
    }

    local numLines = tonumber(scanTooltip:NumLines())
    if numLines and numLines > 0 then
        for i = 1, numLines do
            local leftLine = getglobal("UAScanningTooltipTextLeft" .. i)
            local rightLine = getglobal("UAScanningTooltipTextRight" .. i)
            local text = leftLine and leftLine:GetText()
            local rText = rightLine and rightLine:GetText()

            if text then
                if i == 1 then
                    stats.name = text
                end

                -- Match +Healing
                local _, _, val = string.find(text, "Increases healing done by spells and effects by up to (%d+)")
                if not val then _, _, val = string.find(text, "Increases healing done by up to (%d+)") end
                if not val then _, _, val = string.find(text, "Increases healing done by magical spells and effects by up to (%d+)") end
                if val then stats.healing = stats.healing + tonumber(val) end

                local _, _, val2 = string.find(text, "%+(%d+) Healing Spells")
                if not val2 then _, _, val2 = string.find(text, "%+(%d+) Healing") end
                if val2 then stats.healing = stats.healing + tonumber(val2) end

                -- Match +Damage and Healing (applies 100% to healing in vanilla)
                local _, _, valDH = string.find(text, "Increases damage and healing done by magical spells and effects by up to (%d+)")
                if not valDH then _, _, valDH = string.find(text, "Increases damage and healing done by spells and effects by up to (%d+)") end
                if valDH then stats.healing = stats.healing + tonumber(valDH) end

                local _, _, valDH2 = string.find(text, "%+(%d+) Spell Damage and Healing")
                if not valDH2 then _, _, valDH2 = string.find(text, "%+(%d+) Damage and Healing Spells") end
                if valDH2 then stats.healing = stats.healing + tonumber(valDH2) end

                -- Match Intellect, Spirit, Stamina
                local _, _, valInt = string.find(text, "%+(%d+) Intellect")
                if not valInt then _, _, valInt = string.find(text, "(%d+) Intellect") end
                if valInt then stats.int = stats.int + tonumber(valInt) end

                local _, _, valSpi = string.find(text, "%+(%d+) Spirit")
                if not valSpi then _, _, valSpi = string.find(text, "(%d+) Spirit") end
                if valSpi then stats.spi = stats.spi + tonumber(valSpi) end

                local _, _, valStam = string.find(text, "%+(%d+) Stamina")
                if not valStam then _, _, valStam = string.find(text, "(%d+) Stamina") end
                if valStam then stats.stam = stats.stam + tonumber(valStam) end

                -- Match MP5
                local _, _, valMP5 = string.find(text, "Restores (%d+) mana per 5 sec%.")
                if not valMP5 then _, _, valMP5 = string.find(text, "(%d+) Mana every 5 sec%.") end
                if not valMP5 then _, _, valMP5 = string.find(text, "(%d+) Mana per 5 sec%.") end
                if not valMP5 then _, _, valMP5 = string.find(text, "(%d+) [Mm]ana per 5 [Ss]ec") end
                if valMP5 then stats.mp5 = stats.mp5 + tonumber(valMP5) end

                -- Match Spell Crit
                local _, _, valCrit = string.find(text, "Increases your chance to get a critical strike with spells by (%d+)%%")
                if not valCrit then _, _, valCrit = string.find(text, "Improves your chance to get a critical strike with spells by (%d+)%%") end
                if not valCrit then _, _, valCrit = string.find(text, "Increases your chance to get a critical strike with holy spells by (%d+)%%") end
                if not valCrit then _, _, valCrit = string.find(text, "Improves your chance to get a critical strike with holy spells by (%d+)%%") end
                if valCrit then stats.crit = stats.crit + tonumber(valCrit) end

                -- Detect slot from tooltip if not yet found
                if not stats.slot then
                    if string.find(text, "Head") then stats.slot = "Head"
                    elseif string.find(text, "Neck") then stats.slot = "Neck"
                    elseif string.find(text, "Shoulder") then stats.slot = "Shoulder"
                    elseif string.find(text, "Back") or string.find(text, "Cloak") then stats.slot = "Back"
                    elseif string.find(text, "Chest") or string.find(text, "Robe") then stats.slot = "Chest"
                    elseif string.find(text, "Wrist") or string.find(text, "Bracer") then stats.slot = "Wrists"
                    elseif string.find(text, "Hands") or string.find(text, "Gloves") then stats.slot = "Hands"
                    elseif string.find(text, "Waist") or string.find(text, "Belt") then stats.slot = "Belt"
                    elseif string.find(text, "Legs") or string.find(text, "Pants") then stats.slot = "Legs"
                    elseif string.find(text, "Feet") or string.find(text, "Boots") then stats.slot = "Boots"
                    elseif string.find(text, "Finger") or string.find(text, "Ring") then stats.slot = "Ring"
                    elseif string.find(text, "Trinket") then stats.slot = "Trinket"
                    elseif string.find(text, "Two%-Hand") then stats.slot = "Twohand"
                    elseif string.find(text, "Main Hand") then stats.slot = "Mainhand"
                    elseif string.find(text, "One%-Hand") then stats.slot = "Mainhand"
                    elseif string.find(text, "Held In Off%-Hand") or string.find(text, "Off Hand") then stats.slot = "Offhand"
                    elseif string.find(text, "Ranged") or string.find(text, "Wand") then stats.slot = "Wand"
                    end
                end
            end

            if rText and not stats.slot then
                if string.find(rText, "Head") then stats.slot = "Head"
                elseif string.find(rText, "Neck") then stats.slot = "Neck"
                elseif string.find(rText, "Shoulder") then stats.slot = "Shoulder"
                elseif string.find(rText, "Back") or string.find(rText, "Cloak") then stats.slot = "Back"
                elseif string.find(rText, "Chest") or string.find(rText, "Robe") then stats.slot = "Chest"
                elseif string.find(rText, "Wrist") or string.find(rText, "Bracer") then stats.slot = "Wrists"
                elseif string.find(rText, "Hands") or string.find(rText, "Gloves") then stats.slot = "Hands"
                elseif string.find(rText, "Waist") or string.find(rText, "Belt") then stats.slot = "Belt"
                elseif string.find(rText, "Legs") or string.find(rText, "Pants") then stats.slot = "Legs"
                elseif string.find(rText, "Feet") or string.find(rText, "Boots") then stats.slot = "Boots"
                elseif string.find(rText, "Finger") or string.find(rText, "Ring") then stats.slot = "Ring"
                elseif string.find(rText, "Trinket") then stats.slot = "Trinket"
                elseif string.find(rText, "Two%-Hand") then stats.slot = "Twohand"
                elseif string.find(rText, "Main Hand") then stats.slot = "Mainhand"
                elseif string.find(rText, "One%-Hand") then stats.slot = "Mainhand"
                elseif string.find(rText, "Held In Off%-Hand") or string.find(rText, "Off Hand") then stats.slot = "Offhand"
                elseif string.find(rText, "Ranged") or string.find(rText, "Wand") then stats.slot = "Wand"
                end
            end
        end
    end

    if (stats.name == "" or not stats.slot) and (itemID or itemLink) then
        local name, _, _, _, _, _, _, _, equipSlot = GetItemInfo(itemID or itemLink)
        if name and stats.name == "" then stats.name = name end
        if equipSlot and not stats.slot and EQUIP_SLOT_MAP[equipSlot] then
            stats.slot = EQUIP_SLOT_MAP[equipSlot]
        end
    end

    if stats.name ~= "" or stats.slot ~= nil then
        ITEM_STAT_CACHE[cacheKey] = stats
        if itemID and cacheKey ~= itemID then
            ITEM_STAT_CACHE[itemID] = stats
        end
        return stats
    end

    return nil
end

-- Get comprehensive item data (merging curated database + dynamic tooltip scanner)
function UA.GetItemData(itemID, itemLink)
    local dbData = itemID and UA.UPGRADE_DATABASE[itemID]
    if dbData then
        return dbData
    end

    -- Dynamically resolve unknown / Turtle WoW custom items
    local scanned = UA.ScanItemStats(itemID, itemLink)
    if scanned then
        return scanned
    end

    return nil
end

-- Calculate item score using Holy Priest EP weights
function UA.GetItemScore(item)
    if not item then return 0 end
    if item.ep_override then
        return item.ep_override
    end

    local score = 0
    score = score + (item.healing or 0) * UA.STAT_WEIGHTS.healing
    score = score + (item.spi or 0) * UA.STAT_WEIGHTS.spi
    score = score + (item.mp5 or 0) * UA.STAT_WEIGHTS.mp5
    score = score + (item.crit or 0) * UA.STAT_WEIGHTS.spell_crit
    score = score + (item.int or 0) * UA.STAT_WEIGHTS.int
    score = score + (item.stam or 0) * UA.STAT_WEIGHTS.stamina
    score = score + (item.spell_damage or 0) * UA.STAT_WEIGHTS.spell_damage
    return math.floor(score + 0.5)
end

-- ================================================
-- 5. DYNAMIC INVENTORY QUERYING
-- ================================================

-- Query currently equipped item for a specific slot directly from the engine
function UA.GetEquippedItemData(slotName)
    local slotID = UA.SLOT_IDS[slotName]
    if not slotID then return nil end

    local link = GetInventoryItemLink("player", slotID)
    if link then
        local _, _, itemID = string.find(link, "item:(%d+):")
        if itemID then
            itemID = tonumber(itemID)
            local data = UA.GetItemData(itemID, link)
            if data then return data end
        end
    end

    -- Fallback to static snapshot if available
    local fallback = UA.CURRENT_GEAR[slotName]
    if not fallback and slotName == "Ranged" then
        fallback = UA.CURRENT_GEAR["Wand"]
    elseif not fallback and slotName == "Wand" then
        fallback = UA.CURRENT_GEAR["Ranged"]
    end
    if fallback and fallback.id then
        return UA.GetItemData(fallback.id)
    end

    return nil
end

-- Extract item ID from item link
function UA.GetItemIDFromLink(itemLink)
    if not itemLink then return nil end
    local _, _, itemID = string.find(itemLink, "item:(%d+):")
    return tonumber(itemID)
end

-- ================================================
-- 6. CORE UPGRADE COMPARISON LOGIC
-- ================================================

-- Check if candidate item is an upgrade over currently equipped gear
function UA.IsUpgrade(itemID, itemLink)
    local itemData = UA.GetItemData(itemID, itemLink)
    if not itemData then
        return false, "Item data unavailable"
    end

    local slot = itemData.slot
    if not slot then
        return false, "Unknown equipment slot"
    end

    local newScore = UA.GetItemScore(itemData)

    -- --------------------------------------------
    -- TRINKETS: Role check + Min-Score replacement
    -- --------------------------------------------
    if slot == "Trinket" then
        if itemData.role and itemData.role ~= "HEAL" then
            return false, "Non-healer trinket (" .. itemData.role .. ")"
        end

        local t1 = UA.GetEquippedItemData("Trinket1")
        local t2 = UA.GetEquippedItemData("Trinket2")
        local score1 = UA.GetItemScore(t1)
        local score2 = UA.GetItemScore(t2)

        local minScore = math.min(score1, score2)
        local replaceSlot = (score1 <= score2) and "Trinket1" or "Trinket2"

        if newScore > minScore then
            local delta = newScore - minScore
            return true, format("Trinket Upgrade over %s (+%d EP, %d -> %d)", replaceSlot, delta, minScore, newScore)
        else
            return false, format("Trinket Downgrade vs %s (%d vs %d EP)", replaceSlot, newScore, minScore)
        end
    end

    -- --------------------------------------------
    -- RINGS: Dual-slot Min-Score replacement
    -- --------------------------------------------
    if slot == "Ring" then
        local r1 = UA.GetEquippedItemData("Ring1")
        local r2 = UA.GetEquippedItemData("Ring2")
        local score1 = UA.GetItemScore(r1)
        local score2 = UA.GetItemScore(r2)

        local minScore = math.min(score1, score2)
        local replaceSlot = (score1 <= score2) and "Ring1" or "Ring2"

        if newScore > minScore then
            local delta = newScore - minScore
            return true, format("Ring Upgrade over %s (+%d EP, %d -> %d)", replaceSlot, delta, minScore, newScore)
        else
            return false, format("Ring Downgrade vs %s (%d vs %d EP)", replaceSlot, newScore, minScore)
        end
    end

    -- --------------------------------------------
    -- WEAPONS: Two-Hand (Staff) vs Mainhand + Offhand
    -- --------------------------------------------
    if slot == "Twohand" or slot == "Staff" then
        local mh = UA.GetEquippedItemData("Mainhand")
        local oh = UA.GetEquippedItemData("Offhand")
        local mhScore = UA.GetItemScore(mh)
        local ohScore = UA.GetItemScore(oh)
        local currentSetScore = mhScore + ohScore

        if newScore > currentSetScore then
            local delta = newScore - currentSetScore
            return true, format("2H Upgrade over MH+OH Set (+%d EP: %d vs %d)", delta, newScore, currentSetScore)
        else
            return false, format("2H Downgrade vs MH+OH Set (%d vs %d EP)", newScore, currentSetScore)
        end
    end

    if slot == "Mainhand" then
        local currentMH = UA.GetEquippedItemData("Mainhand")
        if currentMH and (currentMH.slot == "Twohand" or currentMH.slot == "Staff") then
            -- Currently wielding a 2H staff; compare New MH + Current OH vs Current 2H
            local current2HScore = UA.GetItemScore(currentMH)
            local currentOH = UA.GetEquippedItemData("Offhand")
            local ohScore = UA.GetItemScore(currentOH)
            local projectedScore = newScore + ohScore
            if projectedScore > current2HScore then
                return true, format("1H Upgrade over 2H Staff (+%d EP: %d vs %d)", projectedScore - current2HScore, projectedScore, current2HScore)
            else
                return false, format("1H Downgrade vs 2H Staff (%d vs %d EP)", projectedScore, current2HScore)
            end
        else
            local currentScore = UA.GetItemScore(currentMH)
            if newScore > currentScore then
                return true, format("Mainhand Upgrade (+%d EP: %d -> %d)", newScore - currentScore, currentScore, newScore)
            else
                return false, format("Mainhand Downgrade (%d vs %d EP)", newScore, currentScore)
            end
        end
    end

    if slot == "Offhand" then
        local currentOH = UA.GetEquippedItemData("Offhand")
        local currentScore = UA.GetItemScore(currentOH)
        if newScore > currentScore then
            return true, format("Offhand Upgrade (+%d EP: %d -> %d)", newScore - currentScore, currentScore, newScore)
        else
            return false, format("Offhand Downgrade (%d vs %d EP)", newScore, currentScore)
        end
    end

    -- --------------------------------------------
    -- STANDARD SINGLE SLOTS
    -- --------------------------------------------
    local currentItem = UA.GetEquippedItemData(slot)
    if not currentItem then
        return true, format("Slot %s is empty - Free Upgrade (+%d EP)", slot, newScore)
    end

    local currentScore = UA.GetItemScore(currentItem)
    if newScore > currentScore then
        local delta = newScore - currentScore
        return true, format("Score: %d -> %d (+%d EP)", currentScore, newScore, delta)
    else
        return false, format("Downgrade: %d vs %d EP", newScore, currentScore)
    end
end

-- Format item details for UI / Tooltip
function UA.FormatItemInfo(itemID, itemLink)
    local data = UA.GetItemData(itemID, itemLink)
    if not data then return "Unknown item" end

    local lines = {}
    table.insert(lines, data.name or "Item")
    table.insert(lines, format("Slot: %s  |  Score: %d EP", data.slot or "Unknown", UA.GetItemScore(data)))

    local statParts = {}
    if (data.healing or 0) > 0 then table.insert(statParts, format("+%d Healing", data.healing)) end
    if (data.spi or 0) > 0 then table.insert(statParts, format("+%d Spirit", data.spi)) end
    if (data.mp5 or 0) > 0 then table.insert(statParts, format("+%d MP5", data.mp5)) end
    if (data.crit or 0) > 0 then table.insert(statParts, format("+%d%% Crit", data.crit)) end
    if (data.int or 0) > 0 then table.insert(statParts, format("+%d Int", data.int)) end
    if (data.stam or 0) > 0 then table.insert(statParts, format("+%d Stam", data.stam)) end
    if table.getn(statParts) > 0 then
        table.insert(lines, table.concat(statParts, "  "))
    end

    if data.drop then table.insert(lines, format("Source: %s", data.drop)) end
    if data.note then table.insert(lines, format("|cffffd100%s|r", data.note)) end

    return table.concat(lines, "\n")
end

-- ================================================
-- 7. ALERT UI FRAME & ANIMATIONS
-- ================================================

local alertFrame = CreateFrame("Frame", "UpgradeAlertFrame", UIParent)
alertFrame:Hide()
alertFrame:SetWidth(360)
alertFrame:SetHeight(190)
alertFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 120)
alertFrame:SetBackdrop({
    bgFile = "Interface/Tooltips/UI-Tooltip-Background",
    edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 16,
    insets = {left = 4, right = 4, top = 4, bottom = 4}
})
alertFrame:SetBackdropColor(0, 0, 0, 0.90)
alertFrame:SetMovable(true)
alertFrame:EnableMouse(true)
alertFrame:RegisterForDrag("LeftButton")
alertFrame:SetScript("OnDragStart", function() alertFrame:StartMoving() end)
alertFrame:SetScript("OnDragStop", function() alertFrame:StopMovingOrSizing() end)
alertFrame:SetFrameLevel(200)
alertFrame:SetClampedToScreen(true)

-- Title
local title = alertFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
title:SetPoint("TOP", alertFrame, "TOP", 0, -10)
title:SetText("UPGRADE ALERT!")
title:SetTextColor(1, 0.82, 0, 1)
title:SetJustifyH("CENTER")

-- Icon
local itemIcon = alertFrame:CreateTexture(nil, "ARTWORK")
itemIcon:SetWidth(44)
itemIcon:SetHeight(44)
itemIcon:SetPoint("TOP", alertFrame, "TOP", 0, -34)

-- Item name
local itemNameText = alertFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
itemNameText:SetPoint("TOP", itemIcon, "BOTTOM", 0, -8)
itemNameText:SetTextColor(1, 1, 1, 1)
itemNameText:SetJustifyH("CENTER")
itemNameText:SetWidth(330)

-- Source text
local sourceText = alertFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
sourceText:SetPoint("TOP", itemNameText, "BOTTOM", 0, -6)
sourceText:SetTextColor(0.7, 0.7, 1, 1)
sourceText:SetJustifyH("CENTER")
sourceText:SetWidth(330)

-- Stat comparison text
local statsText = alertFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
statsText:SetPoint("TOP", sourceText, "BOTTOM", 0, -8)
statsText:SetTextColor(0.4, 1, 0.4, 1)
statsText:SetJustifyH("CENTER")
statsText:SetWidth(330)

-- Close button
local closeBtn = CreateFrame("Button", nil, alertFrame, "UIPanelCloseButton")
closeBtn:SetWidth(28)
closeBtn:SetHeight(28)
closeBtn:SetPoint("TOPRIGHT", alertFrame, "TOPRIGHT", -4, -4)
closeBtn:SetScript("OnClick", function() alertFrame:Hide() end)

-- Display Alert Function
function UA.ShowAlert(itemID, itemLink, texture)
    local data = UA.GetItemData(itemID, itemLink)
    if not data then return false end

    local displayName = data.name or "Unknown Item"
    if itemLink then
        local _, _, linkName = string.find(itemLink, "|h%[(.-)%]|h")
        if linkName then displayName = linkName end
    end

    -- Icon texture fallback
    if texture then
        itemIcon:SetTexture(texture)
    else
        itemIcon:SetTexture("Interface/Icons/INV_Misc_QuestionMark")
    end

    itemNameText:SetText(format("|cffa335ee%s|r", displayName))
    sourceText:SetText(format("Source: %s", data.drop or "Dungeon / Raid Drop"))

    local isUpgrade, reason = UA.IsUpgrade(itemID, itemLink)
    if isUpgrade then
        statsText:SetText(format("|cff00ff00UPGRADE!|r %s", reason))
    else
        statsText:SetText(format("|cffff4444%s|r", reason))
    end

    alertFrame:Show()
    alertFrame:SetAlpha(1)

    -- Flash animation
    alertFrame._timer = 0
    alertFrame._flashTimer = 0
    alertFrame:SetScript("OnUpdate", function()
        if not alertFrame:IsVisible() then return end
        alertFrame._timer = alertFrame._timer + arg1
        alertFrame._flashTimer = alertFrame._flashTimer + arg1

        if alertFrame._flashTimer < 0.6 then
            local alpha = 0.5 + 0.5 * math.sin(alertFrame._flashTimer * 15)
            alertFrame:SetAlpha(alpha)
        else
            alertFrame:SetAlpha(1)
        end

        if alertFrame._timer > 25 then
            alertFrame:Hide()
            alertFrame:SetScript("OnUpdate", nil)
        end
    end)

    PlaySound("QUESTADVENTURECOMPLETE")

    if isUpgrade then
        UA_Print(format("|cff00ff00UPGRADE ALERT:|r |cffa335ee%s|r - %s", displayName, reason))
    end

    return true
end

-- ================================================
-- 8. EVENT HANDLING & LOOT MONITOR
-- ================================================

-- Check loot window when opened (compatible with default UI, pfUI, XLoot)
function UA.CheckLootWindow()
    local numItems = GetNumLootItems()
    if not numItems or numItems == 0 then return end

    for i = 1, numItems do
        if LootSlotIsItem(i) then
            local texture, item, quantity, quality = GetLootSlotInfo(i)
            local link = GetLootSlotLink(i)
            if link and (not quality or quality >= 2) then
                local itemID = UA.GetItemIDFromLink(link)
                if itemID then
                    local isUpgrade = UA.IsUpgrade(itemID, link)
                    if isUpgrade then
                        UA.ShowAlert(itemID, link, texture)
                    end
                end
            end
        end
    end
end

-- Check chat messages for loot links
function UA.CheckLootChatMessage(message)
    if not message then return end
    for itemID in string.gfind(message, "item:(%d+):") do
        itemID = tonumber(itemID)
        if itemID then
            local isUpgrade = UA.IsUpgrade(itemID)
            if isUpgrade then
                UA.ShowAlert(itemID)
            end
        end
    end
end

-- Proactive Boss Mouseover Alert (Clean UnitName API)
local function OnMouseOverUnit()
    if not UnitExists("mouseover") or UnitIsPlayer("mouseover") then return end
    local bossName = UnitName("mouseover")
    if not bossName then return end

    if UA.BOSS_DROPS[bossName] then
        local upgradeCount = 0
        for _, itemID in ipairs(UA.BOSS_DROPS[bossName]) do
            local isUpg = UA.IsUpgrade(itemID)
            if isUpg then
                upgradeCount = upgradeCount + 1
            end
        end

        if upgradeCount > 0 then
            UIErrorsFrame:AddMessage(
                format("|cff00ff00[UpgradeAlert]|r %s drops %d upgrade(s) for your spec!", bossName, upgradeCount),
                1.0, 1.0, 0.0, 1.0
            )
        end
    end
end

-- Consolidated Event Dispatcher
local eventFrame = CreateFrame("Frame", "UpgradeAlertEventFrame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("UPDATE_INVENTORY_ALERTS")
eventFrame:RegisterEvent("LOOT_OPENED")
eventFrame:RegisterEvent("CHAT_MSG_LOOT")
eventFrame:RegisterEvent("UPDATE_MOUSEOVER_UNIT")

eventFrame:SetScript("OnEvent", function()
    if event == "ADDON_LOADED" then
        if arg1 == "UpgradeAlert" then
            if not UpgradeAlertDB then UpgradeAlertDB = {} end
        end
    elseif event == "LOOT_OPENED" then
        UA.CheckLootWindow()
    elseif event == "CHAT_MSG_LOOT" then
        UA.CheckLootChatMessage(arg1)
    elseif event == "UPDATE_MOUSEOVER_UNIT" then
        OnMouseOverUnit()
    end
end)

-- ================================================
-- 9. SLASH COMMANDS
-- ================================================

SLASH_UpgradeAlert1 = "/upgradealert"
SLASH_UpgradeAlert2 = "/ua"
SlashCmdList["UpgradeAlert"] = function(msg)
    local cmd = string.lower(msg or "")
    if cmd == "toggle" then
        if alertFrame:IsVisible() then
            alertFrame:Hide()
        else
            UA.ShowAlert(19958)
        end
    elseif cmd == "db" or cmd == "database" then
        UA_Print("Known High-Priority Upgrades:")
        for id, data in pairs(UA.UPGRADE_DATABASE) do
            if (data.priority or 99) <= 10 then
                UA_Print(format("  * [%d] |cffa335ee%s|r (%s) - Score: %d EP", id, data.name, data.slot, UA.GetItemScore(data)))
            end
        end
    elseif cmd == "gear" then
        UA_Print("Currently Tracked Gear (Live Query):")
        for _, slotName in ipairs(UA.GEAR_DISPLAY_ORDER) do
            local data = UA.GetEquippedItemData(slotName)
            if data then
                UA_Print(format("  %s: |cffa335ee%s|r (%d EP)", slotName, data.name or "Equipped", UA.GetItemScore(data)))
            else
                UA_Print(format("  %s: |cff888888[Empty]|r", slotName))
            end
        end
    elseif cmd == "help" then
        UA_Print("Commands:")
        UA_Print("  /ua toggle - Test/Show alert frame")
        UA_Print("  /ua gear   - Show current equipped gear and EP scores")
        UA_Print("  /ua db     - List curated priority upgrade database")
        UA_Print("  /ua help   - Show this help message")
    else
        UA_Print("Monitoring ZG/MC/BWL/Kara boss & trash drops for Holy Priest upgrades.")
        UA_Print("Type |cff00ff00/ua help|r for commands.")
    end
end
