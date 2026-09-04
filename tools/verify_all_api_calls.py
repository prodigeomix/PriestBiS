#!/usr/bin/env python3
"""
tools/verify_all_api_calls.py
=============================
Call-graph verification: scans PriestBiS Lua files for all UA.* / PriestBiS.*
function call sites and ensures 100% resolution against actual definitions.
"""

import os
import re
import sys

if sys.platform == "win32":
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
ADDON_DIR = os.path.abspath(os.path.join(SCRIPT_DIR, ".."))

def main():
    print("Verifying internal API call resolution in PriestBiS across all modules...")

    lua_files = []
    for root, _, files in os.walk(ADDON_DIR):
        if "tools" in root or ".git" in root:
            continue
        for f in files:
            if f.endswith('.lua'):
                lua_files.append(os.path.join(root, f))

    # 1. Collect all defined functions and tables in UA / PriestBiS
    defined_funcs = set()
    for filepath in lua_files:
        with open(filepath, "r", encoding="utf-8", errors="ignore") as f:
            content = f.read()
        for m in re.finditer(r'function\s+(?:UA|PriestBiS|PB)\.([A-Za-z0-9_]+)\s*\(', content):
            defined_funcs.add(m.group(1))
        for m in re.finditer(r'(?:UA|PriestBiS|PB)\.([A-Za-z0-9_]+)\s*=', content):
            defined_funcs.add(m.group(1))

    print(f"Found {len(defined_funcs)} defined API functions / data tables across {len(lua_files)} modules.")

    # 2. Collect all call sites like UA.FunctionName( or PriestBiS.FunctionName(
    call_sites = []
    for filepath in lua_files:
        rel = os.path.relpath(filepath, ADDON_DIR)
        with open(filepath, "r", encoding="utf-8", errors="ignore") as f:
            lines = f.read().splitlines()
        for line_idx, line in enumerate(lines, start=1):
            clean_line = line.split('--')[0]
            # Ignore definitions
            if re.search(r'function\s+(?:UA|PriestBiS|PB)\.', clean_line):
                continue
            for m in re.finditer(r'(?:UA|PriestBiS|PB)\.([A-Za-z0-9_]+)\s*\(', clean_line):
                func_name = m.group(1)
                call_sites.append((rel, line_idx, func_name, clean_line.strip()))

    print(f"Found {len(call_sites)} API call sites.")

    unresolved = []
    for rel, line_idx, func_name, snippet in call_sites:
        if func_name not in defined_funcs:
            unresolved.append((rel, line_idx, func_name, snippet))

    if unresolved:
        print(f"\n[FAIL] Found {len(unresolved)} unresolved API call(s):")
        for rel, line_idx, func_name, snippet in unresolved:
            print(f"  {rel}:{line_idx}: '{func_name}' is called but not defined!")
            print(f"    Code: {snippet}")
        sys.exit(1)
    else:
        print("\nAll API call sites resolved with 100% accuracy across all modules!")
        sys.exit(0)

if __name__ == "__main__":
    main()
