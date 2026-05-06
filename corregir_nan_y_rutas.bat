@echo off
cd /d "%~dp0"
powershell -ExecutionPolicy Bypass -File "%~dp0corregir_nan_y_rutas.ps1"
