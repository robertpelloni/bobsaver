@echo off
cd OmniGen2
call venv\scripts\activate.bat
python app_chat.py
call venv\scripts\deactivate.bat
cd..
