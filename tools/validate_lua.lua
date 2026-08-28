#!/usr/bin/env lua
--[[
Lua syntax validator for PriestBiS.lua
Uses standalone Lua 5.1 to check syntax without requiring WoW API.
]]--

local function noop() end

-- Create a universal stub table that returns noop for any method call
local function make_stub()
    local stub = {}
    local mt = {
        __index = function(self, key)
            local func = function(...)
                -- Return another stub for method chaining
                return make_stub()
            end
            return func
        end,
        __newindex = function(self, key, value)
            -- Actually store the value so field access works after assignment
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

-- Load the addon file
local filepath = arg and arg[1] or "PriestBiS.lua"
local success, err = pcall(dofile, filepath)
if success then
    print("SYNTAX OK: " .. filepath .. " loaded successfully")
else
    print("SYNTAX ERROR: " .. tostring(err))
    os.exit(1)
end
