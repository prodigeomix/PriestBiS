#!/usr/bin/env python3
"""
tools/check_lua.py
==================
Validates block balance (function, if, do, for, while, repeat vs end, until)
across all PriestBiS Lua files.
"""

import os
import re
import sys

if sys.platform == "win32":
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
ADDON_DIR = os.path.abspath(os.path.join(SCRIPT_DIR, ".."))

def check_blocks(filepath):
    if not os.path.exists(filepath):
        print(f"Error: File '{filepath}' not found.")
        return False
        
    with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
        content = f.read()
    
    # Strip multiline comments
    content = re.sub(r'--\[\[.*?\]\]', '', content, flags=re.DOTALL)
    # Strip single line comments
    content = re.sub(r'--.*', '', content)
    # Strip single and double quoted strings (newline-restricted)
    content = re.sub(r'"(?:[^"\\\n]|\\.)*"|\'(?:[^\'\\\n]|\\.)*\'', '""', content)

    stack = []
    lines = content.split('\n')
    
    for line_idx, line in enumerate(lines, start=1):
        for m in re.finditer(r'\b(function|do|while|repeat|end|until)\b|(?<!else)\bif\b', line):
            t = m.group(0)
            if t in ['function', 'if', 'do', 'while', 'repeat']:
                stack.append((t, line_idx))
            elif t == 'end':
                if not stack:
                    print(f"  Unmatched 'end' at line {line_idx} in {filepath}")
                    return False
                top_token, top_line = stack.pop()
                if top_token == 'repeat':
                    print(f"  Mismatched 'end' for 'repeat' at line {line_idx} (opened line {top_line})")
                    return False
            elif t == 'until':
                if not stack:
                    print(f"  Unmatched 'until' at line {line_idx} in {filepath}")
                    return False
                top_token, top_line = stack.pop()
                if top_token != 'repeat':
                    print(f"  Mismatched 'until' for '{top_token}' at line {line_idx} (opened line {top_line})")
                    return False
                    
    if stack:
        print(f"  Unclosed blocks in {filepath}: {stack}")
        return False
    return True

def main():
    print("Checking Lua block balance across PriestBiS files...")
    lua_files = []
    for root, _, files in os.walk(ADDON_DIR):
        for f in files:
            if f.endswith('.lua'):
                lua_files.append(os.path.join(root, f))
                
    all_ok = True
    for filepath in sorted(lua_files):
        rel = os.path.relpath(filepath, ADDON_DIR)
        print(f"  Verifying {rel}...")
        if not check_blocks(filepath):
            all_ok = False
            
    if all_ok:
        print(f"\nAll {len(lua_files)} Lua files have balanced syntax blocks!")
        sys.exit(0)
    else:
        print("\nBlock balance verification failed!")
        sys.exit(1)

if __name__ == "__main__":
    main()
