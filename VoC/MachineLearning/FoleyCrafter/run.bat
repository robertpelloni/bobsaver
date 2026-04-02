@echo off
rem cls
cd FoleyCrafter
call venv\scripts\activate.bat
python app.py
call venv\scripts\deactivate.bat
cd..
