@echo off
cd TransPixar
call venv\scripts\activate.bat
python app.py
call venv\scripts\deactivate.bat
cd..
