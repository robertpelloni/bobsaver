@echo off

cd Direct3D-S2
call venv\scripts\activate.bat
python app.py
call venv\scripts\deactivate.bat
cd..
