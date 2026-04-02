@echo off
cls
copy download_models.py .\exui\download_models.py
cd ExUI
md models
call venv\scripts\activate.bat
python download_models.py
call venv\scripts\deactivate.bat
cd..
