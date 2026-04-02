@echo off
rem cls
cd stable-fast-3d
call venv\scripts\activate.bat
huggingface-cli login --token
python  -X utf8 gradio_app.py
call venv\scripts\deactivate.bat
cd..
