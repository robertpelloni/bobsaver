@echo off
rem cls
cd hallo
call venv\scripts\activate.bat
python scripts\app.py
cd..
call venv\scripts\deactivate.bat
cd..
