@echo off
rem cls
cd AnimateDiff
call venv\scripts\activate.bat
python app.py
call venv\scripts\deactivate.bat
cd..
