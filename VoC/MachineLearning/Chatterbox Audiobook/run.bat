@echo off
cd Chatterbox Audiobook
call venv\scripts\activate.bat
python gradio_tts_app_audiobook.py
call venv\scripts\deactivate.bat
cd..
