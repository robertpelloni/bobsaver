@echo off
cd DreamO
call venv\Scripts\activate.bat
python app.py --quant int8
call venv\scripts\deactivate.bat
cd..
