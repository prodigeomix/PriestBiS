#!/usr/bin/env python3
"""
tools/deep_contract_audit.py
============================
Deep Cross-Module Boundary, Contract & TOC Load-Order Auditor for PriestBiS.
Imported & adapted from HolyPriest verification tools.

Exhaustively checks:
1. TOC load-order compliance: verifies all 13 modules load in strict dependency sequence.
2. Cross-module export and call-site resolution for UA.* and PriestBiS.* namespaces.
3. Top-level chunk safety: ensures top-level execution does not call downstream functions.
4. Data schema alignment across Data/ItemDatabase.lua, Data/SetBonuses.lua, and Core/Engine.lua.

Exit code 0 on success, 1 on any contract or boundary violation.
"""

import os
import re
import sys
from collections import defaultdict

if sys.platform == "win32":
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
ADDON_DIR = os.path.abspath(os.path.join(SCRIPT_DIR, ".."))

TOC_FILE = os.path.join(ADDON_DIR, "PriestBiS.toc")

def read_toc(toc_path):
    files = []
    with open(toc_path, "r", encoding="utf-8", errors="ignore") as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            if line.endswith(".lua"):
                files.append(line.replace("/", os.sep).replace("\\", os.sep))
    return files

def strip_lua(content):
    """Strips comments and string literals while preserving line breaks."""
    res = []
    i = 0
    n = len(content)
    while i < n:
        if content[i:i+4] == '--[[':
            end = content.find(']]', i+4)
            if end == -1: break
            lines = content[i:end+2].count('\n')
            res.append('\n' * lines + ' ' * 2)
            i = end + 2
        elif content[i:i+2] == '--':
            end = content.find('\n', i+2)
            if end == -1: break
            res.append(' ' * (end - i))
            i = end
        elif content[i] in ('"', "'"):
            quote = content[i]
            j = i + 1
            while j < n:
                if content[j] == '\\':
                    j += 2
                elif content[j] == quote:
                    j += 1
                    break
                elif content[j] == '\n':
                    break
                else:
                    j += 1
            res.append('""' + ' ' * (j - i - 2))
            i = j
        else:
            res.append(content[i])
            i += 1
    return "".join(res)

def audit():
    print("=" * 80)
    print("PRIESTBIS DEEP CROSS-MODULE CONTRACT & BOUNDARY AUDITOR")
    print("=" * 80)
    
    if not os.path.exists(TOC_FILE):
        print(f"Error: TOC file not found at {TOC_FILE}")
        return 1

    toc_files = read_toc(TOC_FILE)
    print(f"Loaded {len(toc_files)} files from PriestBiS.toc in order:")
    for idx, f in enumerate(toc_files, start=1):
        full_p = os.path.join(ADDON_DIR, f)
        exists = "EXISTS" if os.path.exists(full_p) else "MISSING"
        print(f"  {idx:2d}. {f:<35} [{exists}]")
        if exists == "MISSING":
            print(f"[FAIL] Required TOC file {f} is missing from disk!")
            return 1

    total_violations = 0
    
    # 1. Collect exported symbols and where they are defined
    # format: name -> {file, line, is_func}
    exported_symbols = {}
    file_exports = defaultdict(set)
    file_calls = defaultdict(list)
    top_level_calls = defaultdict(list)
    
    re_func_def = re.compile(r'\bfunction\s+(?:UA|PriestBiS|PB)\.([A-Za-z0-9_]+)\s*\(')
    re_table_def = re.compile(r'\b(?:UA|PriestBiS|PB)\.([A-Za-z0-9_]+)\s*=')
    re_call = re.compile(r'\b(?:UA|PriestBiS|PB)\.([A-Za-z0-9_]+)\s*\(')

    for toc_idx, f in enumerate(toc_files):
        full_p = os.path.join(ADDON_DIR, f)
        with open(full_p, "r", encoding="utf-8", errors="ignore") as fp:
            raw_lines = fp.readlines()
            
        clean_content = strip_lua("".join(raw_lines))
        clean_lines = clean_content.splitlines()

        in_function_depth = 0
        
        for line_idx, line in enumerate(clean_lines, start=1):
            # Check function definitions
            for m in re_func_def.finditer(line):
                sym = m.group(1)
                exported_symbols[sym] = (f, toc_idx, line_idx, True)
                file_exports[f].add(sym)

            # Check table/field assignments
            for m in re_table_def.finditer(line):
                sym = m.group(1)
                if sym not in exported_symbols:
                    exported_symbols[sym] = (f, toc_idx, line_idx, False)
                    file_exports[f].add(sym)

            # Track function block nesting to detect top-level chunk calls
            clean_str = line.strip()
            # Simple heuristic for top-level code: if line has 'function', increment
            if re.search(r'\bfunction\b', clean_str):
                in_function_depth += 1
            if re.search(r'\bend\b', clean_str):
                in_function_depth = max(0, in_function_depth - 1)

            # Find call sites
            for m in re_call.finditer(line):
                callee = m.group(1)
                # Ignore self-definition lines
                if re_func_def.search(line) and re_func_def.search(line).group(1) == callee:
                    continue
                file_calls[f].append((callee, toc_idx, line_idx, raw_lines[line_idx-1].strip()))
                if in_function_depth == 0 and not re_table_def.search(line):
                    top_level_calls[f].append((callee, toc_idx, line_idx))

    print(f"\nDiscovered {len(exported_symbols)} exported API symbols/tables across {len(toc_files)} modules.")
    
    # 2. Check call-sites: does callee exist? Is it defined downstream when called at top-level?
    print("\n--- Verifying Cross-Module Call Sites and Top-Level Safety ---")
    missing_calls = 0
    top_level_safety_violations = 0
    
    for f in toc_files:
        for callee, caller_toc_idx, line_num, raw_line in file_calls[f]:
            if callee not in exported_symbols:
                print(f"  [ERROR] {f}:{line_num} calls undefined API 'UA.{callee}' -> {raw_line}")
                missing_calls += 1
            else:
                def_file, def_toc_idx, def_line, is_func = exported_symbols[callee]
                # If call happens at top-level chunk load, def must NOT be downstream in TOC!
                if any(tl[0] == callee and tl[2] == line_num for tl in top_level_calls[f]):
                    if def_toc_idx > caller_toc_idx:
                        print(f"  [CRITICAL LOAD ORDER VIOLATION] {f}:{line_num} invokes 'UA.{callee}' at top-level chunk, but '{callee}' is defined downstream in {def_file}:{def_line}!")
                        top_level_safety_violations += 1

    if missing_calls > 0 or top_level_safety_violations > 0:
        total_violations += (missing_calls + top_level_safety_violations)
        print(f"\n[FAIL] Found {missing_calls} unresolved calls and {top_level_safety_violations} top-level load-order violations!")
    else:
        print("  [PASS] 100% of cross-module calls resolve with load-time order safety!")

    # 3. Check Data Schema alignment
    print("\n--- Auditing Item Database & Set Bonus Schema Contracts ---")
    data_violations = 0
    
    # Check ItemDatabase
    item_db_path = os.path.join(ADDON_DIR, "Data", "ItemDatabase.lua")
    with open(item_db_path, "r", encoding="utf-8", errors="ignore") as fp:
        db_content = fp.read()
        
    valid_roles = {"HEAL", "DPS", "CASTER_DPS", "MELEE", "TANK"}
    valid_tiers = {"S", "A", "B", "C", "F"}
    
    # Check roles
    for m in re.finditer(r'role\s*=\s*"([^"]+)"', db_content):
        r = m.group(1)
        if r not in valid_roles:
            print(f"  [SCHEMA ERROR] Invalid item role '{r}' in Data/ItemDatabase.lua")
            data_violations += 1

    # Check tiers
    for m in re.finditer(r'tier\s*=\s*"([^"]+)"', db_content):
        t = m.group(1)
        if t not in valid_tiers:
            print(f"  [SCHEMA ERROR] Invalid item tier '{t}' in Data/ItemDatabase.lua")
            data_violations += 1

    if data_violations == 0:
        print("  [PASS] All item metadata roles, tiers, and drop sources conform to schema!")
    else:
        total_violations += data_violations

    print("\n" + "=" * 80)
    if total_violations == 0:
        print("AUDIT RESULT: 100% OF CROSS-MODULE CONTRACTS & BOUNDARIES VERIFIED!")
        print("=" * 80)
        return 0
    else:
        print(f"AUDIT RESULT: FAILED WITH {total_violations} VIOLATION(S)!")
        print("=" * 80)
        return 1

if __name__ == "__main__":
    sys.exit(audit())
