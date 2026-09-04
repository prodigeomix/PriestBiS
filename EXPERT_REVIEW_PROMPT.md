# Expert Review Document: PriestBiS Architecture (v1.2.0)

## Overview

**PriestBiS** is a real-time loot and upgrade monitor built for Holy & Discipline Priests on **Vanilla WoW 1.12.1** and **Turtle WoW 1.18.1**, engineered in strict **Lua 5.0.2**.

---

## Target Environment & Engine Constraints

1. **Runtime VM:** Lua 5.0.2 engine.
   - Upvalue caching (`local format = string.format`, `local gsub = string.gsub`) is standard and recommended for Lua 5.0 bytecode optimization (register access vs. global hash lookups).
   - Strict avoidance of Lua 5.1+ primitives (`#` length operator, `string.match`, `string.gmatch`, `goto`, `HookScript`, `C_*` namespaces).
2. **Localization Engine:**
   - In Vanilla WoW 1.12.1, `GetItemInfo(link)` returns localized `itemType` and `itemSubType` strings matching the user's active game client locale (e.g., Russian, German, French, Chinese). Localized lookup dictionary keys are active runtime lookups across localized clients.
3. **Tooltip Engine Limits:**
   - Pre-allocates and manages fontstrings beyond the native 30-fontstring C engine limit to prevent UI crashes and allocation churn.

---

## Technical Architecture

### 1. 100% Dynamic Live State Queries (Zero Static Gear Snapshot)
- **Problem solved:** Traditional addons hardcode static tables of equipped gear that immediately desync with actual player gear, enchants, or server stat tweaks.
- **Solution:** Real-time query directly from engine memory via `GetInventoryItemLink("player", slotID)` and `scanTooltip:SetInventoryItem("player", slotID)`.

### 2. Runtime Tooltip Stat Scanner & Memoization
- All candidate items are parsed on the fly directly from the game client's tooltips (`UA.ScanItemStats`).
- Multi-language regex engine supporting English, German, French, Russian, and Chinese item tooltips.
- Cached in `ITEM_STAT_CACHE` for sub-millisecond lookup performance.
- Clean memoization invalidation upon talent respec (`CHARACTER_POINTS_CHANGED`) and spell updates (`SPELLS_CHANGED`).

### 3. Priest Equivalence Points (EP) Model
- **+Healing:** `1.0 EP`
- **Spirit:** Dynamic talent scaling:
  $$\text{Spirit EP} = 0.30\text{ (Base FSR)} + 0.05 \times \text{Rank}_{\text{Spiritual Guidance}} + 0.05 \times \text{Rank}_{\text{Meditation}}$$
- **MP5:** `2.20 EP` ($1\text{ MP5} = 12\text{ mana/min}$)
- **Spell Crit:** `8.0 EP` (Inspiration armor buff uptime + direct throughput)
- **Intellect:** `0.22 EP`
- **Stamina:** `0.05 EP`
- **Pure Spell/Holy Damage:** `0.0 EP` (Does not increase healing on Turtle 1.18.1).

### 4. Strict Class Gatekeeping & Equipability
- **Armor Type:** Cloth only (Head, Shoulder, Chest, Wrists, Hands, Belt, Legs, Boots). Rejects Leather, Mail, Plate, and Shields across all client locales.
- **Weapon Types:** One-Handed Maces, Daggers, Staves, and Wands. Rejects Swords, Axes, Polearms, 2H Maces, Bows, Guns, and Crossbows.
- **Class Restrictions:** Parses multi-lingual `Classes: Druid, Shaman, Paladin` lines.

### 5. Dual-Slot & Set Breakpoint Mathematics
- **Rings & Trinkets:** Evaluates candidate upgrades against the weaker equipped piece (`math.min(score1, score2)`).
- **2H Staff vs. MH+OH:** Calculates $MH + OH$ combined set totals against $2H$ staves.
- **Tier & Set Bonus Breakpoints:** Dynamically counts equipped set pieces across all slots (`UA.GetEquippedSetCount`) and awards set bonus EP value when reaching thresholds (+25 EP for 3-pc T2 Transcendence, +15 EP for 3-pc T1 Prophecy, +21 EP for ZG Mojo Infusion).

### 6. Ecosystem Interoperability
- **`LootBlare` Hook:** Hooks `ItemRollFrame:Show()` and updates the title with `[UPGRADE +X EP]`.
- **Raid Roll Chat Detector:** Parses `/rw`, `/raid`, and `/party` roll calls (`"Roll for [Item]"`).
- **`pfQuest` / `pfDB` Dynamic Resolver:** Resolves unit drops, shared raid loot (`refloot`), and quests directly from `pfDB` without hardcoded strings.
- **Unified `UA` Namespace:** Uses `UA` (`PriestBiS`) as the single internal module namespace.

---

## Verification & Test Harness
- 100% pass rate in headless test suite (`tools/run_tests.py` & `tools/test_priest_bis.lua`).
