# Changelog

All notable changes to **PriestBiS** will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.3.1] - 2026-09-04

### Added
- **Universal Role Mismatch Filtering**: Promoted role mismatch validation to the global entry point of `Core/Comparison.lua`, instantly rejecting curated non-healer items (`role = "TANK"`, `"MELEE"`, `"CASTER_DPS"`) across all armor, jewelry, and weapon slots.
- **Alert Frame Drag Position Persistence**: Added `OnDragStop` coordinate saving to `PriestBiSDB.alertPos` and automatic frame restoration via `UA.RestoreAlertFramePosition()` on addon load.
- **Multi-Drop Alert Queueing**: Implemented sequential alert queueing in `UI/AlertFrame.lua` to gracefully queue and display rapid multi-drop raid loot without clobbering or losing alerts.
- **Full 5-Locale Set Bonus Coverage**: Completed localized definitions in `Data/SetBonuses.lua` for Dungeon 1 *The Devout* (German *Die Andacht*, French *Les dévots*) and Dungeon 2 *Vestments of the Virtuous* (Russian *Одеяния Добродетели*, German *Gewänder der Tugendhaften*, French *Habits des vertueux*), plus Russian aliases for Turtle custom sets.
- **Localized Bag Piece Tooltip Annotation**: Replaced remaining hardcoded English text in `UI/TooltipHooks.lua` with localized `L["WITH_BAG_PIECES"]` across all 5 languages (`enUS`, `zhCN`, `ruRU`, `deDE`, `frFR`).
- **Hierarchical Set Breakpoint Display**: Sorted set breakpoint keys ascending with `table.sort` in `/pbis gear` to guarantee proper sequential order (3-pc -> 5-pc -> 8-pc).
- **pfDB Drop Rate Priority Sorting**: Sorted candidate drop units descending by rate in `Core/Engine.lua` so the primary high-probability encounter is always listed first.
- **Top 0.1% GitHub Infrastructure**: Added multi-version Python CI matrix (3.10, 3.11, 3.12) to `.github/workflows/ci.yml`, `CONTRIBUTING.md` with Lua 5.0 rules, `SECURITY.md`, and `.github/pull_request_template.md`.

### Fixed
- **Missing Event Registrations in Event Lifecycle**: Registered `BAG_UPDATE`, `PLAYERBANKSLOTS_CHANGED`, `PLAYERBANKBAGSLOTS_CHANGED`, and `UNIT_INVENTORY_CHANGED` in `PriestBiS.lua` to ensure `UA.bagCacheDirty` is invalidated upon looting or gear swaps, preventing stale container caches.
- **Database Validator Truncation**: Fixed non-greedy regex flaw in `tools/validate_item_database.py` that halted at the first set definition; expanded auditor to verify all 36 set tier definitions (84 breakpoints), token turn-in `rewardID` integrity, slot consistency, and 44 boss encounters.
- **Version String Harmonization**: Synchronized version strings across `PriestBiS.toc`, `Core/Engine.lua`, and all 5 client localization files (`enUS`, `zhCN`, `ruRU`, `deDE`, `frFR`).

---

## [1.3.0] - 2026-09-03

### Added
- **Modular Addon Architecture**: Decomposed monolith into clean, single-responsibility modules under `Data/`, `Core/`, and `UI/`:
  - `Data/ItemDatabase.lua`: Curated item metadata, boss drop mappings, and upgrade tables.
  - `Data/SetBonuses.lua`: Multilingual tier set bonus tables and EP breakpoint values.
  - `Core/Engine.lua`: Stat weighting, dynamic talent weight sync, tooltip stat scanner, item data extraction, base EP calculation, and priest equipability validation.
  - `Core/Comparison.lua`: Inventory & bank offhand scanning, bag set piece detection, set breakpoint math, net character delta evaluation, and dual-slot resolution.
  - `UI/AlertFrame.lua`: Loot popup alert frame, visual flash animations, audio cues, and movable frame handlers.
  - `UI/TooltipHooks.lua`: 80-line font string pool expansion, dynamic line cleanup, EP badge rendering, and universal hook engine for GameTooltip, ItemRefTooltip, and AtlasLoot.
  - `PriestBiS.lua`: Lean lifecycle event listener, loot monitor, and slash command dispatcher.
- **Raid Quest Token & Starter Item Resolution**:
  - `[18646]` *The Eye of Divinity* mapped to `[18608]` *Benediction* (Twohand staff, 215 EP override) for Majordomo Executus drops.
  - `[19002]` *Head of Onyxia* mapped to `[17064]` *Shard of the Scale* (Trinket, 85 EP override).
  - `[19003]` *Head of Nefarian* mapped to `[19382]` *Pure Elementium Band* (Ring, 74 EP override).
  - `[19802]` *Heart of Hakkar* mapped to `[19950]` *Zandalarian Hero Charm* (Trinket, 90 EP override).
- **Curated On-Use & Proc Trinket EP Ratings**:
  - `[19288]` *Darkmoon Card: Blue Dragon* (+90 EP sustain override).
  - `[23047]` *Eye of the Dead* (+130 EP Naxxramas BiS on-use burst override).
  - `[21625]` *Scarab Brooch* (+80 EP AQ40 heal shield override).
  - `[19930]` *Mar'li's Eye* (+45 EP ZG decaying on-use override).
  - `[18820]` *Talisman of Ephemeral Power* (+70 EP MC burst override).
- **Bag Set Piece Detection**: Discovers unequipped set pieces in player bags to project upcoming set completion bonuses (+25 EP for 3-pc T2, etc.) when looting or considering a candidate set piece.
- **Dual-Slot Ring Net Delta Replacement**: Simultaneously evaluates Ring 1 and Ring 2, factoring individual set losses and gains to recommend the replacement yielding the greatest net character EP.

### Fixed
- **Set Bonus Double-Counting & Contamination**: Fixed item base EP calculation to strictly measure item base stats; set bonuses are now added as character-level deltas during comparison rather than mutating item base scores.
- **Empty Slot Set Bonus Calculation**: Fixed early return when slot was unequipped, ensuring set bonuses and bag-assisted completions are properly recognized when equipping into empty slots.

---

## [1.2.0] - 2026-08-31

### Added
- **Bags & Bank Off-Hand Scanner**: Automatically scans player's inventory (`Bags 0..4`) and bank containers (`-1`, `5..10`) for owned Off-Hands, persisting the best bank Off-Hand in `PriestBiSDB.characters[realm][playerName]`.
- **Smart 2H-to-1H Projection Engine**: Eliminates false-negative downgrade alerts when holding a 2H Staff by projecting candidate 1H weapons with the player's best owned bag/bank Off-Hand against the 2H staff.
- **Dedicated Projected OH Tooltip Badge**: Displays `Projected OH: [Item] (+X EP | Bags/Bank)` in tooltips across all 5 supported client locales.
- **Bagshui-Inspired Scoped Character Storage**: Scopes bank caches and user data under `[Realm][PlayerName]` for complete alt and cross-realm isolation.
- **Real-Time Bank Event Lifecycle**: Registered `PLAYERBANKSLOTS_CHANGED` and `PLAYERBANKBAGSLOTS_CHANGED` in addition to `BANKFRAME_OPENED` for instant live bank updates.
- **Debounced Dirty-Flag Inventory Caching**: Implemented `UA.bagCacheDirty` on `BAG_UPDATE` to prevent unnecessary container looping on every tooltip hover.
- **Set Bonus Breakpoint Engine**: Dynamically detects equipped set item counts (`UA.GetEquippedSetCount`) and factors tier set breakpoints (+25 EP for 3-pc T2 *Transcendence*, +15 EP for 3-pc T1 *Prophecy*, +21 EP for *ZG Mojo Infusion*) into gear evaluation and upgrade scoring.
- **Set Break Warnings**: Warns players in upgrade tooltips when replacing a set piece will deactivate a critical set bonus threshold.
- **Active Set Bonuses Display**: Added active set bonuses summary to `/pbis gear` with individual breakpoint EP breakdown.
- **Raid Roll "rush" Keyword Support**: Added `"rush"` keyword recognition to `ROLL_KEYWORDS` to natively support Turtle WoW raid roll conventions (e.g. `rush [Item] 100`).
- **Spell Power & Healing Scanner Fallback**: Enhanced tooltip scanning engine to parse dual `DAMAGE_HEALING` ("Increases damage and healing done by magical spells...") as a fallback when pure +healing is not listed.
- **Dynamic Talent Weight & Multi-Language Unit Tests**: Added comprehensive test coverage in `tools/test_priest_bis.lua` for dynamic *Spiritual Guidance* and *Meditation* scaling across all talent combinations (0.30 to 0.70 EP), 1H mace stat scanning (*Jin'do's Hexxer*), raid roll detection with `"rush"`, non-roll chatter rejection, and alert frame nil-safety.

### Fixed
- **Re-entrancy Guard Hardening (`insideAppend`)**: Extracted tooltip rendering into `UA.RenderTooltipLines` and wrapped execution in `pcall` to ensure `insideAppend = false` on all error/exit paths, preventing silent tooltip lockups.
- **Unified `/pbis gear` Localization**: Refactored `UA.FormatItemInfo` to use `UA.FormatStatBreakdown(data)` directly, ensuring full localized stat formatting across all languages.
- **Empty-Slot Percentage Roll Formatting**: Cleaned up percentage calculations for empty slots in roll alerts and LootBlare hooks to default to 100% rather than displaying `+0.0%`.
- **Tightened `IsSetLine` Detection**: Replaced loose word matching with structured set patterns (`%(%d+/%d+%)`, `%(%d+%)%s*Set`, `Комплект`, `套装`), preventing false positives on Russian and French stat lines.
- **LootBlare Hook Hardening & Exception Isolation**: Refactored `HookLootBlare()` with `pcall` error isolation, colon/dot invocation safety (`frame = self or itemRollFrame`), and nil-safe text setter guards to guarantee master loot UI is never interrupted.
- **Alert Frame `OnUpdate` Nil-Safety**: Protected `alertFrame._timer` against `nil` `arg1` elapsed time parameters during frame update cycles.
- **Raid Roll Hyperlink Regex**: Corrected hyperlink regex pattern in `CheckRaidRollMessage` to ensure reliable capture across different client chat channels.

---

## [1.1.0] - 2026-08-28

### Added
- **Multi-Language Localization Framework (i18n)**: Full native localization support for English (`enUS`), Simplified Chinese (`zhCN`), Russian (`ruRU`), German (`deDE`), and French (`frFR`).
- **Cross-Language Item Link Scanning**: Capability to evaluate item hyperlinks shared by players using different language clients.
- **Dynamic Talent Synchronization**: Multi-lingual talent scanning for *Spiritual Guidance* and *Meditation* across all 5 supported languages.
- **Turtle WoW Karazhan & Custom Items Database**: Ingested Lower/Upper Karazhan loot (*Sliver of Hope*, *Clawlord Howlfang*, custom cloaks, wands, rings) into `UA.ITEM_METADATA` and `UA.BOSS_DROPS`.

---

## [1.0.0] - 2026-08-25

### Added
- **100% Dynamic Live-Query Architecture**: Real-time evaluation directly from client memory (`GetInventoryItemLink`) and tooltips without static gear snapshot desyncs.
- **Priest Equivalence Points (EP) Model**: Tailored EP weights for Holy and Discipline Priests (+Healing, Spirit FSR scaling, MP5, Spell Crit, Intellect, Stamina).
- **Dual-Slot Matrix Math**: Automatic evaluation against the weaker equipped piece for Rings and Trinkets (`math.min(score1, score2)`).
- **2H Staff vs. MH+OH Math**: Dynamic combined set comparison for staves vs. main-hand and off-hand combinations.
- **LootBlare & Raid Roll Hooking**: Visual upgrade badges and audio alerts during master looter rolls and chat roll calls.
- **pfQuest & pfDB Dynamic Drop Source Engine**: Dynamic resolver for unit drops, shared loot, and quest rewards.
- **Interactive Slash Commands**: `/pbis gear`, `/pbis toggle`, `/pbis tooltip`, `/pbis downgrades`, `/pbis db`, `/pbis help`.
