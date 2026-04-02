@echo off

cd Janus
call venv\scripts\activate.bat
python demo/app_januspro.py
call venv\scripts\deactivate.bat
cd..
