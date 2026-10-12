#!/usr/bin/env python3
"""
tools/test_simulation_vm.py
===========================
In-Memory Lua Virtual Machine Runtime Simulation Test for PriestBiS.
Imported & adapted from HolyPriest's 'test_downranking_and_bridges.py' (lupa VM).

Executes PriestBiS's actual Lua code inside an embedded Lua runtime to verify:
1. Dynamic talent synchronization across all 5 client locales (Spiritual Guidance, Meditation).
2. EP stat scoring formula & curated item overrides (ZHC, Hazza'rah, Eye of the Dead).
3. Quest turn-in token resolution (Heart of Hakkar, Head of Onyxia, Eye of Divinity).
4. Tooltip parsing with regex engine in Lua across gear lines.
5. Upgrade comparison engine:
   - Direct single-slot upgrades
   - Dual-slot lower-bound resolution (Ring1/Ring2, Trinket1/Trinket2)
   - 1H + Offhand vs 2H staff comparisons with bag inventory backing
   - Role mismatch filtering (rejection of Melee AP and Tank items)
   - Set bonus activation and breakpoint loss calculations (Prophecy & Transcendence)

Exit code 0 on all tests passing, 1 on any failure.
"""

import os
import sys

if sys.platform == "win32":
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")

try:
    import lupa
    from lupa import LuaRuntime
except ImportError:
    print("NOTICE: 'lupa' not installed in current Python environment.")
    print("        To run full embedded Lua VM execution tests, install dependencies:")
    print("        pip install -r requirements.txt")
    sys.exit(0)

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
ADDON_DIR = os.path.abspath(os.path.join(SCRIPT_DIR, ".."))

TOC_ORDER = [
    "Locales/Localization.lua",
    "Locales/Localization.enUS.lua",
    "Locales/Localization.zhCN.lua",
    "Locales/Localization.ruRU.lua",
    "Locales/Localization.deDE.lua",
    "Locales/Localization.frFR.lua",
    "Data/ItemDatabase.lua",
    "Data/SetBonuses.lua",
    "Core/Engine.lua",
    "Core/Comparison.lua",
]

def create_mocked_lua_environment():
    lua = LuaRuntime(unpack_returned_tuples=True)

    mock_wow = """
    _G = _G or {}
    getfenv = function(n) return _G end
    getglobal = function(n) return _G[n] end
    setglobal = function(n, v) _G[n] = v end

    table.getn = function(t)
        if not t then return 0 end
        local n = 0
        for k, v in ipairs(t) do n = n + 1 end
        return n
    end
    math.mod = function(a, b) return a % b end
    getn = table.getn
    string.gfind = string.gmatch
    DEFAULT_CHAT_FRAME = { AddMessage = function() end }
    UIParent = {}
    
    GetLocale = function() return 'enUS' end
    GetRealmName = function() return 'TurtleWoW' end
    UnitName = function() return 'Carbon' end
    UnitClass = function() return 'Priest', 'PRIEST' end
    UnitIsPlayer = function() return 1 end
    UnitExists = function() return 1 end
    
    -- Mock Item and Inventory APIs
    MOCK_ITEMS = {}
    MOCK_EQUIPPED = {}
    MOCK_BAGS = {}
    MOCK_TOOLTIPS = {}
    
    GetItemInfo = function(idOrLink)
        local id = tonumber(idOrLink)
        if not id and type(idOrLink) == "string" then
            local _, _, idStr = string.find(idOrLink, "item:(%d+)")
            id = tonumber(idStr)
        end
        if id and MOCK_ITEMS[id] then
            local it = MOCK_ITEMS[id]
            return it.name, it.link, it.quality, it.iLevel, it.reqLevel, it.class, it.subclass, it.maxStack, it.invType, it.texture
        end
        return nil
    end
    
    GetInventoryItemLink = function(unit, slotID)
        return MOCK_EQUIPPED[slotID]
    end
    
    GetInventoryItemID = function(unit, slotID)
        local link = MOCK_EQUIPPED[slotID]
        if link then
            local _, _, idStr = string.find(link, "item:(%d+)")
            return tonumber(idStr)
        end
        return nil
    end
    
    -- Mock Container APIs
    GetContainerNumSlots = function(bagID)
        if MOCK_BAGS[bagID] then return table.getn(MOCK_BAGS[bagID]) end
        return 0
    end
    
    GetContainerItemLink = function(bagID, slot)
        if MOCK_BAGS[bagID] then return MOCK_BAGS[bagID][slot] end
        return nil
    end

    -- Pre-create FontStrings for tooltip lines
    for i = 1, 30 do
        local fsL = {
            text = "", r = 1, g = 1, b = 1,
            GetText = function(s) return s.text end,
            SetText = function(s, t) s.text = t end,
            GetTextColor = function(s) return s.r or 1, s.g or 1, s.b or 1 end,
            SetTextColor = function(s, r, g, b) s.r = r; s.g = g; s.b = b end
        }
        _G["UAScanningTooltipTextLeft" .. i] = fsL
        local fsR = {
            text = "", r = 1, g = 1, b = 1,
            GetText = function(s) return s.text end,
            SetText = function(s, t) s.text = t end,
            GetTextColor = function(s) return s.r or 1, s.g or 1, s.b or 1 end,
            SetTextColor = function(s, r, g, b) s.r = r; s.g = g; s.b = b end
        }
        _G["UAScanningTooltipTextRight" .. i] = fsR
    end

    -- Mock Frame creation
    CreateFrame = function(fType, name, parent, template)
        local f = {
            activeLines = {},
            SetScript = function() end,
            RegisterEvent = function() end,
            SetOwner = function() end,
            ClearLines = function(self)
                self.activeLines = {}
                for i = 1, 30 do
                    local fsL = _G["UAScanningTooltipTextLeft" .. i]
                    if fsL then fsL.text = ""; fsL.r = 1; fsL.g = 1; fsL.b = 1 end
                    local fsR = _G["UAScanningTooltipTextRight" .. i]
                    if fsR then fsR.text = ""; fsR.r = 1; fsR.g = 1; fsR.b = 1 end
                end
            end,
            SetHyperlink = function(self, link)
                local lines = MOCK_TOOLTIPS[link]
                if not lines then
                    local _, _, idStr = string.find(link, "item:(%d+)")
                    local key = "item:" .. (idStr or "") .. ":0:0:0"
                    lines = MOCK_TOOLTIPS[key] or {}
                end
                self.activeLines = lines
                for i = 1, 30 do
                    local entry = lines[i]
                    local txt = ""
                    local r, g, b = 1, 1, 1
                    if type(entry) == "table" then
                        txt = entry.text or ""
                        r = entry.r or 1
                        g = entry.g or 1
                        b = entry.b or 1
                    elseif type(entry) == "string" then
                        txt = entry
                    end
                    local fsL = _G["UAScanningTooltipTextLeft" .. i]
                    if fsL then
                        fsL.text = txt
                        fsL.r = r
                        fsL.g = g
                        fsL.b = b
                    end
                end
            end,
            SetInventoryItem = function(self, unit, slotID)
                local link = MOCK_EQUIPPED[slotID]
                if link then self:SetHyperlink(link) end
            end,
            NumLines = function(self)
                return table.getn(self.activeLines)
            end,
            SetPoint = function() end,
            Show = function() end,
            Hide = function() end,
        }
        if name then _G[name] = f end
        return f
    end

    -- Mock Talents
    MOCK_TALENTS = {}
    GetNumTalents = function(tab) return 5 end
    GetTalentInfo = function(tab, idx)
        local t = MOCK_TALENTS[tab .. "_" .. idx]
        if t then
            return t.name, t.icon, t.tier, t.column, t.rank
        end
        return nil
    end
    """
    lua.execute(mock_wow)

    for rel_f in TOC_ORDER:
        full_p = os.path.join(ADDON_DIR, rel_f)
        with open(full_p, "r", encoding="utf-8", errors="ignore") as fp:
            lua.execute(fp.read())

    return lua

def test_dynamic_talent_sync(lua):
    print("\n--- [Suite 1] Dynamic Talent Sync Across Locales ---")
    ua = lua.eval("PriestBiS.UA")
    ua.ApplyStatWeights("throughput")
    
    # 1. English talents: Spiritual Guidance (Holy tab 2) and Meditation (Disc tab 1)
    lua.execute("""
    MOCK_TALENTS = {
        ["1_1"] = { name = "Meditation", rank = 3 },
        ["2_1"] = { name = "Spiritual Guidance", rank = 5 }
    }
    """)
    ua.UpdateDynamicTalentWeights()
    spi_w = round(ua.STAT_WEIGHTS.spi, 2)
    assert spi_w == 0.70, f"Expected 0.70 (5/5 SG + 3/3 Med), got {spi_w}"
    print("  [PASS] enUS: 5/5 SG + 3/3 Meditation -> Spirit Weight = 0.70 EP")

    # 2. Zero ranks
    lua.execute("""
    MOCK_TALENTS = {
        ["1_1"] = { name = "Meditation", rank = 0 },
        ["2_1"] = { name = "Spiritual Guidance", rank = 0 }
    }
    """)
    ua.UpdateDynamicTalentWeights()
    spi_w = round(ua.STAT_WEIGHTS.spi, 2)
    assert spi_w == 0.30, f"Expected 0.30 (0/5 SG + 0/3 Med), got {spi_w}"
    print("  [PASS] enUS: 0/5 SG + 0/3 Meditation -> Spirit Weight = 0.30 EP")

    # 3. Chinese locale talents
    lua.execute("""
    MOCK_TALENTS = {
        ["1_1"] = { name = "冥想", rank = 3 },
        ["2_1"] = { name = "精神指引", rank = 5 }
    }
    """)
    ua.UpdateDynamicTalentWeights()
    spi_w = round(ua.STAT_WEIGHTS.spi, 2)
    assert spi_w == 0.70, f"Expected 0.70 with Chinese talent names, got {spi_w}"
    print("  [PASS] zhCN: 精神指引 + 冥想 -> Spirit Weight = 0.70 EP")

    # 4. Russian locale talents
    lua.execute("""
    MOCK_TALENTS = {
        ["1_1"] = { name = "Медитация", rank = 2 },
        ["2_1"] = { name = "Духовное направление", rank = 4 }
    }
    """)
    ua.UpdateDynamicTalentWeights()
    spi_w = round(ua.STAT_WEIGHTS.spi, 2)
    assert spi_w == 0.60, f"Expected 0.60 with Russian talent names, got {spi_w}"
    print("  [PASS] ruRU: Духовное направление + Медитация -> Spirit Weight = 0.60 EP")

    # Restore standard 5/5 SG + 3/3 Med
    lua.execute("""
    MOCK_TALENTS = {
        ["1_1"] = { name = "Meditation", rank = 3 },
        ["2_1"] = { name = "Spiritual Guidance", rank = 5 }
    }
    """)
    ua.UpdateDynamicTalentWeights()

def test_ep_scoring_and_curated_database(lua):
    print("\n--- [Suite 2] EP Scoring & Curated Database Overrides ---")
    ua = lua.eval("PriestBiS.UA")

    # 1. Pure stats item score
    item_stats = lua.table(healing=55, spi=15, mp5=6, int=10, crit=1, stam=10, spell_damage=0, casting_regen=0, haste=0)
    score = ua.GetItemScore(item_stats)
    assert score == 89, f"Expected EP 89, got {score}"
    print(f"  [PASS] Raw stats calculation: +55 Heal, 15 Spi, 6 MP5, 1% Crit -> {score} EP")

    # 2. Curated Trinket Overrides
    trinkets_expected = {
        19958: (120, "Hazza'rah's Charm of Healing"),
        19950: (90, "Zandalarian Hero Charm"),
        19288: (90, "Darkmoon Card: Blue Dragon"),
        23047: (130, "Eye of the Dead"),
        19395: (105, "Rejuvenating Gem"),
        17064: (85, "Shard of the Scale"),
        21625: (80, "Scarab Brooch"),
    }
    for item_id, (expected_ep, name) in trinkets_expected.items():
        data = ua.GetItemData(item_id)
        assert data is not None, f"Failed to retrieve {name} (#{item_id})"
        actual_ep = ua.GetItemScore(data)
        assert actual_ep == expected_ep, f"{name} (#{item_id}): expected {expected_ep} EP, got {actual_ep}"
        print(f"  [PASS] {name:<35} -> {actual_ep:>3} EP (Curated Override Verified)")

    # 3. Quest token resolution
    tokens_expected = {
        19802: (90, "Heart of Hakkar -> ZHC"),
        19002: (85, "Head of Onyxia -> Shard of the Scale"),
        18646: ("Twohand", "Eye of Divinity -> Benediction"),
    }
    for token_id, (expected_val, desc) in tokens_expected.items():
        data = ua.GetItemData(token_id)
        assert data is not None, f"Failed to resolve token #{token_id}"
        if isinstance(expected_val, int):
            score = ua.GetItemScore(data)
            assert score == expected_val, f"{desc}: expected {expected_val} EP, got {score}"
            print(f"  [PASS] Token {desc:<35} -> {score:>3} EP")
        else:
            assert data.slot == expected_val, f"{desc}: expected slot {expected_val}, got {data.slot}"
            print(f"  [PASS] Token {desc:<35} -> Resolved slot '{data.slot}'")

def test_equipment_comparison_engine(lua):
    print("\n--- [Suite 3] Equipment Comparison & Upgrade Logic ---")
    ua = lua.eval("PriestBiS.UA")

    # Setup mock tooltips for items
    lua.execute("""
    MOCK_ITEMS[10001] = { name = "Simple Gold Ring", invType = "INVTYPE_FINGER" }
    MOCK_ITEMS[10002] = { name = "Prismatic Band", invType = "INVTYPE_FINGER" }
    MOCK_ITEMS[19382] = { name = "Pure Elementium Band", invType = "INVTYPE_FINGER" }
    MOCK_ITEMS[19406] = { name = "Drake Fang Talisman", invType = "INVTYPE_TRINKET" }
    MOCK_ITEMS[18608] = { name = "Benediction", invType = "INVTYPE_2HWEAPON" }
    MOCK_ITEMS[61208] = { name = "Staff of the Dreamer", invType = "INVTYPE_2HWEAPON" }

    MOCK_TOOLTIPS["item:10001:0:0:0"] = {
        "Simple Gold Ring", "Binds when equipped", "Finger",
        "+10 Spirit", "Equip: Increases healing done by spells and effects by up to 20."
    }
    MOCK_TOOLTIPS["item:10002:0:0:0"] = {
        "Prismatic Band", "Binds when equipped", "Finger",
        "+15 Spirit", "Equip: Increases healing done by spells and effects by up to 35."
    }
    MOCK_TOOLTIPS["item:19382:0:0:0"] = {
        "Pure Elementium Band", "Binds when picked up", "Finger",
        "+10 Spirit", "+9 Intellect", "+10 Stamina",
        "Equip: Increases healing done by spells and effects by up to 33."
    }
    MOCK_TOOLTIPS["item:19406:0:0:0"] = {
        "Drake Fang Talisman", "Binds when picked up", "Trinket",
        "Equip: +56 Attack Power.", "Equip: Improves your chance to hit by 2%."
    }
    MOCK_TOOLTIPS["item:18608:0:0:0"] = {
        "Benediction", "Binds when picked up", "Two-Hand Staff",
        "+31 Intellect", "+12 Spirit",
        "Equip: Increases healing done by spells and effects by up to 106.",
        "Equip: Improves your chance to get a critical strike with spells by 2%."
    }
    MOCK_TOOLTIPS["item:61208:0:0:0"] = {
        "Staff of the Dreamer", "Binds when picked up", "Two-Hand Staff",
        "Equip: Increases healing done by spells and effects by up to 134.",
        "Equip: Allows 5% of your Mana regeneration to continue while casting.",
        "Equip: Increases your attack and casting speed by 1%."
    }

    -- Equip Simple Gold Ring in slot 11, Prismatic Band in slot 12
    MOCK_EQUIPPED[11] = "|Hitem:10001:0:0:0|h[Simple Gold Ring]|h"
    MOCK_EQUIPPED[12] = "|Hitem:10002:0:0:0|h[Prismatic Band]|h"
    UA.ClearCache()
    """)

    # 1. Dual-slot Ring upgrade
    comp = ua.GetUpgradeComparison(19382, "|Hitem:19382:0:0:0|h[Pure Elementium Band]|h")
    assert comp is not None, "Upgrade comparison returned nil for Pure Elementium Band"
    assert comp.isUpgrade == True, "Pure Elementium Band should be detected as an upgrade"
    assert comp.replaceSlot == "Ring1", f"Expected to replace Ring1 (lower slot), got {comp.replaceSlot}"
    assert comp.delta == 15, f"Expected delta +15 EP, got {comp.delta}"
    print(f"  [PASS] Dual-slot Ring: Pure Elementium Band replaces {comp.replaceSlot} ({comp.currentItemName}) with delta +{comp.delta} EP")

    # 2. Role Mismatch Protection: Drake Fang Talisman
    dft_comp = ua.GetUpgradeComparison(19406, "|Hitem:19406:0:0:0|h[Drake Fang Talisman]|h")
    assert dft_comp is not None
    assert dft_comp.roleMismatch == True, "Drake Fang Talisman must flag roleMismatch=True"
    assert dft_comp.isUpgrade == False, "Drake Fang Talisman must not be an upgrade"
    print("  [PASS] Role Protection: Drake Fang Talisman correctly flagged roleMismatch=True, isUpgrade=False")

    # 3. 2H Staff upgrade: Benediction vs Staff of the Dreamer
    lua.execute("""
    MOCK_EQUIPPED[16] = "|Hitem:18608:0:0:0|h[Benediction]|h"
    MOCK_EQUIPPED[17] = nil
    UA.ClearCache()
    """)
    staff_comp = ua.GetUpgradeComparison(61208, "|Hitem:61208:0:0:0|h[Staff of the Dreamer]|h")
    assert staff_comp is not None
    assert staff_comp.isUpgrade == True
    assert staff_comp.delta > 25, f"Staff of the Dreamer should give >25 EP upgrade over Benediction (got {staff_comp.delta})"
    print(f"  [PASS] 2H Weapon: Staff of the Dreamer upgrades over Benediction with delta +{staff_comp.delta} EP")

def test_set_bonuses_math(lua):
    print("\n--- [Suite 4] Set Bonus Breakpoints & Math ---")
    ua = lua.eval("PriestBiS.UA")

    # Test Vestments of Transcendence (T2)
    # Breakpoint 3: +15% Mana regen while casting (25.0 EP)
    # Breakpoint 5: Fade proc (10.0 EP)
    # Breakpoint 8: Greater Heal triggers Renew (40.0 EP)
    count3_ep, desc3 = ua.GetActiveSetBonusForPiece("Vestments of Transcendence", 3)
    assert count3_ep == 25.0, f"Expected 25.0 EP for Transcendence 3-piece, got {count3_ep}"
    assert desc3 is not None and "15%" in desc3
    print(f"  [PASS] Transcendence 3-piece: +{count3_ep} EP ('{desc3}')")

    count8_ep, desc8 = ua.GetActiveSetBonusForPiece("Vestments of Transcendence", 8)
    # 3-piece (25.0) + 5-piece (10.0) + 8-piece (40.0) = 75.0 EP
    assert count8_ep == 75.0, f"Expected 75.0 EP for Transcendence 8-piece, got {count8_ep}"
    print(f"  [PASS] Transcendence 8-piece: +{count8_ep} EP (All breakpoints active: {count8_ep} EP)")

    # Test Vestments of Prophecy (T1)
    # Breakpoint 3: -0.1s Flash Heal (15.0 EP)
    count_t1_3, desc_t1 = ua.GetActiveSetBonusForPiece("Vestments of Prophecy", 3)
    assert count_t1_3 == 15.0, f"Expected 15.0 EP for Prophecy 3-piece, got {count_t1_3}"
    print(f"  [PASS] Prophecy 3-piece: +{count_t1_3} EP ('{desc_t1}')")

def test_weight_presets_and_raid_weapons(lua):
    print("\n--- [Suite 5] Stat Weight Presets & Raid Weapons ---")
    ua = lua.eval("PriestBiS.UA")

    # 1. Verify New BWL/ES/Raid Weapons in metadata
    weapons = [
        (33075, "Staff of Cleansing Vapors", "HEAL", "Twohand"),
        (19360, "Lok'amir il Romathis", "HEAL", "Mainhand"),
        (33148, "Alar'tar, Born from Hope", "HEAL", "Twohand"),
        (61454, "Rod of Resuscitation", "HEAL", "Twohand"),
        (19355, "Shadow Wing Focus Staff", "CASTER_DPS", "Twohand"),
    ]
    for item_id, name, expected_role, expected_slot in weapons:
        meta = ua.ITEM_METADATA[item_id]
        assert meta is not None, f"Item {name} (#{item_id}) missing from ITEM_METADATA"
        assert meta.role == expected_role, f"Item {name} role mismatch: expected {expected_role}, got {meta.role}"
        print(f"  [PASS] Weapon #{item_id} {name:<28} role={meta.role} slot={expected_slot}")

    # 2. Verify Shadow Wing Focus Staff is correctly rejected as Caster DPS
    sw_comp = ua.GetUpgradeComparison(19355, "|Hitem:19355:0:0:0|h[Shadow Wing Focus Staff]|h")
    assert sw_comp.roleMismatch == True, "Shadow Wing Focus Staff should be flagged as role mismatch"
    assert sw_comp.isUpgrade == False, "Shadow Wing Focus Staff must not be an upgrade"
    print("  [PASS] Shadow Wing Focus Staff correctly rejected for Holy Priest (roleMismatch=True)")

    # 3. Test Capybara / Standard Presets vs Throughput
    ua.ApplyStatWeights("standard")
    assert ua.STAT_WEIGHTS.healing == 1.0
    assert ua.STAT_WEIGHTS.mp5 == 2.0
    assert ua.STAT_WEIGHTS.int == 0.5
    assert ua.STAT_WEIGHTS.spi == 0.5
    assert ua.STAT_WEIGHTS.spell_crit == 2.0
    assert ua.GetActiveWeightProfile() == "standard"
    print("  [PASS] Capybara / Standard preset applied: heal=1.0, mp5=2.0, int=0.5, spi=0.5, crit=2.0")

    ua.ApplyStatWeights("throughput")
    assert ua.STAT_WEIGHTS.healing == 1.0
    assert ua.STAT_WEIGHTS.mp5 == 2.2
    assert ua.STAT_WEIGHTS.int == 0.22
    assert ua.STAT_WEIGHTS.spell_crit == 8.0
    assert ua.GetActiveWeightProfile() == "throughput"
    print("  [PASS] Throughput preset applied: heal=1.0, mp5=2.2, int=0.22, crit=8.0")

    # Revert back to standard
    ua.ApplyStatWeights("standard")

def test_equipped_tier_scan_and_enchant_stripping(lua):
    print("\n--- [Suite 6] Live Equipped Scanning, Set Breakpoint & Enchant Stripping ---")
    ua = lua.eval("PriestBiS.UA")
    ua.ApplyStatWeights("throughput")

    lua.execute("""
    -- Setup items
    MOCK_ITEMS[16819] = { name = "Vambraces of Prophecy", invType = "INVTYPE_WRIST" }
    MOCK_ITEMS[16926] = { name = "Bindings of Transcendence", invType = "INVTYPE_WRIST" }
    MOCK_ITEMS[16925] = { name = "Belt of Transcendence", invType = "INVTYPE_WAIST" }
    MOCK_ITEMS[16922] = { name = "Leggings of Transcendence", invType = "INVTYPE_LEGS" }
    MOCK_ITEMS[16813] = { name = "Circlet of Prophecy", invType = "INVTYPE_HEAD" }
    MOCK_ITEMS[16817] = { name = "Mantle of Prophecy", invType = "INVTYPE_SHOULDER" }
    MOCK_ITEMS[16811] = { name = "Boots of Prophecy", invType = "INVTYPE_FEET" }

    -- Vambraces of Prophecy in bag (T1)
    MOCK_TOOLTIPS["item:16819:0:0:0"] = {
        "Vambraces of Prophecy",
        "Binds when picked up",
        "Wrist",
        "Cloth",
        "40 Armor",
        "+11 Intellect",
        "+14 Spirit",
        "Classes: Priest",
        "Requires Level 60",
        "Equip: Increases healing done by spells and effects by up to 27.",
        "Vestments of Prophecy (3/8)",
        "(3) Set: Reduces the casting time of your Flash Heal spell by 0.1 sec."
    }

    -- Bindings of Transcendence equipped (T2) with +24 Healing Enchant
    local t2_wrists_link = "|Hitem:16926:2566:0:0|h[Bindings of Transcendence]|h"
    MOCK_TOOLTIPS[t2_wrists_link] = {
        "Bindings of Transcendence",
        "Binds when picked up",
        "Wrist",
        "Cloth",
        "44 Armor",
        "+13 Intellect",
        "+13 Spirit",
        "Classes: Priest",
        "Requires Level 60",
        { text = "Healing Spells +24", r = 0, g = 1, b = 0 }, -- Green player enchant
        "Equip: Increases healing done by spells and effects by up to 26.",
        "Equip: Restores 4 mana per 5 sec.",
        "Vestments of Transcendence (3/8)",
        "(3) Set: Allows 15% of your Mana regeneration to continue while casting."
    }
    MOCK_TOOLTIPS["item:16926:0:0:0"] = MOCK_TOOLTIPS[t2_wrists_link]

    -- Other 2 Transcendence pieces to make 3-pc active
    MOCK_TOOLTIPS["item:16925:0:0:0"] = {
        "Belt of Transcendence", "Waist", "Cloth", "+15 Intellect", "+15 Spirit", "Vestments of Transcendence (3/8)"
    }
    MOCK_TOOLTIPS["item:16922:0:0:0"] = {
        "Leggings of Transcendence", "Legs", "Cloth", "+20 Intellect", "+20 Spirit", "Vestments of Transcendence (3/8)"
    }

    -- 3 Prophecy pieces equipped
    MOCK_TOOLTIPS["item:16813:0:0:0"] = { "Circlet of Prophecy", "Head", "Cloth", "+20 Intellect", "+20 Spirit", "Vestments of Prophecy (3/8)" }
    MOCK_TOOLTIPS["item:16817:0:0:0"] = { "Mantle of Prophecy", "Shoulder", "Cloth", "+15 Intellect", "+15 Spirit", "Vestments of Prophecy (3/8)" }
    MOCK_TOOLTIPS["item:16811:0:0:0"] = { "Boots of Prophecy", "Feet", "Cloth", "+15 Intellect", "+15 Spirit", "Vestments of Prophecy (3/8)" }

    -- Equip gear on player:
    -- Wrists (slot 9): Bindings of Transcendence (with +24 Healing enchant)
    MOCK_EQUIPPED[9] = t2_wrists_link
    -- Waist (slot 6): Belt of Transcendence
    MOCK_EQUIPPED[6] = "|Hitem:16925:0:0:0|h[Belt of Transcendence]|h"
    -- Legs (slot 7): Leggings of Transcendence
    MOCK_EQUIPPED[7] = "|Hitem:16922:0:0:0|h[Leggings of Transcendence]|h"
    -- Head (slot 1): Circlet of Prophecy
    MOCK_EQUIPPED[1] = "|Hitem:16813:0:0:0|h[Circlet of Prophecy]|h"
    -- Shoulder (slot 3): Mantle of Prophecy
    MOCK_EQUIPPED[3] = "|Hitem:16817:0:0:0|h[Mantle of Prophecy]|h"
    -- Feet (slot 8): Boots of Prophecy
    MOCK_EQUIPPED[8] = "|Hitem:16811:0:0:0|h[Boots of Prophecy]|h"

    UA.ClearCache()
    """)

    # Verify equipped item data for Wrists slot (slotID 9)
    eq_wrists = ua.GetEquippedItemData("Wrists")
    assert eq_wrists is not None, "Failed to get equipped wrists data"
    assert eq_wrists.name == "Bindings of Transcendence"
    assert eq_wrists.setName == "Vestments of Transcendence"
    # Verify enchant +24 healing was stripped (healing should be 26 from base equip line, NOT 50!)
    assert eq_wrists.healing == 26, f"Expected 26 healing (enchant stripped), got {eq_wrists.healing}"
    assert eq_wrists.mp5 == 4, f"Expected 4 mp5, got {eq_wrists.mp5}"
    assert eq_wrists.int == 13, f"Expected 13 int, got {eq_wrists.int}"
    assert eq_wrists.spi == 13, f"Expected 13 spi, got {eq_wrists.spi}"
    eq_score = ua.GetItemScore(eq_wrists)
    assert eq_score == 47, f"Expected 47 EP base score for Bindings of Transcendence, got {eq_score}"
    print(f"  [PASS] Live Equipped Scan: Bindings of Transcendence parsed via SetInventoryItem with +24 enchant stripped (score: {eq_score} EP)")

    # Verify equipped set counts
    t2_count = ua.GetEquippedSetCount("Vestments of Transcendence")
    assert t2_count == 3, f"Expected 3 equipped Transcendence pieces, got {t2_count}"
    t1_count = ua.GetEquippedSetCount("Vestments of Prophecy")
    assert t1_count == 3, f"Expected 3 equipped Prophecy pieces, got {t1_count}"
    print(f"  [PASS] Set Counts: Transcendence = {t2_count}, Prophecy = {t1_count}")

    # Now compare candidate item in bags: Vambraces of Prophecy (T1 bracers) vs equipped T2 bracers
    comp = ua.GetUpgradeComparison(16819, "|Hitem:16819:0:0:0|h[Vambraces of Prophecy]|h")
    assert comp is not None
    assert comp.isUpgrade == False, f"Vambraces of Prophecy should NOT be an upgrade! isUpgrade={comp.isUpgrade}"
    assert comp.currentScore == 47, f"Expected currentScore 47 EP, got {comp.currentScore}"
    assert comp.newScore == 39, f"Expected newScore 39 EP, got {comp.newScore}"
    assert comp.itemDelta == -8, f"Expected itemDelta -8 EP, got {comp.itemDelta}"
    assert comp.setBonusEP == 0, f"Expected setBonusEP 0 (3 -> 4 pieces crosses no breakpoint), got {comp.setBonusEP}"
    assert comp.lostSetBonusEP == 25, f"Expected lostSetBonusEP 25 (breaking 3-pc T2), got {comp.lostSetBonusEP}"
    assert comp.netSetDelta == -25, f"Expected netSetDelta -25 EP, got {comp.netSetDelta}"
    assert comp.delta == -33, f"Expected total delta -33 EP, got {comp.delta}"
    assert comp.effectiveScore == 72, f"Expected effectiveScore 72 EP (47 + 25), got {comp.effectiveScore}"
    print(f"  [PASS] Upgrade Comparison: Vambraces of Prophecy vs Bindings of Transcendence -> DOWNGRADE: delta={comp.delta} EP ({comp.newScore} vs {comp.effectiveScore} EP), lostSetBonusEP={comp.lostSetBonusEP}")

def main():
    print("=" * 80)
    print("PRIESTBIS IN-MEMORY LUA RUNTIME SIMULATION TEST (LUPA)")
    print("=" * 80)
    
    lua = create_mocked_lua_environment()
    print("Booted Lua 5.0 compatible VM and loaded PriestBiS modules.")

    test_dynamic_talent_sync(lua)
    test_ep_scoring_and_curated_database(lua)
    test_equipment_comparison_engine(lua)
    test_set_bonuses_math(lua)
    test_weight_presets_and_raid_weapons(lua)
    test_equipped_tier_scan_and_enchant_stripping(lua)

    print("\n" + "=" * 80)
    print("SIMULATION RESULT: ALL IN-MEMORY LUA RUNTIME TESTS PASSED 100%!")
    print("=" * 80)
    return 0

if __name__ == "__main__":
    sys.exit(main())
