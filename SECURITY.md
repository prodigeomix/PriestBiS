# Security Policy

## Supported Versions

| Version | Supported          |
| :--- | :---: |
| 1.3.x | :white_check_mark: |
| 1.2.x | :x:                |
| < 1.2 | :x:                |

---

## Client Safety & Sandboxing

PriestBiS is an in-game World of Warcraft user interface modification running within the World of Warcraft 1.12.1 / Turtle WoW 1.18.1 client sandbox.

The addon:
* Does not execute shell commands or access the host filesystem outside standard `SavedVariablesPerCharacter`.
* Does not communicate over unauthorized external sockets or protocols.
* Strictly respects the Blizzard UI event lifecycle and avoids recursive hook execution via re-entrancy guards.

---

## Reporting a Vulnerability or Client Freeze

If you discover a security vulnerability, client lockup, memory leak, or game freeze caused by PriestBiS:
1. Please **do not** open a public issue.
2. Email the maintainer or submit a private security advisory through GitHub.
3. Include:
   * Client version (Turtle WoW 1.18.1, Vanilla 1.12.1).
   * Active addons (AtlasLoot, pfQuest, LootBlare, etc.).
   * Exact reproduction steps (item hovered, roll message received, or slash command executed).
