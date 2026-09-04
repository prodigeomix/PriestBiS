-- PriestBiS.lua
-- Real-time dynamic gear upgrade detection, healing EP scoring, talent sync, and raid roll alerts for Holy & Discipline Priests.
-- Author: prodigeomix (Carbon) (Optimized for Vanilla 1.12.1 / Turtle WoW 1.18.1)
-- Multi-Language Support (English, Chinese zhCN, Russian ruRU, German deDE, French frFR)
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

local function PB_Print(msg)
    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage("|cffffd100[PriestBiS]|r " .. tostring(msg))
    end
end
PriestBiS.Print = PB_Print
local UA_Print = PB_Print

-- ================================================
-- LOOT WINDOW & ROLL MONITORING
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

-- Check chat messages for loot links (only trigger alerts if YOU looted the item)
function UA.CheckLootChatMessage(message)
    if not message then return end
    local isSelfLoot = false
    local lower = string.lower(message)
    if string.find(lower, "you receive") or string.find(message, "你获得") or string.find(message, "你得到")
       or string.find(message, "Ваша добыча") or string.find(message, "Вы получаете")
       or string.find(lower, "ihr erhaltet") or string.find(lower, "vous recevez") then
        isSelfLoot = true
    end

    if isSelfLoot then
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
end

-- Proactive Boss Mouseover Alert
local function OnMouseOverUnit()
    if not UnitExists("mouseover") or UnitIsPlayer("mouseover") then return end
    local bossName = UnitName("mouseover")
    if not bossName then return end

    if UA.BOSS_DROPS and UA.BOSS_DROPS[bossName] then
        local upgradeCount = 0
        for _, itemID in ipairs(UA.BOSS_DROPS[bossName]) do
            local isUpg = UA.IsUpgrade(itemID)
            if isUpg then
                upgradeCount = upgradeCount + 1
            end
        end

        if upgradeCount > 0 then
            UIErrorsFrame:AddMessage(
                format("|cffffd100[PriestBiS]|r " .. L["BOSS_DROPS_ALERT"], bossName, upgradeCount),
                1.0, 1.0, 0.0, 1.0
            )
        end
    end
end

-- Monitor raid rolls and LootBlare master loot events for instant real-time upgrade alerts
function UA.HookLootBlare()
    local itemRollFrame = getglobal("ItemRollFrame")
    if itemRollFrame and not UA.HookedLootBlare then
        UA.HookedLootBlare = true

        local function CheckLootBlareFrame(frame)
            if not frame or not frame:IsShown() then return end
            local currentLink = frame.itemLink
            if currentLink and currentLink ~= "" and frame._pbLastEvaluatedLink ~= currentLink then
                frame._pbLastEvaluatedLink = currentLink
                local itemID = UA.GetItemIDFromLink(currentLink)
                if itemID then
                    local comp = UA.GetUpgradeComparison(itemID, currentLink)
                    if comp and comp.isUpgrade then
                        UA.ShowAlert(itemID, currentLink)
                        local pctStr = comp.pct and format(" / +%.1f%%", comp.pct) or ""
                        UA_Print(format("|cffffd100%s|r " .. L["ROLL_NOW"], L["LOOTBLARE_ROLL_ALERT"], comp.newItemName or "Item", comp.delta or 0, pctStr))
                        if frame.name and frame.name.GetText and frame.name.SetText then
                            local curText = frame.name:GetText() or ""
                            if not string.find(curText, "%[UPGRADE") then
                                frame.name:SetText(curText .. format("\n|cff00ff00[%s +%d EP]|r", L["UPGRADE_TAG"] or "UPGRADE", comp.delta or 0))
                            end
                        end
                    end
                end
            end
        end

        local origShow = itemRollFrame.Show
        itemRollFrame.Show = function(self)
            local frame = self or itemRollFrame
            if origShow then
                origShow(frame)
            end
            frame._pbLastEvaluatedLink = nil
            pcall(CheckLootBlareFrame, frame)
        end

        local origOnUpdate = itemRollFrame:GetScript("OnUpdate")
        itemRollFrame:SetScript("OnUpdate", function()
            if origOnUpdate then
                origOnUpdate()
            end
            if this and this:IsShown() and this.itemLink and this.itemLink ~= "" and this._pbLastEvaluatedLink ~= this.itemLink then
                pcall(CheckLootBlareFrame, this)
            end
        end)
    end
end

-- Check raid warning and party/raid chat for active roll announcements across all locales
function UA.CheckRaidRollMessage(message)
    if not message then return end
    local lower = string.lower(message)
    local isRollCall = false

    local activeLoc = PriestBiS.clientLocale or "enUS"
    if PriestBiS.Patterns and PriestBiS.Patterns[activeLoc] and PriestBiS.Patterns[activeLoc].ROLL_KEYWORDS then
        for _, kw in ipairs(PriestBiS.Patterns[activeLoc].ROLL_KEYWORDS) do
            if string.find(lower, string.lower(kw)) then
                isRollCall = true
                break
            end
        end
    end

    if not isRollCall and PriestBiS.Patterns then
        for _, pGroup in pairs(PriestBiS.Patterns) do
            if pGroup.ROLL_KEYWORDS then
                for _, kw in ipairs(pGroup.ROLL_KEYWORDS) do
                    if string.find(lower, string.lower(kw)) then
                        isRollCall = true
                        break
                    end
                end
            end
            if isRollCall then break end
        end
    end

    if isRollCall then
        for itemLink in string.gfind(message, "(|c%x+|Hitem:[%d:-]+|h%[[^%]]+%]|h|r)") do
            local itemID = UA.GetItemIDFromLink(itemLink)
            if itemID then
                local comp = UA.GetUpgradeComparison(itemID, itemLink)
                if comp and comp.isUpgrade then
                    UA.ShowAlert(itemID, itemLink)
                    local pctStr = comp.pct and format(" / +%.1f%%", comp.pct) or ""
                    UA_Print(format("|cffffd100%s|r " .. L["ROLL_NOW"], L["ROLL_ALERT_TITLE"], itemLink, comp.delta or 0, pctStr))
                end
            end
        end
    end
end

-- ================================================
-- EVENT REGISTRATION & LIFECYCLE
-- ================================================

local eventFrame = CreateFrame("Frame", "PriestBiSEventFrame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("CHARACTER_POINTS_CHANGED")
eventFrame:RegisterEvent("SPELLS_CHANGED")
eventFrame:RegisterEvent("UPDATE_INVENTORY_ALERTS")
eventFrame:RegisterEvent("UNIT_INVENTORY_CHANGED")
eventFrame:RegisterEvent("BAG_UPDATE")
eventFrame:RegisterEvent("BANKFRAME_OPENED")
eventFrame:RegisterEvent("PLAYERBANKSLOTS_CHANGED")
eventFrame:RegisterEvent("PLAYERBANKBAGSLOTS_CHANGED")
eventFrame:RegisterEvent("LOOT_OPENED")
eventFrame:RegisterEvent("CHAT_MSG_LOOT")
eventFrame:RegisterEvent("CHAT_MSG_RAID_WARNING")
eventFrame:RegisterEvent("CHAT_MSG_RAID")
eventFrame:RegisterEvent("CHAT_MSG_PARTY")
eventFrame:RegisterEvent("CHAT_MSG_RAID_LEADER")
eventFrame:RegisterEvent("CHAT_MSG_PARTY_LEADER")
eventFrame:RegisterEvent("CHAT_MSG_ADDON")
eventFrame:RegisterEvent("UPDATE_MOUSEOVER_UNIT")

eventFrame:SetScript("OnEvent", function()
    if event == "ADDON_LOADED" then
        if not PriestBiSDB then PriestBiSDB = {} end
        if PriestBiSDB.tooltipAlerts == nil then PriestBiSDB.tooltipAlerts = true end
        if PriestBiSDB.showDowngrades == nil then PriestBiSDB.showDowngrades = true end
        if UA.RestoreAlertFramePosition then
            UA.RestoreAlertFramePosition()
        end
        UA.HookAllTooltips()
        UA.HookLootBlare()
    elseif event == "PLAYER_ENTERING_WORLD" then
        if UA.RestoreAlertFramePosition then
            UA.RestoreAlertFramePosition()
        end
        UA.HookAllTooltips()
        UA.HookLootBlare()
        UA.UpdateDynamicTalentWeights()
        if not UA.hasAnnouncedLoaded then
            UA.hasAnnouncedLoaded = true
            UA_Print(L["SLASH_VERSION"] .. " loaded. Type |cffffd100/pbis|r for commands.")
        end
    elseif event == "CHARACTER_POINTS_CHANGED" or event == "SPELLS_CHANGED" then
        UA.UpdateDynamicTalentWeights()
    elseif event == "BAG_UPDATE" or (event == "UNIT_INVENTORY_CHANGED" and (not arg1 or arg1 == "player")) then
        UA.bagCacheDirty = true
    elseif event == "BANKFRAME_OPENED" or event == "PLAYERBANKSLOTS_CHANGED" or event == "PLAYERBANKBAGSLOTS_CHANGED" then
        UA.ScanBankForBestOffhand()
    elseif event == "LOOT_OPENED" then
        UA.CheckLootWindow()
    elseif event == "CHAT_MSG_LOOT" then
        UA.CheckLootChatMessage(arg1)
    elseif event == "CHAT_MSG_RAID_WARNING" or event == "CHAT_MSG_RAID" or event == "CHAT_MSG_PARTY" or event == "CHAT_MSG_RAID_LEADER" or event == "CHAT_MSG_PARTY_LEADER" then
        UA.CheckRaidRollMessage(arg1)
    elseif event == "CHAT_MSG_ADDON" then
        if arg1 == "LootBlare" then
            UA.HookLootBlare()
        end
    elseif event == "UPDATE_MOUSEOVER_UNIT" then
        OnMouseOverUnit()
    end
end)

-- Hook available tooltips immediately
UA.HookAllTooltips()

-- ================================================
-- SLASH COMMANDS (/priestbis, /pbis, /bis, /ua)
-- ================================================

SLASH_PriestBiS1 = "/priestbis"
SLASH_PriestBiS2 = "/pbis"
SLASH_PriestBiS3 = "/bis"
SLASH_PriestBiS4 = "/ua"

local function PriestBiS_SlashHandler(msg)
    local cmd = string.lower(msg or "")
    local db = PriestBiSDB or {}
    PriestBiSDB = db

    local alertFrame = getglobal("PriestBiSAlertFrame")

    if cmd == "toggle" then
        if alertFrame and alertFrame:IsVisible() then
            alertFrame:Hide()
        else
            UA.ShowAlert(19958)
        end
    elseif cmd == "tooltip" or cmd == "tooltips" then
        db.tooltipAlerts = not db.tooltipAlerts
        UA_Print(L["TOOLTIP_ALERTS_STATUS"] .. (db.tooltipAlerts and L["ENABLED"] or L["DISABLED"]))
    elseif cmd == "downgrades" or cmd == "downgrade" then
        db.showDowngrades = not db.showDowngrades
        UA_Print(L["TOOLTIP_DOWNGRADES_STATUS"] .. (db.showDowngrades and L["ENABLED"] or L["DISABLED"]))
    elseif cmd == "db" or cmd == "database" then
        UA_Print(L["CURATED_UPGRADES_TITLE"])
        for id, meta in pairs(UA.ITEM_METADATA) do
            if (meta.priority or 99) <= 10 then
                local itemData = UA.GetItemData(id)
                if itemData then
                    UA_Print(format("  * [%d] |cffa335ee%s|r (%s) - Score: %d EP", id, itemData.name or meta.name or ("Item #" .. id), itemData.slot or "Item", UA.GetItemScore(itemData)))
                end
            end
        end
    elseif cmd == "gear" then
        UA_Print(L["TRACKED_GEAR_TITLE"])
        local mhData = UA.GetEquippedItemData("Mainhand")
        local is2H = mhData and (mhData.slot == "Twohand" or mhData.slot == "Staff")
        local totalGearScore = 0
        for _, slotName in ipairs(UA.GEAR_DISPLAY_ORDER) do
            local data = UA.GetEquippedItemData(slotName)
            if slotName == "Mainhand" and is2H then
                local score = data and UA.GetItemScore(data) or 0
                totalGearScore = totalGearScore + score
                UA_Print(format("  Twohand: |cffa335ee%s|r (%d EP)", data and data.name or "Equipped", score))
            elseif slotName == "Offhand" and is2H then
                UA_Print("  Offhand: |cff888888[N/A - 2H Equipped]|r")
            elseif data then
                local score = UA.GetItemScore(data)
                totalGearScore = totalGearScore + score
                UA_Print(format("  %s: |cffa335ee%s|r (%d EP)", slotName, data.name or "Equipped", score))
            else
                UA_Print(format("  %s: %s", slotName, L["EMPTY_LABEL"]))
            end
        end

        -- Active set bonuses
        local totalSetBonusEP = 0
        local activeSets = {}
        for _, slotName in ipairs(UA.GEAR_DISPLAY_ORDER) do
            local data = UA.GetEquippedItemData(slotName)
            if data and data.setName and not activeSets[data.setName] then
                activeSets[data.setName] = true
                local count = UA.GetEquippedSetCount(data.setName)
                if UA.SET_BONUSES and UA.SET_BONUSES[data.setName] then
                    local bps = {}
                    for bp in pairs(UA.SET_BONUSES[data.setName]) do
                        table.insert(bps, bp)
                    end
                    table.sort(bps)
                    for _, breakpoint in ipairs(bps) do
                        local bonusData = UA.SET_BONUSES[data.setName][breakpoint]
                        if count >= breakpoint then
                            totalSetBonusEP = totalSetBonusEP + (bonusData.ep or 0)
                            UA_Print(format("  |cff00ff00Active Set Bonus:|r |cffffd100%s (%d pc)|r (+%d EP): %s", data.setName, breakpoint, bonusData.ep or 0, bonusData.desc or ""))
                        end
                    end
                end
            end
        end

        local grandTotal = totalGearScore + totalSetBonusEP
        if totalSetBonusEP > 0 then
            UA_Print(format("  |cffffd100Total Equipped Score:|r |cff00ff00%d EP|r (|cffffffff%d base + %d set bonus|r)", grandTotal, totalGearScore, totalSetBonusEP))
        else
            UA_Print(format("  |cffffd100Total Equipped Score:|r |cff00ff00%d EP|r", grandTotal))
        end
    elseif cmd == "help" then
        UA_Print(L["SLASH_HEADER"])
        UA_Print(L["SLASH_GEAR"])
        UA_Print(L["SLASH_TOGGLE"])
        UA_Print(L["SLASH_TOOLTIP"])
        UA_Print(L["SLASH_DOWNGRADES"])
        UA_Print(L["SLASH_DB"])
        UA_Print(L["SLASH_HELP"])
    else
        UA_Print(L["SLASH_VERSION"])
        UA_Print(L["SLASH_HELP_PROMPT"])
    end
end

SlashCmdList["PriestBiS"] = PriestBiS_SlashHandler
