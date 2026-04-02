@echo off
cd InstantCharacter
call venv\Scripts\activate.bat
python inference.py
call venv\scripts\deactivate.bat
cd..
