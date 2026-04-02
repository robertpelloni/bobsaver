@echo off
cd InstantIR
call venv\scripts\activate.bat
set INSTANTIR_PATH=.\models\InstantIR\models
python gradio_demo/app.py
call venv\scripts\deactivate.bat
cd..
