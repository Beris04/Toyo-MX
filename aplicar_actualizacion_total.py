#!/usr/bin/env python3
# -*- coding: utf-8 -*-
from __future__ import annotations
import os, re, json, csv, sys
from pathlib import Path

ROOT = Path(".").resolve()
IGNORE_DIRS = {".git", ".github", "node_modules", "__pycache__"}

VERSION = "2026-05-05-v4"

def update_html_asset_refs(root: Path):
    updated = 0
    scanned = 0
    changed_files = []
    for dirpath, dirnames, filenames in os.walk(root):
        dirnames[:] = [d for d in dirnames if d not in IGNORE_DIRS and not d.startswith(".")]
        for fn in filenames:
            if not fn.lower().endswith(".html"):
                continue
            path = Path(dirpath) / fn
            try:
                text = path.read_text(encoding="utf-8")
            except Exception:
                try:
                    text = path.read_text(encoding="utf-8-sig")
                except Exception:
                    continue
            original = text
            # preserve relative prefixes and only swap basename + add version
            text = re.sub(
                r'(href=["\'][^"\']*pedido_assets/)pedido_app(?:_v\d+)?\.css(?:\?v=[^"\']*)?(["\'])',
                r'\1pedido_app_v4.css?v=' + VERSION + r'\2',
                text,
                flags=re.I
            )
            text = re.sub(
                r'(src=["\'][^"\']*pedido_assets/)pedido_app(?:_v\d+)?\.js(?:\?v=[^"\']*)?(["\'])',
                r'\1pedido_app_v4.js?v=' + VERSION + r'\2',
                text,
                flags=re.I
            )
            if text != original:
                path.write_text(text, encoding="utf-8")
                updated += 1
                changed_files.append(str(path.relative_to(root)).replace("\\","/"))
            scanned += 1
    return scanned, updated, changed_files

def code_from_name(name: str) -> str:
    m = re.search(r'((?:c|cpol|ctln|cgdl|czpn|ctjo|cslp|cags|cpn)[a-z0-9]+)', name, flags=re.I)
    return m.group(1).upper() if m else ""

def client_name_from_file(name: str, code: str) -> str:
    base = re.sub(r'\.html?$', '', name, flags=re.I)
    if code:
        base = re.sub(re.escape(code), '', base, flags=re.I)
    base = re.sub(r'[_\-]+$', '', base)
    base = base.replace('_', ' ').replace('-', ' ').strip()
    base = re.sub(r'\s+', ' ', base)
    return base.upper()

def vendor_label(folder: str) -> str:
    if not folder:
        return "GENERAL"
    return folder.replace("_", " ").upper()

def rebuild_clients_json(root: Path):
    rows = []
    for dirpath, dirnames, filenames in os.walk(root):
        dirnames[:] = [d for d in dirnames if d not in IGNORE_DIRS and d != "pedido_assets" and not d.startswith(".")]
        rel = Path(dirpath).relative_to(root)
        folder = "." if str(rel) == "." else str(rel).replace("\\","/")
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
    (root / "clients.json").write_text(json.dumps(rows, ensure_ascii=False, indent=2), encoding="utf-8")
    with (root / "validacion_rutas_case.csv").open("w", newline="", encoding="utf-8-sig") as f:
        w = csv.writer(f)
        w.writerow(["vendor_folder","vendor_label","client_name","client_code","path"])
        for r in rows:
            w.writerow([r["vendor_folder"], r["vendor_label"], r["client_name"], r["client_code"], r["path"]])
    return len(rows)

def main():
    scanned, updated, changed = update_html_asset_refs(ROOT)
    total_clients = rebuild_clients_json(ROOT)
    log = ROOT / "patch_actualizacion_log.txt"
    lines = [
        f"VERSION={VERSION}",
        f"HTML_ESCANEADOS={scanned}",
        f"HTML_ACTUALIZADOS={updated}",
        f"CLIENTES_EN_CLIENTS_JSON={total_clients}",
        "",
        "ARCHIVOS_HTML_ACTUALIZADOS:",
        *changed[:500]
    ]
    log.write_text("\n".join(lines), encoding="utf-8")
    print("OK")
    print(f"HTML escaneados: {scanned}")
    print(f"HTML actualizados: {updated}")
    print(f"Clientes en clients.json: {total_clients}")
    print("Se generaron:")
    print("- clients.json")
    print("- validacion_rutas_case.csv")
    print("- patch_actualizacion_log.txt")

if __name__ == "__main__":
    main()
