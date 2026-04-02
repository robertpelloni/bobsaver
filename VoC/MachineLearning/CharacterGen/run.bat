@echo off
rem cls
cd CharacterGen
call venv\scripts\activate.bat
python webui.py
call venv\scripts\deactivate.bat
cd..
