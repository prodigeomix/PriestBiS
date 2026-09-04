-- Core/Engine.lua
-- Core stat scanning, EP scoring, talent synchronization, and inventory queries for PriestBiS.
-- Author: prodigeomix (Carbon)
-- Strict Lua 5.0 Compliance

local _G = _G or getfenv(0)
local PriestBiS = PriestBiS or _G.PriestBiS or {}
local UA = PriestBiS.UA or PriestBiS
PriestBiS.UA = UA
_G.PriestBiS = PriestBiS
_G.UA = UA

PriestBiS.VERSION = "1.3.1"
UA.VERSION = "1.3.1"

local format = string.format
local tostring = tostring
local tonumber = tonumber
local getglobal = getglobal or function(name) return _G[name] end

-- Localization proxy table
local L = PriestBiS.L or setmetatable({}, {
    __index = function(t, key)
        local loc = PriestBiS.Locales and PriestBiS.Locales[PriestBiS.clientLocale or "enUS"]
        if loc and loc[key] ~= nil then return loc[key] end
        local fallback = PriestBiS.Locales and PriestBiS.Locales["enUS"]
        if fallback and fallback[key] ~= nil then return fallback[key] end
        return key
    end
})
PriestBiS.L = L

-- Logging helper
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
-- STAT WEIGHTS & EQUIVALENCE POINTS (EP)
-- ================================================

UA.STAT_WEIGHTS = {
    healing = 1.0,         -- Baseline throughput (+Healing and +Damage/Healing hybrid gear)
    spi = 0.70,            -- Dynamic default (5/5 Spiritual Guidance + 3/3 Meditation): 0.30 Base FSR + 0.25 SG + 0.15 Med
    mp5 = 2.20,            -- 1 MP5 = 12 mana/min (~2.2 EP)
    spell_crit = 8.0,      -- 1% Crit = 8.0 EP (Inspiration armor buff uptime + throughput)
    int = 0.22,            -- Mana pool buffer + crit scaling
    spell_damage = 0.0,    -- Pure shadow/spell damage provides 0 throughput for Holy/Disc healing spells
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

-- Dedicated off-screen scanning tooltip frame
local scanTooltip = getglobal("UAScanningTooltip")
if not scanTooltip then
    scanTooltip = CreateFrame("GameTooltip", "UAScanningTooltip", UIParent, "GameTooltipTemplate")
end
scanTooltip:SetOwner(UIParent, "ANCHOR_NONE")

local ITEM_STAT_CACHE = {}

function UA.ClearCache()
    for k in pairs(ITEM_STAT_CACHE) do
        ITEM_STAT_CACHE[k] = nil
    end
end

-- Helper to detect armor / weapon subtype across locales
local function DetectSubtype(str)
    if not str or str == "" then return nil end
    if string.find(str, "Leatherworking") or string.find(str, "Lederverarbeitung") or string.find(str, "Travail du cuir") or string.find(str, "Кожевничество") or string.find(str, "制皮")
       or string.find(str, "Blacksmithing") or string.find(str, "Schmiedekunst") or string.find(str, "Forge") or string.find(str, "Кузнечное") or string.find(str, "锻造")
       or string.find(str, "Tailoring") or string.find(str, "Schneiderei") or string.find(str, "Couture") or string.find(str, "Портняжное") or string.find(str, "裁缝") then
        return nil
    end

    if string.find(str, "Leather") or string.find(str, "皮甲") or string.find(str, "Кожа") or string.find(str, "Leder") or string.find(str, "Cuir") then return "Leather"
    elseif string.find(str, "Mail") or string.find(str, "锁甲") or string.find(str, "Кольчуга") or string.find(str, "Schwere Rüstung") or string.find(str, "Maille") then return "Mail"
    elseif string.find(str, "Plate") or string.find(str, "板甲") or string.find(str, "Латы") or string.find(str, "Platte") or string.find(str, "Plaques") then return "Plate"
    elseif string.find(str, "Cloth") or string.find(str, "布甲") or string.find(str, "Ткань") or string.find(str, "Stoff") or string.find(str, "Tissu") then return "Cloth"
    elseif string.find(str, "Shield") or string.find(str, "盾牌") or string.find(str, "Щит") or string.find(str, "Schild") or string.find(str, "Bouclier") then return "Shield"
    elseif string.find(str, "Sword") or string.find(str, "剑") or string.find(str, "Меч") or string.find(str, "Schwert") or string.find(str, "Epée") then return "Sword"
    elseif string.find(str, "Axe") or string.find(str, "斧") or string.find(str, "Топор") or string.find(str, "Axt") or string.find(str, "Hache") then return "Axe"
    elseif string.find(str, "Polearm") or string.find(str, "长柄武器") or string.find(str, "Древковое") or string.find(str, "Stangenwaffe") or string.find(str, "Arme d'hast") then return "Polearm"
    elseif string.find(str, "Two%-Handed Mace") or string.find(str, "双手锤") or string.find(str, "Двуручное дробящее") or string.find(str, "Zweihandstreitkolben") or string.find(str, "Masse à deux mains") then return "Two-Handed Mace"
    elseif string.find(str, "Mace") or string.find(str, "锤") or string.find(str, "Дробящее") or string.find(str, "Streitkolben") or string.find(str, "Masse") then return "Mace"
    elseif string.find(str, "Dagger") or string.find(str, "匕首") or string.find(str, "Кинжал") or string.find(str, "Dolch") or string.find(str, "Dague") then return "Dagger"
    elseif string.find(str, "Staff") or string.find(str, "法杖") or string.find(str, "Посох") or string.find(str, "Stab") or string.find(str, "Bâton") then return "Staff"
    elseif string.find(str, "Wand") or string.find(str, "魔杖") or string.find(str, "Жезл") or string.find(str, "Zauberstab") or string.find(str, "Baguette") then return "Wand"
    elseif string.find(str, "Bow") or string.find(str, "弓") or string.find(str, "Лук") or string.find(str, "Bogen") or string.find(str, "Arc") then return "Bow"
    elseif string.find(str, "Gun") or string.find(str, "枪械") or string.find(str, "Огнестрельное") or string.find(str, "Schusswaffe") or string.find(str, "Arme à feu") then return "Gun"
    elseif string.find(str, "Crossbow") or string.find(str, "弩") or string.find(str, "Арбалет") or string.find(str, "Armbrust") or string.find(str, "Arbalète") then return "Crossbow"
    end
    return nil
end

-- Helper to test string against a list of pattern regexes
local function MatchFirstPattern(text, patternList)
    if not text or not patternList then return nil end
    for _, pat in ipairs(patternList) do
        local _, _, val = string.find(text, pat)
        if val then return tonumber(val) end
    end
    return nil
end

-- Helper to scan across all registered patterns for a stat category
local function ScanStatAcrossLocales(text, statCategory)
    if not text or not PriestBiS.Patterns then return nil end

    -- Check current locale first
    local activeLoc = PriestBiS.clientLocale or "enUS"
    if PriestBiS.Patterns[activeLoc] and PriestBiS.Patterns[activeLoc][statCategory] then
        local val = MatchFirstPattern(text, PriestBiS.Patterns[activeLoc][statCategory])
        if val then return val end
    end

    -- Check enUS fallback if active locale was different
    if activeLoc ~= "enUS" and PriestBiS.Patterns["enUS"] and PriestBiS.Patterns["enUS"][statCategory] then
        local val = MatchFirstPattern(text, PriestBiS.Patterns["enUS"][statCategory])
        if val then return val end
    end

    -- Check all other registered locales
    for locName, pGroup in pairs(PriestBiS.Patterns) do
        if locName ~= activeLoc and locName ~= "enUS" and pGroup[statCategory] then
            local val = MatchFirstPattern(text, pGroup[statCategory])
            if val then return val end
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

    -- Secondary cache hit: if itemID is already cached from previous lookups, reuse immediately
    if itemID and ITEM_STAT_CACHE[itemID] then
        ITEM_STAT_CACHE[cacheKey] = ITEM_STAT_CACHE[itemID]
        return ITEM_STAT_CACHE[itemID]
    end

    scanTooltip:SetOwner(UIParent, "ANCHOR_NONE")
    local clearCount = scanTooltip._prevLineCount or 30
    scanTooltip:ClearLines()
    for j = 1, clearCount do
        local l = getglobal("UAScanningTooltipTextLeft" .. j)
        if l then l:SetText("") end
        local r = getglobal("UAScanningTooltipTextRight" .. j)
        if r then r:SetText("") end
    end
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

    -- 1. Query Blizzard engine GetItemInfo first for authoritative slot and item type
    local linkOrID = rawLink or itemLink or itemID
    if linkOrID and GetItemInfo then
        local gName, _, _, _, gItemType, gItemSubType, _, gEquipSlot = GetItemInfo(linkOrID)
        if gName and gName ~= "" then stats.name = gName end
        if gItemType and gItemType ~= "" then stats.itemType = gItemType end
        if gItemSubType and gItemSubType ~= "" then stats.subType = gItemSubType end
        if gEquipSlot and EQUIP_SLOT_MAP[gEquipSlot] then
            stats.slot = EQUIP_SLOT_MAP[gEquipSlot]
            stats.equipLoc = gEquipSlot
        end
    end

    local function IsSetLine(str)
        if not str or str == "" then return false end
        if string.find(str, "%(%d+/%d+%)") then return true end
        if string.find(str, "Set%s*:") or string.find(str, "%(%d+%)%s*Set") or string.find(str, "%-Set") then return true end
        if string.find(str, "套装") or string.find(str, "Комплект") or string.find(str, "%(%d+%)%s*Комплект") or string.find(str, "%(%d+%)%s*pièce") or string.find(str, "%(%d+%)%s*pièces") then return true end
        return false
    end

    local numLines = tonumber(scanTooltip:NumLines())
    if numLines and numLines > 0 then
        scanTooltip._prevLineCount = math.max(numLines, 30)
        for i = 1, numLines do
            local leftLine = getglobal("UAScanningTooltipTextLeft" .. i)
            local rightLine = getglobal("UAScanningTooltipTextRight" .. i)
            local text = leftLine and leftLine.GetText and leftLine:GetText()
            local rText = rightLine and rightLine.GetText and rightLine:GetText()

            if text and text ~= "" then
                if i == 1 and stats.name == "" then
                    stats.name = text
                end

                -- Detect Set Name (e.g. "Vestments of Transcendence (0/8)", "卓越法衣 (0/8)", "Одеяния Превосходства (0/8)")
                if not stats.setName then
                    local _, _, sName = string.find(text, "([^%(]+)%s*%(%d+/%d+%)")
                    if sName and sName ~= "" then
                        local clean = string.gsub(sName, "^%s+", "")
                        clean = string.gsub(clean, "%s+$", "")
                        stats.setName = clean
                    end
                end

                if not IsSetLine(text) then
                    -- Check Class restrictions (English, German, French, Chinese, Russian)
                    local _, _, classStr = string.find(text, "Classes:%s*(.+)")
                    if not classStr then _, _, classStr = string.find(text, "Klassen:%s*(.+)") end
                    if not classStr then _, _, classStr = string.find(text, "Classes%s*:%s*(.+)") end
                    if not classStr then _, _, classStr = string.find(text, "职业[：:]%s*(.+)") end
                    if not classStr then _, _, classStr = string.find(text, "Классы:%s*(.+)") end
                    if not classStr then _, _, classStr = string.find(text, "Класс:%s*(.+)") end
                    if classStr then
                        stats.restrictedClasses = {}
                        if string.find(classStr, "Priest") or string.find(classStr, "Priester") or string.find(classStr, "Prêtre") or string.find(classStr, "牧师") or string.find(classStr, "Жрец") then
                            stats.restrictedClasses["PRIEST"] = true
                        end
                    end

                    -- Match +Healing and +Spell Damage/Healing (Spell Power)
                    local valH = ScanStatAcrossLocales(text, "HEALING")
                    if valH then
                        stats.healing = stats.healing + valH
                    else
                        local valDH = ScanStatAcrossLocales(text, "DAMAGE_HEALING")
                        if valDH then stats.healing = stats.healing + valDH end
                    end

                    -- Match Intellect, Spirit, Stamina
                    local valInt = ScanStatAcrossLocales(text, "INT")
                    if valInt then stats.int = stats.int + valInt end

                    local valSpi = ScanStatAcrossLocales(text, "SPI")
                    if valSpi then stats.spi = stats.spi + valSpi end

                    local valStam = ScanStatAcrossLocales(text, "STAM")
                    if valStam then stats.stam = stats.stam + valStam end

                    -- Match MP5
                    local valMP5 = ScanStatAcrossLocales(text, "MP5")
                    if valMP5 then stats.mp5 = stats.mp5 + valMP5 end

                    -- Match Spell Crit
                    local valCrit = ScanStatAcrossLocales(text, "CRIT")
                    if valCrit then stats.crit = stats.crit + valCrit end

                    -- Detect slot from tooltip header lines (lines 1 to 6 only, to avoid matching tier set piece listings)
                    if not stats.slot and i <= 6 then
                        if string.find(text, "Head") or string.find(text, "头部") or string.find(text, "Голова") or string.find(text, "Kopf") or string.find(text, "Tête") then stats.slot = "Head"
                        elseif string.find(text, "Neck") or string.find(text, "颈部") or string.find(text, "Шея") or string.find(text, "Hals") or string.find(text, "Cou") then stats.slot = "Neck"
                        elseif string.find(text, "Shoulder") or string.find(text, "肩部") or string.find(text, "Плечи") or string.find(text, "Schulter") or string.find(text, "Épaule") or string.find(text, "Epaule") then stats.slot = "Shoulder"
                        elseif string.find(text, "Back") or string.find(text, "Cloak") or string.find(text, "背部") or string.find(text, "披风") or string.find(text, "Спина") or string.find(text, "Плащ") or string.find(text, "Rücken") or string.find(text, "Umhang") or string.find(text, "Dos") or string.find(text, "Cape") then stats.slot = "Back"
                        elseif string.find(text, "Chest") or string.find(text, "Robe") or string.find(text, "胸部") or string.find(text, "衣服") or string.find(text, "长袍") or string.find(text, "Грудь") or string.find(text, "Brust") or string.find(text, "Torse") then stats.slot = "Chest"
                        elseif string.find(text, "Wrist") or string.find(text, "Bracer") or string.find(text, "手腕") or string.find(text, "护腕") or string.find(text, "Запястья") or string.find(text, "Наручи") or string.find(text, "Handgelenke") or string.find(text, "Armschienen") or string.find(text, "Poignets") then stats.slot = "Wrists"
                        elseif string.find(text, "Hands") or string.find(text, "Gloves") or string.find(text, "手") or string.find(text, "手套") or string.find(text, "Кисти рук") or string.find(text, "Перчатки") or string.find(text, "Hände") or string.find(text, "Handschuhe") or string.find(text, "Mains") or string.find(text, "Gants") then stats.slot = "Hands"
                        elseif string.find(text, "Waist") or string.find(text, "Belt") or string.find(text, "腰部") or string.find(text, "腰带") or string.find(text, "Пояс") or string.find(text, "Taille") or string.find(text, "Gürtel") or string.find(text, "Ceinture") then stats.slot = "Belt"
                        elseif string.find(text, "Legs") or string.find(text, "Pants") or string.find(text, "腿部") or string.find(text, "裤子") or string.find(text, "Ноги") or string.find(text, "Штаны") or string.find(text, "Beine") or string.find(text, "Hosen") or string.find(text, "Jambes") or string.find(text, "Pantalon") then stats.slot = "Legs"
                        elseif string.find(text, "Feet") or string.find(text, "Boots") or string.find(text, "脚") or string.find(text, "鞋子") or string.find(text, "Ступни") or string.find(text, "Сапоги") or string.find(text, "Füße") or string.find(text, "Stiefel") or string.find(text, "Pieds") or string.find(text, "Bottes") then stats.slot = "Boots"
                        elseif string.find(text, "Finger") or string.find(text, "Ring") or string.find(text, "手指") or string.find(text, "戒指") or string.find(text, "Палец") or string.find(text, "Кольцо") or string.find(text, "Doigt") or string.find(text, "Anneau") or string.find(text, "Bague") then stats.slot = "Ring"
                        elseif string.find(text, "Trinket") or string.find(text, "饰品") or string.find(text, "Аксессуар") or string.find(text, "Schmuck") or string.find(text, "Bijou") then stats.slot = "Trinket"
                        elseif string.find(text, "Two%-Hand") or string.find(text, "双手") or string.find(text, "Двуручное") or string.find(text, "Zweihändig") or string.find(text, "Deux mains") then stats.slot = "Twohand"
                        elseif string.find(text, "Main Hand") or string.find(text, "One%-Hand") or string.find(text, "主手") or string.find(text, "单手") or string.find(text, "Правая рука") or string.find(text, "Одноручное") or string.find(text, "Waffenhand") or string.find(text, "Einhand") or string.find(text, "Main droite") or string.find(text, "Une main") then stats.slot = "Mainhand"
                        elseif string.find(text, "Held In Off%-Hand") or string.find(text, "Off Hand") or string.find(text, "副手") or string.find(text, "左手") or string.find(text, "Левая рука") or string.find(text, "Schildhand") or string.find(text, "En main gauche") then stats.slot = "Offhand"
                        elseif string.find(text, "Ranged") or string.find(text, "Wand") or string.find(text, "远程") or string.find(text, "魔杖") or string.find(text, "Дальний бой") or string.find(text, "Жезл") or string.find(text, "Distanz") or string.find(text, "Zauberstab") or string.find(text, "À distance") or string.find(text, "Baguette") then stats.slot = "Wand"
                        end
                    end
                end
            end

            if not stats.subType and i <= 6 then
                if rText and rText ~= "" then
                    stats.subType = DetectSubtype(rText)
                end
                if not stats.subType and i > 1 and text and text ~= "" then
                    stats.subType = DetectSubtype(text)
                end
            end

            if rText and rText ~= "" then
                if not stats.slot and i <= 6 then
                    if string.find(rText, "Head") or string.find(rText, "头部") or string.find(rText, "Голова") or string.find(rText, "Kopf") or string.find(rText, "Tête") then stats.slot = "Head"
                    elseif string.find(rText, "Neck") or string.find(rText, "颈部") or string.find(rText, "Шея") or string.find(rText, "Hals") or string.find(rText, "Cou") then stats.slot = "Neck"
                    elseif string.find(rText, "Shoulder") or string.find(rText, "肩部") or string.find(rText, "Плечи") or string.find(rText, "Schulter") or string.find(rText, "Épaule") or string.find(rText, "Epaule") then stats.slot = "Shoulder"
                    elseif string.find(rText, "Back") or string.find(rText, "Cloak") or string.find(rText, "背部") or string.find(rText, "披风") or string.find(rText, "Спина") or string.find(rText, "Плащ") or string.find(rText, "Rücken") or string.find(rText, "Umhang") or string.find(rText, "Dos") or string.find(rText, "Cape") then stats.slot = "Back"
                    elseif string.find(rText, "Chest") or string.find(rText, "Robe") or string.find(rText, "胸部") or string.find(rText, "衣服") or string.find(rText, "长袍") or string.find(rText, "Грудь") or string.find(rText, "Brust") or string.find(rText, "Torse") then stats.slot = "Chest"
                    elseif string.find(rText, "Wrist") or string.find(rText, "Bracer") or string.find(rText, "手腕") or string.find(rText, "护腕") or string.find(rText, "Запястья") or string.find(rText, "Наручи") or string.find(rText, "Handgelenke") or string.find(rText, "Armschienen") or string.find(rText, "Poignets") then stats.slot = "Wrists"
                    elseif string.find(rText, "Hands") or string.find(rText, "Gloves") or string.find(rText, "手") or string.find(rText, "手套") or string.find(rText, "Кисти рук") or string.find(rText, "Перчатки") or string.find(rText, "Hände") or string.find(rText, "Handschuhe") or string.find(rText, "Mains") or string.find(rText, "Gants") then stats.slot = "Hands"
                    elseif string.find(rText, "Waist") or string.find(rText, "Belt") or string.find(rText, "腰部") or string.find(rText, "腰带") or string.find(rText, "Пояс") or string.find(rText, "Taille") or string.find(rText, "Gürtel") or string.find(rText, "Ceinture") then stats.slot = "Belt"
                    elseif string.find(rText, "Legs") or string.find(rText, "Pants") or string.find(rText, "腿部") or string.find(rText, "裤子") or string.find(rText, "Ноги") or string.find(rText, "Штаны") or string.find(rText, "Beine") or string.find(rText, "Hosen") or string.find(rText, "Jambes") or string.find(rText, "Pantalon") then stats.slot = "Legs"
                    elseif string.find(rText, "Feet") or string.find(rText, "Boots") or string.find(rText, "脚") or string.find(rText, "鞋子") or string.find(rText, "Ступни") or string.find(rText, "Сапоги") or string.find(rText, "Füße") or string.find(rText, "Stiefel") or string.find(rText, "Pieds") or string.find(rText, "Bottes") then stats.slot = "Boots"
                    elseif string.find(rText, "Finger") or string.find(rText, "Ring") or string.find(rText, "手指") or string.find(rText, "戒指") or string.find(rText, "Палец") or string.find(rText, "Кольцо") or string.find(rText, "Doigt") or string.find(rText, "Anneau") or string.find(rText, "Bague") then stats.slot = "Ring"
                    elseif string.find(rText, "Trinket") or string.find(rText, "饰品") or string.find(rText, "Аксессуар") or string.find(rText, "Schmuck") or string.find(rText, "Bijou") then stats.slot = "Trinket"
                    elseif string.find(rText, "Two%-Hand") or string.find(rText, "双手") or string.find(rText, "Двуручное") or string.find(rText, "Zweihändig") or string.find(rText, "Deux mains") then stats.slot = "Twohand"
                    elseif string.find(rText, "Main Hand") or string.find(rText, "One%-Hand") or string.find(rText, "主手") or string.find(rText, "单手") or string.find(rText, "Правая рука") or string.find(rText, "Одноручное") or string.find(rText, "Waffenhand") or string.find(rText, "Einhand") or string.find(rText, "Main droite") or string.find(rText, "Une main") then stats.slot = "Mainhand"
                    elseif string.find(rText, "Held In Off%-Hand") or string.find(rText, "Off Hand") or string.find(rText, "副手") or string.find(rText, "左手") or string.find(rText, "Левая рука") or string.find(rText, "Schildhand") or string.find(rText, "En main gauche") then stats.slot = "Offhand"
                    elseif string.find(rText, "Ranged") or string.find(rText, "Wand") or string.find(rText, "远程") or string.find(rText, "魔杖") or string.find(rText, "Дальний бой") or string.find(rText, "Жезл") or string.find(rText, "Distanz") or string.find(rText, "Zauberstab") or string.find(rText, "À distance") or string.find(rText, "Baguette") then stats.slot = "Wand"
                    end
                end
            end
        end
    end

    if itemID or itemLink then
        local name, _, _, _, itemType, itemSubType, _, equipSlot = GetItemInfo(itemID or itemLink)
        if name and stats.name == "" then stats.name = name end
        if itemType then stats.itemType = itemType end
        if itemSubType and (not stats.subType or stats.subType == "") then stats.subType = itemSubType end
        if equipSlot and not stats.slot and EQUIP_SLOT_MAP[equipSlot] then
            stats.slot = EQUIP_SLOT_MAP[equipSlot]
        end
    end

    if stats.name ~= "" and stats.slot ~= nil then
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
        if numUnits > 1 then
            table.sort(units, function(a, b) return (a.rate or 0) > (b.rate or 0) end)
        end
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
    local itemData = UA.ScanItemStats(itemID, itemLink, slotID)
    if not itemData then
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
                rewardID = meta.rewardID,
                healing = 0, spi = 0, int = 0, mp5 = 0, crit = 0, stam = 0, spell_damage = 0
            }
            return itemData
        end
        return nil
    end

    local meta = itemID and (UA.ITEM_METADATA and UA.ITEM_METADATA[itemID])
    if meta then
        if meta.ep_override then itemData.ep_override = meta.ep_override end
        if meta.role then itemData.role = meta.role end
        if meta.tier then itemData.tier = meta.tier end
        if meta.drop then itemData.drop = meta.drop end
        if meta.note then itemData.note = meta.note end
        if meta.rewardID then itemData.rewardID = meta.rewardID end
    end

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
        return format("|cff888888" .. L["STAT_SPECIAL_TIER"] .. "|r", itemData.tier or "S", itemData.ep_override)
    end

    local parts = {}
    if itemData.healing and itemData.healing > 0 then
        table.insert(parts, format(L["STAT_HEAL"], itemData.healing))
    end
    if itemData.spi and itemData.spi > 0 then
        local epSpi = itemData.spi * UA.STAT_WEIGHTS.spi
        table.insert(parts, format(L["STAT_SPI"], itemData.spi, epSpi))
    end
    if itemData.mp5 and itemData.mp5 > 0 then
        local epMp5 = itemData.mp5 * UA.STAT_WEIGHTS.mp5
        table.insert(parts, format(L["STAT_MP5"], itemData.mp5, epMp5))
    end
    if itemData.crit and itemData.crit > 0 then
        local epCrit = itemData.crit * UA.STAT_WEIGHTS.spell_crit
        table.insert(parts, format(L["STAT_CRIT"], itemData.crit, epCrit))
    end
    if itemData.int and itemData.int > 0 then
        local epInt = itemData.int * UA.STAT_WEIGHTS.int
        table.insert(parts, format(L["STAT_INT"], itemData.int, epInt))
    end
    if itemData.stam and itemData.stam > 0 then
        local epStam = itemData.stam * UA.STAT_WEIGHTS.stamina
        table.insert(parts, format(L["STAT_STAM"], itemData.stam, epStam))
    end

    local numParts = table.getn(parts)
    if numParts == 0 then
        return ""
    end

    local str = "|cff888888" .. L["TOOLTIP_BREAKDOWN"] .. " "
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

-- Container ranges & constants (Inspired by Bagshui architecture)
UA.BAG_CONTAINERS = { 0, 1, 2, 3, 4 }
UA.BANK_CONTAINERS = { -1, 5, 6, 7, 8, 9, 10, 11 }

-- Debounce & dirty-flag cache for bag scans
UA.bagCacheDirty = true

-- Scoped character data storage (isolated per realm and character name)
function UA.GetCharacterData()
    local realm = (GetRealmName and GetRealmName()) or "DefaultRealm"
    local name = (UnitName and UnitName("player")) or "DefaultPlayer"
    if not PriestBiSDB then PriestBiSDB = {} end
    if not PriestBiSDB.characters then PriestBiSDB.characters = {} end
    if not PriestBiSDB.characters[realm] then PriestBiSDB.characters[realm] = {} end
    if not PriestBiSDB.characters[realm][name] then PriestBiSDB.characters[realm][name] = {} end
    return PriestBiSDB.characters[realm][name]
end

-- Priest Armor & Weapon Equipability Rules across all locales
local PRIEST_ARMOR_SLOTS = {
    Head = true, Shoulder = true, Chest = true, Wrists = true,
    Hands = true, Belt = true, Legs = true, Boots = true
}

local PRIEST_WEAPON_SLOTS = {
    Mainhand = true, Twohand = true, Offhand = true, Wand = true
}

local PRIEST_PROHIBITED_ARMOR = {
    ["Leather"] = true, ["皮甲"] = true, ["Кожа"] = true, ["Leder"] = true, ["Cuir"] = true,
    ["Mail"] = true, ["锁甲"] = true, ["Кольчуга"] = true, ["Schwere Rüstung"] = true, ["Maille"] = true,
    ["Plate"] = true, ["板甲"] = true, ["Латы"] = true, ["Platte"] = true, ["Plaques"] = true,
    ["Shield"] = true, ["Shields"] = true, ["盾牌"] = true, ["Щит"] = true, ["Щиты"] = true, ["Schild"] = true, ["Bouclier"] = true,
}

local PRIEST_PROHIBITED_WEAPONS = {
    ["Sword"] = true, ["One-Handed Swords"] = true, ["Two-Handed Swords"] = true, ["剑"] = true, ["单手剑"] = true, ["双手剑"] = true, ["Меч"] = true, ["Одноручные мечи"] = true, ["Двуручные мечи"] = true, ["Schwert"] = true, ["Epée"] = true,
    ["Axe"] = true, ["One-Handed Axes"] = true, ["Two-Handed Axes"] = true, ["斧"] = true, ["单手斧"] = true, ["双手斧"] = true, ["Топор"] = true, ["Одноручные топоры"] = true, ["Двуручные топоры"] = true, ["Axt"] = true, ["Hache"] = true,
    ["Two-Handed Maces"] = true, ["双手锤"] = true, ["Двуручное дробящее"] = true, ["Zweihandstreitkolben"] = true, ["Masse à deux mains"] = true,
    ["Polearm"] = true, ["Polearms"] = true, ["长柄武器"] = true, ["Древковое"] = true, ["Stangenwaffe"] = true, ["Arme d'hast"] = true,
    ["Bow"] = true, ["Bows"] = true, ["弓"] = true, ["Лук"] = true, ["Bogen"] = true, ["Arc"] = true,
    ["Gun"] = true, ["Guns"] = true, ["枪械"] = true, ["Огнестрельное"] = true, ["Schusswaffe"] = true, ["Arme à feu"] = true,
    ["Crossbow"] = true, ["Crossbows"] = true, ["弩"] = true, ["Арбалет"] = true, ["Armbrust"] = true, ["Arbalète"] = true,
    ["Thrown"] = true, ["投掷武器"] = true, ["Метательное"] = true, ["Wurfwaffe"] = true,
    ["Fist Weapon"] = true, ["Fist Weapons"] = true, ["拳套"] = true, ["Кистевое"] = true, ["Faustwaffe"] = true,
}

-- Check whether an item can be physically equipped by a Priest
function UA.IsItemEquipableByPriest(itemData, itemID, itemLink)
    if not itemData then return false end

    -- Must have a valid equipment slot
    local slot = itemData.slot
    if not slot or slot == "" or slot == "Shirt" or slot == "Tabard" then
        return false
    end

    -- Class restriction check (e.g. "Classes: Druid, Shaman, Paladin", "职业：德鲁伊、萨满祭司")
    if itemData.restrictedClasses and not itemData.restrictedClasses["PRIEST"] then
        return false
    end

    -- Tooltip subtype check
    local subType = itemData.subType
    if subType and subType ~= "" then
        if PRIEST_ARMOR_SLOTS[slot] then
            if PRIEST_PROHIBITED_ARMOR[subType] then
                return false
            end
        end

        if PRIEST_WEAPON_SLOTS[slot] then
            if PRIEST_PROHIBITED_WEAPONS[subType] or subType == "Shield" or subType == "盾牌" or subType == "Щит" or subType == "Schild" or subType == "Bouclier" then
                return false
            end
        end
    end

    -- Engine GetItemInfo check
    local linkOrID = itemLink or itemID
    if linkOrID and GetItemInfo then
        local _, _, _, _, itemType, itemSubType, _, itemEquipLoc = GetItemInfo(linkOrID)
        if itemEquipLoc == "INVTYPE_SHIELD" or itemEquipLoc == "INVTYPE_RELIC" or itemEquipLoc == "INVTYPE_THROWN" or itemEquipLoc == "INVTYPE_AMMO" then
            return false
        end

        if itemType == "Armor" or itemType == "护甲" or itemType == "Доспехи" or itemType == "Rüstung" or itemType == "Armure" then
            if PRIEST_ARMOR_SLOTS[slot] then
                if itemSubType and PRIEST_PROHIBITED_ARMOR[itemSubType] then
                    return false
                end
            end
        elseif itemType == "Weapon" or itemType == "武器" or itemType == "Оружие" or itemType == "Waffe" or itemType == "Arme" then
            if itemSubType and PRIEST_PROHIBITED_WEAPONS[itemSubType] then
                return false
            end
        end
    end

    return true
end

-- Dynamically synchronize Holy Priest stat weights with active character talent points across all locales
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
            if name then
                if name == "Spiritual Guidance" or name == "精神指引" or name == "Духовное направление" or name == "Geistige Führung" or name == "Directives spirituelles" then
                    sgRank = currentRank or 0
                elseif name == "Meditation" or name == "冥想" or name == "Медитация" or name == "Méditation" then
                    medRank = currentRank or 0
                end
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
