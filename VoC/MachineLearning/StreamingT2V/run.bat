@echo off


set PYTHONIOENCODING=utf-8
set PYTHONUNBUFFERED=TRUE
set PYTHONLEGACYWINDOWSSTDIO=utf-8




call .venv\scripts\activate.bat
cd StreamingT2V\t2v_enhanced\
python gradio_demo.py
