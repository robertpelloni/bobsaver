@echo off
cd TTS-WebUI
call venv\scripts\activate.bat
python server.py --no-react
call venv\scripts\deactivate.bat
cd..
