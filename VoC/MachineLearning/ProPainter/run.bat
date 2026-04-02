@echo off
set PYTHONUNBUFFERED=TRUE
set PYTHONIOENCODING=utf-8
set PYTHONLEGACYWINDOWSSTDIO=utf-8
cd ProPainter-Webui
call venv\scripts\activate.bat
python app.py