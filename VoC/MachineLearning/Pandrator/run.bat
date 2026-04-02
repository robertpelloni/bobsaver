@echo off
rem cls
cd Pandrator
call venv\scripts\activate.bat
start python -m silero_api_server
start python -m xtts_api_server
python pandrator.py
call venv\scripts\deactivate.bat
cd..
