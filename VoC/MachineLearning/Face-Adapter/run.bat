@echo off
rem cls
cd Face-Adapter
call venv\scripts\activate.bat
python app.py
call venv\scripts\deactivate.bat
cd..
