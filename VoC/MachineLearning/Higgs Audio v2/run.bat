@echo off
rem cls
cd higgs_audio_v2
call venv\scripts\activate.bat
python app.py
call venv\scripts\deactivate.bat
cd..
