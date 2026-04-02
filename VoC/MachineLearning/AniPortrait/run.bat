@echo off
rem cls
cd AniPortrait
call venv\scripts\activate.bat
python -m scripts.app
call venv\scripts\deactivate.bat
cd..
