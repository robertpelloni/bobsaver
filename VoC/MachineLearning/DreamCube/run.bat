@echo off
cd DreamCube
call venv\scripts\activate.bat
python app.py --use-gradio
call venv\scripts\deactivate.bat
cd..
