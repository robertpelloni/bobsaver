@echo off
cd ACE-Step
call venv\Scripts\activate.bat
python acestep\gui.py
rem acestep --port 7865
call venv\scripts\deactivate.bat
cd..
