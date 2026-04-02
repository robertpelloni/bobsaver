@echo off
cd stable-diffusion-videos
call venv\scripts\activate.bat
cd examples
python run_app.py
cd..
call venv\scripts\deactivate.bat
cd..
