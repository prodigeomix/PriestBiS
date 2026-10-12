# Acceptance Gates: PriestBiS T1/T2 Sets, Weapons & Stat Weights Overhaul

## Overview
This ledger defines the deterministic acceptance gates for fixing T1/T2 set calculations, BWL & Emerald Sanctum (ES) staff databases and evaluations, and configurable stat weights matching Capybara / Chronicle Classic standards (`mp5=2.0`, `heal=1.0`, `int=0.5`, `crit=2.0`, `spi=0.5`).

---

### GATE-01: Raid Weapons & Item Database Schema [PASSED & VERIFIED]
- **Description**: Add `Staff of Cleansing Vapors` (33075), `Staff of the Shadow Flame` (19356), `Alar'tar, Born from Hope` (33148), `Rod of Resuscitation` (61454), and `Lok'amir il Romathis` (19360) to `Data/ItemDatabase.lua`. Fix `Shadow Wing Focus Staff` (19355) with `role = "CASTER_DPS"`. Update `UA.BOSS_DROPS` for Ezzel Darkbrewer, Nefarian, and Moroes.
- **CHECK**: `python tools/validate_item_database.py`
- **STATUS**: PASS (105 items verified, 36 set tiers, 49 boss encounters).

---

### GATE-02: Reconcile T2 3-Piece Set Bonus to Realistic Value [PASSED & VERIFIED]
- **Description**: In `Data/SetBonuses.lua`, reconcile the inflated 75 EP on `Vestments of Transcendence` 3-piece bonus down to balanced 25 EP across all 5 locales (enUS, zhCN, ruRU, deDE, frFR).
- **CHECK**: `python tools/golden_table_test.py`
- **STATUS**: PASS (Golden table zero drift across all 13 items & 6 set breakpoints).

---

### GATE-03: Configurable Stat Weights & Capybara Preset [PASSED & VERIFIED]
- **Description**: In `Core/Engine.lua` and `PriestBiS.lua`, support `UA.WEIGHT_PRESETS` including `"standard"` (Capybara: `healing=1.0, mp5=2.0, int=0.5, spi=0.5, spell_crit=2.0`) and `"throughput"` (dynamic), with persistence in `PriestBiSDB.customWeights` and `PriestBiSDB.weightProfile`. Provide `/pbis weights`, `/pbis preset`, and `/pbis setweight` slash commands.
- **CHECK**: `python tools/test_simulation_vm.py`
- **STATUS**: PASS (Both presets verified in Lua runtime VM).

---

### GATE-04: Separate Immediate Equip Delta from Bag-Projected Combos [PASSED & VERIFIED]
- **Description**: In `Core/Comparison.lua`, evaluate immediate upgrade delta and `isUpgrade` based on currently equipped set pieces (`equippedCount -> equippedCount + 1`), preventing phantom upgrade flags from unequipped items in bags. Track bag-assisted set combos separately as `bagSetBonusEP` / `fromBags` potential.
- **CHECK**: `python tools/test_simulation_vm.py`
- **STATUS**: PASS (Set bonus immediate equip separated cleanly from bag combo potential).

---

### GATE-05: Tooltip Score Math Transparency [PASSED & VERIFIED]
- **Description**: In `UI/TooltipHooks.lua`, ensure replacement lines annotate net set deltas (`[Set +X]` / `[Set -X]`) and display immediate set bonuses vs bag combo potential (`Set Potential (with bag pieces)`), reconciling displayed numbers with `comp.delta`.
- **CHECK**: `python tools/validate_lua50.py` & `python tools/scan_ast_globals.py`
- **STATUS**: PASS (Strict Lua 5.0 compliant, 0 AST global leaks).

---

### GATE-06: Full Automated Test Suite & Certification Readiness [PASSED & VERIFIED]
- **Description**: Run `python tools/run_tests.py` and `python certify_bis.py` verifying AST global leak scanner, Lua 5.0 compatibility, contract audits, and simulation tests.
- **CHECK**: `python certify_bis.py`
- **STATUS**: PASS (All 6 certification gates passed; 100% raid & combat ready).

---

### GATE-07: Live Armory Gear Reconciliation & Database Hardening [PASSED & VERIFIED]
- **Description**: Reconcile live character armory loadout for Carbon on Eversong Wilds. Reconcile `Consecrated Caduceus` item ID to `84602` (`slot = "Wand"`, ilvl 68, +13 Heal, +4 MP5) and map to Archivist Galford in `UA.BOSS_DROPS`. Add `Ring of Unleashed Potential` (`55360`, +33 Heal, +11 Int, +4 MP5) and `Fordring's Seal` (`16058`, +37 Heal, +5 Int).
- **CHECK**: `python tools/validate_item_database.py` & `python certify_bis.py`
- **STATUS**: PASS (107 curated items, 50 boss drop encounters, 0 contract violations).

---

### GATE-08: Live Equipped Inventory Scanning, Set Breakpoint & Tooltip Width Fix [PASSED & VERIFIED]
- **Description**:
  1. Fix `UA.GetEquippedItemData(slotName)` to pass `slotID` to `UA.GetItemData(itemID, link, slotID)` and prioritize `scanTooltip:SetInventoryItem("player", slotID)` over synthetic hyperlinks.
  2. Implement native player enchant stripping: detect green text (`r < 0.35 and g > 0.65 and b < 0.35`) lacking `Equip:`, `Use:`, or `Set:` prefixes on items with non-zero enchant IDs (`encID ~= "0"`), ensuring base items compare apples-to-apples without penalizing unenchanted bag drops or inflating equipped gear.
  3. Invalidate `UA.ClearCache()` on `UNIT_INVENTORY_CHANGED` to ensure equipped stats and active set bonuses remain synchronized on gear swaps.
  4. Fix tooltip right-edge clipping: update `UA.AdjustTooltipSize` to measure string widths across all visible native lines (1..30) and custom lines, expanding `tooltip:SetWidth(maxLineWidth)` dynamically.
  5. Verify that comparing Tier 1 Vambraces of Prophecy against equipped Tier 2 Bindings of Transcendence (with 3-pc T2 active) correctly calculates a downgrade (-33 EP in throughput / -32 EP in standard), recognizing the 25 EP penalty for breaking the 3-pc Transcendence set bonus.
- **CHECK**: `python tools/run_tests.py` & `python certify_bis.py`
- **STATUS**: PASS (All 10 test suite checks and pre-raid operational certification verified 100%).


