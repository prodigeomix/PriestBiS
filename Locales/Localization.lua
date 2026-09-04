-- Locales/Localization.lua
-- Core localization engine & fallback table for PriestBiS (Vanilla 1.12.1 / Turtle WoW)
-- Strict Lua 5.0 Compliance

local _G = _G or getfenv(0)
_G._G = _G
PriestBiS = PriestBiS or {}
local UA = PriestBiS

PriestBiS.Locales = PriestBiS.Locales or {}
PriestBiS.Patterns = PriestBiS.Patterns or {}

local clientLocale = (GetLocale and GetLocale()) or "enUS"
if clientLocale == "enGB" then clientLocale = "enUS" end
PriestBiS.clientLocale = clientLocale

-- Create the translation proxy table L
local L = {}
PriestBiS.L = L

setmetatable(L, {
    __index = function(t, key)
        local loc = PriestBiS.Locales[PriestBiS.clientLocale]
        if loc and loc[key] ~= nil then
            return loc[key]
        end
        local fallback = PriestBiS.Locales["enUS"]
        if fallback and fallback[key] ~= nil then
            return fallback[key]
        end
        return key
    end
})

-- Helper to register locale strings
function PriestBiS:RegisterLocale(localeName, tbl)
    if not PriestBiS.Locales[localeName] then
        PriestBiS.Locales[localeName] = {}
    end
    for k, v in pairs(tbl) do
        PriestBiS.Locales[localeName][k] = v
    end
end

-- Helper to register localized scanner patterns
function PriestBiS:RegisterPatterns(localeName, tbl)
    if not PriestBiS.Patterns[localeName] then
        PriestBiS.Patterns[localeName] = {}
    end
    for k, v in pairs(tbl) do
        PriestBiS.Patterns[localeName][k] = v
    end
end
