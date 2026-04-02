@echo off
cls
cd StableDiffusionWebUI
call venv\scripts\activate.bat
python launch.py
call venv\scripts\deactivate.bat
cd..
