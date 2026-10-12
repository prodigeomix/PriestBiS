-- ==============================================================================
-- World of Warcraft 1.12.1 FrameXML & C-API Mock Stub for Lua 5.0.3 Test Harness
-- ==============================================================================

local _G = getfenv(0)

-- Time & Environment
_G.GetTime = function() return _G.MOCK_TIME or 100.0 end
_G.MOCK_TIME = 100.0

-- Client Version & Locale
_G.GetBuildInfo = function() return "1.12.1", "5875", "Jul 14 2006" end
_G.GetLocale = function() return "enUS" end

_G.getglobal = function(name) return _G[name] end
_G.setglobal = function(name, val) _G[name] = val end

-- Chat Frames & Output
_G.DEFAULT_CHAT_FRAME = {
    AddMessage = function(self, msg) end
}
_G.UIErrorsFrame = {
    AddMessage = function(self, msg, r, g, b, a, id) end
}
_G.PlaySound = function(sound) end

-- Slash Commands
_G.SlashCmdList = {}

-- FrameXML Frame Factory Mock
_G.CreateFrame = function(frameType, name, parent, inherits)
    local frame = {
        name = name,
        frameType = frameType,
        parent = parent,
        shown = true,
        scripts = {},
        points = {},
        Show = function(self) self.shown = true end,
        Hide = function(self) self.shown = false end,
        IsShown = function(self) return self.shown end,
        IsVisible = function(self) return self.shown end,
        SetPoint = function(self, point, relTo, relPoint, x, y) end,
        ClearAllPoints = function(self) end,
        SetWidth = function(self, w) self.width = w end,
        SetHeight = function(self, h) self.height = h end,
        GetWidth = function(self) return self.width or 0 end,
        GetHeight = function(self) return self.height or 0 end,
        SetScale = function(self, s) self.scale = s end,
        GetScale = function(self) return self.scale or 1 end,
        SetAlpha = function(self, a) self.alpha = a end,
        GetAlpha = function(self) return self.alpha or 1 end,
        SetFrameStrata = function(self, s) end,
        SetBackdrop = function(self, b) end,
        SetBackdropColor = function(self, r, g, b, a) end,
        SetBackdropBorderColor = function(self, r, g, b, a) end,
        EnableMouse = function(self, e) end,
        SetMovable = function(self, m) end,
        RegisterForDrag = function(self, ...) end,
        StartMoving = function(self) end,
        StopMovingOrSizing = function(self) end,
        RegisterEvent = function(self, ev) end,
        UnregisterEvent = function(self, ev) end,
        SetScript = function(self, handler, fn) self.scripts[handler] = fn end,
        GetScript = function(self, handler) return self.scripts[handler] end,
        CreateFontString = function(self, name, layer, inherits)
            return {
                SetFont = function(s, f, size, flags) end,
                SetPoint = function(s, ...) end,
                SetText = function(s, t) s.text = t end,
                GetText = function(s) return s.text or "" end,
                SetTextColor = function(s, r, g, b, a) end,
                SetJustifyH = function(s, j) end,
                SetJustifyV = function(s, j) end,
                Show = function(s) end,
                Hide = function(s) end,
            }
        end,
        CreateTexture = function(self, name, layer, inherits)
            return {
                SetTexture = function(s, t) s.texture = t end,
                SetAllPoints = function(s, p) end,
                SetPoint = function(s, ...) end,
                SetTexCoord = function(s, ...) end,
                SetVertexColor = function(s, r, g, b, a) end,
                SetWidth = function(s, w) s.width = w end,
                SetHeight = function(s, h) s.height = h end,
                Show = function(s) end,
                Hide = function(s) end,
            }
        end,
    }
    if name then
        _G[name] = frame
    end
    return frame
end

_G.UIParent = _G.CreateFrame("Frame", "UIParent")
_G.Minimap = _G.CreateFrame("Frame", "Minimap")
_G.GameTooltip = _G.CreateFrame("Frame", "GameTooltip")
_G.GameTooltip.SetOwner = function(self, owner, anchor) end
_G.GameTooltip.SetInventoryItem = function(self, unit, slot) end
_G.GameTooltip.SetSpell = function(self, spellId, bookType) end
_G.GameTooltip.ClearLines = function(self) end
_G.GameTooltip.NumLines = function(self) return 0 end
_G.GameTooltip.GetRegions = function(self) return end

-- Dynamic Mock State
_G.MOCK_STATE = {
    units = {},
    cooldowns = {},
    instance = { inInstance = 1, instanceType = "raid" },
    raidMembers = 40,
    partyMembers = 4,
}

-- Unit Inspection & Targeting
_G.UnitExists = function(unit)
    if _G.MOCK_STATE.UnitExists then return _G.MOCK_STATE.UnitExists(unit) end
    if _G.MOCK_STATE.units[unit] and _G.MOCK_STATE.units[unit].exists ~= nil then
        return _G.MOCK_STATE.units[unit].exists
    end
    return true
end

_G.UnitName = function(unit)
    if _G.MOCK_STATE.UnitName then return _G.MOCK_STATE.UnitName(unit) end
    if _G.MOCK_STATE.units[unit] and _G.MOCK_STATE.units[unit].name then
        return _G.MOCK_STATE.units[unit].name
    end
    return unit == "player" and "Dise" or "Target"
end

_G.UnitClass = function(unit) return "Priest", "PRIEST" end

_G.UnitLevel = function(unit)
    if _G.MOCK_STATE.UnitLevel then return _G.MOCK_STATE.UnitLevel(unit) end
    if _G.MOCK_STATE.units[unit] and _G.MOCK_STATE.units[unit].level then
        return _G.MOCK_STATE.units[unit].level
    end
    return 60
end

_G.UnitClassification = function(unit)
    if _G.MOCK_STATE.UnitClassification then return _G.MOCK_STATE.UnitClassification(unit) end
    if _G.MOCK_STATE.units[unit] and _G.MOCK_STATE.units[unit].classification then
        return _G.MOCK_STATE.units[unit].classification
    end
    return "normal"
end

_G.UnitHealth = function(unit)
    if _G.MOCK_STATE.UnitHealth then return _G.MOCK_STATE.UnitHealth(unit) end
    if _G.MOCK_STATE.units[unit] and _G.MOCK_STATE.units[unit].health then
        return _G.MOCK_STATE.units[unit].health
    end
    return 4000
end

_G.UnitHealthMax = function(unit)
    if _G.MOCK_STATE.UnitHealthMax then return _G.MOCK_STATE.UnitHealthMax(unit) end
    if _G.MOCK_STATE.units[unit] and _G.MOCK_STATE.units[unit].healthMax then
        return _G.MOCK_STATE.units[unit].healthMax
    end
    return 4000
end

_G.UnitMana = function(unit) return 6500 end
_G.UnitManaMax = function(unit) return 6500 end

_G.UnitIsDead = function(unit)
    if _G.MOCK_STATE.UnitIsDead then return _G.MOCK_STATE.UnitIsDead(unit) end
    if _G.MOCK_STATE.units[unit] and _G.MOCK_STATE.units[unit].dead ~= nil then
        return _G.MOCK_STATE.units[unit].dead
    end
    return nil
end

_G.UnitIsGhost = function(unit)
    if _G.MOCK_STATE.UnitIsGhost then return _G.MOCK_STATE.UnitIsGhost(unit) end
    if _G.MOCK_STATE.units[unit] and _G.MOCK_STATE.units[unit].ghost ~= nil then
        return _G.MOCK_STATE.units[unit].ghost
    end
    return nil
end

_G.UnitIsConnected = function(unit) return 1 end
_G.UnitIsPlayer = function(unit) return 1 end

_G.UnitCanAttack = function(p, u)
    if _G.MOCK_STATE.UnitCanAttack then return _G.MOCK_STATE.UnitCanAttack(p, u) end
    if _G.MOCK_STATE.units[u] and _G.MOCK_STATE.units[u].canAttack ~= nil then
        return _G.MOCK_STATE.units[u].canAttack
    end
    return nil
end

_G.UnitCanAssist = function(p, u) return 1 end
_G.UnitIsFriend = function(p, u) return 1 end
_G.UnitIsVisible = function(u) return 1 end
_G.UnitSex = function(u) return 2 end
_G.UnitRace = function(u) return "Blood Elf" end

-- Roster & Instance Scoping
_G.IsInInstance = function()
    if _G.MOCK_STATE.IsInInstance then return _G.MOCK_STATE.IsInInstance() end
    return _G.MOCK_STATE.instance.inInstance, _G.MOCK_STATE.instance.instanceType
end

_G.GetNumRaidMembers = function()
    if _G.MOCK_STATE.GetNumRaidMembers then return _G.MOCK_STATE.GetNumRaidMembers() end
    return _G.MOCK_STATE.raidMembers or 0
end

_G.GetNumPartyMembers = function()
    if _G.MOCK_STATE.GetNumPartyMembers then return _G.MOCK_STATE.GetNumPartyMembers() end
    return _G.MOCK_STATE.partyMembers or 0
end

-- Spell & Cast API
_G.SpellStopCasting = function() end
_G.CastSpellByName = function(name, target) end
_G.TargetUnit = function(unit) end
_G.ClearTarget = function() end
_G.GetSpellName = function(id, book) return "Flash Heal", "Rank 7" end
_G.GetSpellCooldown = function(id, book)
    if _G.MOCK_STATE.GetSpellCooldown then return _G.MOCK_STATE.GetSpellCooldown(id, book) end
    if _G.MOCK_STATE.cooldowns[id] then
        local cd = _G.MOCK_STATE.cooldowns[id]
        return cd[1], cd[2]
    end
    return 0, 0
end
_G.GetSpellTexture = function(id, book) return "Interface\\Icons\\Spell_Holy_FlashHeal" end
_G.GetInventoryItemCooldown = function(unit, slot) return 0, 0, 1 end
_G.UseInventoryItem = function(slot) end

-- Global Event Args (FrameXML standard in Lua 5.0)
_G.event = ""
_G.arg1 = nil
_G.arg2 = nil
_G.arg3 = nil
_G.arg4 = nil
_G.arg5 = nil
_G.arg6 = nil
_G.arg7 = nil
_G.arg8 = nil
_G.arg9 = nil
