#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Reconstruye clients.json respetando EXACTAMENTE mayúsculas/minúsculas
de carpetas y archivos HTML existentes en el repo.

Uso:
    python reconstruir_clients_json.py
o
    python reconstruir_clients_json.py /ruta/al/repo

Salida:
    - clients.json
    - validacion_rutas.csv
"""

from __future__ import annotations
import os
import re
import json
import csv
import sys
from pathlib import Path

ROOT = Path(sys.argv[1]).resolve() if len(sys.argv) > 1 else Path(".").resolve()

IGNORAR_CARPETAS = {
    ".git", ".github", "node_modules", "pedido_assets", "__pycache__"
}

def slugify(texto: str) -> str:
    texto = texto.strip().lower()
    texto = texto.replace("&", " y ")
    texto = re.sub(r"[^a-z0-9áéíóúüñ]+", "_", texto, flags=re.IGNORECASE)
    texto = re.sub(r"_+", "_", texto).strip("_")
    return texto

def extraer_codigo(nombre_archivo: str) -> str:
    m = re.search(r"(c\d{4,})", nombre_archivo, flags=re.IGNORECASE)
    return m.group(1).upper() if m else ""

def extraer_nombre_cliente(nombre_archivo: str, codigo: str) -> str:
    base = re.sub(r"\.html?$", "", nombre_archivo, flags=re.IGNORECASE)
    if codigo:
        base = re.sub(re.escape(codigo), "", base, flags=re.IGNORECASE)
    base = re.sub(r"[_\-]+$", "", base)
    base = base.replace("_", " ").replace("-", " ").strip()
    return re.sub(r"\s+", " ", base).upper()

def nombre_vendedor_desde_carpeta(carpeta: str) -> str:
    # Ejemplo: gdl3_maricela_reynoso -> GDL3 · MARICELA REYNOSO
    partes = carpeta.split("_")
    if not partes:
        return carpeta.upper()
    if len(partes) == 1:
        return carpeta.upper()
    return f"{partes[0].upper()} · {' '.join(partes[1:]).upper()}"

def iterar_htmls(root: Path):
    for dirpath, dirnames, filenames in os.walk(root):
        # excluir carpetas
        dirnames[:] = [d for d in dirnames if d not in IGNORAR_CARPETAS and not d.startswith(".")]
        carpeta_actual = Path(dirpath)
        rel_carpeta = carpeta_actual.relative_to(root)
        for fn in filenames:
            if fn.lower().endswith(".html"):
                if fn.lower() == "index.html":
                    continue
                yield rel_carpeta, fn

def construir_registros(root: Path):
    registros = []
    for rel_carpeta, fn in iterar_htmls(root):
        carpeta = "." if str(rel_carpeta) == "." else str(rel_carpeta).replace("\\", "/")
        ruta = f"{carpeta}/{fn}" if carpeta != "." else fn
        codigo = extraer_codigo(fn)
        nombre = extraer_nombre_cliente(fn, codigo)
        vendedor = nombre_vendedor_desde_carpeta(rel_carpeta.parts[0]) if rel_carpeta.parts else "GENERAL"
        registros.append({
            "client_code": codigo,
            "client_name": nombre,
            "seller_name": vendedor,
            "folder": carpeta,
            "file_name": fn,
            "path": ruta
        })
    # ordenar
    registros.sort(key=lambda x: (
        x["seller_name"],
        x["client_name"],
        x["client_code"],
        x["file_name"]
    ))
    return registros

def guardar_json(root: Path, registros):
    payload = {
        "generated_from_repo": True,
        "respect_exact_case": True,
        "total_clients": len(registros),
        "clients": registros
    }
    out = root / "clients.json"
    out.write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8")
    return out

def guardar_csv(root: Path, registros):
    out = root / "validacion_rutas.csv"
    with out.open("w", newline="", encoding="utf-8-sig") as f:
        w = csv.writer(f)
        w.writerow(["client_code", "client_name", "seller_name", "folder", "file_name", "path"])
        for r in registros:
            w.writerow([
                r["client_code"], r["client_name"], r["seller_name"],
                r["folder"], r["file_name"], r["path"]
            ])
    return out

def main():
    registros = construir_registros(ROOT)
    json_path = guardar_json(ROOT, registros)
    csv_path = guardar_csv(ROOT, registros)
    print(f"OK - clients.json generado: {json_path}")
    print(f"OK - validacion_rutas.csv generado: {csv_path}")
    print(f"Total registros: {len(registros)}")

if __name__ == "__main__":
    main()
