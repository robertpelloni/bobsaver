@echo off

cd Chatterbox
call venv\scripts\activate.bat
python gradio_tts_app.py
call venv\scripts\deactivate.bat
cd..
