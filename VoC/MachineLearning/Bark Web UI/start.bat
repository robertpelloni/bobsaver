@echo off


set PYTHONIOENCODING=utf-8
set PYTHONUNBUFFERED=TRUE
set PYTHONLEGACYWINDOWSSTDIO=utf-8




call .venv\scripts\activate.bat
cd bark-gui
echo .|call StartBark.bat
