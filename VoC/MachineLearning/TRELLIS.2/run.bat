@echo off
cd TRELLIS.2
call venv\scripts\activate.bat
python app.py --use-gradio
call venv\scripts\deactivate.bat
cd..
