# Contributing to PriestBiS

Thank you for contributing to **PriestBiS**! This document provides technical guidelines for contributing code, data, and localizations.

---

## 1. Runtime Environment: Strict Lua 5.0.2

Vanilla World of Warcraft (Patch 1.12.1) and Turtle WoW (Patch 1.18.1) run on the **Lua 5.0.2** interpreter. Post-Lua 5.0 syntax is strictly prohibited in addon runtime files:

| Feature / Syntax | Allowed? | Required Alternative |
| :--- | :---: | :--- |
| `#tbl`, `#str` (Length operator) | ❌ | `table.getn(tbl)`, `string.len(str)` |
| `string.match`, `string.gmatch` | ❌ | `string.find`, `string.gfind`, `string.gsub` |
| `math.huge` | ❌ | `1e9` or explicit numerical ceiling |
| `%` (Modulo operator) | ❌ | `math.mod(a, b)` |
| `//` (Integer division) | ❌ | `math.floor(a / b)` |
| `...` vararg expressions | ❌ | Use the implicit `arg` table |
| Modern namespaces (`C_*`) | ❌ | Vanilla 1.12.1 C APIs |

Any violation will cause runtime errors in the WoW client and will fail `tools/validate_lua50.py`.

---

## 2. Multi-Language Support (5 Locales)

PriestBiS supports 5 client languages natively:
* `enUS` (English)
* `zhCN` (Simplified Chinese)
* `ruRU` (Russian)
* `deDE` (German)
* `frFR` (French)

Whenever user-facing strings or tooltip injection lines are introduced:
1. Add the corresponding key to [Locales/Localization.lua](file:///c:/Games/Interface/AddOns/PriestBiS/Locales/Localization.lua).
2. Define translations across all five locale files under [Locales/](file:///c:/Games/Interface/AddOns/PriestBiS/Locales).
3. If adding tier set bonuses in [Data/SetBonuses.lua](file:///c:/Games/Interface/AddOns/PriestBiS/Data/SetBonuses.lua), include the localized set name as parsed by the WoW client.

---

## 3. Local Verification Suite

Before submitting any Pull Request, run the automated verification suite:

```bash
python tools/run_tests.py
```

This executes 9 stages of verification:
1. **Block Balance** (`check_lua.py`): Checks `if/then/end`, `function/end`, `do/end` balance.
2. **Lua 5.0 Compliance** (`validate_lua50.py`): Enforces Lua 5.0 AST rules.
3. **Global Scope Leaks** (`scan_global_leaks.py`): Checks for accidental global variable declarations.
4. **Multi-Locale Patterns** (`test_gear_patterns.py`): Validates stat pattern parsing across all 5 languages.
5. **API Call Resolution** (`verify_all_api_calls.py`): Verifies that all inter-module functions and tables resolve.
6. **Database Integrity** (`validate_item_database.py`): Validates item metadata, slot definitions, set breakpoints, and boss drops.
7. **TOC Syntax Validator** (`validate_lua.lua`): Loads all TOC files in load order via standalone Lua.
8. **Simulation Suite** (`test_priest_bis.lua`): Full unit test simulation of talent sync, math deltas, and roll hooks.
9. **Performance Benchmark** (`test_performance.lua`): Validates that tooltip render overhead remains strictly below the 1.0 ms/render budget.

---

## 4. Development Workflow

1. Fork the repository and create a feature branch (`feature/my-awesome-feature`).
2. Make modular edits under `Data/`, `Core/`, `UI/`, or `Locales/`.
3. Run `python tools/run_tests.py` and ensure `ALL 9 CHECKS PASSED`.
4. Submit a Pull Request targeting the `main` branch with the completed QA checklist.
