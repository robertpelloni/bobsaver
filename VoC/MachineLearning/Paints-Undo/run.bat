@echo off
rem cls
cd Paints-UNDO
call venv\scripts\activate.bat
python gradio_app.py
call venv\scripts\deactivate.bat
cd..
