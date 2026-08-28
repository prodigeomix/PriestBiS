-- tools/test_priest_bis.lua
-- Comprehensive test suite for PriestBiS (Vanilla 1.12.1 / Turtle WoW)
-- Multi-language verification (enUS, zhCN, ruRU, deDE, frFR)

local function make_frame(frameType, name)
    local f = {
        name = name,
        type = frameType,
        GetName = function(self) return self.name end,
        _linesLeft = {},
        _linesRight = {},
        ClearLines = function(self)
            self._linesLeft = {}
            self._linesRight = {}
            if self.orig_ClearLines then self.orig_ClearLines(self) end
        end,
        AddLine = function(self, text, r, g, b)
            table.insert(self._linesLeft, text or "")
            table.insert(self._linesRight, "")
        end,
        AddDoubleLine = function(self, left, right, lr, lg, lb, rr, rg, rb)
            table.insert(self._linesLeft, left or "")
            table.insert(self._linesRight, right or "")
        end,
        SetHyperlink = function(self, link)
            if string.find(link, "^|c") then
                error("Unknown link type")
            end
            self._link = link
            if link == "item:77777:0:0:0:0:0:0:0:0" or link == "item:77777:0:0:0" then
                self._linesLeft = { "Custom Turtle Belt", "Binds when picked up", "Waist", "+30 Healing Spells" }
                self._linesRight = { "", "", "Cloth", "" }

            elseif link == "item:19958:0:0:0" then
                self._linesLeft = { "Hazza'rah's Charm of Healing", "Binds when picked up", "Trinket", "Use: Increases the critical effect chance of your Flash Heal and Greater Heal spells by 25%" }
                self._linesRight = { "", "", "", "" }
            elseif link == "item:19406:0:0:0" then
                self._linesLeft = { "Drake Fang Talisman", "Binds when picked up", "Trinket", "+56 Attack Power" }
                self._linesRight = { "", "", "", "" }
            elseif link == "item:20258:0:0:0" then
                self._linesLeft = { "Zulian Ceremonial Staff", "Two-Hand", "Staff", "Increases healing done by spells and effects by up to 71" }
                self._linesRight = { "", "", "", "" }
            elseif link == "item:22721:0:0:0" then
                self._linesLeft = { "Band of Servitude", "Unique", "Finger", "Increases healing done by spells and effects by up to 28" }
                self._linesRight = { "", "", "", "" }
            elseif link == "item:13346:0:0:0" then
                self._linesLeft = { "Robes of the Exalted", "Chest", "+11 Intellect", "Increases healing done by spells and effects by up to 68" }
                self._linesRight = { "", "", "", "" }
            elseif link == "item:22406:0:0:0" then
                self._linesLeft = { "Redemption", "Main Hand", "Mace", "Increases healing done by spells and effects by up to 84" }
                self._linesRight = { "", "", "", "" }
            elseif link == "item:19820:0:0:0" then
                self._linesLeft = { "Consecrated Caduceus", "Held In Off-hand", "Increases healing done by spells and effects by up to 31", "Restores 4 mana per 5 sec." }
                self._linesRight = { "", "", "", "" }
            elseif link == "item:61004:0:0:0" then
                self._linesLeft = { "Sandswept Ring of Arcanum", "Finger", "+10 Intellect", "+10 Spirit", "Increases healing done by spells and effects by up to 22", "Restores 3 mana per 5 sec." }
                self._linesRight = { "", "", "", "", "", "" }
            elseif link == "item:55286:0:0:0" then
                self._linesLeft = { "Ring of Holy Light", "Finger", "+18 Intellect", "+28 Spirit" }
                self._linesRight = { "", "", "", "" }
            elseif link == "item:16982:0:0:0" then
                self._linesLeft = { "Corehound Boots", "Feet", "+15 Intellect", "+15 Stamina", "Increases healing done by spells and effects by up to 60" }
                self._linesRight = { "", "Leather", "", "", "" }
            elseif link == "item:19349:0:0:0" then
                self._linesLeft = { "Red Dragonscale Protector", "Off Hand", "Increases healing done by spells and effects by up to 37", "Restores 6 mana per 5 sec." }
                self._linesRight = { "", "Shield", "", "" }
            elseif link == "item:17103:0:0:0" then
                self._linesLeft = { "Azuresong Mageblade", "One-Hand", "Sword", "+10 Intellect", "+7 Stamina", "Increases damage and healing done by magical spells and effects by up to 40", "Increases your chance to get a critical strike with spells by 1%" }
                self._linesRight = { "", "", "", "", "", "" }
            elseif link == "item:16900:0:0:0" then
                self._linesLeft = { "Stormrage Boots", "Feet", "Classes: Druid", "+16 Intellect", "+17 Stamina", "+16 Spirit", "Increases healing done by spells and effects by up to 29" }
                self._linesRight = { "", "Leather", "", "", "", "", "" }
            elseif link == "item:16925:0:0:0" then
                self._linesLeft = { "Belt of Transcendence", "Vestments of Transcendence (2/8)", "Waist", "+17 Intellect", "+16 Spirit", "+16 Stamina", "Increases healing done by spells and effects by up to 35" }
                self._linesRight = { "", "", "Cloth", "", "", "", "" }
            elseif link == "item:16924:0:0:0" then
                self._linesLeft = { "Pauldrons of Transcendence", "Vestments of Transcendence (2/8)", "Shoulder", "+16 Intellect", "+17 Spirit", "+17 Stamina", "Increases healing done by spells and effects by up to 37" }
                self._linesRight = { "", "", "Cloth", "", "", "", "" }
            elseif link == "item:16923:0:0:0" then
                self._linesLeft = { "Robes of Transcendence", "Vestments of Transcendence (1/8)", "Chest", "+27 Intellect", "+17 Stamina", "+16 Spirit", "Increases healing done by spells and effects by up to 59" }
                self._linesRight = { "", "", "Cloth", "", "", "", "" }

            -- Chinese items
            elseif link == "item:88001:0:0:0" then
                self._linesLeft = { "卓越法衣", "卓越法衣 (2/8)", "胸部", "+27 智力", "+16 精神", "+17 耐力", "提高法术所造成的治疗效果，最多59点", "每5秒回复4点法力值" }
                self._linesRight = { "", "", "布甲", "", "", "", "", "" }
            elseif link == "item:88002:0:0:0" then
                self._linesLeft = { "野性之皮", "背部", "+10 智力", "+10 精神", "提高所有法术和魔法效果所造成的伤害和治疗效果，最多42点" }
                self._linesRight = { "", "布甲", "", "", "" }
            elseif link == "item:88003:0:0:0" then
                self._linesLeft = { "野性之皮", "背部", "职业：德鲁伊、萨满祭司", "提高法术所造成的治疗效果，最多50点" }
                self._linesRight = { "", "皮甲", "", "" }

            -- Russian items
            elseif link == "item:89001:0:0:0" then
                self._linesLeft = { "Одеяния Превосходства", "Одеяния Превосходства (2/8)", "Грудь", "+27 к интеллекту", "+16 к духу", "+17 к выносливости", "Увеличивает эффект лечения заклинаний на 59", "Восполнение 4 маны каждые 5 сек." }
                self._linesRight = { "", "", "Ткань", "", "", "", "", "" }

            -- German items
            elseif link == "item:87001:0:0:0" then
                self._linesLeft = { "Gewänder der Transzendenz", "Gewänder der Transzendenz (2/8)", "Brust", "+27 Intelligenz", "+16 Willenskraft", "+17 Ausdauer", "Erhöht die durch Zauber und Effekte verursachte Heilung um bis zu 59", "Stellt alle 5 Sek. 4 Mana wieder her" }
                self._linesRight = { "", "", "Stoff", "", "", "", "", "" }

            -- French items
            elseif link == "item:86001:0:0:0" then
                self._linesLeft = { "Habits de transcendance", "Habits de transcendance (2/8)", "Torse", "+27 Intelligence", "+16 Esprit", "+17 Endurance", "Augmente les soins prodigués par les sorts et les effets d'un maximum de 59", "Rend 4 points de mana toutes les 5 sec." }
                self._linesRight = { "", "", "Tissu", "", "", "", "", "" }

            else
                self._linesLeft = { "Test Item", "Binds when picked up", "Chest", "+10 Healing" }
                self._linesRight = { "", "", "Cloth", "" }
            end
            if self.orig_SetHyperlink then self.orig_SetHyperlink(self, link) end
        end,
        SetInventoryItem = function(self, unit, slot)
            local link = GetInventoryItemLink and GetInventoryItemLink(unit, slot)
            if link then
                self:SetHyperlink(link)
            else
                self:SetHyperlink("item:13346:0:0:0")
            end
            if self.orig_SetInventoryItem then self.orig_SetInventoryItem(self, unit, slot) end
        end,
        NumLines = function(self)
            return table.getn(self._linesLeft)
        end,
        SetOwner = function(self, owner, anchor) end,
        SetPoint = function(...) end,
        SetWidth = function(...) end,
        SetHeight = function(...) end,
        SetBackdrop = function(...) end,
        SetBackdropColor = function(...) end,
        SetMovable = function(...) end,
        EnableMouse = function(...) end,
        RegisterForDrag = function(...) end,
        RegisterEvent = function(...) end,
        UnregisterEvent = function(...) end,
        SetAlpha = function(...) end,
        SetScript = function(...) end,
        SetFrameLevel = function(...) end,
        SetClampedToScreen = function(...) end,
        CreateFontString = function(self)
            return {
                SetPoint = function(...) end,
                SetText = function(...) end,
                SetTextColor = function(...) end,
                SetJustifyH = function(...) end,
                SetWidth = function(...) end,
            }
        end,
        CreateTexture = function(self)
            return {
                SetPoint = function(...) end,
                SetWidth = function(...) end,
                SetHeight = function(...) end,
                SetTexture = function(...) end,
            }
        end,
        Show = function(self)
            self._visible = true
            if self.orig_Show then self.orig_Show(self) end
        end,
        Hide = function(self)
            self._visible = false
            if self.orig_Hide then self.orig_Hide(self) end
        end,
        IsVisible = function(self)
            return self._visible == true
        end,
    }
    return f
end

_G.UAScanningTooltip = make_frame("GameTooltip", "UAScanningTooltip")
_G.GameTooltip = make_frame("GameTooltip", "GameTooltip")
_G.ItemRefTooltip = make_frame("ItemRefTooltip", "ItemRefTooltip")

_G.getglobal = function(name)
    local tooltip = _G["UAScanningTooltip"]
    if tooltip and string.find(name, "^UAScanningTooltipTextLeft(%d+)") then
        local _, _, idx = string.find(name, "^UAScanningTooltipTextLeft(%d+)")
        idx = tonumber(idx)
        if idx and tooltip._linesLeft and tooltip._linesLeft[idx] then
            return { GetText = function() return tooltip._linesLeft[idx] end }
        end
        return nil
    elseif tooltip and string.find(name, "^UAScanningTooltipTextRight(%d+)") then
        local _, _, idx = string.find(name, "^UAScanningTooltipTextRight(%d+)")
        idx = tonumber(idx)
        if idx and tooltip._linesRight and tooltip._linesRight[idx] then
            return { GetText = function() return tooltip._linesRight[idx] end }
        end
        return nil
    end
    return _G[name]
end

_G.CreateFrame = function(frameType, name, parent, template)
    return make_frame(frameType, name)
end
_G.GetItemInfo = function(id) return "Test Item", "item:123:0:0:0", 4, 60, 60, "Armor", "Cloth", 1, "INVTYPE_CHEST" end
_G.GetLocale = function() return "enUS" end

local mockInventory = {
    [1] = "item:19132:0:0:0", -- Crystal Adorned Crown (Head)
    [2] = "item:18723:0:0:0", -- Animated Chain Necklace (Neck)
    [3] = "item:51047:0:0:0", -- Sacrosanct Epaulets (Shoulder)
    [5] = "item:13346:0:0:0", -- Robes of the Exalted (Chest)
    [6] = "item:16817:0:0:0", -- Girdle of Prophecy (Belt)
    [7] = "item:16814:0:0:0", -- Pants of Prophecy (Legs)
    [8] = "item:22247:0:0:0", -- Faith Healer's Boots (Boots)
    [9] = "item:16819:0:0:0", -- Vambraces of Prophecy (Wrists)
    [10] = "item:16812:0:0:0", -- Gloves of Prophecy (Hands)
    [11] = "item:61004:0:0:0", -- Sandswept Ring of Arcanum (Ring1)
    [12] = "item:55286:0:0:0", -- Ring of Holy Light (Ring2)
    [13] = "item:58231:0:0:0", -- Penchant of Humility (Trinket1)
    [14] = "item:61700:0:0:0", -- Fabric of Time (Trinket2)
    [15] = "item:18510:0:0:0", -- Hide of the Wild (Back)
    [16] = "item:22406:0:0:0", -- Redemption (Mainhand)
    [17] = "item:19820:0:0:0", -- Consecrated Caduceus (Offhand)
    [18] = "item:19927:0:0:0", -- Mar'li's Touch (Wand)
}
_G.GetInventoryItemLink = function(unit, slotId) return mockInventory[slotId] end
_G.GetNumLootItems = function() return 0 end
_G.GetLootSlotInfo = function(i) return nil end
_G.GetLootSlotLink = function(i) return nil end
_G.LootSlotIsItem = function(i) return false end
_G.PlaySound = function(s) end
_G.UnitExists = function(u) return true end
_G.UnitIsPlayer = function(u) return false end
_G.UnitName = function(u) return "Gnarlmoon" end
_G.UIErrorsFrame = { AddMessage = function(...) end }
_G.DEFAULT_CHAT_FRAME = { AddMessage = function(self, msg) print("[CHAT] " .. tostring(msg)) end }
_G.SlashCmdList = {}

-- Load Localization stack & PriestBiS
dofile("Locales/Localization.lua")
dofile("Locales/Localization.enUS.lua")
dofile("Locales/Localization.zhCN.lua")
dofile("Locales/Localization.ruRU.lua")
dofile("Locales/Localization.deDE.lua")
dofile("Locales/Localization.frFR.lua")
dofile("PriestBiS.lua")

print("--- Testing Upgrade Scoring ---")
local rob = UA.GetItemData(16923) -- Robes of Transcendence (59 heal, 27 int, 16 spi, 17 stam)
local robScore = UA.GetItemScore(rob)
print("Robes of Transcendence EP Score: " .. robScore)
assert(robScore > 0, "Score should be positive")

print("--- Testing Hazza'rah Trinket (Tier S) ---")
local haz = UA.GetItemData(19958)
local hazScore = UA.GetItemScore(haz)
print("Hazza'rah EP Score (EP Override): " .. hazScore)
assert(hazScore == 120, "Hazza'rah should have 120 EP override")

print("--- Testing Drake Fang Talisman (Melee Role) ---")
local isUpg, reason = UA.IsUpgrade(19406)
print("DFT Upgrade Check: " .. tostring(isUpg) .. " - " .. tostring(reason))
assert(isUpg == false, "DFT should not be an upgrade for Holy Priest")

print("--- Testing 2H Staff vs Combined Set ---")
local staffUpg, staffReason = UA.IsUpgrade(20258)
print("2H Zulian Staff Check: " .. tostring(staffUpg) .. " - " .. tostring(staffReason))
assert(staffUpg == false, "2H staff should be recognized as a downgrade against MH+OH")

print("--- Testing Ring Replacement Logic ---")
local ringUpg, ringReason = UA.IsUpgrade(22721)
print("Band of Servitude Ring Check: " .. tostring(ringUpg) .. " - " .. tostring(ringReason))
assert(ringUpg == true, "Band of Servitude (28 EP) should upgrade Ring2 (24 EP)")

print("--- Testing Tooltip Integration on ItemRefTooltip (Chat link / AtlasLoot click) ---")
UA.HookAllTooltips()
ItemRefTooltip:ClearLines()
ItemRefTooltip:SetHyperlink("item:16923:0:0:0")
print("ItemRefTooltip Lines Count:\t" .. table.getn(ItemRefTooltip._linesLeft))
for i, line in ipairs(ItemRefTooltip._linesLeft) do
    print(string.format("  Line %d: %s", i, line))
end
assert(table.getn(ItemRefTooltip._linesLeft) > 5, "Tooltip should contain injected upgrade info")

print("--- Testing Tooltip Downgrade Display on GameTooltip ---")
GameTooltip:ClearLines()
GameTooltip:SetHyperlink("item:20258:0:0:0")
for _, line in ipairs(GameTooltip._linesLeft) do
    print("  GT Line: " .. line)
end

print("--- Testing Tooltip Display on Currently Equipped Item ---")
GameTooltip:ClearLines()
GameTooltip:SetHyperlink("item:13346:0:0:0")
for _, line in ipairs(GameTooltip._linesLeft) do
    print("  GT Equipped Line: " .. line)
end

print("--- Testing Slash Command Functions ---")
SlashCmdList["PriestBiS"]("gear")
SlashCmdList["PriestBiS"]("db")
SlashCmdList["PriestBiS"]("tooltip")
SlashCmdList["PriestBiS"]("downgrades")
SlashCmdList["PriestBiS"]("help")

print("--- Testing Tooltip Scanner with Formatted WoW Hyperlink ---")
local customBelt = UA.GetItemData(77777, "|cffa335ee|Hitem:77777:0:0:0:0:0:0:0:0|h[Custom Turtle Belt]|h|r")
print("Scanned item:\t" .. tostring(customBelt.name) .. "\t" .. tostring(customBelt.slot) .. "\t" .. tostring(customBelt.healing))
assert(customBelt.name == "Custom Turtle Belt", "Scanned item name should match")
assert(customBelt.slot == "Belt", "Scanned item slot should be Belt")
assert(customBelt.healing == 30, "Scanned healing should be 30")

print("--- Testing Link Parser on AtlasLoot Formats ---")
assert(UA.GetItemIDFromLink("item:19958:0:0:0") == 19958)
assert(UA.GetItemIDFromLink("19958") == 19958)
assert(UA.GetItemIDFromLink(19958) == 19958)
assert(UA.GetItemIDFromLink("|cffa335ee|Hitem:19958:0:0:0|h[Hazza'rah's Charm]|h|r") == 19958)

print("--- Testing pfQuest / pfDB Dynamic Source Resolution ---")
_G.pfDB = {
    items = {
        data = {
            [20032] = { U = { [11382] = 0.175 } },
            [99902] = { Q = { [5501] = true } },
        }
    },
    units = {
        enUS = {
            [11382] = "High Priestess Mar'li"
        }
    },
    quests = {
        enUS = {
            [5501] = "A Donation of Silk"
        }
    }
}
local src1 = UA.GetItemSourceFromPfDB(20032)
print("Resolved Unit Drop Source:\t" .. tostring(src1))
assert(src1 == "Drop: High Priestess Mar'li (17.5%)", "Should resolve drop unit name and rate from pfDB")

local src2 = UA.GetItemSourceFromPfDB(99902)
print("Resolved Quest Source:\t" .. tostring(src2))
assert(src2 == "Quest: A Donation of Silk", "Should resolve quest reward from pfDB")

print("--- Testing Dynamic Talent Points Syncing (enUS) ---")
_G.UnitClass = function(u) return "Priest", "PRIEST" end
_G.GetNumTalents = function(tab) return 5 end
_G.GetTalentInfo = function(tab, idx)
    if tab == 2 and idx == 3 then
        return "Spiritual Guidance", "", 4, 3, 5
    elseif tab == 1 and idx == 2 then
        return "Meditation", "", 3, 2, 3
    end
    return "Other Talent", "", 1, 1, 0
end
UA.UpdateDynamicTalentWeights()
print("Updated Spirit Weight with 5/5 SG + 3/3 Meditation:\t" .. tostring(UA.STAT_WEIGHTS.spi))
assert(UA.STAT_WEIGHTS.spi == 0.70, "Spirit weight should be 0.70 for 5/5 SG + 3/3 Med")

print("--- Testing Dynamic Talent Points Syncing (zhCN: 精神指引 & 冥想) ---")
_G.GetTalentInfo = function(tab, idx)
    if tab == 2 and idx == 3 then
        return "精神指引", "", 4, 3, 5
    elseif tab == 1 and idx == 2 then
        return "冥想", "", 3, 2, 3
    end
    return "其他天赋", "", 1, 1, 0
end
UA.UpdateDynamicTalentWeights()
print("Updated Spirit Weight with zhCN talents:\t" .. tostring(UA.STAT_WEIGHTS.spi))
assert(UA.STAT_WEIGHTS.spi == 0.70, "Spirit weight should be 0.70 for zhCN 5/5 SG + 3/3 Med")

print("--- Testing Dynamic Talent Points Syncing (ruRU: Духовное направление & Медитация) ---")
_G.GetTalentInfo = function(tab, idx)
    if tab == 2 and idx == 3 then
        return "Духовное направление", "", 4, 3, 5
    elseif tab == 1 and idx == 2 then
        return "Медитация", "", 3, 2, 3
    end
    return "Другой талант", "", 1, 1, 0
end
UA.UpdateDynamicTalentWeights()
print("Updated Spirit Weight with ruRU talents:\t" .. tostring(UA.STAT_WEIGHTS.spi))
assert(UA.STAT_WEIGHTS.spi == 0.70, "Spirit weight should be 0.70 for ruRU 5/5 SG + 3/3 Med")

print("--- Testing Priest Equipability & Non-Equipable Armor/Weapons ---")
local leatherComp = UA.GetUpgradeComparison(16982, "item:16982:0:0:0")
print("Leather Boots Equip Check:\t" .. tostring(leatherComp.isUpgrade) .. "\t-\t" .. tostring(leatherComp.reason))
assert(leatherComp.isUpgrade == false, "Leather boots must NEVER be an upgrade for Priest")

local shieldComp = UA.GetUpgradeComparison(19349, "item:19349:0:0:0")
print("Healing Shield Equip Check:\t" .. tostring(shieldComp.isUpgrade) .. "\t-\t" .. tostring(shieldComp.reason))
assert(shieldComp.isUpgrade == false, "Shield must NEVER be an upgrade for Priest")

local swordComp = UA.GetUpgradeComparison(17103, "item:17103:0:0:0")
print("Mageblade Sword Equip Check:\t" .. tostring(swordComp.isUpgrade) .. "\t-\t" .. tostring(swordComp.reason))
assert(swordComp.isUpgrade == false, "Sword must NEVER be an upgrade for Priest")

local druidComp = UA.GetUpgradeComparison(16900, "item:16900:0:0:0")
print("Druid-Only Boots Equip Check:\t" .. tostring(druidComp.isUpgrade) .. "\t-\t" .. tostring(druidComp.reason))
assert(druidComp.isUpgrade == false, "Druid-only boots must NEVER be an upgrade for Priest")

print("--- Testing Multi-Language Tooltip Parsing ---")

-- Chinese item scanning
local zhItem = UA.GetItemData(88001, "item:88001:0:0:0")
print("Scanned zhCN Item Stats:\t" .. tostring(zhItem.name) .. "\tSlot: " .. tostring(zhItem.slot) .. "\tHeal: " .. tostring(zhItem.healing) .. "\tInt: " .. tostring(zhItem.int) .. "\tSpi: " .. tostring(zhItem.spi) .. "\tMP5: " .. tostring(zhItem.mp5))
assert(zhItem.name == "卓越法衣", "Chinese name should match")
assert(zhItem.slot == "Chest", "Chinese slot 胸部 should parse as Chest")
assert(zhItem.healing == 59, "Chinese healing should parse as 59")
assert(zhItem.int == 27, "Chinese int should parse as 27")
assert(zhItem.spi == 16, "Chinese spi should parse as 16")
assert(zhItem.mp5 == 4, "Chinese mp5 should parse as 4")

local zhComp = UA.GetUpgradeComparison(88001, "item:88001:0:0:0")
print("zhCN Item Score:\t" .. tostring(zhComp.newScore))
assert(zhComp.newScore > 75, "Chinese item score should be calculated correctly")

local zhRestrictedComp = UA.GetUpgradeComparison(88003, "item:88003:0:0:0")
print("zhCN Class Restriction Check:\t" .. tostring(zhRestrictedComp.isUpgrade) .. "\t-\t" .. tostring(zhRestrictedComp.reason))
assert(zhRestrictedComp.isUpgrade == false, "Chinese restricted class item should not be equipable")

-- Russian item scanning
local ruItem = UA.GetItemData(89001, "item:89001:0:0:0")
print("Scanned ruRU Item Stats:\t" .. tostring(ruItem.name) .. "\tSlot: " .. tostring(ruItem.slot) .. "\tHeal: " .. tostring(ruItem.healing) .. "\tInt: " .. tostring(ruItem.int) .. "\tSpi: " .. tostring(ruItem.spi) .. "\tMP5: " .. tostring(ruItem.mp5))
assert(ruItem.name == "Одеяния Превосходства", "Russian name should match")
assert(ruItem.slot == "Chest", "Russian slot Грудь should parse as Chest")
assert(ruItem.healing == 59, "Russian healing should parse as 59")
assert(ruItem.int == 27, "Russian int should parse as 27")

-- German item scanning
local deItem = UA.GetItemData(87001, "item:87001:0:0:0")
print("Scanned deDE Item Stats:\t" .. tostring(deItem.name) .. "\tSlot: " .. tostring(deItem.slot) .. "\tHeal: " .. tostring(deItem.healing) .. "\tInt: " .. tostring(deItem.int))
assert(deItem.slot == "Chest", "German slot Brust should parse as Chest")
assert(deItem.healing == 59, "German healing should parse as 59")

-- French item scanning
local frItem = UA.GetItemData(86001, "item:86001:0:0:0")
print("Scanned frFR Item Stats:\t" .. tostring(frItem.name) .. "\tSlot: " .. tostring(frItem.slot) .. "\tHeal: " .. tostring(frItem.healing) .. "\tInt: " .. tostring(frItem.int))
assert(frItem.slot == "Chest", "French slot Torse should parse as Chest")
assert(frItem.healing == 59, "French healing should parse as 59")

print("--- Testing Chinese Client Simulation (zhCN Locale Switch) ---")
PriestBiS.clientLocale = "zhCN"
SlashCmdList["PriestBiS"]("help")
local zhAlertComp = UA.GetUpgradeComparison(88001, "item:88001:0:0:0")
print("zhCN Alert Reason Text:\t" .. tostring(zhAlertComp.reason))

-- Switch back to enUS
PriestBiS.clientLocale = "enUS"

print("--- Testing Set Bonus Evaluation & Threshold Breakpoints ---")
local origGetInventoryItemLink = _G.GetInventoryItemLink
_G.GetInventoryItemLink = function(unit, slotID)
    if slotID == UA.SLOT_IDS["Shoulder"] then return "item:16924:0:0:0" end
    if slotID == UA.SLOT_IDS["Chest"] then return "item:16923:0:0:0" end
    if slotID == UA.SLOT_IDS["Head"] then return "item:13346:0:0:0" end
    return origGetInventoryItemLink(unit, slotID)
end
ITEM_STAT_CACHE = {}

local set3Comp = UA.GetUpgradeComparison(16925, "item:16925:0:0:0")
print("3-Piece Transcendence Set Bonus Activation Check:")
print("  New Score (with +25 EP Set Bonus):\t" .. tostring(set3Comp.newScore))
print("  Set Bonus Description:\t" .. tostring(set3Comp.setBonusDesc))
assert(set3Comp.setBonusEP == 25, "Should award 25 EP for 3-pc Transcendence activation")
assert(set3Comp.isUpgrade == true, "3-pc Transcendence must be recognized as an upgrade")

print("ALL TESTS (INCLUDING MULTI-LANGUAGE SUITE) PASSED SUCCESSFULLY!")
