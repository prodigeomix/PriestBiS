#!/usr/bin/env python3
"""
tools/scan_global_leaks.py
==========================
Scans PriestBiS files for unintended global variable assignments in functions.
"""

import os
import re
import sys

if sys.platform == "win32":
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
ADDON_DIR = os.path.abspath(os.path.join(SCRIPT_DIR, ".."))

ALLOWED_GLOBALS = {
    'PriestBiS', 'PriestBiSDB', 'UA', 'PB', 'SLASH_PRIESTBIS1', 'SLASH_PRIESTBIS2',
    'SLASH_PRIESTBIS3', 'SlashCmdList', 'CreateFrame', 'UIParent', 'GameTooltip',
    'DEFAULT_CHAT_FRAME', 'PlaySound', 'GetItemInfo', 'GetInventoryItemLink',
    'GetInventoryItemID', 'GetInventorySlotInfo', 'GetTalentInfo', 'GetNumTalents',
    'GetNumTalentTabs', 'GetLootMethod', 'GetRaidRosterInfo', 'GetNumRaidMembers',
    'GetNumPartyMembers', 'UnitName', 'RandomRoll', 'SendAddonMessage', 'DressUpItemLink',
    'ChatFrameEditBox', 'ItemRollFrame', 'LootBlare', 'AtlasLoot', 'pfQuest', 'pfDB',
    'BCS', 'table', 'string', 'math', 'pairs', 'ipairs', 'next', 'type', 'tostring',
    'tonumber', 'pcall', 'xpcall', 'setmetatable', 'getmetatable', 'getglobal',
    'setglobal', 'getfenv', 'setfenv', 'unpack', 'print', 'error', 'assert', 'event',
    'this', 'arg1', 'arg2', 'arg3', 'arg4', 'arg5', 'arg6', 'arg7', 'arg8', 'arg9',
    'ITEM_QUALITY_COLORS', 'FONT_COLOR_CODE_CLOSE', 'RETRIEVING_ITEM_INFO',
    'ITEM_STAT_CACHE', 'AtlasLoot_ShowItemsFrame', 'AtlasLootItem_OnEnter', 'AtlasLootItem_OnClick'
}

def scan_file(filepath):
    with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
        content = f.read()

    # Find local declarations (including comma-separated lists: local a, b, c)
    local_vars = set()
    for decl in re.findall(r'local\s+([^=;\n]+)', content):
        decl = decl.strip()
        if not decl.startswith('function'):
            for var in decl.split(','):
                v = var.strip()
                if v and re.match(r'^[A-Za-z_][A-Za-z0-9_]*$', v):
                    local_vars.add(v)
        else:
            m = re.search(r'function\s+([A-Za-z_][A-Za-z0-9_]*)', decl)
            if m:
                local_vars.add(m.group(1))
    
    # Find parameters
    params = re.findall(r'function\s*[A-Za-z0-9_:\.]*\s*\((.*?)\)', content)
    for p_list in params:
        for p in p_list.split(','):
            p = p.strip()
            if p:
                local_vars.add(p)

    lines = content.split('\n')
    leaks = []
    in_table = 0
    
    for i, line in enumerate(lines, start=1):
        clean_line = line.split('--')[0].strip()
        if not clean_line:
            continue
            
        # Check if line contains assignments
        match = re.match(r'^([A-Za-z_][A-Za-z0-9_]*)\s*=(?!=)', clean_line)
        if match and in_table == 0:
            var = match.group(1)
            if var not in ALLOWED_GLOBALS and var not in local_vars and not var.startswith('SLASH_'):
                leaks.append((i, var, clean_line))

        # Update table depth after analyzing assignment on current line
        in_table += clean_line.count('{') - clean_line.count('}')
        if in_table < 0:
            in_table = 0

    rel = os.path.relpath(filepath, ADDON_DIR)
    if leaks:
        print(f"\n[FAIL] {rel} has {len(leaks)} undeclared global leak(s):")
        for line_num, var, text in leaks:
            print(f"  Line {line_num}: Global '{var}' -> {text}")
        return False
    else:
        print(f"  [PASS] {rel} (zero global scope leaks)")
        return True

def main():
    print("Scanning PriestBiS Lua files for global scope leaks...")
    all_ok = True
    lua_files = []
    for root, _, files in os.walk(ADDON_DIR):
        if "tools" in root or ".git" in root:
            continue
        for f in files:
            if f.endswith('.lua'):
                lua_files.append(os.path.join(root, f))

    for f in sorted(lua_files):
        if not scan_file(f):
            all_ok = False

    if all_ok:
        print("\nAll scanned files have clean local scoping with zero global leaks!")
        sys.exit(0)
    else:
        print("\nGlobal leak detection failed!")
        sys.exit(1)

if __name__ == "__main__":
    main()
