@echo off

cd Qwen2.5-VL
call venv\scripts\activate.bat
python web_demo_mm.py
call venv\scripts\deactivate.bat
cd..
