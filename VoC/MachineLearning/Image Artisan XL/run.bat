@echo off
rem cls
cd image-artisan-xl
call venv\scripts\activate.bat
set HF_HUB_OFFLINE=True
python -m iartisanxl
