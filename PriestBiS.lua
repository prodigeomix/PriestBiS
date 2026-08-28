-- PriestBiS.lua
-- Real-time dynamic gear upgrade detection, healing EP scoring, talent sync, and raid roll alerts for Holy & Discipline Priests.
-- Author: prodigeomix (Carbon) (Optimized for Vanilla 1.12.1 / Turtle WoW 1.18.1)
-- Strict Lua 5.0 Compliance

local PriestBiS = {}
local PB = PriestBiS
local UA = PriestBiS
_G.PriestBiS = PriestBiS
_G.UA = PriestBiS

local format = string.format
local tostring = tostring
local tonumber = tonumber
local getglobal = getglobal or function(name) return _G[name] end

-- ================================================
-- 1. COMPATIBILITY SHIM & LOGGING (Vanilla 1.12.1)
-- ================================================

local function PB_Print(msg)
    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage("|cffffd100[PriestBiS]|r " .. tostring(msg))
    end
end
PriestBiS.Print = PB_Print
local UA_Print = PB_Print

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

UA.SLOT_IDS = {
    Head = 1, Neck = 2, Shoulder = 3, Shirt = 4, Chest = 5,
    Belt = 6, Legs = 7, Boots = 8, Wrists = 9, Hands = 10,
    Ring1 = 11, Ring2 = 12, Trinket1 = 13, Trinket2 = 14,
    Back = 15, Mainhand = 16, Offhand = 17, Ranged = 18, Wand = 18, Tabard = 19
}

UA.GEAR_DISPLAY_ORDER = {
    "Head", "Neck", "Shoulder", "Back", "Chest",
    "Wrists", "Hands", "Belt", "Legs", "Boots",
    "Ring1", "Ring2", "Trinket1", "Trinket2",
    "Mainhand", "Offhand", "Wand"
}

-- ================================================
-- 3. CURATED ITEM METADATA (Trinkets & Special Drops)
-- ================================================

UA.ITEM_METADATA = {
    -- === TRINKETS (Curated with Tier, Role and On-Use EP Overrides) ===
    [19958] = { name = "Hazza'rah's Charm of Healing", role = "HEAL", tier = "S", ep_override = 120, drop = "ZG: Edge of Madness (14%)", priority = 1, note = "BiS: -40% Greater Heal cast time & -5% mana cost for 15s" },
    [19395] = { name = "Rejuvenating Gem", role = "HEAL", tier = "S", ep_override = 105, drop = "BWL: Ebonroc/Firemaw/Flamegor", priority = 1, note = "BiS: +66 Healing & +9 MP5 stat stick" },
    [19345] = { name = "Aegis of Preservation", role = "HEAL", tier = "B", ep_override = 45, drop = "BWL: Razorgore (11%)", priority = 42, note = "Defense + on-equip mana proc" },
    [58231] = { name = "Penchant of Humility", role = "HEAL", tier = "A", ep_override = 65, drop = "Custom Turtle Item", priority = 20, note = "Solid +healing & MP5 trinket" },
    [61700] = { name = "Fabric of Time", role = "HEAL", tier = "A", ep_override = 70, drop = "Custom Turtle Item", priority = 20, note = "Strong +healing trinket" },
    [55124] = { name = "Pure Jewel of Draenor", role = "HEAL", tier = "B", ep_override = 40, drop = "UKH: Rupturan (14%)", priority = 49, note = "Meta gem trinket" },
    [19406] = { name = "Drake Fang Talisman", role = "MELEE", tier = "F", ep_override = 0, drop = "BWL: Ebonroc (17%)", priority = 99, note = "Melee AP/Hit - not for priest" },
    [55353] = { name = "Remains of Overwhelming Power", role = "MELEE", tier = "F", ep_override = 0, drop = "UKH: Anomalus (25%)", priority = 99, note = "Melee AP - not for priest" },
    [55275] = { name = "Slivers of Nullification", role = "TANK", tier = "F", ep_override = 0, drop = "UKH: Trash (0.25%)", priority = 99, note = "Tank trinket - not for priest" },

    -- === ZUL'GURUB GEAR (Drop & Note Annotations) ===
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
    [22406] = { drop = "Quest / Dungeon", priority = 10, note = "Epic 1H healing mace" },
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
function UA.ScanItemStats(itemID, itemLink, slotID)
    if not itemID and not itemLink and not slotID then return nil end
    local cacheKey = itemID or itemLink or slotID
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
        itemID = UA.GetItemIDFromLink(rawLink)
    end

    scanTooltip:SetOwner(UIParent, "ANCHOR_NONE")
    scanTooltip:ClearLines()
    if slotID and GetInventoryItemLink and GetInventoryItemLink("player", slotID) then
        pcall(function() scanTooltip:SetInventoryItem("player", slotID) end)
    elseif rawLink then
        pcall(function() scanTooltip:SetHyperlink(rawLink) end)
    end

    local stats = {
        name = "",
        slot = nil,
        itemType = nil,
        subType = nil,
        setName = nil,
        restrictedClasses = nil,
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

                -- Detect Set Name (e.g. "Vestments of Transcendence (0/8)", "Vestments of Prophecy (2/8)", "Major Mojo Infusion (1/2)")
                if not stats.setName then
                    local _, _, sName = string.find(text, "([^%(]+)%s*%(%d+/%d+%)")
                    if sName and sName ~= "" then
                        local clean = string.gsub(sName, "^%s+", "")
                        clean = string.gsub(clean, "%s+$", "")
                        stats.setName = clean
                    end
                end

                -- Check Class restrictions (e.g. "Classes: Druid, Shaman, Paladin")
                local _, _, classStr = string.find(text, "Classes:%s*(.+)")
                if not classStr then _, _, classStr = string.find(text, "Klassen:%s*(.+)") end
                if not classStr then _, _, classStr = string.find(text, "Classes%s*:%s*(.+)") end
                if classStr then
                    stats.restrictedClasses = {}
                    if string.find(classStr, "Priest") or string.find(classStr, "Priester") or string.find(classStr, "Prêtre") then
                        stats.restrictedClasses["PRIEST"] = true
                    end
                end

                -- Match +Healing
                local _, _, val = string.find(text, "Increases healing done by spells and effects by up to (%d+)")
                if not val then _, _, val = string.find(text, "Increases healing done by up to (%d+)") end
                if not val then _, _, val = string.find(text, "Increases healing done by magical spells and effects by up to (%d+)") end
                if not val then _, _, val = string.find(text, "Increases healing by up to (%d+)") end
                if val then stats.healing = stats.healing + tonumber(val) end

                local _, _, val2 = string.find(text, "%+(%d+) Healing Spells")
                if not val2 then _, _, val2 = string.find(text, "%+(%d+) Healing") end
                if not val2 then _, _, val2 = string.find(text, "(%d+) Healing Spells") end
                if val2 then stats.healing = stats.healing + tonumber(val2) end

                -- Match +Damage and Healing (applies 100% to healing in vanilla)
                local _, _, valDH = string.find(text, "Increases damage and healing done by magical spells and effects by up to (%d+)")
                if not valDH then _, _, valDH = string.find(text, "Increases damage and healing done by spells and effects by up to (%d+)") end
                if not valDH then _, _, valDH = string.find(text, "Increases spell damage and healing by up to (%d+)") end
                if not valDH then _, _, valDH = string.find(text, "Increases damage and healing by up to (%d+)") end
                if not valDH then _, _, valDH = string.find(text, "Increases damage and healing done by Holy spells and effects by up to (%d+)") end
                if valDH then stats.healing = stats.healing + tonumber(valDH) end

                local _, _, valDH2 = string.find(text, "%+(%d+) Spell Damage and Healing")
                if not valDH2 then _, _, valDH2 = string.find(text, "%+(%d+) Damage and Healing Spells") end
                if not valDH2 then _, _, valDH2 = string.find(text, "%+(%d+) Damage and Healing") end
                if not valDH2 then _, _, valDH2 = string.find(text, "%+(%d+) Spell Power") end
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
                if not valMP5 then _, _, valMP5 = string.find(text, "Restores (%d+) [Mm]ana per 5 [Ss]ec") end
                if not valMP5 then _, _, valMP5 = string.find(text, "(%d+) Mana every 5 sec%.") end
                if not valMP5 then _, _, valMP5 = string.find(text, "(%d+) Mana per 5 sec%.") end
                if not valMP5 then _, _, valMP5 = string.find(text, "(%d+) [Mm]ana per 5 [Ss]ec") end
                if not valMP5 then _, _, valMP5 = string.find(text, "(%d+) [Mm]ana every 5 [Ss]ec") end
                if valMP5 then stats.mp5 = stats.mp5 + tonumber(valMP5) end

                -- Match Spell Crit
                local _, _, valCrit = string.find(text, "Increases your chance to get a critical strike with spells by (%d+)%%")
                if not valCrit then _, _, valCrit = string.find(text, "Improves your chance to get a critical strike with spells by (%d+)%%") end
                if not valCrit then _, _, valCrit = string.find(text, "Increases your chance to get a critical strike with holy spells by (%d+)%%") end
                if not valCrit then _, _, valCrit = string.find(text, "Improves your chance to get a critical strike with holy spells by (%d+)%%") end
                if not valCrit then _, _, valCrit = string.find(text, "%+(%d+)%% Spell Critical Strike") end
                if not valCrit then _, _, valCrit = string.find(text, "%+(%d+)%% Spell Critical") end
                if not valCrit then _, _, valCrit = string.find(text, "%+(%d+)%% Critical Strike") end
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

            if rText and rText ~= "" then
                -- Detect armor / weapon subtype from right-aligned text
                if not stats.subType then
                    if string.find(rText, "Leather") or string.find(rText, "Leder") or string.find(rText, "Cuir") then stats.subType = "Leather"
                    elseif string.find(rText, "Mail") or string.find(rText, "Schwere Rüstung") or string.find(rText, "Maille") then stats.subType = "Mail"
                    elseif string.find(rText, "Plate") or string.find(rText, "Platte") or string.find(rText, "Plaques") then stats.subType = "Plate"
                    elseif string.find(rText, "Cloth") or string.find(rText, "Stoff") or string.find(rText, "Tissu") then stats.subType = "Cloth"
                    elseif string.find(rText, "Shield") or string.find(rText, "Schild") or string.find(rText, "Bouclier") then stats.subType = "Shield"
                    elseif string.find(rText, "Sword") or string.find(rText, "Schwert") or string.find(rText, "Epée") then stats.subType = "Sword"
                    elseif string.find(rText, "Axe") or string.find(rText, "Axt") or string.find(rText, "Hache") then stats.subType = "Axe"
                    elseif string.find(rText, "Polearm") or string.find(rText, "Stangenwaffe") or string.find(rText, "Arme d'hast") then stats.subType = "Polearm"
                    elseif string.find(rText, "Two%-Handed Mace") then stats.subType = "Two-Handed Mace"
                    elseif string.find(rText, "Mace") or string.find(rText, "Streitkolben") or string.find(rText, "Masse") then stats.subType = "Mace"
                    elseif string.find(rText, "Dagger") or string.find(rText, "Dolch") or string.find(rText, "Dague") then stats.subType = "Dagger"
                    elseif string.find(rText, "Staff") or string.find(rText, "Stab") or string.find(rText, "Bâton") then stats.subType = "Staff"
                    elseif string.find(rText, "Wand") or string.find(rText, "Zauberstab") or string.find(rText, "Baguette") then stats.subType = "Wand"
                    elseif string.find(rText, "Bow") or string.find(rText, "Bogen") or string.find(rText, "Arc") then stats.subType = "Bow"
                    elseif string.find(rText, "Gun") or string.find(rText, "Schusswaffe") or string.find(rText, "Arme à feu") then stats.subType = "Gun"
                    elseif string.find(rText, "Crossbow") or string.find(rText, "Armbrust") or string.find(rText, "Arbalète") then stats.subType = "Crossbow"
                    end
                end

                if not stats.slot then
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
    end

    if itemID or itemLink then
        local name, _, _, _, _, itemType, itemSubType, _, equipSlot = GetItemInfo(itemID or itemLink)
        if name and stats.name == "" then stats.name = name end
        if itemType then stats.itemType = itemType end
        if itemSubType and (not stats.subType or stats.subType == "") then stats.subType = itemSubType end
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

-- Dynamically query item drop sources and quest origins from pfQuest/pfDB if present
function UA.GetItemSourceFromPfDB(itemID)
    if not itemID or not pfDB or not pfDB["items"] or not pfDB["items"]["data"] then
        return nil
    end

    local itemData = pfDB["items"]["data"][itemID]
    if not itemData then return nil end

    local units = {}

    -- Direct Unit Drops
    if itemData["U"] then
        for unitID, rate in pairs(itemData["U"]) do
            table.insert(units, { id = unitID, rate = tonumber(rate) or 0 })
        end
    end

    -- Refloot (Shared raid/dungeon loot tables)
    if itemData["R"] and pfDB["refloot"] and pfDB["refloot"]["data"] then
        for refID, _ in pairs(itemData["R"]) do
            local ref = pfDB["refloot"]["data"][refID]
            if ref and ref["U"] then
                for unitID, rate in pairs(ref["U"]) do
                    table.insert(units, { id = unitID, rate = tonumber(rate) or 0 })
                end
            end
        end
    end

    -- Quest Rewards
    if itemData["Q"] and pfDB["quests"] then
        local questNames = pfDB["quests"]["loc"] or pfDB["quests"]["enUS"]
        if questNames then
            for questID, _ in pairs(itemData["Q"]) do
                local qName = questNames[questID]
                if qName then
                    return "Quest: " .. qName
                end
            end
        end
    end

    -- Units / Bosses
    local numUnits = table.getn(units)
    if numUnits > 0 then
        local unitNames = (pfDB["units"] and (pfDB["units"]["loc"] or pfDB["units"]["enUS"])) or {}
        if numUnits == 1 then
            local uName = unitNames[units[1].id]
            if uName then
                if units[1].rate > 0 and units[1].rate < 1 then
                    return format("Drop: %s (%.1f%%)", uName, units[1].rate * 100)
                else
                    return "Drop: " .. uName
                end
            end
        elseif numUnits > 1 then
            local firstBoss = unitNames[units[1].id]
            local secondBoss = unitNames[units[2].id]
            if firstBoss and secondBoss then
                if numUnits > 2 then
                    return format("Drop: %s, %s (+%d more)", firstBoss, secondBoss, numUnits - 2)
                else
                    return format("Drop: %s, %s", firstBoss, secondBoss)
                end
            elseif firstBoss then
                return "Drop: " .. firstBoss .. " (Shared)"
            end
        end
    end

    return nil
end

-- Get comprehensive item data (merging dynamic tooltip stats + curated metadata overrides)
function UA.GetItemData(itemID, itemLink, slotID)
    -- 1. Always dynamically scan the true, live tooltip stats directly from the game client
    local itemData = UA.ScanItemStats(itemID, itemLink, slotID)
    if not itemData then
        -- Fallback if tooltip scanning is unavailable but itemID has metadata
        local meta = itemID and (UA.ITEM_METADATA and UA.ITEM_METADATA[itemID])
        if meta then
            itemData = {
                name = meta.name or ("Item #" .. itemID),
                slot = meta.slot or "Trinket",
                role = meta.role or "HEAL",
                tier = meta.tier or "S",
                ep_override = meta.ep_override,
                drop = meta.drop,
                note = meta.note,
                healing = 0, spi = 0, int = 0, mp5 = 0, crit = 0, stam = 0, spell_damage = 0
            }
            return itemData
        end
        return nil
    end

    -- 2. Enrich with metadata / special on-use trinket overrides if present
    local meta = itemID and (UA.ITEM_METADATA and UA.ITEM_METADATA[itemID])
    if meta then
        if meta.ep_override then itemData.ep_override = meta.ep_override end
        if meta.role then itemData.role = meta.role end
        if meta.tier then itemData.tier = meta.tier end
        if meta.drop then itemData.drop = meta.drop end
        if meta.note then itemData.note = meta.note end
    end

    -- 3. If drop source is unknown, query pfQuest / pfDB dynamically
    if not itemData.drop and itemID then
        local pfSource = UA.GetItemSourceFromPfDB(itemID)
        if pfSource then
            itemData.drop = pfSource
        end
    end

    return itemData
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

-- Query currently equipped item ID for a slot directly from game inventory
function UA.GetEquippedItemID(slotName)
    local slotID = UA.SLOT_IDS[slotName]
    if slotID and GetInventoryItemLink then
        local link = GetInventoryItemLink("player", slotID)
        if link then
            local id = UA.GetItemIDFromLink(link)
            if id then return id end
        end
    end
    return nil
end

-- Check if an item is currently equipped in its slot
function UA.IsItemEquipped(itemID, slot)
    if not itemID then return false end
    if slot == "Ring" then
        local id1 = UA.GetEquippedItemID("Ring1")
        local id2 = UA.GetEquippedItemID("Ring2")
        return (itemID == id1) or (itemID == id2)
    elseif slot == "Trinket" then
        local id1 = UA.GetEquippedItemID("Trinket1")
        local id2 = UA.GetEquippedItemID("Trinket2")
        return (itemID == id1) or (itemID == id2)
    elseif slot == "Mainhand" or slot == "Twohand" or slot == "Staff" then
        return itemID == UA.GetEquippedItemID("Mainhand")
    elseif slot == "Offhand" then
        return itemID == UA.GetEquippedItemID("Offhand")
    elseif slot == "Wand" or slot == "Ranged" then
        return itemID == UA.GetEquippedItemID("Wand") or itemID == UA.GetEquippedItemID("Ranged")
    elseif slot and UA.SLOT_IDS[slot] then
        return itemID == UA.GetEquippedItemID(slot)
    end
    return false
end

-- Format a clean human-readable breakdown of stat EP contributions
function UA.FormatStatBreakdown(itemData)
    if not itemData then return "" end
    if itemData.ep_override then
        return format("|cff888888Special: Curated Tier %s Effect (%d EP)|r", itemData.tier or "S", itemData.ep_override)
    end

    local parts = {}
    if itemData.healing and itemData.healing > 0 then
        table.insert(parts, format("+%d Heal", itemData.healing))
    end
    if itemData.spi and itemData.spi > 0 then
        local epSpi = itemData.spi * UA.STAT_WEIGHTS.spi
        table.insert(parts, format("+%d Spi (%.1f)", itemData.spi, epSpi))
    end
    if itemData.mp5 and itemData.mp5 > 0 then
        local epMp5 = itemData.mp5 * UA.STAT_WEIGHTS.mp5
        table.insert(parts, format("+%d MP5 (%.1f)", itemData.mp5, epMp5))
    end
    if itemData.crit and itemData.crit > 0 then
        local epCrit = itemData.crit * UA.STAT_WEIGHTS.spell_crit
        table.insert(parts, format("+%d%% Crit (%.1f)", itemData.crit, epCrit))
    end
    if itemData.int and itemData.int > 0 then
        local epInt = itemData.int * UA.STAT_WEIGHTS.int
        table.insert(parts, format("+%d Int (%.1f)", itemData.int, epInt))
    end
    if itemData.stam and itemData.stam > 0 then
        local epStam = itemData.stam * UA.STAT_WEIGHTS.stamina
        table.insert(parts, format("+%d Stam (%.1f)", itemData.stam, epStam))
    end

    local numParts = table.getn(parts)
    if numParts == 0 then
        return ""
    end

    local str = "|cff888888Breakdown: "
    for i = 1, numParts do
        str = str .. (i > 1 and " | " or "") .. parts[i]
    end
    str = str .. "|r"
    return str
end

-- Query currently equipped item for a specific slot directly from the engine
function UA.GetEquippedItemData(slotName)
    local slotID = UA.SLOT_IDS[slotName]
    if not slotID then return nil end

    local link = GetInventoryItemLink and GetInventoryItemLink("player", slotID)
    if link then
        local itemID = UA.GetItemIDFromLink(link)
        if itemID then
            local data = UA.GetItemData(itemID, link, slotID)
            if data then return data end
        end
    end

    return nil
end

-- Extract item ID from item link or itemID string/number
function UA.GetItemIDFromLink(itemLink)
    if not itemLink then return nil end
    if type(itemLink) == "number" then return itemLink end
    local _, _, itemID = string.find(tostring(itemLink), "item:(%d+)")
    if itemID then return tonumber(itemID) end
    if tonumber(itemLink) then return tonumber(itemLink) end
    return nil
end

-- ================================================
-- 6. CORE UPGRADE COMPARISON LOGIC & EQUIPABILITY
-- ================================================

-- Priest Armor & Weapon Equipability Rules
local PRIEST_PROHIBITED_ARMOR = {
    ["Leather"] = true, ["Leder"] = true, ["Cuir"] = true,
    ["Mail"] = true, ["Schwere Rüstung"] = true, ["Maille"] = true,
    ["Plate"] = true, ["Platte"] = true, ["Plaques"] = true,
    ["Shield"] = true, ["Shields"] = true, ["Schild"] = true, ["Bouclier"] = true,
}

local PRIEST_PROHIBITED_WEAPONS = {
    ["Sword"] = true, ["One-Handed Swords"] = true, ["Two-Handed Swords"] = true, ["Schwert"] = true, ["Epée"] = true,
    ["Axe"] = true, ["One-Handed Axes"] = true, ["Two-Handed Axes"] = true, ["Axt"] = true, ["Hache"] = true,
    ["Two-Handed Maces"] = true, ["Zweihandstreitkolben"] = true,
    ["Polearm"] = true, ["Polearms"] = true, ["Stangenwaffe"] = true, ["Arme d'hast"] = true,
    ["Bow"] = true, ["Bows"] = true, ["Bogen"] = true, ["Arc"] = true,
    ["Gun"] = true, ["Guns"] = true, ["Schusswaffe"] = true, ["Arme à feu"] = true,
    ["Crossbow"] = true, ["Crossbows"] = true, ["Armbrust"] = true, ["Arbalète"] = true,
    ["Thrown"] = true, ["Wurfwaffe"] = true,
    ["Fist Weapon"] = true, ["Fist Weapons"] = true, ["Faustwaffe"] = true,
}

-- Check whether an item can be physically equipped by a Priest
function UA.IsItemEquipableByPriest(itemData, itemID, itemLink)
    if not itemData then return false end

    -- Must have a valid equipment slot
    local slot = itemData.slot
    if not slot or slot == "" or slot == "Shirt" or slot == "Tabard" then
        return false
    end

    -- Class restriction check (e.g. "Classes: Druid, Shaman, Paladin")
    if itemData.restrictedClasses and not itemData.restrictedClasses["PRIEST"] then
        return false
    end

    -- Tooltip subtype check
    local subType = itemData.subType
    if subType and subType ~= "" then
        -- Armor slots (Head, Shoulder, Chest, Wrists, Hands, Belt, Legs, Boots) CANNOT be Leather, Mail, Plate, Shield
        if slot ~= "Ring" and slot ~= "Neck" and slot ~= "Trinket" and slot ~= "Back" then
            if PRIEST_PROHIBITED_ARMOR[subType] then
                return false
            end
        end

        -- Weapon slots CANNOT be Swords, Axes, 2H Maces, Polearms, Bows, Guns, Shields
        if slot == "Mainhand" or slot == "Twohand" or slot == "Offhand" or slot == "Wand" then
            if PRIEST_PROHIBITED_WEAPONS[subType] or subType == "Shield" then
                return false
            end
        end
    end

    -- Engine GetItemInfo check
    local linkOrID = itemLink or itemID
    if linkOrID and GetItemInfo then
        local _, _, _, _, _, itemType, itemSubType, _, itemEquipLoc = GetItemInfo(linkOrID)
        if itemEquipLoc == "INVTYPE_SHIELD" or itemEquipLoc == "INVTYPE_RELIC" or itemEquipLoc == "INVTYPE_THROWN" or itemEquipLoc == "INVTYPE_AMMO" then
            return false
        end

        if itemType == "Armor" then
            if slot ~= "Ring" and slot ~= "Neck" and slot ~= "Trinket" and slot ~= "Back" then
                if itemSubType and PRIEST_PROHIBITED_ARMOR[itemSubType] then
                    return false
                end
            end
        elseif itemType == "Weapon" then
            if itemSubType and PRIEST_PROHIBITED_WEAPONS[itemSubType] then
                return false
            end
        end
    end

    return true
end

-- Known Priest Set Bonus Breakpoints & EP Values
UA.SET_BONUSES = {
    ["Vestments of Transcendence"] = {
        [3] = { ep = 25, desc = "3-Piece Bonus: +15% Mana Regen while casting" },
    },
    ["Gewänder der Transzendenz"] = {
        [3] = { ep = 25, desc = "3-Set: +15% Manaregeneration während des Zauberns" },
    },
    ["Habits de transcendance"] = {
        [3] = { ep = 25, desc = "Bonus 3 pièces: +15% Récupération de mana pendant l'incantation" },
    },
    ["Vestments of Prophecy"] = {
        [3] = { ep = 15, desc = "3-Piece Bonus: -0.1s Flash Heal cast time" },
    },
    ["Gewänder der Prophezeiung"] = {
        [3] = { ep = 15, desc = "3-Set: -0.1s Zauberzeit von Blitzheilung" },
    },
    ["Habits de prophétie"] = {
        [3] = { ep = 15, desc = "Bonus 3 pièces: -0.1s temps d'incantation de Soins rapides" },
    },
    ["Major Mojo Infusion"] = {
        [2] = { ep = 21, desc = "2-Piece Set Bonus: +21 Healing & Spell Damage" },
    },
    ["The Postulant's Regalia"] = {
        [2] = { ep = 20, desc = "2-Piece Set Bonus: +20 Healing" },
    },
    ["Confessor's Raiment"] = {
        [2] = { ep = 22, desc = "2-Piece Set Bonus: +22 Spell Power" },
    },
}

-- Count how many pieces of a set are currently equipped on the player
function UA.GetEquippedSetCount(setName)
    if not setName or setName == "" then return 0 end
    local count = 0
    for _, slotName in ipairs(UA.GEAR_DISPLAY_ORDER) do
        local equipped = UA.GetEquippedItemData(slotName)
        if equipped and equipped.setName == setName then
            count = count + 1
        end
    end
    return count
end

-- Get structured comparison details against currently equipped gear
function UA.GetUpgradeComparison(itemID, itemLink)
    local itemData = UA.GetItemData(itemID, itemLink)
    if not itemData then
        return nil
    end

    local slot = itemData.slot
    if not slot then
        return nil
    end

    local parsedID = itemID or UA.GetItemIDFromLink(itemLink)
    local isEquipped = UA.IsItemEquipped(parsedID, slot)
    local newScore = UA.GetItemScore(itemData)
    local isEquipable = UA.IsItemEquipableByPriest(itemData, itemID, itemLink)

    -- --------------------------------------------
    -- SET BONUS BREAKPOINT CALCULATION
    -- --------------------------------------------
    local setBonusEP = 0
    local setBonusDesc = nil
    if itemData.setName and UA.SET_BONUSES[itemData.setName] then
        local curCount = UA.GetEquippedSetCount(itemData.setName)
        local currentItemInSlot = UA.GetEquippedItemData(slot)
        local replacingSameSet = currentItemInSlot and currentItemInSlot.setName == itemData.setName
        local projectedCount = replacingSameSet and curCount or (curCount + 1)

        for breakpoint, bonusData in pairs(UA.SET_BONUSES[itemData.setName]) do
            if curCount < breakpoint and projectedCount >= breakpoint then
                setBonusEP = setBonusEP + (bonusData.ep or 0)
                setBonusDesc = bonusData.desc
            end
        end
    end

    if setBonusEP > 0 then
        newScore = newScore + setBonusEP
    end

    local result = {
        itemData = itemData,
        newItemName = itemData.name,
        slot = slot,
        newScore = newScore,
        currentScore = 0,
        delta = 0,
        pct = nil,
        isUpgrade = false,
        isEquipped = isEquipped,
        isEquipable = isEquipable,
        replaceSlot = slot,
        currentItemName = nil,
        drop = itemData.drop,
        note = itemData.note,
        setBonusEP = setBonusEP,
        setBonusDesc = setBonusDesc,
        roleMismatch = false,
        reason = "",
    }

    -- --------------------------------------------
    -- EQUIPABILITY RESTRICTION CHECK
    -- --------------------------------------------
    if not isEquipable then
        result.isUpgrade = false
        result.roleMismatch = true
        if itemData.restrictedClasses and not itemData.restrictedClasses["PRIEST"] then
            result.reason = "Class restriction (Not for Priest)"
        elseif itemData.subType and itemData.subType ~= "" then
            result.reason = "Cannot equip " .. itemData.subType .. " (Priest restriction)"
        else
            result.reason = "Cannot equip this item (Priest restriction)"
        end
        return result
    end

    if isEquipped then
        result.isUpgrade = false
        result.currentScore = newScore
        result.currentItemName = itemData.name
        result.delta = 0
        result.reason = format("Currently Equipped (%d EP)", newScore)
        return result
    end

    -- --------------------------------------------
    -- TRINKETS: Role check + Min-Score replacement
    -- --------------------------------------------
    if slot == "Trinket" then
        if itemData.role and itemData.role ~= "HEAL" then
            result.roleMismatch = true
            result.isUpgrade = false
            result.reason = "Non-healer trinket (" .. itemData.role .. ")"
            return result
        end

        local t1 = UA.GetEquippedItemData("Trinket1")
        local t2 = UA.GetEquippedItemData("Trinket2")
        local score1 = UA.GetItemScore(t1)
        local score2 = UA.GetItemScore(t2)

        local minScore = math.min(score1, score2)
        local replaceSlot = (score1 <= score2) and "Trinket1" or "Trinket2"
        local targetItem = (score1 <= score2) and t1 or t2

        result.replaceSlot = replaceSlot
        result.currentScore = minScore
        result.currentItemName = targetItem and targetItem.name or replaceSlot
        result.delta = newScore - minScore
        if minScore > 0 then
            result.pct = ((newScore - minScore) / minScore) * 100
        end

        if newScore > minScore then
            result.isUpgrade = true
            result.reason = format("Trinket Upgrade over %s (+%d EP, %d -> %d)", replaceSlot, result.delta, minScore, newScore)
        else
            result.isUpgrade = false
            result.reason = format("Trinket Downgrade vs %s (%d vs %d EP)", replaceSlot, newScore, minScore)
        end
        return result
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
        local targetItem = (score1 <= score2) and r1 or r2

        result.replaceSlot = replaceSlot
        result.currentScore = minScore
        result.currentItemName = targetItem and targetItem.name or replaceSlot
        result.delta = newScore - minScore
        if minScore > 0 then
            result.pct = ((newScore - minScore) / minScore) * 100
        end

        if newScore > minScore then
            result.isUpgrade = true
            result.reason = format("Ring Upgrade over %s (+%d EP, %d -> %d)", replaceSlot, result.delta, minScore, newScore)
        else
            result.isUpgrade = false
            result.reason = format("Ring Downgrade vs %s (%d vs %d EP)", replaceSlot, newScore, minScore)
        end
        return result
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

        result.replaceSlot = "2H (MH+OH)"
        result.currentScore = currentSetScore
        local mhName = mh and mh.name or "Mainhand"
        local ohName = oh and oh.name or "Offhand"
        result.currentItemName = mhName .. " + " .. ohName
        result.delta = newScore - currentSetScore
        if currentSetScore > 0 then
            result.pct = ((newScore - currentSetScore) / currentSetScore) * 100
        end

        if newScore > currentSetScore then
            result.isUpgrade = true
            result.reason = format("2H Upgrade over MH+OH Set (+%d EP: %d vs %d)", result.delta, newScore, currentSetScore)
        else
            result.isUpgrade = false
            result.reason = format("2H Downgrade vs MH+OH Set (%d vs %d EP)", newScore, currentSetScore)
        end
        return result
    end

    if slot == "Mainhand" then
        local currentMH = UA.GetEquippedItemData("Mainhand")
        if currentMH and (currentMH.slot == "Twohand" or currentMH.slot == "Staff") then
            -- Currently wielding a 2H staff; compare New MH + Current OH vs Current 2H
            local current2HScore = UA.GetItemScore(currentMH)
            local currentOH = UA.GetEquippedItemData("Offhand")
            local ohScore = UA.GetItemScore(currentOH)
            local projectedScore = newScore + ohScore

            result.replaceSlot = "Mainhand"
            result.currentScore = current2HScore
            result.currentItemName = currentMH.name or "2H Staff"
            result.delta = projectedScore - current2HScore
            if current2HScore > 0 then
                result.pct = ((projectedScore - current2HScore) / current2HScore) * 100
            end

            if projectedScore > current2HScore then
                result.isUpgrade = true
                result.reason = format("1H Upgrade over 2H Staff (+%d EP: %d vs %d)", result.delta, projectedScore, current2HScore)
            else
                result.isUpgrade = false
                result.reason = format("1H Downgrade vs 2H Staff (%d vs %d EP)", projectedScore, current2HScore)
            end
            return result
        else
            local currentScore = UA.GetItemScore(currentMH)
            result.replaceSlot = "Mainhand"
            result.currentScore = currentScore
            result.currentItemName = currentMH and currentMH.name or "Mainhand"
            result.delta = newScore - currentScore
            if currentScore > 0 then
                result.pct = ((newScore - currentScore) / currentScore) * 100
            end

            if newScore > currentScore then
                result.isUpgrade = true
                result.reason = format("Mainhand Upgrade (+%d EP: %d -> %d)", result.delta, currentScore, newScore)
            else
                result.isUpgrade = false
                result.reason = format("Mainhand Downgrade (%d vs %d EP)", newScore, currentScore)
            end
            return result
        end
    end

    if slot == "Offhand" then
        local currentOH = UA.GetEquippedItemData("Offhand")
        local currentScore = UA.GetItemScore(currentOH)
        result.replaceSlot = "Offhand"
        result.currentScore = currentScore
        result.currentItemName = currentOH and currentOH.name or "Offhand"
        result.delta = newScore - currentScore
        if currentScore > 0 then
            result.pct = ((newScore - currentScore) / currentScore) * 100
        end

        if newScore > currentScore then
            result.isUpgrade = true
            result.reason = format("Offhand Upgrade (+%d EP: %d -> %d)", result.delta, currentScore, newScore)
        else
            result.isUpgrade = false
            result.reason = format("Offhand Downgrade (%d vs %d EP)", newScore, currentScore)
        end
        return result
    end

    -- --------------------------------------------
    -- STANDARD SINGLE SLOTS
    -- --------------------------------------------
    local currentItem = UA.GetEquippedItemData(slot)
    if not currentItem then
        result.replaceSlot = slot
        result.currentScore = 0
        result.currentItemName = "[Empty Slot]"
        result.delta = newScore
        result.isUpgrade = (newScore > 0)
        result.reason = format("Slot %s is empty - Free Upgrade (+%d EP)", slot, newScore)
        return result
    end

    local currentScore = UA.GetItemScore(currentItem)
    result.replaceSlot = slot
    result.currentScore = currentScore
    result.currentItemName = currentItem.name or slot
    result.delta = newScore - currentScore
    if currentScore > 0 then
        result.pct = ((newScore - currentScore) / currentScore) * 100
    end

    if newScore > currentScore then
        result.isUpgrade = true
        result.reason = format("Score: %d -> %d (+%d EP)", currentScore, newScore, result.delta)
    else
        result.isUpgrade = false
        result.reason = format("Downgrade: %d vs %d EP", newScore, currentScore)
    end
    return result
end

-- Check if candidate item is an upgrade over currently equipped gear
function UA.IsUpgrade(itemID, itemLink)
    local comp = UA.GetUpgradeComparison(itemID, itemLink)
    if not comp then
        return false, "Item data unavailable"
    end
    return comp.isUpgrade, comp.reason
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

local alertFrame = CreateFrame("Frame", "PriestBiSAlertFrame", UIParent)
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
-- 8. TOOLTIP INTEGRATION & UPGRADE ALERT BADGES
-- ================================================

local insideAppend = false
function UA.AppendTooltipUpgradeInfo(tooltip, link)
    if insideAppend then return end
    if not tooltip or not link then return end
    if tooltip == getglobal("UAScanningTooltip") then return end

    if PriestBiSDB and PriestBiSDB.tooltipAlerts == false then
        return
    end

    local itemID = UA.GetItemIDFromLink(link)
    if not itemID then return end

    local comp = UA.GetUpgradeComparison(itemID, link)
    if not comp or not comp.slot then return end

    -- Check if [PriestBiS] is ALREADY in the tooltip
    local tooltipName = (tooltip.GetName and tooltip:GetName()) or tooltip.name
    if tooltipName then
        local num = tooltip.NumLines and tooltip:NumLines()
        if num and num > 0 then
            for i = 1, num do
                local line = getglobal(tooltipName .. "TextLeft" .. i)
                local text = line and line:GetText()
                if text and string.find(text, "%[PriestBiS%]") then
                    return
                end
            end
        end
    end

    insideAppend = true

    if comp.isEquipped then
        tooltip:AddLine(" ")
        tooltip:AddLine(format("|cffffd100[PriestBiS]|r |cffffffffCurrently Equipped:|r |cffffd100%d EP|r (|cffa335ee%s|r)", comp.newScore, comp.slot), 0.9, 0.9, 0.9)
        local breakdown = UA.FormatStatBreakdown(comp.itemData)
        if breakdown and breakdown ~= "" then
            tooltip:AddLine("  " .. breakdown, 0.6, 0.6, 0.6)
        end
        if comp.drop then
            tooltip:AddLine(format("  |cff71d5ffSource:|r %s", comp.drop), 0.6, 0.8, 1)
        end
        if comp.note then
            tooltip:AddLine(format("  |cffffd100Note:|r %s", comp.note), 1, 0.82, 0)
        end
    elseif comp.isUpgrade then
        tooltip:AddLine(" ")
        local pctStr = comp.pct and format(" / +%.1f%%", comp.pct) or ""
        tooltip:AddLine(format("|cff00ff00[PriestBiS] UPGRADE (+%d EP%s)|r", comp.delta, pctStr), 0, 1, 0)
        
        local replaceTarget = comp.currentItemName or comp.replaceSlot or comp.slot
        tooltip:AddLine(format("  |cffffffffReplaces:|r |cffa335ee%s|r (|cffffd100%d EP|r -> |cff00ff00%d EP|r)", replaceTarget, comp.currentScore, comp.newScore), 0.9, 0.9, 0.9)
        
        local breakdown = UA.FormatStatBreakdown(comp.itemData)
        if breakdown and breakdown ~= "" then
            tooltip:AddLine("  " .. breakdown, 0.6, 0.6, 0.6)
        end
        if comp.setBonusDesc then
            tooltip:AddLine(format("  |cff00ff00Set Bonus Active:|r %s (+%d EP)", comp.setBonusDesc, comp.setBonusEP), 0, 1, 0)
        end
        if comp.drop then
            tooltip:AddLine(format("  |cff71d5ffSource:|r %s", comp.drop), 0.6, 0.8, 1)
        end
        if comp.note then
            tooltip:AddLine(format("  |cffffd100Note:|r %s", comp.note), 1, 0.82, 0)
        end
    else
        local db = PriestBiSDB
        if db and db.showDowngrades == false then
            insideAppend = false
            return
        end

        tooltip:AddLine(" ")
        if comp.roleMismatch then
            tooltip:AddLine(format("|cffff6666[PriestBiS] %s|r", comp.reason), 1, 0.4, 0.4)
        elseif comp.delta == 0 then
            tooltip:AddLine(format("|cffaaaaaa[PriestBiS] Sidegrade (Equal %d EP vs %s)|r", comp.newScore, comp.currentItemName or comp.slot), 0.7, 0.7, 0.7)
            local breakdown = UA.FormatStatBreakdown(comp.itemData)
            if breakdown and breakdown ~= "" then
                tooltip:AddLine("  " .. breakdown, 0.6, 0.6, 0.6)
            end
        else
            tooltip:AddLine(format("|cff888888[PriestBiS]|r |cffff6666Downgrade (%d vs %d EP, %s)|r", comp.newScore, comp.currentScore, comp.currentItemName or comp.slot), 0.8, 0.5, 0.5)
            local breakdown = UA.FormatStatBreakdown(comp.itemData)
            if breakdown and breakdown ~= "" then
                tooltip:AddLine("  " .. breakdown, 0.6, 0.6, 0.6)
            end
        end
        if comp.drop then
            tooltip:AddLine(format("  |cff71d5ffSource:|r %s", comp.drop), 0.6, 0.8, 1)
        end
        if comp.note then
            tooltip:AddLine(format("  |cffffd100Note:|r %s", comp.note), 1, 0.82, 0)
        end
    end

    tooltip._uaLastLink = link
    if tooltip.Show then
        tooltip:Show()
    end
    insideAppend = false
end

local function HookTooltipMethod(tooltip, methodName, getLinkFn)
    local origMethod = tooltip[methodName]
    if origMethod then
        tooltip[methodName] = function(self, a1, a2, a3, a4)
            local ret = origMethod(self, a1, a2, a3, a4)
            local link = getLinkFn(self, a1, a2, a3, a4)
            if link then
                self._uaLastLink = link
                UA.AppendTooltipUpgradeInfo(self, link)
            end
            return ret
        end
    end
end

function UA.HookTooltipFrame(tooltip)
    if not tooltip or tooltip._uaHooked then return end
    tooltip._uaHooked = true

    -- Hook ClearLines & Hide to reset tracking
    local orig_ClearLines = tooltip.ClearLines
    if orig_ClearLines then
        tooltip.ClearLines = function(self)
            self._uaLastLink = nil
            return orig_ClearLines(self)
        end
    end

    local orig_Hide = tooltip.Hide
    if orig_Hide then
        tooltip.Hide = function(self)
            self._uaLastLink = nil
            return orig_Hide(self)
        end
    end

    -- Hook Show to guarantee our badge is rendered after all lines are assembled
    local orig_Show = tooltip.Show
    if orig_Show then
        tooltip.Show = function(self)
            orig_Show(self)
            if not insideAppend then
                local link = self._uaLastLink or (self.itemID and ("item:" .. tostring(self.itemID) .. ":0:0:0"))
                if link then
                    UA.AppendTooltipUpgradeInfo(self, link)
                end
            end
        end
    end

    -- SetHyperlink (Chat links, AtlasLoot, item links)
    HookTooltipMethod(tooltip, "SetHyperlink", function(self, link) return link end)

    -- Container / Bags / Bank
    HookTooltipMethod(tooltip, "SetBagItem", function(self, bag, slot)
        return GetContainerItemLink and GetContainerItemLink(bag, slot)
    end)

    -- Equipped gear / Inspect
    HookTooltipMethod(tooltip, "SetInventoryItem", function(self, unit, slot)
        return GetInventoryItemLink and GetInventoryItemLink(unit, slot)
    end)

    -- Loot Window
    HookTooltipMethod(tooltip, "SetLootItem", function(self, slot)
        return GetLootSlotLink and GetLootSlotLink(slot)
    end)

    -- Merchant / Vendor
    HookTooltipMethod(tooltip, "SetMerchantItem", function(self, slot)
        return GetMerchantItemLink and GetMerchantItemLink(slot)
    end)

    -- Quest Rewards
    HookTooltipMethod(tooltip, "SetQuestItem", function(self, qType, index)
        return GetQuestItemLink and GetQuestItemLink(qType, index)
    end)
    HookTooltipMethod(tooltip, "SetQuestLogItem", function(self, qType, index)
        return GetQuestLogItemLink and GetQuestLogItemLink(qType, index)
    end)

    -- Auction House
    HookTooltipMethod(tooltip, "SetAuctionItem", function(self, aType, index)
        return GetAuctionItemLink and GetAuctionItemLink(aType, index)
    end)

    -- Craft / TradeSkill
    HookTooltipMethod(tooltip, "SetCraftItem", function(self, skill, slot)
        if slot and GetCraftReagentItemLink then return GetCraftReagentItemLink(skill, slot) end
        return GetCraftItemLink and GetCraftItemLink(skill)
    end)
    HookTooltipMethod(tooltip, "SetTradeSkillItem", function(self, skill, slot)
        if slot and GetTradeSkillReagentItemLink then return GetTradeSkillReagentItemLink(skill, slot) end
        return GetTradeSkillItemLink and GetTradeSkillItemLink(skill)
    end)

    -- Mail / Inbox
    HookTooltipMethod(tooltip, "SetInboxItem", function(self, index)
        return GetInboxItemLink and GetInboxItemLink(index)
    end)

    -- Trade Window
    HookTooltipMethod(tooltip, "SetTradePlayerItem", function(self, slot)
        return GetTradePlayerItemLink and GetTradePlayerItemLink(slot)
    end)
    HookTooltipMethod(tooltip, "SetTradeTargetItem", function(self, slot)
        return GetTradeTargetItemLink and GetTradeTargetItemLink(slot)
    end)
end

-- AtlasLoot Dynamic Integration Hook
function UA.HookAtlasLoot()
    if AtlasLoot_ShowItemsFrame and not UA._orig_AtlasLoot_ShowItemsFrame then
        UA._orig_AtlasLoot_ShowItemsFrame = AtlasLoot_ShowItemsFrame
        AtlasLoot_ShowItemsFrame = function(...)
            UA.HookAllTooltips()
            return UA._orig_AtlasLoot_ShowItemsFrame(unpack(arg))
        end
    end

    if AtlasLootItem_OnEnter and not UA._orig_AtlasLootItem_OnEnter then
        UA._orig_AtlasLootItem_OnEnter = AtlasLootItem_OnEnter
        AtlasLootItem_OnEnter = function(...)
            local button = this
            UA.HookAllTooltips()
            UA._orig_AtlasLootItem_OnEnter(unpack(arg))
            if button and button.itemID and button.itemID ~= 0 then
                local rawID = UA.GetItemIDFromLink(button.itemID)
                if rawID and rawID > 0 then
                    local tt = getglobal("AtlasLootTooltip") or GameTooltip
                    if tt and tt:IsVisible() then
                        UA.AppendTooltipUpgradeInfo(tt, "item:" .. rawID .. ":0:0:0")
                    end
                end
            end
        end
    end

    if AtlasLootItem_OnClick and not UA._orig_AtlasLootItem_OnClick then
        UA._orig_AtlasLootItem_OnClick = AtlasLootItem_OnClick
        AtlasLootItem_OnClick = function(...)
            local button = this
            UA.HookAllTooltips()
            UA._orig_AtlasLootItem_OnClick(unpack(arg))
            if button and button.itemID and button.itemID ~= 0 then
                local rawID = UA.GetItemIDFromLink(button.itemID)
                if rawID and rawID > 0 then
                    local tt = ItemRefTooltip
                    if tt and tt:IsVisible() then
                        UA.AppendTooltipUpgradeInfo(tt, "item:" .. rawID .. ":0:0:0")
                    end
                end
            end
        end
    end
end

function UA.HookAllTooltips()
    if GameTooltip then UA.HookTooltipFrame(GameTooltip) end
    if ItemRefTooltip then UA.HookTooltipFrame(ItemRefTooltip) end
    local atlasFrames = {
        "AtlasLootTooltip", "AtlasLootTooltip2", "AtlasLootTooltip3",
        "AtlasLootItemTooltip", "AtlasLoot_Tooltip", "AtlasLoot_ItemTooltip"
    }
    for _, name in ipairs(atlasFrames) do
        local frame = getglobal(name)
        if frame then UA.HookTooltipFrame(frame) end
    end
    UA.HookAtlasLoot()
end

-- ================================================
-- 9. EVENT HANDLING & LOOT MONITOR
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
                format("|cffffd100[PriestBiS]|r %s drops %d upgrade(s) for your spec!", bossName, upgradeCount),
                1.0, 1.0, 0.0, 1.0
            )
        end
    end
end

-- Dynamically synchronize Holy Priest stat weights with active character talent points
function UA.UpdateDynamicTalentWeights()
    if not GetNumTalents or not GetTalentInfo then return end
    local _, playerClass = UnitClass("player")
    if playerClass ~= "PRIEST" then return end

    local sgRank = 0
    local medRank = 0

    -- Scan Discipline and Holy talent trees
    for tabIndex = 1, 2 do
        local numTalents = GetNumTalents(tabIndex) or 0
        for tIndex = 1, numTalents do
            local name, _, _, _, currentRank = GetTalentInfo(tabIndex, tIndex)
            if name == "Spiritual Guidance" or name == "Geistige Führung" or name == "Directives spirituelles" then
                sgRank = currentRank or 0
            elseif name == "Meditation" then
                medRank = currentRank or 0
            end
        end
    end

    -- Spiritual Guidance: 5% of Spirit as +Healing per rank (0.25 max at 5/5)
    -- Meditation: 5% mana regen while casting per rank (0.15 max at 3/3)
    local sgBonus = sgRank * 0.05
    local medBonus = 0.30 + (medRank * 0.05)
    UA.STAT_WEIGHTS.spi = sgBonus + medBonus

    -- Invalidate stat cache so all items are dynamically re-evaluated
    ITEM_STAT_CACHE = {}
end

-- Monitor raid rolls and LootBlare master loot events for upgrade alerts
function UA.HookLootBlare()
    local itemRollFrame = getglobal("ItemRollFrame")
    if itemRollFrame and not UA.HookedLootBlare then
        UA.HookedLootBlare = true
        local origShow = itemRollFrame.Show
        itemRollFrame.Show = function(self)
            origShow(self)
            local currentLink = self.itemLink
            if not currentLink and LootBlare and LootBlare.state then
                currentLink = LootBlare.state.currentItem
            end
            if currentLink then
                local itemID = UA.GetItemIDFromLink(currentLink)
                if itemID then
                    local comp = UA.GetUpgradeComparison(itemID, currentLink)
                    if comp and comp.isUpgrade then
                        UA.ShowAlert(itemID, currentLink)
                        UA_Print(format("|cffffd100[LootBlare Roll Alert]|r |cff00ff00%s|r is an |cff00ff00UPGRADE (+%d EP / +%.1f%%)|r! Roll now!", comp.name or "Item", comp.diff or 0, comp.pct or 0))
                        if self.name and self.name.GetText and self.name.SetText then
                            local curText = self.name:GetText() or ""
                            if not string.find(curText, "%[UPGRADE") then
                                self.name:SetText(curText .. format("\n|cff00ff00[UPGRADE +%d EP]|r", comp.diff or 0))
                            end
                        end
                    end
                end
            end
        end
    end
end

-- Check raid warning and party/raid chat for active roll announcements
function UA.CheckRaidRollMessage(message)
    if not message then return end
    -- Check if message is a roll call (e.g. "Roll for [Item]", "Roll MS", "Roll SR")
    local lower = string.lower(message)
    local isRollCall = string.find(lower, "roll") or string.find(lower, "wuerfeln") or string.find(lower, "rouler")
    if isRollCall then
        for itemLink in string.gfind(message, "(|c%x+|Hitem:[%d:-]+|h%[[^%]]+%]h|r)") do
            local itemID = UA.GetItemIDFromLink(itemLink)
            if itemID then
                local comp = UA.GetUpgradeComparison(itemID, itemLink)
                if comp and comp.isUpgrade then
                    UA.ShowAlert(itemID, itemLink)
                    UA_Print(format("|cffffd100[Raid Roll Alert]|r %s is an |cff00ff00UPGRADE (+%d EP / +%.1f%%)|r!", itemLink, comp.diff or 0, comp.pct or 0))
                end
            end
        end
    end
end

-- Consolidated Event Dispatcher
local eventFrame = CreateFrame("Frame", "PriestBiSEventFrame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("CHARACTER_POINTS_CHANGED")
eventFrame:RegisterEvent("SPELLS_CHANGED")
eventFrame:RegisterEvent("UPDATE_INVENTORY_ALERTS")
eventFrame:RegisterEvent("LOOT_OPENED")
eventFrame:RegisterEvent("CHAT_MSG_LOOT")
eventFrame:RegisterEvent("CHAT_MSG_RAID_WARNING")
eventFrame:RegisterEvent("CHAT_MSG_RAID")
eventFrame:RegisterEvent("CHAT_MSG_PARTY")
eventFrame:RegisterEvent("UPDATE_MOUSEOVER_UNIT")

eventFrame:SetScript("OnEvent", function()
    if event == "ADDON_LOADED" then
        if not PriestBiSDB then PriestBiSDB = {} end
        if PriestBiSDB.tooltipAlerts == nil then PriestBiSDB.tooltipAlerts = true end
        if PriestBiSDB.showDowngrades == nil then PriestBiSDB.showDowngrades = true end
        UA.HookAllTooltips()
        UA.HookLootBlare()
    elseif event == "PLAYER_ENTERING_WORLD" then
        UA.HookAllTooltips()
        UA.HookLootBlare()
        UA.UpdateDynamicTalentWeights()
    elseif event == "CHARACTER_POINTS_CHANGED" or event == "SPELLS_CHANGED" then
        UA.UpdateDynamicTalentWeights()
    elseif event == "LOOT_OPENED" then
        UA.CheckLootWindow()
    elseif event == "CHAT_MSG_LOOT" then
        UA.CheckLootChatMessage(arg1)
    elseif event == "CHAT_MSG_RAID_WARNING" or event == "CHAT_MSG_RAID" or event == "CHAT_MSG_PARTY" then
        UA.CheckRaidRollMessage(arg1)
    elseif event == "UPDATE_MOUSEOVER_UNIT" then
        OnMouseOverUnit()
    end
end)

-- Hook available tooltips immediately
UA.HookAllTooltips()

-- ================================================
-- 10. SLASH COMMANDS (/priestbis, /pbis, /bis, /ua)
-- ================================================

SLASH_PriestBiS1 = "/priestbis"
SLASH_PriestBiS2 = "/pbis"
SLASH_PriestBiS3 = "/bis"
SLASH_PriestBiS4 = "/ua"

local function PriestBiS_SlashHandler(msg)
    local cmd = string.lower(msg or "")
    local db = PriestBiSDB or {}
    PriestBiSDB = db

    if cmd == "toggle" then
        if alertFrame:IsVisible() then
            alertFrame:Hide()
        else
            UA.ShowAlert(19958)
        end
    elseif cmd == "tooltip" or cmd == "tooltips" then
        db.tooltipAlerts = not db.tooltipAlerts
        UA_Print("Tooltip Upgrade Alerts: " .. (db.tooltipAlerts and "|cff00ff00ENABLED|r" or "|cffff4444DISABLED|r"))
    elseif cmd == "downgrades" or cmd == "downgrade" then
        db.showDowngrades = not db.showDowngrades
        UA_Print("Tooltip Downgrade/Sidegrade Info: " .. (db.showDowngrades and "|cff00ff00ENABLED|r" or "|cffff4444DISABLED|r"))
    elseif cmd == "db" or cmd == "database" then
        UA_Print("Curated High-Priority Upgrades:")
        for id, meta in pairs(UA.ITEM_METADATA) do
            if (meta.priority or 99) <= 10 then
                local itemData = UA.GetItemData(id)
                if itemData then
                    UA_Print(format("  * [%d] |cffa335ee%s|r (%s) - Score: %d EP", id, itemData.name or meta.name or ("Item #" .. id), itemData.slot or "Item", UA.GetItemScore(itemData)))
                end
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
        UA_Print("Commands (/pbis or /bis):")
        UA_Print("  /pbis gear       - Show current equipped gear and EP scores")
        UA_Print("  /pbis toggle     - Test/Show popup alert frame")
        UA_Print("  /pbis tooltip    - Toggle tooltip upgrade badges on/off")
        UA_Print("  /pbis downgrades - Toggle tooltip downgrade/sidegrade info on/off")
        UA_Print("  /pbis db         - List curated priority upgrade database")
        UA_Print("  /pbis help       - Show this help message")
    else
        UA_Print("v1.0.0 by |cffffffffprodigeomix|r (Carbon) - Real-time upgrade monitor for Holy & Discipline Priests.")
        UA_Print("Type |cff00ff00/pbis help|r or |cff00ff00/bis gear|r for commands.")
    end
end

SlashCmdList["PriestBiS"] = PriestBiS_SlashHandler
