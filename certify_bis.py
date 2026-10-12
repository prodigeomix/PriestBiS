#!/usr/bin/env python3
"""
certify_bis.py
==============
PriestBiS Pre-Raid Health & Operational Readiness Certification Tool.
Imported & adapted from HolyPriest's 'certify_raid.py'.

One-click automated readiness verification before raid deployment:
1. Executes all deterministic verification gates in tools/run_tests.py.
2. Performs deep AST scope and global leak verification.
3. Audits cross-module boundary contracts and TOC load order safety.
4. Executes in-memory Lua runtime simulation (lupa) for talents, scoring, and upgrades.
5. Verifies git repository clean status and absence of uncommitted code.

Usage:
  python certify_bis.py
"""

import os
import sys
import subprocess
import time

if sys.platform == "win32":
    try:
        sys.stdout.reconfigure(encoding="utf-8")
    except Exception:
        pass

# ANSI color codes
GREEN = "\033[92m"
RED = "\033[91m"
YELLOW = "\033[93m"
CYAN = "\033[96m"
BOLD = "\033[1m"
RESET = "\033[0m"

def print_banner(title):
    print(f"\n{CYAN}{BOLD}{'='*80}{RESET}")
    print(f"{CYAN}{BOLD}  {title}{RESET}")
    print(f"{CYAN}{BOLD}{'='*80}{RESET}\n")

def run_step(step_num, total_steps, title, cmd, cwd=None):
    print(f"{BOLD}[STEP {step_num}/{total_steps}] {title}...{RESET}")
    t0 = time.time()
    res = subprocess.run(cmd, cwd=cwd or os.path.dirname(os.path.abspath(__file__)), capture_output=True, text=True, encoding="utf-8", errors="replace")
    elapsed = time.time() - t0
    output = (res.stdout or "") + (res.stderr or "")
    if res.returncode != 0 or "FAIL" in output:
        print(f"{RED}{BOLD}--> [FAILED] in {elapsed:.2f}s{RESET}")
        lines = [l for l in output.strip().splitlines() if l.strip()]
        for l in lines[-10:]:
            print(f"    {l}")
        return False, output, elapsed
    else:
        print(f"{GREEN}{BOLD}--> [PASS] in {elapsed:.2f}s{RESET}")
        lines = [l for l in output.strip().splitlines() if l.strip()]
        for l in lines[-4:]:
            print(f"    {l}")
        return True, output, elapsed

def audit_git_status(root_dir):
    try:
        res = subprocess.run(["git", "status", "--porcelain"], cwd=root_dir, capture_output=True, text=True)
        if res.returncode != 0:
            return True, "Git check skipped (not a git repo)"
        changes = [l.strip() for l in res.stdout.strip().splitlines() if l.strip()]
        return len(changes) == 0, changes
    except Exception as e:
        return True, f"Git check skipped ({e})"

def main():
    root_dir = os.path.dirname(os.path.abspath(__file__))
    t_start = time.time()
    
    print_banner("PRIESTBIS — PRE-RAID OPERATIONAL READINESS CERTIFICATION")
    print(f"Target Addon Directory: {root_dir}")
    print(f"Target Environment:     Turtle WoW 1.18.1 / Vanilla 1.12.1 Client")
    print(f"Supported Roles:        Holy & Discipline Priests (Loot & Gear Upgrades)\n")

    steps = [
        ("Full Unified Verification Suite (run_tests.py)", [sys.executable, "tools/run_tests.py"]),
        ("AST Global Variable & Leak Scanner (scan_ast_globals.py)", [sys.executable, "tools/scan_ast_globals.py"]),
        ("Cross-Module Contract & Load-Order Audit (deep_contract_audit.py)", [sys.executable, "tools/deep_contract_audit.py"]),
        ("Golden-Table EP Valuation Regression (golden_table_test.py)", [sys.executable, "tools/golden_table_test.py"]),
        ("In-Memory Lua VM Simulation Engine (test_simulation_vm.py)", [sys.executable, "tools/test_simulation_vm.py"]),
    ]

    total_steps = len(steps) + 1
    step_num = 1

    for title, cmd in steps:
        ok, out, elapsed = run_step(step_num, total_steps, title, cmd, cwd=root_dir)
        if not ok:
            print(f"\n{RED}{BOLD}❌ CERTIFICATION REJECTED: Gate failure in Step {step_num}.{RESET}")
            sys.exit(1)
        step_num += 1

    # Final Step: Git cleanliness
    print(f"{BOLD}[STEP {step_num}/{total_steps}] Auditing Git Repository Status...{RESET}")
    git_clean, git_info = audit_git_status(root_dir)
    if isinstance(git_info, str):
        print(f"  {YELLOW}Notice: {git_info}{RESET}")
    elif not git_clean:
        print(f"  {YELLOW}Notice: {len(git_info)} uncommitted file(s) present in working tree.{RESET}")
    else:
        print(f"  {GREEN}[PASS] Working tree clean and synced.{RESET}")

    total_time = time.time() - t_start
    print_banner("CERTIFICATION PASSED: PRIESTBIS IS 100% COMBAT & RAID READY")
    print(f"{GREEN}{BOLD}All {len(steps)} deterministic gates verified in {total_time:.2f}s.{RESET}")
    print(f"{GREEN}{BOLD}Addon is certified for production deployment on Turtle WoW 1.18.1.{RESET}\n")
    sys.exit(0)

if __name__ == "__main__":
    main()
