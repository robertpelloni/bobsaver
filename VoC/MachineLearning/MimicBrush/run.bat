@echo off
rem cls
cd MimicBrush
call venv\scripts\activate.bat
python run_gradio3_demo.py
call venv\scripts\deactivate.bat
cd..
