## Description
<!-- Provide a brief description of the changes introduced in this Pull Request -->

## Type of Change
- [ ] 🐛 Bugfix (non-breaking change fixing an issue)
- [ ] ✨ New Feature / Gear Data (new item metadata, boss drop, or set bonus)
- [ ] 🌐 Localization (translations for enUS, zhCN, ruRU, deDE, or frFR)
- [ ] ⚡ Performance Optimization
- [ ] 🔧 Tooling / Testing / Documentation

## Affected Modules
- [ ] `Core/Engine.lua` (EP weighting, tooltip stat scanner, item extraction)
- [ ] `Core/Comparison.lua` (Dual-slot matrices, weapon projection, set breakpoint deltas)
- [ ] `Data/ItemDatabase.lua` (Curated metadata, token turn-in mappings, boss drops)
- [ ] `Data/SetBonuses.lua` (Tier & dungeon set bonuses across 5 languages)
- [ ] `UI/AlertFrame.lua` (Loot alerts, queueing, and position persistence)
- [ ] `UI/TooltipHooks.lua` (Tooltip line injection, custom line pool, AtlasLoot hooks)
- [ ] `PriestBiS.lua` (Lifecycle events, slash commands)
- [ ] `Locales/` (Localization tables)
- [ ] `tools/` (Verification and benchmarking scripts)

## Strict Lua 5.0.2 Compliance Checklist
- [ ] **NO `#` length operator** (used `table.getn(tbl)` or `string.len(str)` instead)
- [ ] **NO `string.match` / `string.gmatch`** (used `string.find` / `string.gfind` / `string.gsub`)
- [ ] **NO `math.huge`** or post-Lua 5.0 operators (`//`, `%`, `::label::`, `goto`)
- [ ] **NO `...` varargs outside `arg` table**
- [ ] **Zero Global Scope Leaks** (all functions/variables properly scoped with `local` or explicitly prefixed under `UA` / `PriestBiS`)
- [ ] **Multi-Locale Verified** (tested against all 5 supported client locales: `enUS`, `zhCN`, `ruRU`, `deDE`, `frFR`)
- [ ] **Automated Tests Passing** (executed `python tools/run_tests.py` with 100% pass rate across all 9 verification checks)
