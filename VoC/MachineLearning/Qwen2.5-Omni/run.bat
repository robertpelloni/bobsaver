@echo off

cd Qwen2.5-Omni
call venv\scripts\activate.bat
rem python web_demo.py --flash-attn2
rem less GPU VRAM usage, but slower
python web_demo.py
call venv\scripts\deactivate.bat
cd..
