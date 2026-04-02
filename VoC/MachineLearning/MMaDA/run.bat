@echo off

cd MMaDA
call venv\scripts\activate.bat
python app.py
call venv\scripts\deactivate.bat
cd..
