@echo off
cd ChatterboxToolkitUI
call venv\scripts\activate.bat
python ChatterboxToolkitUI.py
call venv\scripts\deactivate.bat
cd..
