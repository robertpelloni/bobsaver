@echo off
cd Hi3DGen
call venv\Scripts\activate.bat
python app.py
call venv\scripts\deactivate.bat
cd..
