@echo off
cd stable-point-aware-3d
call venv\scripts\activate.bat
python gradio_app.py
call venv\scripts\deactivate.bat
cd..
