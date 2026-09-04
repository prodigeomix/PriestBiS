-- UI/AlertFrame.lua
-- On-screen upgrade alert popup, animations, and sound triggers for PriestBiS.
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
local math = math

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
-- ALERT UI FRAME CREATION & ANIMATIONS
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
alertFrame:SetScript("OnDragStop", function()
    alertFrame:StopMovingOrSizing()
    if alertFrame.GetPoint then
        local point, relativeTo, relativePoint, xOfs, yOfs = alertFrame:GetPoint()
        if not PriestBiSDB then PriestBiSDB = {} end
        PriestBiSDB.alertPos = {
            point = point or "CENTER",
            relativePoint = relativePoint or "CENTER",
            x = xOfs or 0,
            y = yOfs or 120
        }
    end
end)
alertFrame:SetFrameLevel(200)
alertFrame:SetClampedToScreen(true)

function UA.RestoreAlertFramePosition()
    if PriestBiSDB and PriestBiSDB.alertPos and alertFrame.SetPoint and alertFrame.ClearAllPoints then
        local pos = PriestBiSDB.alertPos
        alertFrame:ClearAllPoints()
        alertFrame:SetPoint(pos.point or "CENTER", UIParent, pos.relativePoint or "CENTER", pos.x or 0, pos.y or 120)
    end
end

-- Title
local title = alertFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
title:SetPoint("TOP", alertFrame, "TOP", 0, -10)
title:SetText(L["UPGRADE_ALERT_TITLE"])
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

-- Multi-drop Alert Queue
local alertQueue = {}

local function ProcessNextAlert()
    if table.getn(alertQueue) > 0 then
        local nextItem = table.remove(alertQueue, 1)
        if nextItem and nextItem.itemID then
            UA.ShowAlert(nextItem.itemID, nextItem.itemLink, nextItem.texture, true)
        end
    end
end

-- Close button
local closeBtn = CreateFrame("Button", nil, alertFrame, "UIPanelCloseButton")
closeBtn:SetWidth(28)
closeBtn:SetHeight(28)
closeBtn:SetPoint("TOPRIGHT", alertFrame, "TOPRIGHT", -4, -4)
closeBtn:SetScript("OnClick", function()
    alertFrame:Hide()
    alertFrame:SetScript("OnUpdate", nil)
    ProcessNextAlert()
end)

-- Display Alert Function
function UA.ShowAlert(itemID, itemLink, texture, fromQueue)
    local data = UA.GetItemData(itemID, itemLink)
    if not data then return false end

    -- Multi-drop queueing: if currently showing an alert, queue next item
    if alertFrame:IsVisible() and not fromQueue then
        if alertFrame._currentItemID == itemID then
            return true
        end
        local queueLen = table.getn(alertQueue)
        for i = 1, queueLen do
            if alertQueue[i].itemID == itemID then
                return true
            end
        end
        table.insert(alertQueue, { itemID = itemID, itemLink = itemLink, texture = texture })
        return true
    end

    alertFrame._currentItemID = itemID

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

    title:SetText(L["UPGRADE_ALERT_TITLE"])
    itemNameText:SetText(format("|cffa335ee%s|r", displayName))
    sourceText:SetText(format(L["TOOLTIP_SOURCE"] .. " %s", data.drop or "Dungeon / Raid Drop"))

    local isUpgrade, reason = UA.IsUpgrade(itemID, itemLink)
    if isUpgrade then
        statsText:SetText(format("|cff00ff00%s|r %s", L["UPGRADE_DETECTED"], reason))
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
        local elapsed = arg1 or 0
        alertFrame._timer = alertFrame._timer + elapsed
        alertFrame._flashTimer = alertFrame._flashTimer + elapsed

        if alertFrame._flashTimer < 0.6 then
            local alpha = 0.5 + 0.5 * math.sin(alertFrame._flashTimer * 15)
            alertFrame:SetAlpha(alpha)
        else
            alertFrame:SetAlpha(1)
        end

        local maxDuration = (table.getn(alertQueue) > 0) and 6 or 25
        if alertFrame._timer > maxDuration then
            alertFrame:Hide()
            alertFrame:SetScript("OnUpdate", nil)
            ProcessNextAlert()
        end
    end)

    PlaySound("QUESTADVENTURECOMPLETE")

    if isUpgrade and PriestBiS.Print then
        PriestBiS.Print(format("|cff00ff00%s|r |cffa335ee%s|r - %s", L["UPGRADE_ALERT_CHAT"], displayName, reason))
    end

    return true
end
