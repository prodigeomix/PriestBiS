local function make_frame(frameType, name)
    local f = {
        name = name,
        type = frameType,
        _linesLeft = {},
        _linesRight = {},
        ClearLines = function(self)
            self._linesLeft = {}
            self._linesRight = {}
        end,
        SetHyperlink = function(self, link)
            if string.find(link, "^|c") then
                error("Unknown link type")
            end
            self._link = link
            if link == "item:77777:0:0:0:0:0:0:0:0" or link == "item:77777:0:0:0" then
                self._linesLeft = { "Custom Turtle Belt", "Binds when picked up", "Waist", "+30 Healing Spells" }
                self._linesRight = { "", "", "Cloth", "" }
            end
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
_G.GetInventoryItemLink = function(unit, slotId) return nil end
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
local rob = UA.UPGRADE_DATABASE[16923] -- Robes of Transcendence (59 heal, 27 int, 16 spi, 17 stam)
local robScore = UA.GetItemScore(rob)
print("Robes of Transcendence EP Score: " .. robScore)
assert(robScore > 0, "Score should be positive")

print("--- Testing Hazza'rah Trinket (Tier S) ---")
local haz = UA.UPGRADE_DATABASE[19958]
local hazScore = UA.GetItemScore(haz)
print("Hazza'rah EP Score (EP Override): " .. hazScore)
assert(hazScore == 120, "Hazza'rah should have 120 EP override")

print("--- Testing Drake Fang Talisman (Melee Role) ---")
local dft = UA.UPGRADE_DATABASE[19406]
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

print("--- Testing Slash Command Functions ---")
SlashCmdList["UpgradeAlert"]("gear")
SlashCmdList["UpgradeAlert"]("db")
SlashCmdList["UpgradeAlert"]("help")

print("--- Testing Tooltip Scanner with Formatted WoW Hyperlink ---")
local fullLink = "|cffa335ee|Hitem:77777:0:0:0:0:0:0:0:0|h[Custom Turtle Belt]|h|r"
local scanned = UA.ScanItemStats(77777, fullLink)
print("Scanned item:", scanned.name, scanned.slot, scanned.healing)
assert(scanned ~= nil, "Should scan custom item without crashing")
assert(scanned.name == "Custom Turtle Belt", "Name should match")
assert(scanned.slot == "Belt", "Slot should be Belt")
assert(scanned.healing == 30, "Healing should be 30")

print("ALL TESTS PASSED SUCCESSFULLY!")

