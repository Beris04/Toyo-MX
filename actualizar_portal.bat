@echo off
cd /d "%~dp0"
echo ==========================================
echo TOYO MX - APLICAR ACTUALIZACION TOTAL V4
echo ==========================================
where py >nul 2>nul
if %errorlevel%==0 (
  py aplicar_actualizacion_total.py
  goto end
)
where python >nul 2>nul
if %errorlevel%==0 (
  python aplicar_actualizacion_total.py
  goto end
)
echo No se encontro Python en este equipo.
echo Instala Python o ejecuta el script manualmente.
:end
echo.
pause
