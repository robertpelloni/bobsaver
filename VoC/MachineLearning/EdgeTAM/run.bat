@echo off
cd EdgeTAM
call venv\Scripts\activate.bat
python gradio_app.py
call venv\scripts\deactivate.bat
cd..
