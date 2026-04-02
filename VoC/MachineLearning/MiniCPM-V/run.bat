@echo off
rem cls
cd MiniCPM-V
call venv\scripts\activate.bat
python web_demos\web_demo_2.6.py --device cuda
cd..
call venv\scripts\deactivate.bat

