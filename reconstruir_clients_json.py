#!/usr/bin/env python3
# -*- coding: utf-8 -*-
from __future__ import annotations
import os, re, json, csv, sys
from pathlib import Path

ROOT = Path(sys.argv[1]).resolve() if len(sys.argv) > 1 else Path(".").resolve()
IGNORE = {".git",".github","node_modules","pedido_assets","__pycache__"}

def code_from_name(name: str) -> str:
    m = re.search(r"(c[a-z0-9]{4,}|cpol\d+|ctln\d+|cgdl\d+|czpn\d+|ctjo\d+|cslp\d+|cags\d+|cpn\d+)", name, flags=re.I)
    return m.group(1).upper() if m else ""

def client_name_from_file(name: str, code: str) -> str:
    base = re.sub(r"\.html?$", "", name, flags=re.I)
    if code:
        base = re.sub(re.escape(code), "", base, flags=re.I)
    base = re.sub(r"[_\-]+$", "", base)
    base = base.replace("_", " ").replace("-", " ").strip()
    return re.sub(r"\s+", " ", base).upper()

def vendor_label(folder: str) -> str:
    if not folder or folder == ".":
        return "GENERAL"
    return folder.replace("_", " ").upper()

rows = []
for dirpath, dirnames, filenames in os.walk(ROOT):
    dirnames[:] = [d for d in dirnames if d not in IGNORE and not d.startswith(".")]
    rel = Path(dirpath).relative_to(ROOT)
    folder = "." if str(rel) == "." else str(rel).replace("\\", "/")
    top_folder = rel.parts[0] if rel.parts else ""
    for fn in filenames:
        if not fn.lower().endswith(".html"): 
            continue
        if fn.lower() == "index.html":
            continue
        path = fn if folder == "." else f"{folder}/{fn}"
        code = code_from_name(fn)
        rows.append({
            "vendor_folder": top_folder or "",
            "vendor_label": vendor_label(top_folder),
            "client_name": client_name_from_file(fn, code),
            "client_code": code,
            "path": path
        })

rows.sort(key=lambda r: (r["vendor_label"], r["client_name"], r["client_code"], r["path"]))

(ROOT / "clients.json").write_text(json.dumps(rows, ensure_ascii=False, indent=2), encoding="utf-8")

with (ROOT / "validacion_rutas_case.csv").open("w", newline="", encoding="utf-8-sig") as f:
    w = csv.writer(f)
    w.writerow(["vendor_folder","vendor_label","client_name","client_code","path"])
    for r in rows:
        w.writerow([r["vendor_folder"], r["vendor_label"], r["client_name"], r["client_code"], r["path"]])

print(f"clients.json generado con {len(rows)} rutas exactas.")
