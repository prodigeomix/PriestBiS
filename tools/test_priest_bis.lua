-- tools/test_priest_bis.lua
-- Comprehensive test suite for PriestBiS (Vanilla 1.12.1 / Turtle WoW)
-- Multi-language verification (enUS, zhCN, ruRU, deDE, frFR)

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
_G.GetRealmName = function() return "TurtleWoW" end
_G.UnitName = function(unit) return "Carbon" end

local mockBags = {
    [0] = {
        [1] = "item:19820:0:0:0", -- Consecrated Caduceus (Offhand in bag 0 slot 1)
    }
}
local mockBank = {
    [-1] = {
        [1] = "item:19820:0:0:0", -- Consecrated Caduceus (Offhand in bank)
    }
}

_G.GetContainerNumSlots = function(bag)
    if bag >= 0 and bag <= 4 then return 16 end
    if bag == -1 then return 24 end
    if bag >= 5 and bag <= 11 then return 16 end
    return 0
end

_G.GetContainerItemLink = function(bag, slot)
    if mockBags[bag] and mockBags[bag][slot] then
        return mockBags[bag][slot]
    end
    if mockBank[bag] and mockBank[bag][slot] then
        return mockBank[bag][slot]
    end
    return nil
end


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

            elseif link == "item:16817:0:0:0" then
                self._linesLeft = { "Girdle of Prophecy", "Binds when picked up", "Waist", "Cloth", "+10 Stamina", "+22 Intellect", "+10 Spirit", "+7 Fire Resistance", "Healing +8", "Equip: Restores 4 mana per 5 sec.", "Equip: Increases damage and healing done by magical spells and effects by up to 9.", "Equip: Increases healing done by spells and effects by up to 7.", "Vestments of Prophecy (3/8)", "  Boots of Prophecy", "  Circlet of Prophecy", "  Girdle of Prophecy", "  Gloves of Prophecy", "  Pants of Prophecy", "  Robes of Prophecy", "  Shoulderpads of Prophecy", "  Vambraces of Prophecy", "(3) Set: -0.1 sec to the casting time of your Flash Heal spell." }
                self._linesRight = { "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "" }
            elseif link == "item:16814:0:0:0" then
                self._linesLeft = { "Pants of Prophecy", "Binds when picked up", "Legs", "Cloth", "+20 Intellect", "+21 Spirit", "+10 Stamina", "Equip: Increases healing done by spells and effects by up to 27.", "Vestments of Prophecy (3/8)" }
                self._linesRight = { "", "", "", "", "", "", "", "", "" }
            elseif link == "item:16819:0:0:0" then
                self._linesLeft = { "Vambraces of Prophecy", "Binds when picked up", "Wrist", "Cloth", "+13 Intellect", "+14 Spirit", "+8 Stamina", "Equip: Increases healing done by spells and effects by up to 13.", "Vestments of Prophecy (3/8)" }
                self._linesRight = { "", "", "", "", "", "", "", "", "" }
            elseif link == "item:19958:0:0:0" then
                self._linesLeft = { "Hazza'rah's Charm of Healing", "Binds when picked up", "Trinket", "Use: Increases the critical effect chance of your Flash Heal and Greater Heal spells by 25%" }
                self._linesRight = { "", "", "", "" }
            elseif link == "item:19950:0:0:0" then
                self._linesLeft = { "Zandalarian Hero Charm", "Binds when picked up", "Trinket", "Classes: Mage, Priest, Warlock", "Requires Level 60", "Use: Increases damage and healing done by magical spells by up to 204. Each time you cast a spell the damage or healing is reduced by 17. Lasts 20 sec." }
                self._linesRight = { "", "", "", "", "", "" }
            elseif link == "item:19802:0:0:0" then
                self._linesLeft = { "Heart of Hakkar", "Binds when picked up", "Unique", "This Item Begins a Quest" }
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
            elseif link == "item:19890:0:0:0" then
                self._linesLeft = { "Jin'do's Hexxer", "Binds when picked up", "Unique", "Main Hand", "64 - 135 Damage", "(41.4 damage per second)", "+6 Stamina", "+9 Intellect", "Requires Level 60", "Equip: Increases healing done by spells and effects by up to 51.", "Equip: Improves your chance to get a critical strike with spells by 1%." }
                self._linesRight = { "", "", "", "Mace", "Speed 2.40", "", "", "", "", "", "" }
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

            elseif link == "item:19998:0:0:0" then
                self._linesLeft = { "Gri'lek's Blood", "Major Mojo Infusion (1/2)", "Finger", "+10 Intellect", "+8 Spirit", "Increases healing done by spells and effects by up to 18" }
                self._linesRight = { "", "", "", "", "", "" }
            elseif link == "item:19999:0:0:0" then
                self._linesLeft = { "Renataki's Soul", "Major Mojo Infusion (1/2)", "Finger", "+10 Intellect", "+8 Spirit", "Increases healing done by spells and effects by up to 18" }
                self._linesRight = { "", "", "", "", "", "" }
            elseif link == "item:16926:0:0:0" then
                self._linesLeft = { "Bindings of Transcendence", "Vestments of Transcendence (1/8)", "Wrist", "+10 Intellect", "+14 Spirit", "+8 Stamina", "Increases healing done by spells and effects by up to 24" }
                self._linesRight = { "", "", "Cloth", "", "", "", "" }
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

            elseif link == "item:16817:0:0:0" then
                self._linesLeft = {
                    "Girdle of Prophecy", "Soulbound", "Waist", "57 Armor", "+10 Stamina", "+22 Intellect", "+10 Spirit", "+7 Fire Resistance",
                    "Healing +8", "Durability 23 / 35", "Classes: Priest", "Requires Level 60",
                    "Equip: Restores 4 mana per 5 sec.",
                    "Equip: Increases damage and healing done by magical spells and effects by up to 9.",
                    "Equip: Increases healing done by spells and effects by up to 7.",
                    " ",
                    "Vestments of Prophecy (3/8)",
                    " Boots of Prophecy", " Circlet of Prophecy", " Girdle of Prophecy", " Gloves of Prophecy", " Pants of Prophecy", " Mantle of Prophecy", " Robes of Prophecy", " Vambraces of Prophecy",
                    " ",
                    "Set: -0.1 sec to the casting time of your Flash Heal spell.",
                }
                self._linesRight = { "", "", "Cloth", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "" }

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
        SetScript = function(self, script, handler)
            self._scripts = self._scripts or {}
            self._scripts[script] = handler
        end,
        GetPoint = function(self)
            return self._point or "CENTER", nil, self._relPoint or "CENTER", self._x or 0, self._y or 120
        end,
        ClearAllPoints = function(self) end,
        StartMoving = function(self) end,
        StopMovingOrSizing = function(self) end,
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
            return {
                GetText = function() return tooltip._linesLeft[idx] end,
                SetText = function(self, val) tooltip._linesLeft[idx] = val end,
                IsShown = function() return tooltip._linesLeft[idx] ~= nil and tooltip._linesLeft[idx] ~= "" end
            }
        end
        return nil
    elseif tooltip and string.find(name, "^UAScanningTooltipTextRight(%d+)") then
        local _, _, idx = string.find(name, "^UAScanningTooltipTextRight(%d+)")
        idx = tonumber(idx)
        if idx and tooltip._linesRight and tooltip._linesRight[idx] then
            return {
                GetText = function() return tooltip._linesRight[idx] end,
                SetText = function(self, val) tooltip._linesRight[idx] = val end,
                IsShown = function() return tooltip._linesRight[idx] ~= nil and tooltip._linesRight[idx] ~= "" end
            }
        end
        return nil
    end
    return _G[name]
end

_G.CreateFrame = function(frameType, name, parent, template)
    return make_frame(frameType, name)
end
local slotToLoc = {
    ["Head"] = "INVTYPE_HEAD", ["Neck"] = "INVTYPE_NECK", ["Shoulder"] = "INVTYPE_SHOULDER",
    ["Chest"] = "INVTYPE_CHEST", ["Belt"] = "INVTYPE_WAIST", ["Legs"] = "INVTYPE_LEGS",
    ["Boots"] = "INVTYPE_FEET", ["Wrists"] = "INVTYPE_WRIST", ["Hands"] = "INVTYPE_HAND",
    ["Ring"] = "INVTYPE_FINGER", ["Trinket"] = "INVTYPE_TRINKET", ["Back"] = "INVTYPE_CLOAK",
    ["Mainhand"] = "INVTYPE_WEAPONMAINHAND", ["Offhand"] = "INVTYPE_HOLDABLE",
    ["Twohand"] = "INVTYPE_2HWEAPON", ["Wand"] = "INVTYPE_RANGEDRIGHT"
}

_G.GetItemInfo = function(id)
    local numId = tonumber(id)
    if not numId and type(id) == "string" then
        local _, _, extracted = string.find(id, "item:(%d+)")
        numId = tonumber(extracted)
    end
    if numId and _G.UA and _G.UA.ITEM_METADATA and _G.UA.ITEM_METADATA[numId] and _G.UA.ITEM_METADATA[numId].slot then
        local meta = _G.UA.ITEM_METADATA[numId]
        local loc = slotToLoc[meta.slot] or "INVTYPE_CHEST"
        local itype = (meta.slot == "Mainhand" or meta.slot == "Offhand" or meta.slot == "Twohand" or meta.slot == "Wand") and "Weapon" or "Armor"
        return meta.name or "Item", "item:" .. numId .. ":0:0:0", 4, 60, itype, "Cloth", 1, loc, "Interface\\Icons\\INV_Misc_QuestionMark"
    end
    if numId == 16817 then return "Girdle of Prophecy", "item:16817:0:0:0", 4, 60, "Armor", "Cloth", 1, "INVTYPE_WAIST", "Interface\\Icons\\INV_Belt_03" end
    if numId == 16814 then return "Pants of Prophecy", "item:16814:0:0:0", 4, 60, "Armor", "Cloth", 1, "INVTYPE_LEGS", "Interface\\Icons\\INV_Pants_07" end
    if numId == 16819 then return "Vambraces of Prophecy", "item:16819:0:0:0", 4, 60, "Armor", "Cloth", 1, "INVTYPE_WRIST", "Interface\\Icons\\INV_Bracer_07" end
    if numId == 16812 then return "Gloves of Prophecy", "item:16812:0:0:0", 4, 60, "Armor", "Cloth", 1, "INVTYPE_HAND", "Interface\\Icons\\INV_Gauntlets_14" end
    if numId == 16925 then return "Belt of Transcendence", "item:16925:0:0:0", 4, 60, "Armor", "Cloth", 1, "INVTYPE_WAIST", "Interface\\Icons\\INV_Belt_03" end
    if numId == 22406 then return "Redemption", "item:22406:0:0:0", 4, 60, "Weapon", "Maces", 1, "INVTYPE_WEAPONMAINHAND", "Interface\\Icons\\INV_Mace_01" end
    if numId == 19820 then return "Consecrated Caduceus", "item:19820:0:0:0", 4, 60, "Armor", "Cloth", 1, "INVTYPE_HOLDABLE", "Interface\\Icons\\INV_Misc_Horn_01" end
    if numId == 20258 then return "Zulian Healer's Staff", "item:20258:0:0:0", 4, 60, "Weapon", "Staves", 1, "INVTYPE_2HWEAPON", "Interface\\Icons\\INV_Staff_08" end
    if numId == 19406 then return "Drake Fang Talisman", "item:19406:0:0:0", 4, 60, "Armor", "Cloth", 1, "INVTYPE_TRINKET", "Interface\\Icons\\INV_Misc_MonsterClaw_04" end
    if numId == 22721 then return "Band of Servitude", "item:22721:0:0:0", 4, 60, "Armor", "Cloth", 1, "INVTYPE_FINGER", "Interface\\Icons\\INV_Jewelry_Ring_03" end
    if numId == 77777 then return "Custom Turtle Belt", "item:77777:0:0:0", 4, 60, "Armor", "Cloth", 1, "INVTYPE_WAIST", "Interface\\Icons\\INV_Belt_03" end
    if numId == 19998 then return "Gri'lek's Blood", "item:19998:0:0:0", 4, 60, "Armor", "Cloth", 1, "INVTYPE_FINGER", "Interface\\Icons\\INV_Jewelry_Ring_03" end
    if numId == 19999 then return "Renataki's Soul", "item:19999:0:0:0", 4, 60, "Armor", "Cloth", 1, "INVTYPE_FINGER", "Interface\\Icons\\INV_Jewelry_Ring_03" end
    if numId == 16926 then return "Bindings of Transcendence", "item:16926:0:0:0", 4, 60, "Armor", "Cloth", 1, "INVTYPE_WRIST", "Interface\\Icons\\INV_Bracer_07" end
    return nil
end
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
_G.GetRealmName = function() return "TurtleWoW" end
_G.UnitName = function(unit) return "Carbon" end

local mockBags = {
    [0] = {
        [1] = "item:19820:0:0:0", -- Consecrated Caduceus (Offhand in bag 0 slot 1)
    }
}
local mockBank = {
    [-1] = {
        [1] = "item:19820:0:0:0", -- Consecrated Caduceus (Offhand in bank)
    }
}

_G.GetContainerNumSlots = function(bag)
    if bag >= 0 and bag <= 4 then return 16 end
    if bag == -1 then return 24 end
    if bag >= 5 and bag <= 11 then return 16 end
    return 0
end

_G.GetContainerItemLink = function(bag, slot)
    if mockBags[bag] and mockBags[bag][slot] then
        return mockBags[bag][slot]
    end
    if mockBank[bag] and mockBank[bag][slot] then
        return mockBank[bag][slot]
    end
    return nil
end

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

-- Load Localization stack & PriestBiS Modular Files
dofile("Locales/Localization.lua")
dofile("Locales/Localization.enUS.lua")
dofile("Locales/Localization.zhCN.lua")
dofile("Locales/Localization.ruRU.lua")
dofile("Locales/Localization.deDE.lua")
dofile("Locales/Localization.frFR.lua")
dofile("Data/ItemDatabase.lua")
dofile("Data/SetBonuses.lua")
dofile("Core/Engine.lua")
dofile("Core/Comparison.lua")
dofile("UI/AlertFrame.lua")
dofile("UI/TooltipHooks.lua")
dofile("PriestBiS.lua")

UA.ClearCache()

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

print("--- Testing Zandalarian Hero Charm & Heart of Hakkar (Tier S) ---")
local zhc = UA.GetItemData(19950)
local zhcScore = UA.GetItemScore(zhc)
print("Zandalarian Hero Charm EP Score (EP Override): " .. zhcScore)
assert(zhcScore == 90, "ZHC should have 90 EP override")
assert(zhc.tier == "S", "ZHC should be Tier S")

local zhcComp = UA.GetUpgradeComparison(19950)
print("ZHC Upgrade Check: " .. tostring(zhcComp.isUpgrade) .. " (+ " .. tostring(zhcComp.delta) .. " EP vs " .. tostring(zhcComp.currentItemName) .. ")")
assert(zhcComp.isUpgrade == true, "ZHC (90 EP) should be an upgrade over equipped 65 EP trinket")
assert(zhcComp.delta == 25, "ZHC delta should be +25 EP")

local heart = UA.GetItemData(19802)
local heartScore = UA.GetItemScore(heart)
print("Heart of Hakkar EP Score: " .. heartScore)
assert(heartScore == 90, "Heart of Hakkar should inherit 90 EP")
assert(heart.slot == "Trinket", "Heart of Hakkar should evaluate as Trinket slot")

local heartComp = UA.GetUpgradeComparison(19802)
print("Heart of Hakkar Upgrade Check: " .. tostring(heartComp.isUpgrade) .. " (isEquipped=" .. tostring(heartComp.isEquipped) .. ")")
assert(heartComp.isUpgrade == true, "Heart of Hakkar should be an upgrade when ZHC is not yet equipped")

-- Test duplicate prevention when ZHC is equipped
mockInventory[13] = "item:19950:0:0:0"
local heartCompWhenEquipped = UA.GetUpgradeComparison(19802)
print("Heart of Hakkar Duplicate Check when ZHC equipped: isEquipped=" .. tostring(heartCompWhenEquipped.isEquipped) .. ", isUpgrade=" .. tostring(heartCompWhenEquipped.isUpgrade))
assert(heartCompWhenEquipped.isEquipped == true, "Heart of Hakkar should recognize rewardID 19950 is already equipped")
assert(heartCompWhenEquipped.isUpgrade == false, "Heart of Hakkar should not recommend rolling if ZHC is already equipped")
mockInventory[13] = "item:58231:0:0:0" -- restore Penchant of Humility

-- Verify Hakkar Boss Drops
local hakkarDrops = UA.BOSS_DROPS["Hakkar"]
local hasHeart = false
local hasZHC = false
for _, id in ipairs(hakkarDrops) do
    if id == 19802 then hasHeart = true end
    if id == 19950 then hasZHC = true end
end
assert(hasHeart, "Hakkar boss drops should include Heart of Hakkar (19802)")
assert(hasZHC, "Hakkar boss drops should include Zandalarian Hero Charm (19950)")

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

print("--- Testing Jin'do's Hexxer (1H Mace Equipability & Stat Scoring) ---")
local hexxerData = UA.GetItemData(19890, "item:19890:0:0:0")
print("Scanned Hexxer Stats:\t" .. tostring(hexxerData.name) .. "\tSlot: " .. tostring(hexxerData.slot) .. "\tSubType: " .. tostring(hexxerData.subType) .. "\tHeal: " .. tostring(hexxerData.healing) .. "\tCrit: " .. tostring(hexxerData.crit) .. "\tInt: " .. tostring(hexxerData.int))
assert(hexxerData.name == "Jin'do's Hexxer", "Hexxer name must match")
assert(hexxerData.slot == "Mainhand", "Hexxer slot must be Mainhand")
assert(hexxerData.subType == "Mace", "Hexxer subtype must be Mace, not Leather")
assert(hexxerData.healing == 51, "Hexxer healing must be 51")
assert(hexxerData.crit == 1, "Hexxer crit must be 1%")
assert(hexxerData.int == 9, "Hexxer int must be 9")
assert(hexxerData.stam == 6, "Hexxer stam must be 6")

local hexxerComp = UA.GetUpgradeComparison(19890, "item:19890:0:0:0")
print("Hexxer Equipable Check:\t" .. tostring(hexxerComp.isEquipable) .. "\tScore: " .. tostring(hexxerComp.newScore) .. "\tReason: " .. tostring(hexxerComp.reason))
assert(hexxerComp.isEquipable == true, "Jin'do's Hexxer must be equipable by Priest")
assert(hexxerComp.roleMismatch == false, "Jin'do's Hexxer must not have a role mismatch")
assert(hexxerComp.newScore > 60, "Hexxer score should be ~61 EP (+51 Heal + 1.98 Int + 0.3 Stam + 8 Crit)")

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
print("  Base Item Score (unmutated):\t" .. tostring(set3Comp.newScore))
print("  Set Bonus EP:\t" .. tostring(set3Comp.setBonusEP))
print("  Net Delta:\t" .. tostring(set3Comp.delta))
assert(set3Comp.newScore == 51, "Base score must remain 51 EP (unmutated by set bonus)")
assert(set3Comp.setBonusEP == 25, "Should award 25 EP for 3-pc Transcendence activation")
assert(set3Comp.delta == 16, "Net upgrade must be 51 base - 60 current + 25 set bonus = 16 EP")
assert(set3Comp.isUpgrade == true, "3-pc Transcendence must be recognized as an upgrade")

-- Test Equipped Tier Piece with Active Set Bonus (Pure score & effective score check)
_G.GetInventoryItemLink = function(unit, slotID)
    if slotID == UA.SLOT_IDS["Belt"] then return "item:16925:0:0:0" end
    if slotID == UA.SLOT_IDS["Shoulder"] then return "item:16924:0:0:0" end
    if slotID == UA.SLOT_IDS["Chest"] then return "item:16923:0:0:0" end
    return origGetInventoryItemLink(unit, slotID)
end
ITEM_STAT_CACHE = {}

local eqTierComp = UA.GetUpgradeComparison(16925, "item:16925:0:0:0")
assert(eqTierComp.isEquipped == true, "Should recognize 16925 as equipped")
assert(eqTierComp.newScore == 51, "Equipped piece base score must remain 51 EP")
assert(eqTierComp.setBonusEP == 25, "Equipped piece should report 25 EP active set bonus")
assert(eqTierComp.effectiveScore == 76, "Equipped effective score must be 51 base + 25 set bonus = 76 EP")

-- Test Set Break Downgrade Math (Candidate item higher base stats, but breaks 3-pc set bonus)
-- Belt of Transcendence base is 51 EP. Active 3-pc adds 25 EP -> Effective score = 76 EP.
-- A candidate belt with 60 EP (higher than 51 base) will break 3-pc (dropping count to 2), so 60 vs 76 is a DOWNGRADE of -16 EP.
local candComp = UA.GetUpgradeComparison(77777, "item:77777:0:0:0")
assert(candComp.isUpgrade == false, "Candidate breaking 3-pc bonus should be marked as downgrade")
assert(candComp.lostSetBonusEP == 25, "Candidate must track 25 EP lost set bonus")
assert(candComp.effectiveScore == 76, "Effective score must be 51 + 25 = 76 EP")
assert(candComp.delta == -46, "Net delta must be 30 - 76 = -46 EP")

-- Test Set Completion with Pieces in Bags
_G.GetInventoryItemLink = function(unit, slotID)
    return nil -- No tier pieces equipped
end
ITEM_STAT_CACHE = {}
UA.bagCacheDirty = false
UA.cachedBagSetPieces = {
    ["Vestments of Transcendence"] = {
        ["Shoulder"] = { slot = "Shoulder", setName = "Vestments of Transcendence" },
        ["Chest"] = { slot = "Chest", setName = "Vestments of Transcendence" },
    }
}

local bagSetComp = UA.GetUpgradeComparison(16925, "item:16925:0:0:0")
print("Transcendence Set Completion from Bags Check:")
print("  Set Bonus EP:\t" .. tostring(bagSetComp.setBonusEP))
print("  From Bags Flag:\t" .. tostring(bagSetComp.fromBags))
assert(bagSetComp.setBonusEP == 25, "Should award 25 EP set bonus completing 3-pc with bag pieces")
assert(bagSetComp.fromBags == true, "fromBags flag must be true when completing set via bags")
assert(bagSetComp.isUpgrade == true, "Must be an upgrade")
UA.cachedBagSetPieces = nil

-- Test Major Mojo Infusion ZG Ring Dual-Slot Replacement
_G.GetInventoryItemLink = function(unit, slotID)
    if slotID == UA.SLOT_IDS["Ring1"] then return "item:19998:0:0:0" end -- Gri'lek's Blood (Major Mojo Infusion)
    if slotID == UA.SLOT_IDS["Ring2"] then return "item:22721:0:0:0" end -- Band of Servitude (non-set)
    return nil
end
ITEM_STAT_CACHE = {}

local zgRingComp = UA.GetUpgradeComparison(19999, "item:19999:0:0:0") -- Renataki's Soul (Major Mojo Infusion)
print("Major Mojo Infusion ZG Ring Replacement Check:")
print("  Target Slot:\t" .. tostring(zgRingComp.replaceSlot))
print("  Set Bonus EP:\t" .. tostring(zgRingComp.setBonusEP))
print("  Is Upgrade:\t" .. tostring(zgRingComp.isUpgrade))
assert(zgRingComp.replaceSlot == "Ring2", "Must choose Ring2 to replace non-set ring and complete 2-pc set")
assert(zgRingComp.setBonusEP == 21, "Must activate 2-pc Major Mojo Infusion (+21 EP)")
assert(zgRingComp.isUpgrade == true, "2-pc ZG ring completion must be an upgrade")

_G.GetInventoryItemLink = origGetInventoryItemLink
ITEM_STAT_CACHE = {}

print("--- Testing Raid Roll Chat Detection & 'rush' Keyword ---")
local alertCalledWith = nil
local origShowAlert = UA.ShowAlert
UA.ShowAlert = function(id, link)
    alertCalledWith = id
end

-- Test standard roll
alertCalledWith = nil
UA.CheckRaidRollMessage("Roll for |cffa335ee|Hitem:16923:0:0:0|h[Robes of Transcendence]|h|r MS/OS")
assert(alertCalledWith == 16923, "Should trigger alert for standard 'Roll' message")

-- Test 'rush' keyword (Turtle WoW raid convention)
alertCalledWith = nil
UA.CheckRaidRollMessage("rush |cffa335ee|Hitem:16923:0:0:0|h[Robes of Transcendence]|h|r 100")
assert(alertCalledWith == 16923, "Should trigger alert for 'rush' keyword message")

-- Test non-roll chatter (should NOT trigger)
alertCalledWith = nil
UA.CheckRaidRollMessage("Gz on getting |cffa335ee|Hitem:16923:0:0:0|h[Robes of Transcendence]|h|r!")
assert(alertCalledWith == nil, "Should NOT trigger alert for non-roll chatter")

UA.ShowAlert = origShowAlert

print("--- Testing Alert Frame OnUpdate Nil-Safety & Position Persistence ---")
-- Test toggle/show and verify OnUpdate handler runs cleanly when arg1 is nil
UA.ShowAlert(19958)
local alertF = _G["PriestBiSAlertFrame"] or _G["PriestBiS_AlertFrame"]
if alertF and alertF._scripts and alertF._scripts["OnUpdate"] then
    _G.arg1 = nil
    -- Executing OnUpdate with nil arg1 should not raise an error
    local ok, err = pcall(alertF._scripts["OnUpdate"])
    assert(ok, "OnUpdate should execute safely when arg1 is nil: " .. tostring(err))
    print("AlertFrame OnUpdate nil-safety verified successfully.")
end

-- Test drag stop position persistence
if alertF and alertF._scripts and alertF._scripts["OnDragStop"] then
    alertF._point = "TOPLEFT"
    alertF._relPoint = "TOPLEFT"
    alertF._x = 42
    alertF._y = -84
    alertF._scripts["OnDragStop"]()
    assert(PriestBiSDB and PriestBiSDB.alertPos, "alertPos should be saved to PriestBiSDB on drag stop")
    assert(PriestBiSDB.alertPos.x == 42 and PriestBiSDB.alertPos.y == -84, "Saved coordinates should match")
    print("AlertFrame position persistence on drag stop verified.")
end

print("--- Testing LootBlare Hook Protection & Real-Time OnUpdate Latency Catch ---")
local alertCount = 0
local origShowAlert = UA.ShowAlert
UA.ShowAlert = function(id, link)
    alertCount = alertCount + 1
end

local mockItemRollFrame = {
    Show = function(self) self._shown = true end,
    IsShown = function(self) return self._shown end,
    name = {
        _text = "Item Name",
        GetText = function(self) return self._text end,
        SetText = function(self, t) self._text = t end,
    },
    itemLink = nil,
    _scripts = {},
    SetScript = function(self, name, handler) self._scripts[name] = handler end,
    GetScript = function(self, name) return self._scripts[name] end,
}
_G["ItemRollFrame"] = mockItemRollFrame
UA.HookedLootBlare = false
UA.HookLootBlare()

-- 1. Simulate Show() when itemLink is nil (async item query pending)
mockItemRollFrame:Show()
assert(mockItemRollFrame._shown == true, "Original Show should be called on ItemRollFrame")
assert(alertCount == 0, "ShowAlert should not fire while itemLink is nil")

-- 2. Simulate OnUpdate() after async query resolves itemLink
mockItemRollFrame.itemLink = "item:19958:0:0:0"
local onUpdateFn = mockItemRollFrame:GetScript("OnUpdate")
assert(onUpdateFn ~= nil, "OnUpdate hook should be registered")
_G["this"] = mockItemRollFrame
onUpdateFn()
assert(alertCount == 1, "ShowAlert should fire immediately upon itemLink resolution in OnUpdate")

-- 3. Simulate subsequent OnUpdate ticks (ensure no duplicate alerts)
onUpdateFn()
assert(alertCount == 1, "ShowAlert should only fire once per item roll")

-- Test CHAT_MSG_LOOT self-filtering
alertCount = 0
UA.CheckLootChatMessage("Bob receives loot: item:19958:0:0:0.")
assert(alertCount == 0, "Third-party loot messages should NOT trigger upgrade alert popups")

UA.CheckLootChatMessage("You receive loot: item:19958:0:0:0.")
assert(alertCount == 1, "Self loot message SHOULD trigger upgrade alert")

UA.ShowAlert = origShowAlert
print("--- Testing Dynamic Talent Weight Synchronization ---")
_G.UnitClass = function(unit) return "Priest", "PRIEST" end

local mockTalents = {
    [1] = { { name = "Meditation", rank = 3 } },
    [2] = { { name = "Spiritual Guidance", rank = 5 } },
}

_G.GetNumTalents = function(tabIndex)
    return mockTalents[tabIndex] and table.getn(mockTalents[tabIndex]) or 0
end

_G.GetTalentInfo = function(tabIndex, tIndex)
    if mockTalents[tabIndex] and mockTalents[tabIndex][tIndex] then
        local t = mockTalents[tabIndex][tIndex]
        return t.name, nil, nil, nil, t.rank
    end
    return nil
end

-- Test 5/5 SG + 3/3 Meditation (0.25 + 0.45 = 0.70)
mockTalents[1][1].rank = 3
mockTalents[2][1].rank = 5
UA.UpdateDynamicTalentWeights()
assert(math.abs(UA.STAT_WEIGHTS.spi - 0.70) < 0.001, "5/5 SG + 3/3 Med should equal 0.70 SPI weight")

-- Test 0/5 SG + 0/3 Meditation (Untalented: 0.00 + 0.30 = 0.30)
mockTalents[1][1].rank = 0
mockTalents[2][1].rank = 0
UA.UpdateDynamicTalentWeights()
assert(math.abs(UA.STAT_WEIGHTS.spi - 0.30) < 0.001, "0/5 SG + 0/3 Med should equal 0.30 SPI weight")

-- Test 0/5 SG + 3/3 Meditation (Med only: 0.00 + 0.45 = 0.45)
mockTalents[1][1].rank = 3
mockTalents[2][1].rank = 0
UA.UpdateDynamicTalentWeights()
assert(math.abs(UA.STAT_WEIGHTS.spi - 0.45) < 0.001, "0/5 SG + 3/3 Med should equal 0.45 SPI weight")

-- Test 5/5 SG + 0/3 Meditation (SG only: 0.25 + 0.30 = 0.55)
mockTalents[1][1].rank = 0
mockTalents[2][1].rank = 5
UA.UpdateDynamicTalentWeights()
assert(math.abs(UA.STAT_WEIGHTS.spi - 0.55) < 0.001, "5/5 SG + 0/3 Med should equal 0.55 SPI weight")

-- Reset back to 5/5 SG + 3/3 Med
mockTalents[1][1].rank = 3
mockTalents[2][1].rank = 5
UA.UpdateDynamicTalentWeights()

print("--- Testing Girdle of Prophecy Tooltip Parsing & Tier Comparison ---")
local girdleTooltipLines = {
    [1] = "Girdle of Prophecy",
    [2] = "Soulbound",
    [3] = "Waist Cloth",
    [4] = "57 Armor",
    [5] = "+10 Stamina",
    [6] = "+22 Intellect",
    [7] = "+10 Spirit",
    [8] = "+7 Fire Resistance",
    [9] = "Healing +8",
    [10] = "Durability 23 / 35",
    [11] = "Classes: Priest",
    [12] = "Requires Level 60",
    [13] = "Equip: Restores 4 mana per 5 sec.",
    [14] = "Equip: Increases damage and healing done by magical spells and effects by up to 9.",
    [15] = "Equip: Increases healing done by spells and effects by up to 7.",
    [16] = " ",
    [17] = "Vestments of Prophecy (3/8)",
    [18] = " Boots of Prophecy",
    [19] = " Circlet of Prophecy",
    [20] = " Girdle of Prophecy",
    [21] = " Gloves of Prophecy",
    [22] = " Pants of Prophecy",
    [23] = " Mantle of Prophecy",
    [24] = " Robes of Prophecy",
    [25] = " Vambraces of Prophecy",
    [26] = " ",
    [27] = "Set: -0.1 sec to the casting time of your Flash Heal spell.",
}
_G.UAScanningTooltip._linesLeft = girdleTooltipLines
_G.UAScanningTooltip._numLines = 27
local girdleData = UA.ScanItemStats(16817, "item:16817:0:0:0")
assert(girdleData ~= nil, "Girdle of Prophecy should parse successfully")
assert(girdleData.slot == "Belt", "Girdle of Prophecy slot should be Belt")
assert(girdleData.setName == "Vestments of Prophecy", "Girdle of Prophecy set should be Vestments of Prophecy")
assert(girdleData.int == 22, "Girdle Int should be 22")
assert(girdleData.spi == 10, "Girdle Spi should be 10")
assert(girdleData.mp5 == 4, "Girdle MP5 should be 4")
assert(girdleData.healing == 24, "Girdle Healing should be 24 (9+7+8), got " .. tostring(girdleData.healing))

-- Mock Girdle, Pants, and Vambraces equipped (3-piece Vestments of Prophecy)
_G.GetInventoryItemLink = function(unit, slot)
    if slot == 6 then return "item:16817:0:0:0" end -- Girdle of Prophecy (Belt)
    if slot == 7 then return "item:16814:0:0:0" end -- Pants of Prophecy (Legs)
    if slot == 9 then return "item:16819:0:0:0" end -- Vambraces of Prophecy (Wrists)
    return nil
end
local girdleComp = UA.GetUpgradeComparison(16817, "item:16817:0:0:0")
assert(girdleComp ~= nil, "Girdle comparison should not be nil")
assert(girdleComp.isEquipped == true, "Girdle should be identified as equipped")
assert(girdleComp.setBonusEP == 15, "Girdle active set bonus should be 15 EP")

-- --- Testing 2H Staff Equipped vs 1H Candidate with Bag/Bank Off-Hand ---
print("--- Testing 2H Staff Equipped vs 1H Candidate with Bag/Bank Off-Hand ---")
_G.GetInventoryItemLink = function(unit, slot)
    if slot == 16 then return "item:20258:0:0:0" end -- Zulian Ceremonial Staff (Twohand, 71 Heal)
    if slot == 17 then return nil end -- Offhand empty because 2H equipped
    return nil
end
ITEM_STAT_CACHE = {}

local bagOH = UA.ScanBagsForBestOffhand()
assert(bagOH ~= nil, "ScanBagsForBestOffhand should find Consecrated Caduceus")
assert(bagOH.score > 0, "Bag off-hand score should be > 0")

local bankOH = UA.ScanBankForBestOffhand()
assert(bankOH ~= nil, "ScanBankForBestOffhand should find bank off-hand")
assert(PriestBiSDB ~= nil and PriestBiSDB.bestBankOffhand ~= nil, "PriestBiSDB.bestBankOffhand should be cached")

local bestAvailOH = UA.GetBestAvailableOffhand()
assert(bestAvailOH ~= nil, "GetBestAvailableOffhand should return best OH")

local mh2hComp = UA.GetUpgradeComparison(22406, "item:22406:0:0:0")
assert(mh2hComp ~= nil, "Mainhand vs 2H comparison should return valid result")
assert(mh2hComp.projectedOH ~= nil, "mh2hComp should include projectedOH")
assert(mh2hComp.isUpgrade == true, "Redemption + Bag/Bank OH should be an upgrade over 2H Staff")
assert(mh2hComp.delta > 40, "Upgrade delta should reflect 1H + projected OH vs 2H staff")

-- --- Testing Bagshui-Inspired Character Scoping & Dirty-Flag Debouncing ---
print("--- Testing Bagshui-Inspired Character Scoping & Dirty-Flag Debouncing ---")
_G.GetRealmName = function() return "TurtleWoW" end
_G.UnitName = function(u) return "Carbon" end
local charData = UA.GetCharacterData()
assert(charData ~= nil, "GetCharacterData should return character profile")
assert(PriestBiSDB.characters["TurtleWoW"]["Carbon"] ~= nil, "Character profile should be scoped by realm and name")

-- Test dirty flag
UA.bagCacheDirty = false
UA.cachedBagOffhand = { name = "Cached Caduceus", score = 39.8, source = "Bags" }
local cachedOH = UA.ScanBagsForBestOffhand()
assert(cachedOH.name == "Cached Caduceus", "ScanBagsForBestOffhand should return cached item when not dirty")

UA.bagCacheDirty = true
local rescannedOH = UA.ScanBagsForBestOffhand()
assert(rescannedOH.name == "Consecrated Caduceus", "ScanBagsForBestOffhand should rescan when dirty")

-- Test bank update event simulation and Bank Container 11 scanning
assert(UA.BANK_CONTAINERS[table.getn(UA.BANK_CONTAINERS)] == 11, "BANK_CONTAINERS must include slot 11")
mockBank[11] = { [1] = "item:19820:0:0:0" }
mockBank[-1][1] = nil
charData.bestBankOffhand = nil
UA.ScanBankForBestOffhand()
assert(charData.bestBankOffhand ~= nil, "Bank offhand in bag 11 should be detected and stored in charData")
assert(charData.bestBankOffhand.score > 0, "Stored bank offhand from bag 11 should have positive score")

-- --- Testing insideAppend Re-entrancy Guard Hardening & Fault Recovery ---
print("--- Testing insideAppend Re-entrancy Guard Hardening & Fault Recovery ---")
local testTT = make_frame("GameTooltip", "TestFaultTooltip")
testTT.origRender = UA.RenderTooltipLines
UA.RenderTooltipLines = function(tooltip, link, comp)
    error("Simulated tooltip rendering fault!")
end

-- Call AppendTooltipUpgradeInfo with throwing render
UA.AppendTooltipUpgradeInfo(testTT, "item:22406:0:0:0")

-- Restore RenderTooltipLines
UA.RenderTooltipLines = testTT.origRender

-- Verify that subsequent tooltip calls STILL work (insideAppend was reset properly)
testTT._uaAppendedLink = nil
UA.AppendTooltipUpgradeInfo(testTT, "item:22406:0:0:0")
assert(testTT._uaLastLink == "item:22406:0:0:0", "insideAppend must reset to false after error, allowing subsequent tooltips to render")

-- --- Testing Curated Raid Quest Tokens & On-Use Trinkets ---
print("--- Testing Curated Raid Quest Tokens & On-Use Trinkets ---")
local eyeDivData = UA.GetItemData(18646)
assert(eyeDivData ~= nil, "The Eye of Divinity must have item data")
assert(eyeDivData.slot == "Twohand", "The Eye of Divinity should map to Twohand slot")
assert(UA.GetItemScore(eyeDivData) == 215, "The Eye of Divinity should have 215 EP override (Benediction)")

local onyHeadData = UA.GetItemData(19002)
assert(onyHeadData ~= nil, "Head of Onyxia must have item data")
assert(onyHeadData.slot == "Trinket", "Head of Onyxia should map to Trinket slot")
assert(UA.GetItemScore(onyHeadData) == 85, "Head of Onyxia should have 85 EP override (Shard of the Scale)")

local nefHeadData = UA.GetItemData(19003)
assert(nefHeadData ~= nil, "Head of Nefarian must have item data")
assert(nefHeadData.slot == "Ring", "Head of Nefarian should map to Ring slot")
assert(UA.GetItemScore(nefHeadData) == 74, "Head of Nefarian should have 74 EP override (Pure Elementium Band)")

local dmcData = UA.GetItemData(19288)
assert(dmcData ~= nil and UA.GetItemScore(dmcData) == 90, "DMC Blue Dragon should have 90 EP")

local eotdData = UA.GetItemData(23047)
assert(eotdData ~= nil and UA.GetItemScore(eotdData) == 130, "Eye of the Dead should have 130 EP")

local scarabData = UA.GetItemData(21625)
assert(scarabData ~= nil and UA.GetItemScore(scarabData) == 80, "Scarab Brooch should have 80 EP")

local marliTrinket = UA.GetItemData(19930)
assert(marliTrinket ~= nil and UA.GetItemScore(marliTrinket) == 45, "Mar'li's Eye should have 45 EP")

-- Test upgrade comparison with quest starter token
local compEye = UA.GetUpgradeComparison(18646)
assert(compEye ~= nil and compEye.slot == "Twohand", "Eye of Divinity comparison should evaluate against Twohand / MH+OH")

-- --- Testing Universal Role Mismatch for Non-Trinket Items ---
print("--- Testing Universal Role Mismatch for Non-Trinket Items ---")
local meleeRingComp = UA.GetUpgradeComparison(22722)
assert(meleeRingComp ~= nil, "Band of Servitude should return comparison")
assert(meleeRingComp.roleMismatch == true, "Melee ring (Band of Servitude) must be flagged as roleMismatch")
assert(meleeRingComp.isUpgrade == false, "Melee ring must not be considered an upgrade")
assert(string.find(meleeRingComp.reason, "MELEE"), "Reason should mention MELEE role")

local tankRingComp = UA.GetUpgradeComparison(55123)
assert(tankRingComp ~= nil, "Rupturan's Seal should return comparison")
assert(tankRingComp.roleMismatch == true, "Tank ring (Rupturan's Seal) must be flagged as roleMismatch")
assert(tankRingComp.isUpgrade == false, "Tank ring must not be considered an upgrade")
assert(string.find(tankRingComp.reason, "TANK"), "Reason should mention TANK role")

-- --- Testing pfDB Drop Rate Sorting ---
print("--- Testing pfDB Drop Rate Sorting ---")
_G.pfDB = {
    items = {
        data = {
            [99901] = {
                U = {
                    [101] = 0.001, -- 0.1% trash mob
                    [102] = 0.25,  -- 25.0% boss
                }
            }
        }
    },
    units = {
        enUS = {
            [101] = "Crypt Ghoul",
            [102] = "Clawlord Howlfang",
        }
    }
}
local sortedSource = UA.GetItemSourceFromPfDB(99901)
assert(sortedSource ~= nil, "Source should resolve")
assert(string.find(sortedSource, "Clawlord Howlfang"), "Highest rate boss should be listed first in sortedSource: " .. tostring(sortedSource))

print("ALL TESTS (INCLUDING MULTI-LANGUAGE SUITE & TALENT SYNC) PASSED SUCCESSFULLY!")



