@echo off
cd MiMo-Audio
call venv\scripts\activate.bat
python run_mimo_audio.py
call venv\scripts\deactivate.bat
cd..
