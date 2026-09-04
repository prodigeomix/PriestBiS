-- Core/Comparison.lua
-- Equipment comparison engine, dual-slot resolution, set math, and upgrade logic for PriestBiS.
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
-- OFF-HAND SCANNING & INVENTORY BACKING
-- ================================================

UA.cachedBagOffhand = nil

-- Scan player's bags (0..4) for the best Off-Hand item with dirty-flag debouncing
function UA.ScanBagsForBestOffhand()
    if not UA.bagCacheDirty and UA.cachedBagOffhand ~= nil then
        return UA.cachedBagOffhand
    end
    if not GetContainerNumSlots or not GetContainerItemLink then return nil end
    local best = nil
    local bestScore = -1

    local numBags = table.getn(UA.BAG_CONTAINERS)
    for b = 1, numBags do
        local bag = UA.BAG_CONTAINERS[b]
        local numSlots = GetContainerNumSlots(bag) or 0
        for slot = 1, numSlots do
            local link = GetContainerItemLink(bag, slot)
            if link then
                local itemData = UA.GetItemData(nil, link)
                if itemData and (itemData.slot == "Offhand" or itemData.equipLoc == "INVTYPE_HOLDABLE") then
                    local score = UA.GetItemScore(itemData)
                    if score > bestScore then
                        bestScore = score
                        best = {
                            name = itemData.name or "Offhand",
                            link = link,
                            score = score,
                            source = L["SOURCE_BAGS"] or "Bags"
                        }
                    end
                end
            end
        end
    end
    UA.cachedBagOffhand = best
    UA.bagCacheDirty = false
    return best
end

-- Scan player's bank containers (-1, 5..10) on BANK events and cache per-character
function UA.ScanBankForBestOffhand()
    if not GetContainerNumSlots or not GetContainerItemLink then return nil end
    local best = nil
    local bestScore = -1

    local numBankBags = table.getn(UA.BANK_CONTAINERS)
    for i = 1, numBankBags do
        local bag = UA.BANK_CONTAINERS[i]
        local numSlots = GetContainerNumSlots(bag) or 0
        for slot = 1, numSlots do
            local link = GetContainerItemLink(bag, slot)
            if link then
                local itemData = UA.GetItemData(nil, link)
                if itemData and (itemData.slot == "Offhand" or itemData.equipLoc == "INVTYPE_HOLDABLE") then
                    local score = UA.GetItemScore(itemData)
                    if score > bestScore then
                        bestScore = score
                        best = {
                            name = itemData.name or "Offhand",
                            link = link,
                            score = score,
                            source = L["SOURCE_BANK"] or "Bank"
                        }
                    end
                end
            end
        end
    end

    local charData = UA.GetCharacterData()
    if charData then
        charData.bestBankOffhand = best
    end
    if PriestBiSDB then
        PriestBiSDB.bestBankOffhand = best
    end
    return best
end

-- Retrieve best available offhand among Equipped, Bags, and Bank (character scoped)
function UA.GetBestAvailableOffhand()
    local best = nil
    local bestScore = -1

    -- 1. Check equipped offhand
    local eqData = UA.GetEquippedItemData("Offhand")
    if eqData then
        local eqScore = UA.GetItemScore(eqData)
        if eqScore > bestScore then
            bestScore = eqScore
            best = {
                name = eqData.name or "Offhand",
                link = eqData.link,
                score = eqScore,
                source = L["SOURCE_EQUIPPED"] or "Equipped"
            }
        end
    end

    -- 2. Check bags
    local bagBest = UA.ScanBagsForBestOffhand()
    if bagBest and bagBest.score > bestScore then
        bestScore = bagBest.score
        best = bagBest
    end

    -- 3. Check character-scoped cached bank
    local charData = UA.GetCharacterData()
    local bankBest = (charData and charData.bestBankOffhand) or (PriestBiSDB and PriestBiSDB.bestBankOffhand)
    if bankBest and bankBest.score and bankBest.score > bestScore then
        bestScore = bankBest.score
        best = {
            name = bankBest.name or "Offhand",
            link = bankBest.link,
            score = bankBest.score,
            source = L["SOURCE_BANK"] or "Bank"
        }
    end

    return best
end

-- ================================================
-- SET BONUSES: BAG TRACKING & BREAKPOINT MATH
-- ================================================

UA.cachedBagSetPieces = nil

-- Scan player's bags (0..4) for set items with dirty-flag debouncing
function UA.ScanBagsForSetPieces()
    if not UA.bagCacheDirty and UA.cachedBagSetPieces ~= nil then
        return UA.cachedBagSetPieces
    end
    if not GetContainerNumSlots or not GetContainerItemLink then
        return UA.cachedBagSetPieces or {}
    end

    local setPieces = {} -- [setName] = { [normSlot] = itemData }
    local numBags = table.getn(UA.BAG_CONTAINERS)
    for b = 1, numBags do
        local bag = UA.BAG_CONTAINERS[b]
        local numSlots = GetContainerNumSlots(bag) or 0
        for slot = 1, numSlots do
            local link = GetContainerItemLink(bag, slot)
            if link then
                local itemData = UA.GetItemData(nil, link)
                if itemData and itemData.setName and itemData.slot then
                    local sName = itemData.setName
                    local normSlot = (itemData.slot == "Ring") and "Ring"
                                  or (itemData.slot == "Trinket") and "Trinket"
                                  or itemData.slot
                    if not setPieces[sName] then
                        setPieces[sName] = {}
                    end
                    setPieces[sName][normSlot] = itemData
                end
            end
        end
    end
    UA.cachedBagSetPieces = setPieces
    return setPieces
end

-- Count unique slots equipped and available in bags for a given set
function UA.GetSetPieceCount(setName, excludeSlot)
    if not setName or setName == "" then return 0, 0, 0 end
    local equippedCount = 0
    local equippedSlots = {}

    -- 1. Scan equipped items for unique slots belonging to setName
    for _, slotName in ipairs(UA.GEAR_DISPLAY_ORDER) do
        if not excludeSlot or slotName ~= excludeSlot then
            local equipped = UA.GetEquippedItemData(slotName)
            if equipped and equipped.setName == setName then
                equippedSlots[slotName] = true
                equippedCount = equippedCount + 1
            end
        end
    end

    -- 2. Scan bags for distinct slots of setName not already worn
    local bagPieces = UA.ScanBagsForSetPieces()
    local totalCount = equippedCount
    local bagContrib = 0
    if bagPieces and bagPieces[setName] then
        local ringWorn = 0
        if equippedSlots["Ring1"] then ringWorn = ringWorn + 1 end
        if equippedSlots["Ring2"] then ringWorn = ringWorn + 1 end
        local trinketWorn = 0
        if equippedSlots["Trinket1"] then trinketWorn = trinketWorn + 1 end
        if equippedSlots["Trinket2"] then trinketWorn = trinketWorn + 1 end

        for bSlot, _ in pairs(bagPieces[setName]) do
            if bSlot == "Ring" then
                if ringWorn < 2 and (not excludeSlot or (excludeSlot ~= "Ring1" and excludeSlot ~= "Ring2")) then
                    ringWorn = ringWorn + 1
                    totalCount = totalCount + 1
                    bagContrib = bagContrib + 1
                end
            elseif bSlot == "Trinket" then
                if trinketWorn < 2 and (not excludeSlot or (excludeSlot ~= "Trinket1" and excludeSlot ~= "Trinket2")) then
                    trinketWorn = trinketWorn + 1
                    totalCount = totalCount + 1
                    bagContrib = bagContrib + 1
                end
            else
                if not equippedSlots[bSlot] and (not excludeSlot or bSlot ~= excludeSlot) then
                    equippedSlots[bSlot] = true
                    totalCount = totalCount + 1
                    bagContrib = bagContrib + 1
                end
            end
        end
    end

    return equippedCount, totalCount, bagContrib
end

-- Count how many pieces of a set are currently equipped on the player
function UA.GetEquippedSetCount(setName)
    if not setName or setName == "" then return 0 end
    local eqCount, _, _ = UA.GetSetPieceCount(setName)
    return eqCount
end

-- Calculate set bonus EP gained when moving from curCount to projectedCount (sorted breakpoints)
function UA.CalculateSetBreakpoints(setName, curCount, projectedCount)
    if not setName or not UA.SET_BONUSES or not UA.SET_BONUSES[setName] then return 0, nil end
    local totalEP = 0
    local descs = {}

    local breakpoints = {}
    for bp, _ in pairs(UA.SET_BONUSES[setName]) do
        table.insert(breakpoints, bp)
    end
    table.sort(breakpoints)

    local numBp = table.getn(breakpoints)
    for i = 1, numBp do
        local bp = breakpoints[i]
        local bData = UA.SET_BONUSES[setName][bp]
        if curCount < bp and projectedCount >= bp then
            totalEP = totalEP + (bData.ep or 0)
            if bData.desc then table.insert(descs, bData.desc) end
        end
    end

    local descStr = (table.getn(descs) > 0) and table.concat(descs, "; ") or nil
    return totalEP, descStr
end

-- Calculate set bonus EP lost when moving from curCount to projectedCount (sorted breakpoints)
function UA.CalculateSetLoss(setName, curCount, projectedCount)
    if not setName or not UA.SET_BONUSES or not UA.SET_BONUSES[setName] then return 0, nil end
    local totalEP = 0
    local descs = {}

    local breakpoints = {}
    for bp, _ in pairs(UA.SET_BONUSES[setName]) do
        table.insert(breakpoints, bp)
    end
    table.sort(breakpoints)

    local numBp = table.getn(breakpoints)
    for i = 1, numBp do
        local bp = breakpoints[i]
        local bData = UA.SET_BONUSES[setName][bp]
        if curCount >= bp and projectedCount < bp then
            totalEP = totalEP + (bData.ep or 0)
            if bData.desc then table.insert(descs, bData.desc) end
        end
    end

    local descStr = (table.getn(descs) > 0) and table.concat(descs, "; ") or nil
    return totalEP, descStr
end

-- Get active set bonus EP and descriptions for an equipped piece
function UA.GetActiveSetBonusForPiece(setName, equippedCount)
    if not setName or not UA.SET_BONUSES or not UA.SET_BONUSES[setName] then return 0, nil end
    local totalEP = 0
    local descs = {}

    local breakpoints = {}
    for bp, _ in pairs(UA.SET_BONUSES[setName]) do
        table.insert(breakpoints, bp)
    end
    table.sort(breakpoints)

    local numBp = table.getn(breakpoints)
    for i = 1, numBp do
        local bp = breakpoints[i]
        local bData = UA.SET_BONUSES[setName][bp]
        if equippedCount >= bp then
            totalEP = totalEP + (bData.ep or 0)
            if bData.desc then table.insert(descs, bData.desc) end
        end
    end

    local descStr = (table.getn(descs) > 0) and table.concat(descs, "; ") or nil
    return totalEP, descStr
end

-- ================================================
-- UPGRADE COMPARISON ENGINE
-- ================================================

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
    if not isEquipped and itemData.rewardID then
        isEquipped = UA.IsItemEquipped(itemData.rewardID, slot)
    end
    local newScore = UA.GetItemScore(itemData)
    local isEquipable = UA.IsItemEquipableByPriest(itemData, itemID, itemLink)

    local result = {
        itemData = itemData,
        newItemName = itemData.name,
        slot = slot,
        newScore = newScore,
        currentScore = 0,
        effectiveScore = 0,
        itemDelta = 0,
        delta = 0,
        pct = nil,
        isUpgrade = false,
        isEquipped = isEquipped,
        isEquipable = isEquipable,
        replaceSlot = slot,
        currentItemName = nil,
        drop = itemData.drop,
        note = itemData.note,
        setBonusEP = 0,
        setBonusDesc = nil,
        fromBags = false,
        lostSetBonusEP = 0,
        lostSetBonusDesc = nil,
        netSetDelta = 0,
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
            result.reason = L["CLASS_RESTRICTION"]
        elseif itemData.subType and itemData.subType ~= "" then
            result.reason = format(L["CANNOT_EQUIP_SUBTYPE"], itemData.subType)
        else
            result.reason = L["CANNOT_EQUIP_GENERAL"]
        end
        return result
    end

    -- --------------------------------------------
    -- ROLE MISMATCH CHECK (Curated non-healer gear)
    -- --------------------------------------------
    if itemData.role and itemData.role ~= "HEAL" then
        result.roleMismatch = true
        result.isUpgrade = false
        if slot == "Trinket" then
            result.reason = format(L["NON_HEALER_TRINKET"], itemData.role)
        else
            result.reason = format(L["NON_HEALER_ITEM"] or "Non-healer item (%s)", itemData.role)
        end
        return result
    end

    -- --------------------------------------------
    -- ALREADY EQUIPPED
    -- --------------------------------------------
    if isEquipped then
        local activeSetEP, activeSetDesc = 0, nil
        if itemData.setName then
            local count = UA.GetEquippedSetCount(itemData.setName)
            activeSetEP, activeSetDesc = UA.GetActiveSetBonusForPiece(itemData.setName, count)
        end

        result.isUpgrade = false
        result.currentScore = newScore
        result.effectiveScore = newScore + activeSetEP
        result.setBonusEP = activeSetEP
        result.setBonusDesc = activeSetDesc
        result.currentItemName = itemData.name
        result.delta = 0
        result.reason = format(L["CURRENTLY_EQUIPPED_REASON"], newScore)
        return result
    end

    -- --------------------------------------------
    -- TRINKETS: Role check + Min-Score replacement
    -- --------------------------------------------
    if slot == "Trinket" then
        if itemData.role and itemData.role ~= "HEAL" then
            result.roleMismatch = true
            result.isUpgrade = false
            result.reason = format(L["NON_HEALER_TRINKET"], itemData.role)
            return result
        end

        local t1 = UA.GetEquippedItemData("Trinket1")
        local t2 = UA.GetEquippedItemData("Trinket2")
        local score1 = UA.GetItemScore(t1)
        local score2 = UA.GetItemScore(t2)

        local minScore = math.min(score1, score2)
        local replaceSlot = (score1 <= score2) and "Trinket1" or "Trinket2"
        local targetItem = (score1 <= score2) and t1 or t2

        local itemDelta = newScore - minScore
        result.replaceSlot = replaceSlot
        result.currentScore = minScore
        result.currentItemName = targetItem and targetItem.name or replaceSlot
        result.itemDelta = itemDelta
        result.delta = itemDelta
        if minScore > 0 then
            result.pct = ((newScore - minScore) / minScore) * 100
        end

        if itemDelta > 0 then
            result.isUpgrade = true
            result.reason = format(L["TRINKET_UPGRADE"], replaceSlot, itemDelta, minScore, newScore)
        else
            result.isUpgrade = false
            result.reason = format(L["TRINKET_DOWNGRADE"], replaceSlot, newScore, minScore)
        end
        return result
    end

    -- --------------------------------------------
    -- RINGS: Dual-slot Set-Aware Net Delta Replacement
    -- --------------------------------------------
    if slot == "Ring" then
        local r1 = UA.GetEquippedItemData("Ring1")
        local r2 = UA.GetEquippedItemData("Ring2")
        local score1 = UA.GetItemScore(r1)
        local score2 = UA.GetItemScore(r2)

        -- Evaluate Option 1: Replace Ring1
        local setGain1, setDesc1, fromBags1 = 0, nil, false
        if itemData.setName then
            local eqCount, totalCount, bagCount = UA.GetSetPieceCount(itemData.setName, "Ring1")
            local curCount = totalCount
            local projectedCount = curCount + 1
            setGain1, setDesc1 = UA.CalculateSetBreakpoints(itemData.setName, curCount, projectedCount)
            if setGain1 > 0 and bagCount > 0 and eqCount < curCount then fromBags1 = true end
        end
        local setLoss1, setLossDesc1 = 0, nil
        if r1 and r1.setName and (not itemData.setName or itemData.setName ~= r1.setName) then
            local curCount = UA.GetEquippedSetCount(r1.setName)
            setLoss1, setLossDesc1 = UA.CalculateSetLoss(r1.setName, curCount, curCount - 1)
        end
        local itemDelta1 = newScore - score1
        local netDelta1 = itemDelta1 + setGain1 - setLoss1

        -- Evaluate Option 2: Replace Ring2
        local setGain2, setDesc2, fromBags2 = 0, nil, false
        if itemData.setName then
            local eqCount, totalCount, bagCount = UA.GetSetPieceCount(itemData.setName, "Ring2")
            local curCount = totalCount
            local projectedCount = curCount + 1
            setGain2, setDesc2 = UA.CalculateSetBreakpoints(itemData.setName, curCount, projectedCount)
            if setGain2 > 0 and bagCount > 0 and eqCount < curCount then fromBags2 = true end
        end
        local setLoss2, setLossDesc2 = 0, nil
        if r2 and r2.setName and (not itemData.setName or itemData.setName ~= r2.setName) then
            local curCount = UA.GetEquippedSetCount(r2.setName)
            setLoss2, setLossDesc2 = UA.CalculateSetLoss(r2.setName, curCount, curCount - 1)
        end
        local itemDelta2 = newScore - score2
        local netDelta2 = itemDelta2 + setGain2 - setLoss2

        -- Choose the replacement that yields the greatest net character gain
        local pickSlot = nil
        local targetItem = nil
        local targetScore = 0
        local bestNetDelta = 0
        local bestItemDelta = 0
        local bestSetGain = 0
        local bestSetDesc = nil
        local bestSetLoss = 0
        local bestSetLossDesc = nil
        local bestFromBags = false

        if netDelta1 > netDelta2 or (netDelta1 == netDelta2 and score1 <= score2) then
            pickSlot = "Ring1"
            targetItem = r1
            targetScore = score1
            bestNetDelta = netDelta1
            bestItemDelta = itemDelta1
            bestSetGain = setGain1
            bestSetDesc = setDesc1
            bestSetLoss = setLoss1
            bestSetLossDesc = setLossDesc1
            bestFromBags = fromBags1
        else
            pickSlot = "Ring2"
            targetItem = r2
            targetScore = score2
            bestNetDelta = netDelta2
            bestItemDelta = itemDelta2
            bestSetGain = setGain2
            bestSetDesc = setDesc2
            bestSetLoss = setLoss2
            bestSetLossDesc = setLossDesc2
            bestFromBags = fromBags2
        end

        local effectiveCurrentScore = targetScore + bestSetLoss
        result.replaceSlot = pickSlot
        result.currentScore = targetScore
        result.effectiveScore = effectiveCurrentScore
        result.currentItemName = targetItem and targetItem.name or pickSlot
        result.itemDelta = bestItemDelta
        result.setBonusEP = bestSetGain
        result.setBonusDesc = bestSetDesc
        result.fromBags = bestFromBags
        result.lostSetBonusEP = bestSetLoss
        result.lostSetBonusDesc = bestSetLossDesc
        result.netSetDelta = bestSetGain - bestSetLoss
        result.delta = bestNetDelta
        if effectiveCurrentScore > 0 then
            result.pct = (bestNetDelta / effectiveCurrentScore) * 100
        end

        if bestNetDelta > 0 then
            result.isUpgrade = true
            result.reason = format(L["RING_UPGRADE"], pickSlot, bestNetDelta, targetScore, newScore)
        else
            result.isUpgrade = false
            result.reason = format(L["RING_DOWNGRADE"], pickSlot, newScore, targetScore)
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

        -- Set gain for 2H
        local setGain, setDesc, fromBags = 0, nil, false
        if itemData.setName then
            local eqCount, totalCount, bagCount = UA.GetSetPieceCount(itemData.setName, "Mainhand")
            local curCount = totalCount
            local projectedCount = curCount + 1
            setGain, setDesc = UA.CalculateSetBreakpoints(itemData.setName, curCount, projectedCount)
            if setGain > 0 and bagCount > 0 and eqCount < curCount then fromBags = true end
        end

        -- Set loss from removing Mainhand or Offhand
        local totalSetLoss = 0
        local lostDescs = {}
        if mh and mh.setName and (not itemData.setName or itemData.setName ~= mh.setName) then
            local curCount = UA.GetEquippedSetCount(mh.setName)
            local loss, lDesc = UA.CalculateSetLoss(mh.setName, curCount, curCount - 1)
            totalSetLoss = totalSetLoss + loss
            if lDesc then table.insert(lostDescs, lDesc) end
        end
        if oh and oh.setName and (not itemData.setName or itemData.setName ~= oh.setName) then
            local curCount = UA.GetEquippedSetCount(oh.setName)
            local loss, lDesc = UA.CalculateSetLoss(oh.setName, curCount, curCount - 1)
            totalSetLoss = totalSetLoss + loss
            if lDesc then table.insert(lostDescs, lDesc) end
        end

        local itemDelta = newScore - currentSetScore
        local netSetDelta = setGain - totalSetLoss
        local netDelta = itemDelta + netSetDelta
        local effectiveCurrentScore = currentSetScore + totalSetLoss

        result.replaceSlot = "2H (MH+OH)"
        result.currentScore = currentSetScore
        result.effectiveScore = effectiveCurrentScore
        local mhName = mh and mh.name or "Mainhand"
        local ohName = oh and oh.name or "Offhand"
        result.currentItemName = mhName .. " + " .. ohName
        result.itemDelta = itemDelta
        result.setBonusEP = setGain
        result.setBonusDesc = setDesc
        result.fromBags = fromBags
        result.lostSetBonusEP = totalSetLoss
        result.lostSetBonusDesc = (table.getn(lostDescs) > 0) and table.concat(lostDescs, "; ") or nil
        result.netSetDelta = netSetDelta
        result.delta = netDelta
        if effectiveCurrentScore > 0 then
            result.pct = (netDelta / effectiveCurrentScore) * 100
        end

        if netDelta > 0 then
            result.isUpgrade = true
            result.reason = format(L["TWOHAND_UPGRADE"], netDelta, newScore, currentSetScore)
        else
            result.isUpgrade = false
            result.reason = format(L["TWOHAND_DOWNGRADE"], newScore, currentSetScore)
        end
        return result
    end

    if slot == "Mainhand" then
        local currentMH = UA.GetEquippedItemData("Mainhand")
        local setGain, setDesc, fromBags = 0, nil, false
        if itemData.setName then
            local eqCount, totalCount, bagCount = UA.GetSetPieceCount(itemData.setName, "Mainhand")
            local curCount = totalCount
            local projectedCount = curCount + 1
            setGain, setDesc = UA.CalculateSetBreakpoints(itemData.setName, curCount, projectedCount)
            if setGain > 0 and bagCount > 0 and eqCount < curCount then fromBags = true end
        end

        local setLoss, setLossDesc = 0, nil
        if currentMH and currentMH.setName and (not itemData.setName or itemData.setName ~= currentMH.setName) then
            local curCount = UA.GetEquippedSetCount(currentMH.setName)
            setLoss, setLossDesc = UA.CalculateSetLoss(currentMH.setName, curCount, curCount - 1)
        end
        local netSetDelta = setGain - setLoss

        if currentMH and (currentMH.slot == "Twohand" or currentMH.slot == "Staff") then
            -- Currently wielding a 2H staff; compare New MH + Best Available OH vs Current 2H
            local current2HScore = UA.GetItemScore(currentMH)
            local bestOH = UA.GetBestAvailableOffhand()
            local ohScore = bestOH and bestOH.score or 0
            local projectedScore = newScore + ohScore
            local itemDelta = projectedScore - current2HScore
            local netDelta = itemDelta + netSetDelta
            local effectiveCurrentScore = current2HScore + setLoss

            result.replaceSlot = "Mainhand"
            result.currentScore = current2HScore
            result.effectiveScore = effectiveCurrentScore
            result.currentItemName = currentMH.name or "2H Staff"
            result.projectedOH = bestOH
            result.itemDelta = itemDelta
            result.setBonusEP = setGain
            result.setBonusDesc = setDesc
            result.fromBags = fromBags
            result.lostSetBonusEP = setLoss
            result.lostSetBonusDesc = setLossDesc
            result.netSetDelta = netSetDelta
            result.delta = netDelta
            if effectiveCurrentScore > 0 then
                result.pct = (netDelta / effectiveCurrentScore) * 100
            end

            if netDelta > 0 then
                result.isUpgrade = true
                result.reason = format(L["MAINHAND_2H_UPGRADE"], netDelta, projectedScore, current2HScore)
            else
                result.isUpgrade = false
                result.reason = format(L["MAINHAND_2H_DOWNGRADE"], projectedScore, current2HScore)
            end
            return result
        else
            local currentScore = UA.GetItemScore(currentMH)
            local itemDelta = newScore - currentScore
            local netDelta = itemDelta + netSetDelta
            local effectiveCurrentScore = currentScore + setLoss

            result.replaceSlot = "Mainhand"
            result.currentScore = currentScore
            result.effectiveScore = effectiveCurrentScore
            result.currentItemName = currentMH and currentMH.name or "Mainhand"
            result.itemDelta = itemDelta
            result.setBonusEP = setGain
            result.setBonusDesc = setDesc
            result.fromBags = fromBags
            result.lostSetBonusEP = setLoss
            result.lostSetBonusDesc = setLossDesc
            result.netSetDelta = netSetDelta
            result.delta = netDelta
            if effectiveCurrentScore > 0 then
                result.pct = (netDelta / effectiveCurrentScore) * 100
            end

            if netDelta > 0 then
                result.isUpgrade = true
                result.reason = format(L["MAINHAND_UPGRADE"], netDelta, currentScore, newScore)
            else
                result.isUpgrade = false
                result.reason = format(L["MAINHAND_DOWNGRADE"], newScore, currentScore)
            end
            return result
        end
    end

    if slot == "Offhand" then
        local currentOH = UA.GetEquippedItemData("Offhand")
        local currentScore = UA.GetItemScore(currentOH)

        local setGain, setDesc, fromBags = 0, nil, false
        if itemData.setName then
            local eqCount, totalCount, bagCount = UA.GetSetPieceCount(itemData.setName, "Offhand")
            local curCount = totalCount
            local projectedCount = curCount + 1
            setGain, setDesc = UA.CalculateSetBreakpoints(itemData.setName, curCount, projectedCount)
            if setGain > 0 and bagCount > 0 and eqCount < curCount then fromBags = true end
        end

        local setLoss, setLossDesc = 0, nil
        if currentOH and currentOH.setName and (not itemData.setName or itemData.setName ~= currentOH.setName) then
            local curCount = UA.GetEquippedSetCount(currentOH.setName)
            setLoss, setLossDesc = UA.CalculateSetLoss(currentOH.setName, curCount, curCount - 1)
        end

        local itemDelta = newScore - currentScore
        local netSetDelta = setGain - setLoss
        local netDelta = itemDelta + netSetDelta
        local effectiveCurrentScore = currentScore + setLoss

        result.replaceSlot = "Offhand"
        result.currentScore = currentScore
        result.effectiveScore = effectiveCurrentScore
        result.currentItemName = currentOH and currentOH.name or "Offhand"
        result.itemDelta = itemDelta
        result.setBonusEP = setGain
        result.setBonusDesc = setDesc
        result.fromBags = fromBags
        result.lostSetBonusEP = setLoss
        result.lostSetBonusDesc = setLossDesc
        result.netSetDelta = netSetDelta
        result.delta = netDelta
        if effectiveCurrentScore > 0 then
            result.pct = (netDelta / effectiveCurrentScore) * 100
        end

        if netDelta > 0 then
            result.isUpgrade = true
            result.reason = format(L["OFFHAND_UPGRADE"], netDelta, currentScore, newScore)
        else
            result.isUpgrade = false
            result.reason = format(L["OFFHAND_DOWNGRADE"], newScore, currentScore)
        end
        return result
    end

    -- --------------------------------------------
    -- STANDARD SINGLE SLOTS
    -- --------------------------------------------
    local currentItem = UA.GetEquippedItemData(slot)
    local currentScore = currentItem and UA.GetItemScore(currentItem) or 0
    local isSlotEmpty = (currentItem == nil)

    -- Set calculations for replacing currentItem in slot
    local setBonusEP = 0
    local setBonusDesc = nil
    local fromBags = false
    if itemData.setName then
        local eqCount, totalCount, bagCount = UA.GetSetPieceCount(itemData.setName, slot)
        local curCount = totalCount
        local projectedCount = curCount + 1
        setBonusEP, setBonusDesc = UA.CalculateSetBreakpoints(itemData.setName, curCount, projectedCount)
        if setBonusEP > 0 and bagCount > 0 and eqCount < curCount then
            fromBags = true
        end
    end

    local lostSetBonusEP = 0
    local lostSetBonusDesc = nil
    if currentItem and currentItem.setName and (not itemData.setName or itemData.setName ~= currentItem.setName) then
        local curCount = UA.GetEquippedSetCount(currentItem.setName)
        local projectedCount = curCount - 1
        lostSetBonusEP, lostSetBonusDesc = UA.CalculateSetLoss(currentItem.setName, curCount, projectedCount)
    end

    local itemDelta = newScore - currentScore
    local netSetDelta = setBonusEP - lostSetBonusEP
    local netDelta = itemDelta + netSetDelta
    local effectiveCurrentScore = currentScore + lostSetBonusEP

    result.replaceSlot = slot
    result.currentScore = currentScore
    result.effectiveScore = effectiveCurrentScore
    result.currentItemName = isSlotEmpty and L["EMPTY_SLOT"] or (currentItem.name or slot)
    result.itemDelta = itemDelta
    result.setBonusEP = setBonusEP
    result.setBonusDesc = setBonusDesc
    result.fromBags = fromBags
    result.lostSetBonusEP = lostSetBonusEP
    result.lostSetBonusDesc = lostSetBonusDesc
    result.netSetDelta = netSetDelta
    result.delta = netDelta
    if effectiveCurrentScore > 0 then
        result.pct = (netDelta / effectiveCurrentScore) * 100
    end

    if isSlotEmpty then
        result.isUpgrade = (netDelta > 0)
        result.reason = format(L["EMPTY_SLOT_UPGRADE"], slot, netDelta)
        return result
    end

    if netDelta > 0 then
        result.isUpgrade = true
        result.reason = format(L["SCORE_UPGRADE"], effectiveCurrentScore, newScore + setBonusEP, netDelta)
    else
        result.isUpgrade = false
        result.reason = format(L["SCORE_DOWNGRADE"], newScore + setBonusEP, effectiveCurrentScore)
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
    table.insert(lines, format("%s %s  |  %s %d EP", L["CHAT_SLOT"], data.slot or "Unknown", L["CHAT_SCORE"], UA.GetItemScore(data)))

    local stats = UA.FormatStatBreakdown(data)
    if stats and stats ~= "" then
        table.insert(lines, stats)
    end

    if data.drop then table.insert(lines, format(L["TOOLTIP_SOURCE"] .. " %s", data.drop)) end
    if data.note then table.insert(lines, format("|cffffd100%s|r", data.note)) end

    return table.concat(lines, "\n")
end
