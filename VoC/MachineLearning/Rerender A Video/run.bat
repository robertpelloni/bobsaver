@echo off
set PYTHONUNBUFFERED=True

echo *** VOC - activating venv
call .venv\scripts\activate.bat

echo *** VoC - starting webui.py
cd Rerender_A_Video
python -u -B -W ignore webui.py
