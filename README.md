# ✨ PriestBiS (for Vanilla 1.12.1 & Turtle WoW 1.18.1)

> **The Intelligent Real-Time Loot, Upgrade & BiS Assistant for Holy and Discipline Priests.**

[![WoW Version](https://img.shields.io/badge/Interface-1.12.1%20%7C%20Turtle%20WoW%201.18.1-blue.svg)](https://turtle-wow.org)
[![Class](https://img.shields.io/badge/Class-Priest%20(Holy%2FDiscipline)-gold.svg)]()
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](https://opensource.org/licenses/MIT)
[![Build Status](https://img.shields.io/badge/tests-100%25%20passed-brightgreen.svg)]()

---

## 🌟 Why PriestBiS?

Most loot addons rely on static, outdated item databases with hardcoded stats that break on custom server patches or enchants. 

**PriestBiS** is engineered with a **100% dynamic live-query architecture**:
- It reads your actual equipped gear directly from client memory (`GetInventoryItemLink`).
- It scans candidate items in real time directly from game tooltips (`GameTooltip` & `ItemRefTooltip`).
- It syncs with your active talent ranks (*Spiritual Guidance* and *Meditation*) to dynamically calibrate your exact Spirit value.
- It detects when a dropping item will complete an active **Set Bonus** (e.g. 3-pc T2 Transcendence 15% in-FSR mana regen) and factors that bonus directly into the upgrade score.
- It hooks **LootBlare** and raid roll calls (`/rw`, `/raid`) so you instantly know whether to roll main-spec on a drop.

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

### 🛡️ 2. Strict Priest Equipability Filtering
Never see false upgrade alerts on items your Priest cannot wear:
* **Armor Type Gatekeeping:** Cloth only. Rejects Leather, Mail, Plate, and Shields.
* **Weapon Gatekeeping:** One-Handed Maces, Daggers, Staves, and Wands only. Rejects Swords, Axes, Polearms, 2H Maces, Bows, Guns, and Crossbows.
* **Class Restriction Parsing:** Automatically respects `Classes: Druid, Shaman, Paladin` tooltip restrictions.

---

### ⚔️ 3. Dual-Slot Matrix & Set Math
* **Rings & Trinkets:** Automatically compares candidate items against the **weaker** of your two equipped items (`math.min(score1, score2)`).
* **Two-Handed Staves vs. Mainhand + Offhand:** When a 2H staff drops, compares its score against your combined $MH + OH$ total. When a 1H weapon drops while wielding a staff, projects your new weapon with your offhand against the staff.
* **Dynamic Set Bonus Breakpoints:** Recognizes when equipping an item reaches a set breakpoint (e.g. 2 pieces $\to$ 3 pieces of *Vestments of Transcendence* or *Vestments of Prophecy*) and awards the set bonus EP value directly (+25 EP for 3-pc T2).

---

### 🔔 4. Raid Roll & LootBlare Hooking
* **LootBlare Master Loot Integration:** When the master looter triggers a roll in `LootBlare`, PriestBiS immediately evaluates if the item is an upgrade, triggers a sound effect, and stamps a green `[UPGRADE +X EP]` badge right inside the LootBlare frame.
* **Raid Warning Detector:** Automatically parses `/rw`, `/raid`, and `/party` roll calls (`"Roll for [Item]"`).

---

### 🌍 5. Deep Mod Interoperability & Multi-Language Support
* **pfQuest & pfDB Dynamic Drop Source Engine:** Dynamically queries boss names, drop rates, and quest names for Vanilla and Turtle WoW custom items.
* **Multi-Language Tooltip Parsing:** Full German (`Klassen`, `Stoff`, `Geistige Führung`), French (`Tissu`, `Directives spirituelles`), and English support.
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
