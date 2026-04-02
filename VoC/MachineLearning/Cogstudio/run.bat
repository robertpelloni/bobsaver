@echo off
cd Cogvideo
call venv\scripts\activate.bat
cd inference\gradio_composite_demo
python cogstudio.py
cd..
cd..
call venv\scripts\deactivate.bat
cd..
