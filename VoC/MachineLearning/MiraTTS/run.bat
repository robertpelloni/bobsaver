@echo off
cd MiraTTS
call venv\scripts\activate.bat
rem python Mira-TTS\web_ui.py
python Mira-TTS\app.py
call venv\scripts\deactivate.bat
cd..
