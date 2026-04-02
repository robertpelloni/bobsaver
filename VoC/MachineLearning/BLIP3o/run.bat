@echo off

cd BLIP3o
call venv\scripts\activate.bat
cd gradio
python app.py models\BLIP3o4B
call venv\scripts\deactivate.bat
cd..
