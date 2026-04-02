@echo off
rem cls
cd AnimateAnyone
call venv\scripts\activate.bat
python app.py
call venv\scripts\deactivate.bat
cd..
