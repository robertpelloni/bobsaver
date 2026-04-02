@echo off
set CUDA_VISIBLE_DEVICES=0
cd magicquill
call venv\scripts\activate.bat
python gradio_run.py
call venv\scripts\deactivate.bat
cd..
