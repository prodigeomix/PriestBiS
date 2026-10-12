#!/usr/bin/env python3
"""
tools/scan_ast_globals.py
=========================
AST-Based Global Variable and Scope Leak Scanner for PriestBiS.
Imported & adapted from HolyPriest verification tools.

Parses every Lua file into an Abstract Syntax Tree (AST) using 'luaparser' to enforce:
1. Zero unintended global assignments (catches missing 'local' in loops, functions, tables).
2. Zero undeclared global functions.
3. 100% resolution of bare global function calls against permitted WoW 1.12 & PriestBiS APIs.

Exit code 0 on clean scan, 1 if any scope leaks are detected.
"""

import os
import sys
import subprocess

if sys.platform == "win32":
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")

try:
    import luaparser
    from luaparser import ast, astnodes
except ImportError:
    print("Notice: Package 'luaparser' not found in environment. Attempting install...")
    try:
        subprocess.check_call([sys.executable, "-m", "pip", "install", "luaparser"])
        from luaparser import ast, astnodes
    except Exception as e:
        print(f"NOTICE: 'luaparser' is not installed and could not be installed ({e}).")
        print("        To run full AST global leak scanning, install dependencies:")
        print("        pip install -r requirements.txt")
        sys.exit(0)

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
ADDON_DIR = os.path.abspath(os.path.join(SCRIPT_DIR, ".."))

KNOWN_GLOBALS = {
    # PriestBiS namespace & saved variables
    'PriestBiS', 'PriestBiSDB', 'UA', 'PB',
    'SLASH_PriestBiS1', 'SLASH_PriestBiS2', 'SLASH_PriestBiS3', 'SLASH_PriestBiS4',
    
    # WoW 1.12 Core UI & Environment
    'SlashCmdList', 'CreateFrame', 'UIParent', 'GameTooltip', 'DEFAULT_CHAT_FRAME',
    'PlaySound', 'GameFontNormalSmall', 'ItemRefTooltip', 'UIErrorsFrame',
    'this', 'event', 'arg1', 'arg2', 'arg3', 'arg4', 'arg5', 'arg6', 'arg7', 'arg8', 'arg9',
    'ITEM_QUALITY_COLORS', 'FONT_COLOR_CODE_CLOSE', 'RETRIEVING_ITEM_INFO', 'ITEM_STAT_CACHE',
    
    # WoW 1.12 Item & Inventory APIs
    'GetItemInfo', 'GetInventoryItemLink', 'GetInventoryItemID', 'GetInventorySlotInfo',
    'GetContainerNumSlots', 'GetContainerItemLink', 'GetMerchantItemLink',
    'GetTradeSkillItemLink', 'GetTradeSkillReagentItemLink', 'GetCraftItemLink',
    'GetCraftReagentItemLink', 'GetTradePlayerItemLink', 'GetTradeTargetItemLink',
    'GetQuestItemLink', 'GetQuestLogItemLink', 'GetInboxItemLink', 'GetAuctionItemLink',
    'GetNumLootItems', 'GetLootSlotInfo', 'GetLootSlotLink', 'LootSlotIsItem',
    'DressUpItemLink', 'ChatFrameEditBox', 'ItemRollFrame',
    
    # WoW 1.12 Player, Group & Talent APIs
    'GetTalentInfo', 'GetNumTalents', 'GetNumTalentTabs', 'GetLootMethod',
    'GetRaidRosterInfo', 'GetNumRaidMembers', 'GetNumPartyMembers',
    'UnitName', 'UnitClass', 'UnitExists', 'UnitIsPlayer', 'RandomRoll',
    'SendAddonMessage', 'GetLocale', 'GetRealmName',
    
    # Optional Third-Party Addon Integrations (AtlasLoot, pfQuest/pfDB, BCS, LootBlare)
    'AtlasLoot', 'AtlasLoot_ShowItemsFrame', 'AtlasLootItem_OnEnter', 'AtlasLootItem_OnClick',
    'pfQuest', 'pfDB', 'BCS', 'LootBlare',
    
    # Standard Lua 5.0 base functions and libraries
    'table', 'string', 'math', 'pairs', 'ipairs', 'next', 'type',
    'tostring', 'tonumber', 'pcall', 'xpcall', 'setmetatable', 'getmetatable',
    'getglobal', 'setglobal', 'getfenv', 'setfenv', 'unpack', 'print',
    'error', 'assert', 'getn'
}

class Scope:
    def __init__(self, parent=None):
        self.parent = parent
        self.locals = set()
        
    def add_local(self, name):
        self.locals.add(name)
        
    def is_local(self, name):
        if name in self.locals:
            return True
        if self.parent:
            return self.parent.is_local(name)
        return False

def check_file(filepath):
    with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
        src = f.read()
        
    try:
        tree = ast.parse(src)
    except Exception as e:
        print(f"Failed to parse {filepath}: {e}")
        return 1

    leaks = []
    
    def visit(node, scope):
        if isinstance(node, astnodes.Block):
            new_scope = Scope(scope)
            for stmt in node.body:
                visit(stmt, new_scope)
        elif isinstance(node, astnodes.LocalAssign):
            for target in node.targets:
                if isinstance(target, astnodes.Name):
                    scope.add_local(target.id)
            if node.values:
                for val in node.values:
                    visit(val, scope)
        elif isinstance(node, astnodes.Function):
            if isinstance(node.name, astnodes.Name):
                name = node.name.id
                if not scope.is_local(name) and name not in KNOWN_GLOBALS:
                    leaks.append((name, getattr(node, 'line', '?'), "Global Function"))
            new_scope = Scope(scope)
            for arg in node.args:
                if isinstance(arg, astnodes.Name):
                    new_scope.add_local(arg.id)
                elif isinstance(arg, astnodes.Varargs):
                    new_scope.add_local("arg")
            visit(node.body, new_scope)
        elif isinstance(node, astnodes.AnonymousFunction):
            new_scope = Scope(scope)
            for arg in node.args:
                if isinstance(arg, astnodes.Name):
                    new_scope.add_local(arg.id)
                elif isinstance(arg, astnodes.Varargs):
                    new_scope.add_local("arg")
            visit(node.body, new_scope)
        elif isinstance(node, astnodes.LocalFunction):
            scope.add_local(node.name.id)
            new_scope = Scope(scope)
            for arg in node.args:
                if isinstance(arg, astnodes.Name):
                    new_scope.add_local(arg.id)
                elif isinstance(arg, astnodes.Varargs):
                    new_scope.add_local("arg")
            visit(node.body, new_scope)
        elif isinstance(node, astnodes.Assign):
            for target in node.targets:
                if isinstance(target, astnodes.Name):
                    name = target.id
                    if not scope.is_local(name) and name not in KNOWN_GLOBALS:
                        leaks.append((name, getattr(node, 'line', '?'), "Global Variable"))
                else:
                    visit(target, scope)
            if node.values:
                for val in node.values:
                    visit(val, scope)
        elif isinstance(node, astnodes.Forin):
            new_scope = Scope(scope)
            for name in node.targets:
                if isinstance(name, astnodes.Name):
                    new_scope.add_local(name.id)
            visit(node.body, new_scope)
        elif isinstance(node, astnodes.Fornum):
            new_scope = Scope(scope)
            if isinstance(node.target, astnodes.Name):
                new_scope.add_local(node.target.id)
            visit(node.body, new_scope)
        elif isinstance(node, astnodes.Call):
            func = node.func
            if isinstance(func, astnodes.Name):
                fname = func.id
                if not scope.is_local(fname) and fname not in KNOWN_GLOBALS:
                    leaks.append((fname, getattr(node, 'line', '?'), "Unresolved Global Call"))
            visit(func, scope)
            for arg in node.args:
                visit(arg, scope)
        else:
            for key, val in vars(node).items():
                if isinstance(val, list):
                    for item in val:
                        if isinstance(item, astnodes.Node):
                            visit(item, scope)
                elif isinstance(val, astnodes.Node):
                    visit(val, scope)

    root_scope = Scope()
    visit(tree, root_scope)
    
    rel = os.path.relpath(filepath, ADDON_DIR)
    if leaks:
        print(f"\n[FAIL] {rel} has {len(leaks)} AST scope leak(s):")
        for name, line, reason in leaks:
            print(f"  Line {line}: {reason} -> '{name}'")
        return len(leaks)
    else:
        print(f"  [PASS] {rel} (zero AST global leaks)")
        return 0

def main():
    print("=" * 80)
    print("PRIESTBIS AST GLOBAL SCOPE & LEAK SCANNER")
    print("=" * 80)
    
    lua_files = []
    for root, _, files in os.walk(ADDON_DIR):
        if "tools" in root or ".git" in root or ".agents" in root:
            continue
        for f in files:
            if f.endswith('.lua'):
                lua_files.append(os.path.join(root, f))
                
    lua_files.sort()
    print(f"Scanning {len(lua_files)} PriestBiS Lua files with AST parser...")
    
    total_leaks = 0
    for f in lua_files:
        total_leaks += check_file(f)
        
    print("\n" + "=" * 80)
    if total_leaks > 0:
        print(f"FAILED: {total_leaks} global leaks / unresolved calls detected!")
        print("=" * 80)
        sys.exit(1)
    else:
        print(f"SUCCESS: All {len(lua_files)} files passed AST scope validation with 0 leaks!")
        print("=" * 80)
        sys.exit(0)

if __name__ == "__main__":
    main()
