# ✨ PriestBiS (for Vanilla 1.12.1 & Turtle WoW 1.18.1)

> **The Intelligent Real-Time Loot, Upgrade & BiS Assistant for Holy and Discipline Priests.**

[![WoW Version](https://img.shields.io/badge/Interface-1.12.1%20%7C%20Turtle%20WoW%201.18.1-blue.svg)](https://turtle-wow.org)
[![Version](https://img.shields.io/badge/version-1.3.1-blue.svg)]()
[![Languages](https://img.shields.io/badge/Languages-enUS%20%7C%20zhCN%20%7C%20ruRU%20%7C%20deDE%20%7C%20frFR-purple.svg)]()
[![Class](https://img.shields.io/badge/Class-Priest%20(Holy%2FDiscipline)-gold.svg)]()
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](https://opensource.org/licenses/MIT)
[![Build Status](https://img.shields.io/badge/tests-100%25%20passed-brightgreen.svg)]()

---

## 🌟 Why PriestBiS?

Most loot addons rely on static, outdated item databases with hardcoded stats that break on custom server patches or enchants. 

**PriestBiS** is engineered with a **100% dynamic live-query architecture**:
- It reads your actual equipped gear directly from client memory (`GetInventoryItemLink`).
- It scans candidate items in real time directly from game tooltips (`GameTooltip` & `ItemRefTooltip`).
- It syncs with your active talent ranks (*Spiritual Guidance* and *Meditation*) to dynamically calibrate your exact Spirit value across all languages.
- It detects when a dropping item will complete an active **Set Bonus** (e.g. 3-pc T2 Transcendence 15% in-FSR mana regen) and factors that bonus directly into the upgrade score.
- It features an automated **Bags & Bank Off-Hand Scanner** that intelligently projects combined 1H + OH scores when wielding a 2H staff.
- It hooks **LootBlare** and raid roll calls (`/rw`, `/raid`) so you instantly know whether to roll main-spec on a drop.
- It provides **complete native localization** for English, Simplified Chinese, Russian, German, and French clients.

---

## 🚀 Key Features

### ⚡ 1. Real-Time Healing Equivalence Points (EP) Engine
* **+Healing:** $1.0\text{ EP}$
* **Spirit:** Dynamically calculated based on your active talent ranks:
  $$\text{Spirit EP} = \text{Base FSR } (0.30) + (0.05 \times \text{Rank}_{\text{Spiritual Guidance}}) + (0.05 \times \text{Rank}_{\text{Meditation}})$$
* **MP5:** $2.20\text{ EP}$ ($1\text{ MP5} = 12\text{ mana/min}$)
* **Spell Crit:** $8.0\text{ EP}$ (Factoring in *Inspiration* armor buff uptime + direct throughput)
* **Intellect:** $0.22\text{ EP}$
* **Stamina:** $0.05\text{ EP}$
* **On-Use Trinkets:** Hand-tuned curated overrides (e.g. *Hazza'rah's Charm of Healing* $= 120\text{ EP}$).

---

### 🌐 2. Native Multi-Language Support (i18n)
PriestBiS features an integrated internationalization framework designed for multi-region private servers and Turtle WoW:

| Language | Client Locale | Supported Elements |
| :--- | :--- | :--- |
| **English** | `enUS` / `enGB` | Full UI, Chat, Tooltips, Slash Commands, Set Bonuses, Talents |
| **Simplified Chinese (简体中文)** | `zhCN` | 完整UI界面、聊天信息、装备属性扫描、天赋同步(`精神指引`/`冥想`)、套装(`卓越法衣`/`预言法衣`)、Roll点警报(`需求`/`贪婪`/`掷骰`) |
| **Russian (Русский)** | `ruRU` | Полный интерфейс, всплывающие подсказки, сканирование характеристик, таланты (`Духовное направление`/`Медитация`), комплекты (`Одеяния Превосходства`), ролл (`нужно`/`ролл`) |
| **German (Deutsch)** | `deDE` | Vollständige UI, Tooltips, Talent-Erkennung (`Geistige Führung`/`Meditation`), Set-Boni (`Gewänder der Transzendenz`), Würfel-Meldungen (`bedarf`/`wuerfeln`) |
| **French (Français)** | `frFR` | Interface complète, infobulles, talents (`Directives spirituelles`/`Méditation`), bonus d'ensemble (`Habits de transcendance`), alertes de butin (`besoin`/`rouler`) |

* **Dynamic Client Detection:** Automatically loads the active client locale with instant `enUS` proxy fallback.
* **Cross-Language Item Link Scanning:** Capable of evaluating item links shared by players using different language clients.

---

### 🛡️ 3. Strict Priest Equipability Filtering
Never see false upgrade alerts on items your Priest cannot wear:
* **Armor Type Gatekeeping:** Cloth only (`布甲`, `Ткань`, `Stoff`, `Tissu`). Rejects Leather, Mail, Plate, and Shields across all client languages.
* **Weapon Gatekeeping:** One-Handed Maces, Daggers, Staves, and Wands only. Rejects Swords, Axes, Polearms, 2H Maces, Bows, Guns, and Crossbows.
* **Class Restriction Parsing:** Automatically respects `Classes: Druid, Shaman, Paladin` (and localized equivalents `职业:`, `Класс:`, `Klassen:`) tooltip restrictions.

---

### ⚔️ 4. Dual-Slot Matrix, Set Math & Smart 2H-to-1H Projection
* **Rings & Trinkets:** Automatically compares candidate items against the **weaker** of your two equipped items (`math.min(score1, score2)`).
* **Two-Handed Staves vs. Mainhand + Offhand:** When a 2H staff drops, compares its score against your combined $MH + OH$ total.
* **Smart 2H-to-1H Projection (Bags & Bank Scanner):** When inspecting a 1H Mace or Dagger while wielding a 2H Staff (where the Off-Hand slot is empty), PriestBiS dynamically pulls your best owned Off-Hand from your **Bags or Bank** and calculates:
  $$\text{Projected Score} = \text{EP}(\text{Candidate 1H}) + \text{EP}(\text{Best Owned Bag/Bank OH})$$
  $$\Delta = \text{Projected Score} - \text{EP}(\text{Equipped 2H Staff})$$
  Renders an informative badge directly in tooltips: `Projected OH: Consecrated Caduceus (+39 EP | Bags)`.
* **Dynamic Set Bonus Breakpoints:** Recognizes when equipping an item reaches a set breakpoint (e.g. 2 pieces $\to$ 3 pieces of *Vestments of Transcendence* / *卓越法衣* / *Одеяния Превосходства*) and awards the set bonus EP value directly (+25 EP for 3-pc T2).

---

### 🔔 5. Raid Roll & LootBlare Hooking
* **LootBlare Master Loot Integration:** When the master looter triggers a roll in `LootBlare`, PriestBiS immediately evaluates if the item is an upgrade, triggers a sound effect, and stamps a green `[UPGRADE +X EP]` badge right inside the LootBlare frame.
* **Raid Warning Detector:** Automatically parses `/rw`, `/raid`, and `/party` roll calls (`"Roll for [Item]"`, `"需求 [物品]"`, `"ролл [предмет]"`).

---

### 🎒 6. Bagshui-Inspired Inventory & Bank Architecture
* **Character & Realm Scoped Storage:** Bank off-hands and settings are automatically scoped by `[Realm][PlayerName]`, keeping alts and cross-realm characters completely isolated.
* **Full Bank Event Lifecycle:** Listens to `BANKFRAME_OPENED`, `PLAYERBANKSLOTS_CHANGED`, and `PLAYERBANKBAGSLOTS_CHANGED` to ensure real-time cache updates when depositing or withdrawing items at the banker.
* **Debounced Dirty-Flag Bag Scanning:** Uses a cached inventory scanner flagged on `BAG_UPDATE` to eliminate redundant container iteration during rapid mouse hovering.
* **Re-entrancy Guard Hardening:** All tooltip rendering logic is executed under protected `pcall` boundaries to guarantee the re-entrancy lock never bricks tooltips on unexpected client errors.

---

### 🔍 7. Deep Mod Interoperability
* **pfQuest & pfDB Dynamic Drop Source Engine:** Dynamically queries boss names, drop rates, and quest names for Vanilla and Turtle WoW custom items.
* **AtlasLoot Compatible:** Click any item in AtlasLoot to view instant upgrade comparisons and breakdown stats.

---

## ⌨️ Slash Commands

Use `/pbis`, `/bis`, or `/priestbis` in-game:

| Command | Action |
| :--- | :--- |
| `/pbis gear` | Displays all 17 slots of your equipped gear and their live EP scores |
| `/pbis toggle` | Tests the visual upgrade popup alert frame and plays the alert sound |
| `/pbis tooltip` | Toggles tooltip upgrade badges on/off |
| `/pbis downgrades` | Toggles downgrade / sidegrade information on/off in tooltips |
| `/pbis db` | Lists high-priority curated dungeon/raid upgrades |
| `/pbis help` | Displays the in-game command reference |

---

## 📥 Installation

1. Download the latest release `.zip` from the [Releases](https://github.com/prodigeomix/PriestBiS/releases) page.
2. Extract the folder into your `World of Warcraft/Interface/AddOns/` directory.
3. Ensure the folder is named **`PriestBiS`**.
4. Launch the game and type `/pbis gear` or `/bis` to verify!

---

## 👤 Author & Creator

* **Original Creator & Author:** **[prodigeomix](https://github.com/prodigeomix)** (In-Game: `Carbon`)
* **Target Platforms:** Vanilla WoW 1.12.1 & Turtle WoW 1.18.1
* **License:** [MIT License](LICENSE) (c) 2026 prodigeomix (Carbon) & PriestBiS Contributors
