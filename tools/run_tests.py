#!/usr/bin/env python3
"""
tools/run_tests.py
==================
PriestBiS Unified Automated Verification Suite Runner.

Executes all static analysis, Lua 5.0 compatibility, global scope, API resolution,
multi-language regex patterns, database integrity, and Lua functional simulation tests:
1. tools/check_lua.py             (Block balance across all Lua files)
2. tools/validate_lua50.py        (Strict Lua 5.0 syntax & operator compliance)
3. tools/scan_global_leaks.py     (Global variable and scope leak detection)
4. tools/test_gear_patterns.py    (Multi-locale gear tooltip pattern regressions)
5. tools/verify_all_api_calls.py  (100% call-site resolution against definitions)
6. tools/validate_item_database.py(Item metadata, stat weights & set bonus integrity)
7. tools/validate_lua.lua         (Standalone TOC load & syntax verification)
8. tools/test_priest_bis.lua      (Full functional simulation & multi-language test suite)
9. tools/test_performance.lua     (CPU profiling, memoization & performance benchmarks)

Returns exit code 0 if all checks pass, 1 if any check fails.
"""

import os
import sys
import subprocess
import time

if sys.platform == "win32":
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
ADDON_ROOT = os.path.abspath(os.path.join(SCRIPT_DIR, ".."))

CHECKS = [
    ("Block Balance (check_lua.py)", [sys.executable, os.path.join(SCRIPT_DIR, "check_lua.py")]),
    ("Lua 5.0 Compliance (validate_lua50.py)", [sys.executable, os.path.join(SCRIPT_DIR, "validate_lua50.py")]),
    ("Global Scope Leaks (scan_global_leaks.py)", [sys.executable, os.path.join(SCRIPT_DIR, "scan_global_leaks.py")]),
    ("Multi-Locale Patterns (test_gear_patterns.py)", [sys.executable, os.path.join(SCRIPT_DIR, "test_gear_patterns.py")]),
    ("API Call Resolution (verify_all_api_calls.py)", [sys.executable, os.path.join(SCRIPT_DIR, "verify_all_api_calls.py")]),
    ("Database Integrity (validate_item_database.py)", [sys.executable, os.path.join(SCRIPT_DIR, "validate_item_database.py")]),
    ("TOC Syntax Validator (validate_lua.lua)", ["lua", os.path.join(SCRIPT_DIR, "validate_lua.lua")]),
    ("Simulation Suite (test_priest_bis.lua)", ["lua", os.path.join(SCRIPT_DIR, "test_priest_bis.lua")]),
    ("Performance Benchmark (test_performance.lua)", ["lua", os.path.join(SCRIPT_DIR, "test_performance.lua")]),
]

def main():
    print("=" * 80)
    print("PRIESTBIS AUTOMATED VERIFICATION SUITE")
    print("=" * 80)
    
    total_start = time.time()
    all_passed = True
    results = []

    for name, cmd in CHECKS:
        print(f"\n>>> Running {name}...")
        start_t = time.time()
        res = subprocess.run(cmd, cwd=ADDON_ROOT, capture_output=True, text=True, encoding="utf-8", errors="replace")
        duration = time.time() - start_t
        
        output = (res.stdout or "") + (res.stderr or "")
        lines = [l for l in output.strip().splitlines() if l.strip()]
        for l in lines[-6:]:
            print(f"    {l}")
            
        passed = (res.returncode == 0) and ("FAIL" not in output)
        if not passed:
            all_passed = False
            results.append((name, "FAIL", duration))
            print(f"    --> [FAIL] Exit code: {res.returncode}")
        else:
            results.append((name, "PASS", duration))
            print(f"    --> [PASS] ({duration:.2f}s)")

    print("\n" + "=" * 80)
    print("SUITE EXECUTION SUMMARY")
    print("=" * 80)
    for name, status, duration in results:
        indicator = "[PASS]" if status == "PASS" else "[FAIL]"
        print(f"  {indicator:<8} {name:<48} ({duration:.2f}s)")

    total_time = time.time() - total_start
    print("-" * 80)
    if all_passed:
        print(f"OVERALL RESULT: ALL {len(CHECKS)} CHECKS PASSED (Total time: {total_time:.2f}s)")
        print("=" * 80)
        sys.exit(0)
    else:
        print(f"OVERALL RESULT: VERIFICATION FAILED (Total time: {total_time:.2f}s)")
        print("=" * 80)
        sys.exit(1)

if __name__ == "__main__":
    main()
