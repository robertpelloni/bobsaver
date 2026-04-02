@echo off
cd OmniGen
call venv\scripts\activate.bat
python app.py
call venv\scripts\deactivate.bat
cd..
