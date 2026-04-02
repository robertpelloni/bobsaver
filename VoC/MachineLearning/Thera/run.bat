@echo off
cd Thera
call venv\Scripts\activate.bat
cd thera-demo
python app.py
call venv\scripts\deactivate.bat
cd..
