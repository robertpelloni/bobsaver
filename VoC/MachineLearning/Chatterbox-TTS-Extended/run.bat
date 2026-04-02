@echo off
cd Chatterbox-TTS-Extended
call venv\scripts\activate.bat
python Chatter.py
call venv\scripts\deactivate.bat
cd..
