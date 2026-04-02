@echo off
rem cls
cd HunyuanVideoGP
call venv\Scripts\activate.bat
python gradio_server.py --profile 4
call venv\scripts\deactivate.bat
cd..
