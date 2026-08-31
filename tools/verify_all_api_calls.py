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
    print("Verifying internal API call resolution in PriestBiS...")

    main_lua = os.path.join(ADDON_DIR, "PriestBiS.lua")
    with open(main_lua, "r", encoding="utf-8", errors="ignore") as f:
        content = f.read()

    # 1. Collect all defined functions in UA / PriestBiS
    defined_funcs = set()
    for m in re.finditer(r'function\s+(?:UA|PriestBiS|PB)\.([A-Za-z0-9_]+)\s*\(', content):
        defined_funcs.add(m.group(1))

    # Also include standard tables and properties
    for m in re.finditer(r'(?:UA|PriestBiS|PB)\.([A-Za-z0-9_]+)\s*=', content):
        defined_funcs.add(m.group(1))

    print(f"Found {len(defined_funcs)} defined API functions / data tables in PriestBiS.lua.")

    # 2. Collect all call sites like UA.FunctionName( or PriestBiS.FunctionName(
    call_sites = []
    lines = content.splitlines()
    for line_idx, line in enumerate(lines, start=1):
        clean_line = line.split('--')[0]
        # Ignore definitions
        if re.search(r'function\s+(?:UA|PriestBiS|PB)\.', clean_line):
            continue
        for m in re.finditer(r'(?:UA|PriestBiS|PB)\.([A-Za-z0-9_]+)\s*\(', clean_line):
            func_name = m.group(1)
            call_sites.append((line_idx, func_name, clean_line.strip()))

    print(f"Found {len(call_sites)} API call sites.")

    unresolved = []
    for line_idx, func_name, snippet in call_sites:
        if func_name not in defined_funcs:
            unresolved.append((line_idx, func_name, snippet))

    if unresolved:
        print(f"\n[FAIL] Found {len(unresolved)} unresolved API call(s):")
        for line_idx, func_name, snippet in unresolved:
            print(f"  Line {line_idx}: '{func_name}' is called but not defined!")
            print(f"    Code: {snippet}")
        sys.exit(1)
    else:
        print("\nAll API call sites resolved with 100% accuracy!")
        sys.exit(0)

if __name__ == "__main__":
    main()
