# PriestBiS — Project Status & Handoff Document

> **Last Updated:** 2026-09-06 09:05 (Antigravity Assistant)  
> **Status:** Production Ready & Stable (v1.2.0)  
> **Target Engine:** Turtle WoW 1.18.1 / Vanilla 1.12.1 Client  
> **Active Verification:** `python tools/run_tests.py` → **ALL CHECKS PASS** (Strict Lua 5.0, UI Hooks, Pattern Tests)

---

## 1. Current Architecture
* **Core Engine**:
  - `PriestBiS.lua`: Main addon core, item evaluation algorithms, EP (Equivalence Points) calculation, slot weighting.
  - `Data/`: AtlasLoot-extracted databases covering Raids (MC, Onyxia, BWL, ZG, AQ, Naxx, Karazhan), Dungeons (Black Morass, Strat, Scholo, DM), and crafted items.
  - `Core/Scanner.lua`: Bag and bank scanning logic with item ID cache.
  - `UI/TooltipHooks.lua`: Hooked game tooltip integration showing item EP score, stat breakdowns, and comparison against currently equipped items.
  - `UI/AlertFrame.lua`: Loot drop upgrade alerts when an item in group loot exceeds current gear EP.
  - `Locales/`: Multi-language localization tables (enUS, deDE, frFR, ruRU, zhCN, esES).
* **Automated Tooling (`tools/`)**:
  - `tools/run_tests.py`: Master test suite executing syntax balance, strict Lua 5.0 conformance, global leak checks, and gear tooltip pattern validation.
  - `tools/atlasloot_parser.py`: Offline data extraction from AtlasLoot tables into Lua tables.

---

## 2. Invariant Rules (DO NOT TOUCH)
1. **Tooltip Hook Safety**:
   - `GameTooltip:HookScript` does not exist in 1.12.1. Tooltip hooks must use the classic method hook pattern with recursive guards:
     ```lua
     local orig = GameTooltip.SetBagItem
     GameTooltip.SetBagItem = function(self, bag, slot)
         orig(self, bag, slot)
         PriestBiS:ProcessTooltip(self)
     end
     ```
2. **Item Cache Isolation**: Never trigger synchronous AtlasLoot or item cache queries on every frame. Use the item ID memoization table.
3. **EP Math Purity**: Healing EP weights must accurately balance +Heal, MP5, Spirit (with Meditation), and Intellect without doubling stats.

---

## 3. Active Backlog & Next Steps
- [x] All 8 test gates passing in `tools/run_tests.py`.
- [x] Git working tree is completely clean on branch `main`.
- [ ] Maintain 7-day code freeze. No speculative refactoring of item tables unless a missing item is reported in-game.
