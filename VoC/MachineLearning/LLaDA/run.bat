@echo off
cd LLaDA
call venv\Scripts\activate.bat
python app.py
call venv\scripts\deactivate.bat
cd..
