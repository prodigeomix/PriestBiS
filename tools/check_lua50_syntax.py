#!/usr/bin/env python3
"""
tools/check_lua50_syntax.py
===========================
Deterministic Native Lua 5.0.3 Bytecode & Syntax Compiler Gate.
Executes the vendored native Lua 5.0.3 compiler ('luac50.exe -p') across all
registered addon Lua source files to guarantee complete syntax, grammar,
and token compliance directly against the target runtime.

Usage:
  python tools/check_lua50_syntax.py
Exits with 0 if all files compile cleanly, 1 if any syntax error is detected.
"""

import os
import re
import subprocess
import sys

if sys.platform == "win32":
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
ADDON_ROOT = os.path.abspath(os.path.join(SCRIPT_DIR, ".."))
LUAC_BIN = os.path.join(SCRIPT_DIR, "bin", "lua50", "luac50.exe")

IGNORE_SUBDIRS = ["bcc", "libs/bcc", "src/bcc", "tests", "examples", ".git", "tools"]

def normalize_path(p):
    return os.path.normpath(p).replace("\\", "/")

def should_ignore(rel_path):
    n = normalize_path(rel_path).lower()
    for ig in IGNORE_SUBDIRS:
        if ig in n:
            return True
    return False

def discover_lua_files():
    toc_files = [f for f in os.listdir(ADDON_ROOT) if f.endswith(".toc")]
    discovered = []
    seen = set()

    def add_file(p):
        norm = normalize_path(p)
        if norm not in seen and os.path.exists(p) and p.endswith(".lua"):
            rel = os.path.relpath(p, ADDON_ROOT)
            if not should_ignore(rel):
                seen.add(norm)
                discovered.append(p)

    def parse_xml(xml_path):
        if not os.path.exists(xml_path):
            return
        try:
            with open(xml_path, "r", encoding="utf-8", errors="replace") as f:
                content = f.read()
            # Match <Script file="..."/>
            for m in re.finditer(r'<Script\s+file="([^"]+)"', content, re.IGNORECASE):
                sub_path = os.path.normpath(os.path.join(os.path.dirname(xml_path), m.group(1)))
                add_file(sub_path)
            # Match <Include file="..."/>
            for m in re.finditer(r'<Include\s+file="([^"]+)"', content, re.IGNORECASE):
                sub_xml = os.path.normpath(os.path.join(os.path.dirname(xml_path), m.group(1)))
                if sub_xml.endswith(".xml"):
                    parse_xml(sub_xml)
        except Exception as e:
            pass

    for toc in toc_files:
        toc_path = os.path.join(ADDON_ROOT, toc)
        with open(toc_path, "r", encoding="utf-8", errors="replace") as f:
            for line in f:
                line = line.strip()
                if not line or line.startswith("#"):
                    continue
                full_p = os.path.normpath(os.path.join(ADDON_ROOT, line))
                if line.endswith(".lua"):
                    add_file(full_p)
                elif line.endswith(".xml"):
                    parse_xml(full_p)

    # If no TOC files or TOC had no Lua files, scan directory
    if not discovered:
        for root, dirs, files in os.walk(ADDON_ROOT):
            rel_dir = os.path.relpath(root, ADDON_ROOT)
            if should_ignore(rel_dir):
                continue
            for f in files:
                if f.endswith(".lua"):
                    full_p = os.path.join(root, f)
                    add_file(full_p)

    return discovered

def main():
    print("=" * 76)
    print("NATIVE LUA 5.0.3 COMPILER SYNTAX AUDIT (luac50.exe -p)")
    print("=" * 76)

    if not os.path.exists(LUAC_BIN):
        print(f"FATAL: Native Lua 5.0 compiler not found at: {LUAC_BIN}")
        sys.exit(1)

    files = discover_lua_files()
    if not files:
        print("WARNING: No Lua files found to audit.")
        sys.exit(0)

    print(f"Discovered {len(files)} Lua source file(s) for compilation audit.\n")

    failures = []
    for f in files:
        rel = os.path.relpath(f, ADDON_ROOT)
        res = subprocess.run([LUAC_BIN, "-p", f], capture_output=True, text=True, encoding="utf-8", errors="replace")
        if res.returncode != 0:
            err = (res.stderr or res.stdout or "").strip()
            failures.append((rel, err))
            print(f"  [FAIL] {rel}")
            for l in err.splitlines():
                print(f"         {l}")
        else:
            # OK
            pass

    print("\n" + "=" * 76)
    if failures:
        print(f"RESULT: FAILED ({len(failures)}/{len(files)} files failed Lua 5.0 compilation)")
        print("=" * 76)
        sys.exit(1)
    else:
        print(f"RESULT: PASSED (All {len(files)} Lua files compiled cleanly with 0 errors)")
        print("=" * 76)
        sys.exit(0)

if __name__ == "__main__":
    main()
