# Changelog

All notable changes to **PriestBiS** will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.2.0] - 2026-08-31

### Added
- **Set Bonus Breakpoint Engine**: Dynamically detects equipped set item counts (`UA.GetEquippedSetCount`) and factors tier set breakpoints (+25 EP for 3-pc T2 *Transcendence*, +15 EP for 3-pc T1 *Prophecy*, +21 EP for *ZG Mojo Infusion*) into gear evaluation and upgrade scoring.
- **Set Break Warnings**: Warns players in upgrade tooltips when replacing a set piece will deactivate a critical set bonus threshold.
- **Active Set Bonuses Display**: Added active set bonuses summary to `/pbis gear` with individual breakpoint EP breakdown.
- **Raid Roll "rush" Keyword Support**: Added `"rush"` keyword recognition to `ROLL_KEYWORDS` to natively support Turtle WoW raid roll conventions (e.g. `rush [Item] 100`).
- **Spell Power & Healing Scanner Fallback**: Enhanced tooltip scanning engine to parse dual `DAMAGE_HEALING` ("Increases damage and healing done by magical spells...") as a fallback when pure +healing is not listed.
- **Strict Weapon & Armor Gatekeeping Tables**: Explicit `PRIEST_ARMOR_SLOTS` and `PRIEST_WEAPON_SLOTS` tables to prevent non-armor slots (rings, necks, trinkets, cloaks) and non-weapon slots from triggering false equipability rejections.
- **Headless Unit Test Suite Expansion**: Added comprehensive test coverage in `tools/test_priest_bis.lua` for 1H mace stat scanning (*Jin'do's Hexxer*), raid roll detection with `"rush"`, non-roll chatter rejection, and alert frame nil-safety.

### Fixed
- **Alert Frame `OnUpdate` Nil-Safety**: Protected `alertFrame._timer` against `nil` `arg1` elapsed time parameters during frame update cycles.
- **Raid Roll Hyperlink Regex**: Corrected hyperlink regex pattern in `CheckRaidRollMessage` to ensure reliable capture across different client chat channels.
- **Two-Hand Staff Display in `/pbis gear`**: Fixed slot display when wielding a 2H staff so offhand is cleanly marked `[N/A - 2H Equipped]`.
- **Release Packaging Workflow**: Fixed `.github/workflows/release.yml` to package `Locales/` and `CHANGELOG.md` into the distribution zip.

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
