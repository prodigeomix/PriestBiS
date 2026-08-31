#!/usr/bin/env python3
"""
tools/validate_lua50.py
=======================
Strict Lua 5.0 and WoW 1.12.1 / Turtle WoW 1.18.1 Compatibility Validator.
Scans all .lua files for post-Lua 5.0 syntax and modern WoW APIs.
"""

import os
import re
import sys

if sys.platform == "win32":
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
ADDON_DIR = os.path.abspath(os.path.join(SCRIPT_DIR, ".."))

BANNED_PATTERNS = [
    (r'(?<![A-Za-z0-9_])#\s*[A-Za-z0-9_\{\(\"\']', "Length operator '#' (Lua 5.1+). Use 'table.getn(t)' or 'string.len(s)'."),
    (r'(?<![A-Za-z0-9_])//(?![A-Za-z0-9_])', "Integer division operator '//' (Lua 5.3+). Use 'math.floor(a / b)'."),
    (r'\bgoto\s+[A-Za-z0-9_]+', "'goto' statement (Lua 5.2+)."),
    (r'::[A-Za-z0-9_]+::', "Label marker '::label::' (Lua 5.2+)."),
    (r'\bstring\.match\b', "'string.match' (Lua 5.1+). Use 'string.find' with capture indices."),
    (r'\bstring\.gmatch\b', "'string.gmatch' (Lua 5.1+). Use 'string.gfind'."),
    (r'\btable\.unpack\b', "'table.unpack' (Lua 5.1+). Use global 'unpack()'."),
    (r'\btable\.pack\b', "'table.pack' (Lua 5.1+)."),
    (r'\bmath\.huge\b', "'math.huge' (Lua 5.1+). Use '1/0' or 999999."),
    (r'\bhooksecurefunc\b', "'hooksecurefunc' (WoW 2.0+). Use classic function detouring."),
    (r':HookScript\b', "':HookScript' (WoW 2.0+). Use standard 1.12 hook assignment."),
    (r'\bC_[A-Za-z0-9_]+\b', "Modern WoW API namespace 'C_*' (WoW 6.0+ / Retail)."),
]

def strip_comments_and_strings(code):
    lines = code.split('\n')
    cleaned_lines = []
    in_block_comment = False
    for line in lines:
        if in_block_comment:
            if '--]]' in line:
                in_block_comment = False
                line = line[line.find('--]]') + 4:]
            else:
                cleaned_lines.append('')
                continue
        if '--[[' in line:
            in_block_comment = True
            line = line[:line.find('--[[')]
            
        # Remove single line comments
        comment_idx = line.find('--')
        if comment_idx != -1:
            line = line[:comment_idx]
            
        # Replace string contents with empty quotes to preserve line structure
        line = re.sub(r'"[^"\\]*(?:\\.[^"\\]*)*"', '""', line)
        line = re.sub(r"'[^'\\]*(?:\\.[^'\\]*)*'", "''", line)
        cleaned_lines.append(line)
    return cleaned_lines

def validate_file(filepath):
    if not os.path.exists(filepath):
        print(f"Error: File '{filepath}' does not exist.")
        return False

    with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
        content = f.read()

    cleaned_lines = strip_comments_and_strings(content)
    violations = []

    for line_num, line in enumerate(cleaned_lines, start=1):
        for pattern, description in BANNED_PATTERNS:
            if re.search(pattern, line):
                original_line = content.split('\n')[line_num - 1].strip()
                violations.append((line_num, original_line, description))

    rel = os.path.relpath(filepath, ADDON_DIR)
    if violations:
        print(f"\n[FAIL] {rel} has {len(violations)} Lua 5.0 / WoW 1.12 compatibility issue(s):")
        for line_num, code_snippet, desc in violations:
            print(f"  Line {line_num}: {desc}")
            print(f"    Code: {code_snippet}")
        return False
    else:
        print(f"  [PASS] {rel} (strict Lua 5.0 compliant)")
        return True

def main():
    print("Scanning PriestBiS Lua files for strict Lua 5.0 & WoW 1.12 compliance...")
    all_passed = True
    lua_files = []
    for root, _, files in os.walk(ADDON_DIR):
        for file in files:
            if file.endswith('.lua') and not file.startswith('validate_lua.'):
                lua_files.append(os.path.join(root, file))
                
    for f in sorted(lua_files):
        if not validate_file(f):
            all_passed = False
            
    if all_passed:
        print(f"\nAll {len(lua_files)} files passed strict Lua 5.0 compatibility verification!")
        sys.exit(0)
    else:
        print("\nLua 5.0 compatibility verification failed!")
        sys.exit(1)

if __name__ == "__main__":
    main()
