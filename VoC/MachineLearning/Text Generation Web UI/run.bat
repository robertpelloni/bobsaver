@echo off
cd text-generation-webui
call venv\Scripts\activate.bat
python server.py --model Dolphin3.0-Llama3.1-8B --verbose --auto-launch --auto-devices
call venv\scripts\deactivate.bat
cd..
