@echo off
rem cls
cd AniTalker
call venv\scripts\activate.bat
python code\webgui.py
call venv\scripts\deactivate.bat
cd..
