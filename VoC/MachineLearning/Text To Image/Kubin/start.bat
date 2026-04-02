@echo off


set PYTHONIOENCODING=utf-8
set PYTHONUNBUFFERED=TRUE
set PYTHONLEGACYWINDOWSSTDIO=utf-8




cd kubin
call .venv\scripts\activate.bat
python src\kubin.py
