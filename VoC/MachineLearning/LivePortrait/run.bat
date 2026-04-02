@echo off
rem cls
cd LivePortrait
call venv\scripts\activate.bat
python app.py --no-share
call venv\scripts\deactivate.bat
cd..
