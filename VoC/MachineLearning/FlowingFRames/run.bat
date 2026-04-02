@echo off
rem cls
cd FlowingFrames
call venv\scripts\activate.bat
python run.py
call venv\scripts\deactivate.bat
cd..
