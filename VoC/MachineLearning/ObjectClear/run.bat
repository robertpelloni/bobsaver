@echo off
rem cls
cd ObjectClear
call venv\scripts\activate.bat
python app.py
call venv\scripts\deactivate.bat
cd..
