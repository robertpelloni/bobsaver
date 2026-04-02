@echo off
rem cls
cd biniou
call venv\scripts\activate.bat
set AUDIOCRAFT_CACHE_DIR=.\models\Audiocraft\
python webui.py
call venv\scripts\deactivate.bat
cd..
