@echo off
rem cls



cd TRELLIS
call venv\scripts\activate.bat
set ATTN_BACKEND=flash-attn
rem set ATTN_BACKEND=xformers
set SPCONV_ALGO=native
python app.py
call venv\scripts\deactivate.bat
cd..
