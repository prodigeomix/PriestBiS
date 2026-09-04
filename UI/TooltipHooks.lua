-- UI/TooltipHooks.lua
-- Tooltip font string extension, badge rendering, and tooltip hook system for PriestBiS.
-- Author: prodigeomix (Carbon)
-- Strict Lua 5.0 Compliance

local _G = _G or getfenv(0)
local PriestBiS = PriestBiS or _G.PriestBiS or {}
local UA = PriestBiS.UA or PriestBiS
PriestBiS.UA = UA
_G.PriestBiS = PriestBiS
_G.UA = UA

local format = string.format
local tostring = tostring
local tonumber = tonumber
local math = math
local getglobal = getglobal or function(name) return _G[name] end

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

-- ================================================
-- TOOLTIP FONT STRING EXTENSION (Beyond 30-Line Cap)
-- ================================================

-- Helper to dynamically ensure tooltips support up to 80 lines (Tier sets with 8-pc lists + enchants + stats + EP badges)
local function EnsureTooltipFontStrings(tt, maxLines)
    if not tt then return end
    local name = nil
    if tt.GetName and type(tt.GetName) == "function" then
        name = tt:GetName()
    end
    if (not name or type(name) ~= "string") and type(tt.name) == "string" then
        name = tt.name
    end
    if not name or type(name) ~= "string" or name == "" then return end
    maxLines = maxLines or 80
    for i = 1, maxLines do
        local leftName = name .. "TextLeft" .. i
        local fsLeft = getglobal(leftName)
        if not fsLeft and tt.CreateFontString then
            fsLeft = tt:CreateFontString(leftName, "ARTWORK", "GameTooltipText")
            if fsLeft then
                if fsLeft.SetFontObject and GameFontNormalSmall then
                    fsLeft:SetFontObject(GameFontNormalSmall)
                end
                local prevLeft = getglobal(name .. "TextLeft" .. (i - 1))
                if prevLeft and fsLeft.SetPoint then
                    fsLeft:SetPoint("TOPLEFT", prevLeft, "BOTTOMLEFT", 0, -2)
                end
            end
        end
        local rightName = name .. "TextRight" .. i
        local fsRight = getglobal(rightName)
        if not fsRight and tt.CreateFontString then
            fsRight = tt:CreateFontString(rightName, "ARTWORK", "GameTooltipText")
            if fsRight then
                if fsRight.SetFontObject and GameFontNormalSmall then
                    fsRight:SetFontObject(GameFontNormalSmall)
                end
                local prevRight = getglobal(name .. "TextRight" .. (i - 1))
                if prevRight and fsRight.SetPoint then
                    fsRight:SetPoint("TOPRIGHT", prevRight, "BOTTOMRIGHT", 0, -2)
                end
            end
        end
    end
end

-- Helper to clean up dynamically managed font strings beyond line 30
local function CleanupCustomTooltipLines(tooltip)
    if not tooltip then return end
    local ttName = tooltip.GetName and tooltip:GetName()
    if ttName and ttName ~= "" then
        for i = 31, 80 do
            local left = getglobal(ttName .. "TextLeft" .. i)
            if left then
                left:SetText("")
                left:Hide()
            end
            local right = getglobal(ttName .. "TextRight" .. i)
            if right then
                right:SetText("")
                right:Hide()
            end
        end
    end
    tooltip._uaCustomLineCount = 0
end

-- Robust line adder that works beyond Vanilla 1.12.1's native 30-line C engine limit
function UA.AddLine(tooltip, text, r, g, b, wrap)
    if not tooltip or not text then return end
    r = r or 1.0
    g = g or 1.0
    b = b or 1.0

    local ttName = tooltip.GetName and tooltip:GetName()
    local nativeCount = (tooltip.NumLines and tooltip:NumLines()) or 0
    local customCount = tooltip._uaCustomLineCount or 0

    if customCount == 0 and nativeCount < 30 then
        if tooltip.AddLine then
            tooltip:AddLine(text, r, g, b)
        end
        return
    end

    if not ttName or ttName == "" then
        if tooltip.AddLine then
            tooltip:AddLine(text, r, g, b)
        end
        return
    end

    local currentTotal = math.max(nativeCount, 30) + customCount
    local newLineIndex = currentTotal + 1

    local leftName = ttName .. "TextLeft" .. newLineIndex
    local fsLeft = getglobal(leftName)
    if not fsLeft and tooltip.CreateFontString then
        fsLeft = tooltip:CreateFontString(leftName, "ARTWORK", "GameTooltipText")
    end

    if not fsLeft then
        if tooltip.AddLine then
            tooltip:AddLine(text, r, g, b)
        end
        return
    end

    if fsLeft.SetFontObject and GameFontNormalSmall then
        fsLeft:SetFontObject(GameFontNormalSmall)
    end
    if fsLeft.SetJustifyH then
        fsLeft:SetJustifyH("LEFT")
    end

    local prevLeft = getglobal(ttName .. "TextLeft" .. (newLineIndex - 1))
    if prevLeft and fsLeft.SetPoint then
        fsLeft:ClearAllPoints()
        fsLeft:SetPoint("TOPLEFT", prevLeft, "BOTTOMLEFT", 0, -2)
    end

    fsLeft:SetTextColor(r, g, b)
    fsLeft:SetText(text)
    fsLeft:Show()

    tooltip._uaCustomLineCount = customCount + 1
end

-- ================================================
-- TOOLTIP UPGRADE LINE RENDERING
-- ================================================

function UA.RenderTooltipLines(tooltip, link, comp)
    if comp.isEquipped then
        UA.AddLine(tooltip, " ")
        if comp.setBonusEP and comp.setBonusEP > 0 then
            UA.AddLine(tooltip, format(L["TOOLTIP_EQUIPPED"], comp.newScore, comp.slot) .. format(" |cff00ff00(+%d Set Bonus)|r", comp.setBonusEP), 0.9, 0.9, 0.9)
            UA.AddLine(tooltip, format("  |cff00ff00" .. L["TOOLTIP_SET_BONUS"] .. "|r %s (+%d EP)", comp.setBonusDesc or "Set Bonus", comp.setBonusEP), 0, 1, 0)
        else
            UA.AddLine(tooltip, format(L["TOOLTIP_EQUIPPED"], comp.newScore, comp.slot), 0.9, 0.9, 0.9)
        end
        local breakdown = UA.FormatStatBreakdown(comp.itemData)
        if breakdown and breakdown ~= "" then
            UA.AddLine(tooltip, "  " .. breakdown, 0.6, 0.6, 0.6)
        end
        if comp.drop then
            UA.AddLine(tooltip, format("  |cff71d5ff" .. L["TOOLTIP_SOURCE"] .. "|r %s", comp.drop), 0.6, 0.8, 1)
        end
        if comp.note then
            UA.AddLine(tooltip, format("  |cffffd100" .. L["TOOLTIP_NOTE"] .. "|r %s", comp.note), 1, 0.82, 0)
        end
    elseif comp.isUpgrade then
        UA.AddLine(tooltip, " ")
        local pctStr = comp.pct and format(" / +%.1f%%", comp.pct) or ""
        UA.AddLine(tooltip, format(L["TOOLTIP_UPGRADE"], comp.delta, pctStr), 0, 1, 0)
        
        local replaceTarget = comp.currentItemName or comp.replaceSlot or comp.slot
        UA.AddLine(tooltip, format("  |cffffffff" .. L["TOOLTIP_REPLACES"] .. "|r |cffa335ee%s|r (|cffffd100%d EP|r -> |cff00ff00%d EP|r)", replaceTarget, comp.currentScore, comp.newScore), 0.9, 0.9, 0.9)
        
        local breakdown = UA.FormatStatBreakdown(comp.itemData)
        if breakdown and breakdown ~= "" then
            UA.AddLine(tooltip, "  " .. breakdown, 0.6, 0.6, 0.6)
        end
        if comp.projectedOH and comp.projectedOH.score and comp.projectedOH.score > 0 then
            UA.AddLine(tooltip, format("  |cff71d5ff" .. L["TOOLTIP_PROJECTED_OH"] .. "|r %s (+%d EP | %s)", comp.projectedOH.name or "Offhand", comp.projectedOH.score, comp.projectedOH.source or L["SOURCE_BAGS"]), 0.6, 0.8, 1)
        end
        if comp.setBonusEP and comp.setBonusEP > 0 and comp.setBonusDesc then
            local bagNote = comp.fromBags and (" | " .. L["WITH_BAG_PIECES"]) or ""
            UA.AddLine(tooltip, format("  |cff00ff00" .. L["TOOLTIP_SET_BONUS"] .. "|r %s (+%d EP%s)", comp.setBonusDesc, comp.setBonusEP, bagNote), 0, 1, 0)
        end
        if comp.lostSetBonusEP and comp.lostSetBonusEP > 0 then
            UA.AddLine(tooltip, format(L["TOOLTIP_SET_BREAK"], comp.lostSetBonusDesc or L["DEFAULT_SET_NAME"], comp.lostSetBonusEP), 1, 0.4, 0.4)
        end
        if comp.drop then
            UA.AddLine(tooltip, format("  |cff71d5ff" .. L["TOOLTIP_SOURCE"] .. "|r %s", comp.drop), 0.6, 0.8, 1)
        end
        if comp.note then
            UA.AddLine(tooltip, format("  |cffffd100" .. L["TOOLTIP_NOTE"] .. "|r %s", comp.note), 1, 0.82, 0)
        end
    else
        local db = PriestBiSDB
        if db and db.showDowngrades == false then
            return
        end

        UA.AddLine(tooltip, " ")
        if comp.roleMismatch then
            UA.AddLine(tooltip, format(L["TOOLTIP_ROLE_MISMATCH"], comp.reason), 1, 0.4, 0.4)
        elseif comp.delta == 0 then
            UA.AddLine(tooltip, format(L["TOOLTIP_SIDEGRADE"], comp.newScore, comp.currentItemName or comp.slot), 0.7, 0.7, 0.7)
            local breakdown = UA.FormatStatBreakdown(comp.itemData)
            if breakdown and breakdown ~= "" then
                UA.AddLine(tooltip, "  " .. breakdown, 0.6, 0.6, 0.6)
            end
        else
            local curScoreDisplay = (comp.lostSetBonusEP and comp.lostSetBonusEP > 0) and comp.effectiveScore or comp.currentScore
            UA.AddLine(tooltip, format(L["TOOLTIP_DOWNGRADE"], comp.newScore, curScoreDisplay, comp.currentItemName or comp.slot), 0.8, 0.5, 0.5)
            local breakdown = UA.FormatStatBreakdown(comp.itemData)
            if breakdown and breakdown ~= "" then
                UA.AddLine(tooltip, "  " .. breakdown, 0.6, 0.6, 0.6)
            end
            if comp.projectedOH and comp.projectedOH.score and comp.projectedOH.score > 0 then
                UA.AddLine(tooltip, format("  |cff71d5ff" .. L["TOOLTIP_PROJECTED_OH"] .. "|r %s (+%d EP | %s)", comp.projectedOH.name or "Offhand", comp.projectedOH.score, comp.projectedOH.source or L["SOURCE_BAGS"]), 0.6, 0.8, 1)
            end
            if comp.lostSetBonusEP and comp.lostSetBonusEP > 0 then
                UA.AddLine(tooltip, format(L["TOOLTIP_SET_BREAK"], comp.lostSetBonusDesc or L["DEFAULT_SET_NAME"], comp.lostSetBonusEP), 1, 0.4, 0.4)
            end
        end
        if comp.drop then
            UA.AddLine(tooltip, format("  |cff71d5ff" .. L["TOOLTIP_SOURCE"] .. "|r %s", comp.drop), 0.6, 0.8, 1)
        end
        if comp.note then
            UA.AddLine(tooltip, format("  |cffffd100" .. L["TOOLTIP_NOTE"] .. "|r %s", comp.note), 1, 0.82, 0)
        end
    end

    tooltip._uaLastLink = link
    if tooltip.Show then
        tooltip:Show()
    end

    if tooltip._uaCustomLineCount and tooltip._uaCustomLineCount > 0 then
        local ttName = tooltip.GetName and tooltip:GetName()
        if ttName and ttName ~= "" then
            local extraHeight = 0
            local baseLines = math.max((tooltip.NumLines and tooltip:NumLines()) or 0, 30)
            local lastFs = nil
            for c = 1, tooltip._uaCustomLineCount do
                local lineIdx = baseLines + c
                local fs = getglobal(ttName .. "TextLeft" .. lineIdx)
                if fs and fs.IsShown and fs:IsShown() then
                    lastFs = fs
                    local h = (fs.GetHeight and fs:GetHeight()) or 14
                    if h < 10 then h = 13 end
                    extraHeight = extraHeight + h + 2
                    local w = (fs.GetStringWidth and fs:GetStringWidth()) or 0
                    if tooltip.GetWidth and tooltip.SetWidth and tooltip:GetWidth() < (w + 24) then
                        tooltip:SetWidth(w + 24)
                    end
                end
            end

            if extraHeight > 0 and tooltip.GetHeight and tooltip.SetHeight then
                local newHeight = tooltip:GetHeight() + extraHeight
                local moneyFrame = getglobal(ttName .. "MoneyFrame")
                if moneyFrame and moneyFrame.IsVisible and moneyFrame:IsVisible() and lastFs then
                    moneyFrame:ClearAllPoints()
                    moneyFrame:SetPoint("TOPLEFT", lastFs, "BOTTOMLEFT", 0, -4)
                    local mH = (moneyFrame.GetHeight and moneyFrame:GetHeight()) or 16
                    newHeight = newHeight + mH + 4
                end
                tooltip:SetHeight(newHeight)
            end
        end
    end
end

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

    EnsureTooltipFontStrings(tooltip, 80)

    if tooltip._uaAppendedLink == link then
        return
    end
    tooltip._uaAppendedLink = link

    insideAppend = true
    pcall(UA.RenderTooltipLines, tooltip, link, comp)
    insideAppend = false
end

local function HookTooltipMethod(tooltip, methodName, getLinkFn)
    local origMethod = tooltip[methodName]
    if origMethod then
        tooltip[methodName] = function(self, a1, a2, a3, a4)
            self._uaAppendedLink = nil
            CleanupCustomTooltipLines(self)
            local r1, r2, r3, r4 = origMethod(self, a1, a2, a3, a4)
            local link = getLinkFn(self, a1, a2, a3, a4)
            if link then
                self._uaLastLink = link
                pcall(function()
                    UA.AppendTooltipUpgradeInfo(self, link)
                end)
            end
            return r1, r2, r3, r4
        end
    end
end

function UA.HookTooltipFrame(tooltip)
    if not tooltip or tooltip._uaHooked then return end
    tooltip._uaHooked = true
    EnsureTooltipFontStrings(tooltip, 80)

    local orig_ClearLines = tooltip.ClearLines
    if orig_ClearLines then
        tooltip.ClearLines = function(self)
            CleanupCustomTooltipLines(self)
            self._uaLastLink = nil
            self._uaAppendedLink = nil
            return orig_ClearLines(self)
        end
    end

    local orig_Hide = tooltip.Hide
    if orig_Hide then
        tooltip.Hide = function(self)
            CleanupCustomTooltipLines(self)
            self._uaLastLink = nil
            self._uaAppendedLink = nil
            return orig_Hide(self)
        end
    end

    HookTooltipMethod(tooltip, "SetHyperlink", function(self, link) return link end)
    HookTooltipMethod(tooltip, "SetBagItem", function(self, bag, slot)
        return GetContainerItemLink and GetContainerItemLink(bag, slot)
    end)
    HookTooltipMethod(tooltip, "SetInventoryItem", function(self, unit, slot)
        return GetInventoryItemLink and GetInventoryItemLink(unit, slot)
    end)
    HookTooltipMethod(tooltip, "SetLootItem", function(self, slot)
        return GetLootSlotLink and GetLootSlotLink(slot)
    end)
    HookTooltipMethod(tooltip, "SetMerchantItem", function(self, slot)
        return GetMerchantItemLink and GetMerchantItemLink(slot)
    end)
    HookTooltipMethod(tooltip, "SetQuestItem", function(self, qType, index)
        return GetQuestItemLink and GetQuestItemLink(qType, index)
    end)
    HookTooltipMethod(tooltip, "SetQuestLogItem", function(self, qType, index)
        return GetQuestLogItemLink and GetQuestLogItemLink(qType, index)
    end)
    HookTooltipMethod(tooltip, "SetAuctionItem", function(self, aType, index)
        return GetAuctionItemLink and GetAuctionItemLink(aType, index)
    end)
    HookTooltipMethod(tooltip, "SetCraftItem", function(self, skill, slot)
        if slot and GetCraftReagentItemLink then return GetCraftReagentItemLink(skill, slot) end
        return GetCraftItemLink and GetCraftItemLink(skill)
    end)
    HookTooltipMethod(tooltip, "SetTradeSkillItem", function(self, skill, slot)
        if slot and GetTradeSkillReagentItemLink then return GetTradeSkillReagentItemLink(skill, slot) end
        return GetTradeSkillItemLink and GetTradeSkillItemLink(skill)
    end)
    HookTooltipMethod(tooltip, "SetInboxItem", function(self, index)
        return GetInboxItemLink and GetInboxItemLink(index)
    end)
    HookTooltipMethod(tooltip, "SetTradePlayerItem", function(self, slot)
        return GetTradePlayerItemLink and GetTradePlayerItemLink(slot)
    end)
    HookTooltipMethod(tooltip, "SetTradeTargetItem", function(self, slot)
        return GetTradeTargetItemLink and GetTradeTargetItemLink(slot)
    end)
end

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
