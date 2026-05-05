@echo off
cd /d "%~dp0"
powershell -ExecutionPolicy Bypass -File "%~dp0aplicar_actualizacion_total.ps1"
