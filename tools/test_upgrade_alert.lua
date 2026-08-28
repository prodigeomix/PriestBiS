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
                self._linesLeft = { "Red Dragonscale Protector", "Shield", "+10 Intellect", "Increases healing done by spells and effects by up to 50" }
                self._linesRight = { "", "Shield", "", "" }
            elseif link == "item:17103:0:0:0" then
                self._linesLeft = { "Azuresong Mageblade", "Main Hand", "+12 Intellect", "Increases damage and healing done by spells and effects by up to 40" }
                self._linesRight = { "", "Sword", "", "" }
            elseif link == "item:16900:0:0:0" then
                self._linesLeft = { "Stormrage Boots", "Feet", "Classes: Druid", "Increases healing done by spells and effects by up to 50" }
                self._linesRight = { "", "Leather", "", "" }
            elseif link == "item:16923:0:0:0" then
                self._linesLeft = { "Robes of Transcendence", "Vestments of Transcendence (1/8)", "Chest", "+27 Intellect", "+17 Stamina", "+16 Spirit", "Increases healing done by spells and effects by up to 59" }
                self._linesRight = { "", "", "Cloth", "", "", "", "" }
            elseif link == "item:16924:0:0:0" then
                self._linesLeft = { "Pauldrons of Transcendence", "Vestments of Transcendence (2/8)", "Shoulder", "+19 Intellect", "+12 Stamina", "+12 Spirit", "Increases healing done by spells and effects by up to 40" }
                self._linesRight = { "", "", "Cloth", "", "", "", "" }
            elseif link == "item:16925:0:0:0" then
                self._linesLeft = { "Halo of Transcendence", "Vestments of Transcendence (3/8)", "Head", "+27 Intellect", "+17 Stamina", "+16 Spirit", "Increases healing done by spells and effects by up to 59" }
                self._linesRight = { "", "", "Cloth", "", "", "", "" }
            end
        end,
        SetInventoryItem = function(self, unit, slotId)
            local link = _G.GetInventoryItemLink(unit, slotId)
            if link then self:SetHyperlink(link) end
        end,
        NumLines = function(self) return table.getn(self._linesLeft) end,
        SetOwner = function() end,
        Hide = function() end,
        Show = function() end,
        SetWidth = function() end,
        SetHeight = function() end,
        SetPoint = function() end,
        SetBackdrop = function() end,
        SetBackdropColor = function() end,
        SetMovable = function() end,
        EnableMouse = function() end,
        RegisterForDrag = function() end,
        SetScript = function() end,
        SetFrameLevel = function() end,
        SetClampedToScreen = function() end,
        CreateFontString = function()
            return {
                SetPoint = function() end,
                SetText = function() end,
                SetTextColor = function() end,
                SetJustifyH = function() end,
                SetWidth = function() end,
            }
        end,
        CreateTexture = function()
            return {
                SetWidth = function() end,
                SetHeight = function() end,
                SetPoint = function() end,
                SetTexture = function() end,
            }
        end,
        RegisterEvent = function() end,
    }
    if name then _G[name] = f end
    return f
end

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

-- Load UpgradeAlert.lua
dofile("UpgradeAlert.lua")

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
-- Zulian Ceremonial Staff [20258] (71 heal = 71 EP)
-- Equipped: Redemption (84 EP) + Consecrated Caduceus (31 heal + 4 mp5 = 39.8 EP) => Combined 123.8 EP
local isUpg2H, reason2H = UA.IsUpgrade(20258)
print("2H Zulian Staff Check: " .. tostring(isUpg2H) .. " - " .. tostring(reason2H))
assert(isUpg2H == false, "Zulian Staff should be a downgrade against Redemption + Caduceus set")

print("--- Testing Ring Replacement Logic ---")
-- Band of Servitude [22721] (28 heal = 28 EP)
-- Equipped rings: Sandswept Ring of Arcanum [61004] (22 heal, 10 int, 10 spi, 3 mp5 = 37.8 EP), Ring of Holy Light [55286] (18 int, 28 spi = 23.56 EP)
local isUpgRing, reasonRing = UA.IsUpgrade(22721)
print("Band of Servitude Ring Check: " .. tostring(isUpgRing) .. " - " .. tostring(reasonRing))
assert(isUpgRing == true, "Band of Servitude should beat the weaker ring (Ring of Holy Light)")

print("--- Testing Tooltip Integration on ItemRefTooltip (Chat link / AtlasLoot click) ---")
ItemRefTooltip:ClearLines()
ItemRefTooltip:SetHyperlink("item:16923:0:0:0")
print("ItemRefTooltip Lines Count:", ItemRefTooltip:NumLines())
for i, line in ipairs(ItemRefTooltip._linesLeft) do
    print("  Line " .. i .. ": " .. line)
end
assert(ItemRefTooltip:NumLines() > 7, "Tooltip should have appended upgrade lines")
local foundUpgradeLine = false
for _, line in ipairs(ItemRefTooltip._linesLeft) do
    if string.find(line, "%[PriestBiS%] UPGRADE") or string.find(line, "%[UpgradeAlert%] UPGRADE") then
        foundUpgradeLine = true
    end
end
assert(foundUpgradeLine, "Should find [PriestBiS] UPGRADE in tooltip lines")

print("--- Testing Tooltip Downgrade Display on GameTooltip ---")
GameTooltip:ClearLines()
GameTooltip:SetHyperlink("item:20258:0:0:0") -- Zulian Ceremonial Staff (Downgrade vs MH+OH)
local foundDowngradeLine = false
for _, line in ipairs(GameTooltip._linesLeft) do
    print("  GT Line: " .. line)
    if string.find(line, "Downgrade") then
        foundDowngradeLine = true
    end
end
assert(foundDowngradeLine, "Should find Downgrade in tooltip lines")

print("--- Testing Tooltip Display on Currently Equipped Item ---")
GameTooltip:ClearLines()
GameTooltip:SetHyperlink("item:13346:0:0:0") -- Robes of the Exalted (Equipped Chest)
local foundEquippedLine = false
for _, line in ipairs(GameTooltip._linesLeft) do
    print("  GT Equipped Line: " .. line)
    if string.find(line, "Currently Equipped") then
        foundEquippedLine = true
    end
end
assert(foundEquippedLine, "Should find Currently Equipped in tooltip lines")

print("--- Testing Slash Command Functions ---")
SlashCmdList["PriestBiS"]("gear")
SlashCmdList["PriestBiS"]("db")
SlashCmdList["PriestBiS"]("tooltip")
SlashCmdList["PriestBiS"]("downgrades")
SlashCmdList["PriestBiS"]("help")

print("--- Testing Tooltip Scanner with Formatted WoW Hyperlink ---")
local fullLink = "|cffa335ee|Hitem:77777:0:0:0:0:0:0:0:0|h[Custom Turtle Belt]|h|r"
local scanned = UA.ScanItemStats(77777, fullLink)
print("Scanned item:", scanned.name, scanned.slot, scanned.healing)
assert(scanned ~= nil, "Should scan custom item without crashing")
assert(scanned.name == "Custom Turtle Belt", "Name should match")
assert(scanned.slot == "Belt", "Slot should be Belt")
assert(scanned.healing == 30, "Healing should be 30")

print("--- Testing Link Parser on AtlasLoot Formats ---")
assert(UA.GetItemIDFromLink("item:22720") == 22720, "Should parse item:22720 without trailing colon")
assert(UA.GetItemIDFromLink("item:22720:0:0:0") == 22720, "Should parse item:22720:0:0:0")
assert(UA.GetItemIDFromLink(22720) == 22720, "Should parse pure number 22720")
assert(UA.GetItemIDFromLink("22720") == 22720, "Should parse string number '22720'")

print("--- Testing pfQuest / pfDB Dynamic Source Resolution ---")
_G.pfDB = {
    items = {
        data = {
            [99901] = { ["U"] = { [14510] = 0.175 } },
            [99902] = { ["Q"] = { [8401] = 1 } }
        }
    },
    units = {
        enUS = {
            [14510] = "High Priestess Mar'li"
        }
    },
    quests = {
        enUS = {
            [8401] = "A Donation of Silk"
        }
    }
}
local src1 = UA.GetItemSourceFromPfDB(99901)
print("Resolved Unit Drop Source:", src1)
assert(src1 == "Drop: High Priestess Mar'li (17.5%)", "Should resolve unit drop from pfDB")

local src2 = UA.GetItemSourceFromPfDB(99902)
print("Resolved Quest Source:", src2)
assert(src2 == "Quest: A Donation of Silk", "Should resolve quest reward from pfDB")

print("--- Testing Dynamic Talent Points Syncing ---")
_G.UnitClass = function(u) return "Priest", "PRIEST" end
_G.GetNumTalents = function(tab) return 5 end
_G.GetTalentInfo = function(tab, idx)
    if tab == 2 and idx == 3 then
        return "Spiritual Guidance", "", 4, 3, 5 -- 5/5 Spiritual Guidance
    elseif tab == 1 and idx == 2 then
        return "Meditation", "", 3, 2, 3 -- 3/3 Meditation
    end
    return "Other Talent", "", 1, 1, 0
end
UA.UpdateDynamicTalentWeights()
print("Updated Spirit Weight with 5/5 SG + 3/3 Meditation:", UA.STAT_WEIGHTS.spi)
assert(UA.STAT_WEIGHTS.spi == 0.70, "Spirit weight should be 0.70 for 5/5 SG + 3/3 Med")

print("--- Testing Priest Equipability & Non-Equipable Armor/Weapons ---")
local leatherComp = UA.GetUpgradeComparison(16982, "item:16982:0:0:0")
print("Leather Boots Equip Check:", leatherComp.isUpgrade, "-", leatherComp.reason)
assert(leatherComp.isUpgrade == false, "Leather boots must NEVER be an upgrade for Priest")
assert(string.find(leatherComp.reason, "Leather"), "Reason must mention Leather restriction")

local shieldComp = UA.GetUpgradeComparison(19349, "item:19349:0:0:0")
print("Healing Shield Equip Check:", shieldComp.isUpgrade, "-", shieldComp.reason)
assert(shieldComp.isUpgrade == false, "Shield must NEVER be an upgrade for Priest")

local swordComp = UA.GetUpgradeComparison(17103, "item:17103:0:0:0")
print("Mageblade Sword Equip Check:", swordComp.isUpgrade, "-", swordComp.reason)
assert(swordComp.isUpgrade == false, "Sword must NEVER be an upgrade for Priest")

local druidComp = UA.GetUpgradeComparison(16900, "item:16900:0:0:0")
print("Druid-Only Boots Equip Check:", druidComp.isUpgrade, "-", druidComp.reason)
assert(druidComp.isUpgrade == false, "Druid-only boots must NEVER be an upgrade for Priest")

print("--- Testing Set Bonus Evaluation & Threshold Breakpoints ---")
-- Mock equipped gear with 2 pieces of Transcendence (Pauldrons + Robes)
local origGetInventoryItemLink = _G.GetInventoryItemLink
_G.GetInventoryItemLink = function(unit, slotID)
    if slotID == UA.SLOT_IDS["Shoulder"] then return "item:16924:0:0:0" end -- Pauldrons of Transcendence
    if slotID == UA.SLOT_IDS["Chest"] then return "item:16923:0:0:0" end -- Robes of Transcendence
    if slotID == UA.SLOT_IDS["Head"] then return "item:13346:0:0:0" end -- Non-set Head (70 EP)
    return origGetInventoryItemLink(unit, slotID)
end
ITEM_STAT_CACHE = {} -- Invalidate cache

local set3Comp = UA.GetUpgradeComparison(16925, "item:16925:0:0:0") -- Halo of Transcendence (3rd piece!)
print("3-Piece Transcendence Set Bonus Activation Check:")
print("  New Score (with +25 EP Set Bonus):", set3Comp.newScore)
print("  Set Bonus Description:", set3Comp.setBonusDesc)
assert(set3Comp.setBonusEP == 25, "Should award 25 EP for 3-pc Transcendence activation")
assert(set3Comp.isUpgrade == true, "3-pc Transcendence must be recognized as an upgrade")

print("ALL TESTS PASSED SUCCESSFULLY!")

