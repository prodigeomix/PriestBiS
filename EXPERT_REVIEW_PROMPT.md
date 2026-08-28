# Expert Review Request: UpgradeAlert Addon Strategy

Paste this entire document PLUS the contents of `UpgradeAlert.lua` and `UpgradeAlert.toc` as context to your expert AI.

---

## CONTEXT

**Expert role:** Top 0.1% World of Warcraft addon architect + senior Lua engineer, specializing in vanilla 1.12.1 / Turtle WoW 1.18.1 add development. You are reviewing an existing addon written in strict Lua 5.0 for the vanilla client (patch 1.12.1, Turtle WoW 1.18.1).

**Target environment constraints:**
- Lua 5.0 (NO `#` length operator, NO `string.match`, use `table.getn`/`string.len`/`string.find`/`string.gsub`)
- Vanilla 1.12.1 WoW API (no retail-only events like `LOOT_READY`, `BONUS_ROLL_ROLL_SPECIFIC_CURRENCY_CURRENCYID` etc.)
- Turtle WoW 1.18.1 custom content (IDs > 50000 are custom items: UKH, LKH, custom bosses)
- No `print()` global in vanilla — must use `DEFAULT_CHAT_FRAME:AddMessage()`
- `GetItemInfo(itemID)` returns 9 values: name, link, quality, iLevel, reqLevel, class, subclass, maxStack, equipSlot (NO icon — icon must come from item link texture or database lookup)
- `OnEvent` uses global `event` + `arg1`–`arg9` (closure-based frame scripts work but parameters are positional, not named)
- Item links format: `|cFFFFFFFF|HolItemCountHitem:ITEMID:ENCHANT:...|h[Item Name]|h|r`

**Player context:**
- Holy Priest in Turtle WoW 1.18.1, raiding Molten Core. Primary spec: pure +healing engine.
- PoH has zero +healing coefficient on Turtle 1.18.1 (this matters for stat weight evaluation).
- Current gear snapshot from combat log (27.08.26) — hardcoded as static `UA.CURRENT_GEAR`.
- Actively raiding MC, progressing into BWL/ZG.

**Existing skills/knowledge to cross-reference:**
- `wow-addon-dev` skill (Lua 5.0 rules, vanilla API constraints)
- `wow-gear-upgrade-analysis` skill (AtlasLoot loot table parsing, stat weights, item ID mappings)
- The `references/upgrade-alert-addon-pattern.md` document in the skill above (the documented pattern for build-this-exact-addon)

---

## THE ADDON AS BUILT (strategy summary)

The addon (798 lines, `UpgradeAlert.lua` + `UpgradeAlert.toc`) implements:

### Architecture
1. **Static BiS database** — 87 hardcoded item entries in `UA.UPGRADE_DATABASE`, each with: name, slot, stat values (healing, spell_damage, int, spi, stam, mp5, crit), drop source, priority rating, and notes. Cross-referenced with Wowhead/Method/wowtbc.gg for stat accuracy.
2. **Static CURRENT_GEAR** — 19 equipment slots hardcoded from combat log snapshot, with a `ScanEquippedGear()` function that refreshes on `PLAYER_ENTERING_WORLD` and `UPDATE_INVENTORY_ALERTS`.
3. **Stat-weight scoring** — `UA.GetItemScore(item)` computes `healing*1.0 + spell_damage*0.7 + int*0.3 + spi*0.4 + stam*0.1 + mp5*0.35 + crit*0.45` as a linear weighted sum.
4. **Upgrade comparison** — `UA.IsUpgrade(itemID)` compares the dropped item's score against the currently equipped item in the same slot, returning `(true/false, reason_string)`.
5. **Dual-slot logic** — Rings and trinkets get OR-comparison: alert if the new item beats EITHER current slot item.
6. **Event-driven detection:**
   - `LOOT_OPENED` → `UA.CheckLootWindow()` reads loot slots via `GetNumLootItems()` + `LootSlotIsItem()` + `GetLootSlotLink()`
   - `CHAT_MSG_LOOT` → `UA.CheckLootChatMessage(message)` parses `|c...|Hitem:ID:...|h...|h|r` from loot chat
   - `PLAYER_ENTERING_WORLD` + `UPDATE_INVENTORY_ALERTS` → `ScanEquippedGear()` + `DetectAddons()`
7. **Proactive pfExtend integration** (optional) — if `pfDB`/`pfDatabase`/`pfMap` globals exist, registers `UPDATE_MOUSEOVER_UNIT` to alert on targeting known boss NPCs before loot drops.
8. **Alert UI** — draggable 350×180 frame with flashing alpha animation (OnUpdate sine wave), `PlaySound("QUESTADVENTURECOMPLETE")`, and chat output via a `print()` that may not exist in 1.12.1 (no fallback to `DEFAULT_CHAT_FRAME:AddMessage()`).
9. **Slash commands** — `/ua toggle`, `/ua db`, `/ua help`.

### Key strategic decisions in the code
- Trinkets: auto-alert on ANY trinket with `healing > 0` ("BiS confirmed"), and auto-alert on ALL other trinkets unconditionally (line 343).
- Rings: if either current ring isn't in the database, auto-alert as "Ring upgrade (current ring not in DB)".
- Items not in database: `UA.CheckAndAlert` returns early if `itemID not in UPGRADE_DATABASE` — so only pre-known items trigger alerts.
- Two-handed weapons: slot = "Twohand", but `CURRENT_GEAR` has no `Twohand` slot → falls through to "Slot empty - any item is an upgrade" → always alerts.

---

## WHAT I WANT YOU TO EVALUATE

Please give a top-to-bottom expert-level critique. I'm particularly interested in architectural strategy questions, not just line-level bugs. Structure your response as:

### A. High-Level Architecture Assessment (1-paragraph executive summary)
Does this strategy (static DB + stat weights + event detection + UI) make sense for the use case? What's the biggest architectural risk?

### B. Item-by-Item Strategic Questions (address each)

**Q1 — Static CURRENT_GEAR vs. dynamic scanning:**
The gear is hardcoded from a one-time combat log snapshot. `ScanEquippedGear()` (line 740) has a bug: for non-Wand slots, it only updates if `UA.CURRENT_GEAR[slotName]` already exists (`elseif UA.CURRENT_GEAR[slotName] then` on line 758) — so newly-filled slots never get populated. Also, `ScanEquippedGear` uses `GetItemInfo(link)` on line 753 which may return nil for uncached items. Should gear tracking be fully dynamic (always query at alert-time via `GetInventoryItemLink("player", slotID)`) instead of caching? What's the robust vanilla 1.12.1 pattern?

**Q2 — Stat weighting model validity:**
The weights (`healing=1.0, spell_damage=0.7, int=0.3, spi=0.4, mp5=0.35, crit=0.45`) are a linear sum with no diminishing returns, no mana sustainability modeling, and no slot-normalization. For a Holy priest on Turtle 1.18.1 where PoH has zero +healing coefficient, is +healing per-slot the right primary axis? Should `spell_damage` really be 0.7 (it only helps Holy Nova/Wand/Shadow spells)? Should there be a "slot value density" check (healing-per-item-level) rather than raw stat totals? Suggest a better scoring formula if one exists.

**Q3 — Trinket handling philosophy:**
Current logic: any trinket with `healing > 0` → auto-flag "BiS". All other trinkets → auto-flag unconditionally. This means Hazza'rah's Charm of Healing (correct), but also a melee AP trinket or a +stamina trinket would alert as "upgrade." Trinkets are fundamentally different from other slots because they have use-effects, procs, and on-use mechanics that don't appear in static stat values. What's the right strategy here? Options: (a) keep the aggressive alert and let the player decide, (b) add a trinket-specific sub-database with proc/on-use descriptions and a "recommend" vs "auto-upgrade" flag, (c) only alert on trinkets that are strictly better in stat-sum AND have a useful proc. Which would you implement?

**Q4 — Ring dual-slot OR logic:**
`if newScore > score1 or newScore > score2 then` — alerts if it beats either ring. Is OR correct, or should it prefer replacing the weaker ring and compare against `math.min(score1, score2)`? Also, proc-based rings (e.g., Band of Forced Concentration, +1% spell crit) are scored as raw stats only — the proc is invisible to the comparison. How should procs be weighted? Suggest a proc-value estimation approach.

**Q5 — TwoHand vs. Mainhand + Offhand:**
The database has `slot = "Twohand"` for [20258] (Zulian Ceremonial Staff), but `CURRENT_GEAR` has `Mainhand` and `Offhand` slots, no `Twohand`. So `IsUpgrade` looks up `UA.CURRENT_GEAR["Twohand"]` → nil → "Slot empty - any item is an upgrade" → always alerts for 2H weapons, even if the player's MH+OH combination is strictly better. Should the comparison compute `scoreMH + scoreOH` and compare against the 2H score? How should "weapon type appropriateness" (staff vs. mace+offhand for a priest) be encoded?

**Q6 — Handling items not in the database:**
When an item isn't in `UPGRADE_DATABASE`, `CheckAndAlert` (line 667) returns early — no alert at all. This means if a new Turtle WoW custom item drops that's an amazing upgrade but isn't in your curated 87-item list, the player gets nothing. Meanwhile, currently equipped items NOT in the DB (e.g., Penchant of Humility, Fabric of Time) trigger "Current item not in DB - manual check recommended" → everything alerts. What's the right strategy? Options: (a) fall back to `GetItemInfo` + `GetInventoryItemLink` to at least show item name/quality, (b) dynamically parse AtlasLoot's Instances.lua/Items.lua tables at runtime (the addon could read its own data), (c) maintain the curated list and accept gaps. Which approach scales best?

**Q7 — Event system correctness & Loot detection:**
Events registered: `LOOT_OPENED`, `CHAT_MSG_LOOT`, `PLAYER_ENTERING_WORLD`, `ADDON_LOADED`, `UPDATE_INVENTORY_ALERTS`. 
- `LOOT_OPENED` is correct for vanilla (not `LOOT_READY` which is retail).
- `CHAT_MSG_LOOT` parsing on line 655 uses `string.gfind(message, "|c.-|H(item:%d+:[0-9:-]+)|h.-|h|r")` — is this regex robust for Turtle WoW's item link format? Are there edge cases (stack sizes, random suffixes, missing enchant fields)?
- `LootFrame:IsVisible()` check on line 627 — is this reliable? The pattern reference says it may cause a race condition if `LOOT_OPENED` fires before the frame is visible.
- `GetLootSlotInfo(i)` returns texture/name/quantity/quality/canUse — it does NOT return itemID. The code correctly uses `GetLootSlotLink(i)` to get the link and parses the ID. Good?

**Q8 — GetItemInfo and caching:**
Line 521: `local name, link, quality, iLevel, reqLevel, class, subclass, maxStack, equipSlot, itemIcon2 = GetItemInfo(itemID)`. In vanilla 1.12.1, `GetItemInfo` returns 9 values (no icon). `itemIcon2` will be nil. Line 522: `if not name then return false end` — if the item isn't cached yet (first encounter), `GetItemInfo` returns nil and the alert silently aborts. Should the addon queue a retry, or fall back to database values for icon/quality and use `GetItemInfo` icon only as a progressive enhancement?

**Q9 — print() absence in vanilla:**
The addon calls bare `print()` (lines 583, 586, 697, 700, 704-709, 710-715) but vanilla 1.12.1 has no global `print()`. The pattern reference notes this as a critical issue — these calls will throw Lua errors. There is no `print` compatibility shim defined anywhere in the file. How critical is this and what's the 1.12.1-safe pattern?

**Q10 — Two OnEvent handlers (overlapping registration):**
Lines 599-618 register an `OnEvent` handler. Then lines 768-798 register a SECOND `OnEvent` handler that wraps the first (`oldOnEvent`). This double-wrapping is unusual — the second handler calls `oldOnEvent(frame, event, a1, ...)` and then ALSO handles `PLAYER_ENTERING_WORLD`/`UPDATE_INVENTORY_ALERTS` for gear scanning. Is this a clean pattern or does it create double-firing / ordering bugs? Should this be consolidated into one handler?

### C. Strategic Recommendations
1. **Should the addon dynamically parse AtlasLoot's Lua data tables at runtime** instead of maintaining a static hand-curated database? This would automatically include all current + new loot table data (drop rates, source bosses, item stats from tooltip strings) and eliminate the "87 known items" limitation. Trade-off: dependency on AtlasLoot being installed.
2. **Should stat weights live in a separate config file** (e.g., `UpgradeAlertConfig.lua`) for easy tuning, with the database in a separate data file? Current file is 798 lines monolithic.
3. **Should the proactive pfExtend mouseover alert use a more robust tooltip-scanning approach** (e.g., `BattlePetToolTip` or `GameTooltip:GetText()`) or is the current `getglobal("GameTooltipTextLeft1"):GetText()` + `string.gsub` color-code stripping approach sound?
4. **Biggest one fix you'd make if you could only change one thing** in this addon to improve its reliability for a raiding Holy priest?

---

## FILE CONTENTS

[ Paste the full contents of `UpgradeAlert.lua` and `UpgradeAlert.toc` here ]