@echo off
cd DetailGen3D
call venv\Scripts\activate.bat
python app.py
call venv\scripts\deactivate.bat
cd..
