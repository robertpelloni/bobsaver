@echo off
rem cls
cd exui
call venv\scripts\activate.bat
python server.py
call venv\scripts\deactivate.bat
cd..
