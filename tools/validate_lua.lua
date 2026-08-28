#!/usr/bin/env lua
--[[
Lua syntax validator for PriestBiS (Vanilla 1.12.1 / Turtle WoW)
Validates all TOC files and standalone Lua syntax.
]]--

local function noop() end

local function make_stub()
    local stub = {}
    local mt = {
        __index = function(self, key)
            return function(...) return make_stub() end
        end,
        __newindex = function(self, key, value)
            rawset(self, key, value)
        end,
    }
    setmetatable(stub, mt)
    return stub
end

_G.CreateFrame = function(...) return make_stub() end
_G.GetItemInfo = function() return nil, nil, nil, nil end
_G.GetSpellInfo = function() return "Unknown" end
_G.GetUnitName = function() return "Unknown" end
_G.GetLocale = function() return "enUS" end
_G.GetCVar = function() return 0 end
_G.SetCVar = noop
_G.pairs = pairs
_G.tonumber = tonumber
_G.tostring = tostring
_G.type = type
_G.select = select
_G.unpack = unpack or table.unpack
_G.getmetatable = getmetatable
_G.setmetatable = setmetatable
_G.ipairs = ipairs
_G.next = next

_G.Enum = {}
_G.C_ChatInfo = { SendAddonMessage = noop }
_G.C_UnitAuras = {}
_G.C_AddOns = {}
_G.SlashCmdList = setmetatable({}, { __index = function() return noop end, __newindex = noop })

_G.UIParent = make_stub()
_G.GameTooltip = make_stub()
_G.GameTooltipTextLeft1 = make_stub()
_G.GameTooltipTextRight1 = make_stub()
_G.GameTooltipTextLeft2 = make_stub()
_G.GameTooltipTextRight2 = make_stub()
_G.GameTooltipTextLeft3 = make_stub()
_G.GameTooltipTextRight3 = make_stub()
_G.NormalFont = make_stub()
_G.Highlight = make_stub()
_G.PurpleFont = make_stub()

local files = {
    "Locales/Localization.lua",
    "Locales/Localization.enUS.lua",
    "Locales/Localization.zhCN.lua",
    "Locales/Localization.ruRU.lua",
    "Locales/Localization.deDE.lua",
    "Locales/Localization.frFR.lua",
    "PriestBiS.lua"
}

if arg and arg[1] then
    files = { arg[1] }
end

for _, filepath in ipairs(files) do
    local success, err = pcall(dofile, filepath)
    if success then
        print("SYNTAX OK: " .. filepath .. " loaded successfully")
    else
        print("SYNTAX ERROR in " .. filepath .. ": " .. tostring(err))
        os.exit(1)
    end
end
