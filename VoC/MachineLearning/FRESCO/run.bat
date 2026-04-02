@echo off
set PYTHONUNBUFFERED=True

echo *** VOC - activating venv
call .venv\scripts\activate.bat

echo *** VoC - starting webui.py
cd FRESCO
python -u -B -W ignore webUI.py
