@echo off
rem cls
cd VideoLLaMA2
call venv\scripts\activate.bat
python videollama2/serve/gradio_web_server_adhoc.py
call venv\scripts\deactivate.bat
cd..
