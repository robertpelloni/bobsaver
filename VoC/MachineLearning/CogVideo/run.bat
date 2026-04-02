@echo off
rem cls
cd CogVideo
call venv\scripts\activate.bat
python inference\gradio_web_demo.py
call venv\scripts\deactivate.bat
cd..
