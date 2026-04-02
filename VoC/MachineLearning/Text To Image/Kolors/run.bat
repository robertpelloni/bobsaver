@echo off
rem cls


cd Kolors
call venv\scripts\activate.bat
python scripts\sampleui.py
call venv\scripts\deactivate.bat
cd..
pause
