@echo off
cd JoyVASA
call venv\scripts\activate.bat
python app.py
call venv\scripts\deactivate.bat
cd..
