@echo off
cd CogVideoX-Fun
call venv\scripts\activate.bat
python examples\cogvideox_fun\app.py
call venv\scripts\deactivate.bat
cd..
