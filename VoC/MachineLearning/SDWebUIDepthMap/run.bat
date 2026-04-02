@echo off
cd SDWebUIDepthMap
call venv\scripts\activate.bat
python main.py
call venv\scripts\deactivate.bat
cd..
