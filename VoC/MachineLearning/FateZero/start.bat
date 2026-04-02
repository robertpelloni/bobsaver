@echo off



set PYTHONUNBUFFERED=TRUE
set PYTHONLEGACYWINDOWSSTDIO=utf-8




call .venv\scripts\activate.bat
cd FateZero
python app_fatezero.py
