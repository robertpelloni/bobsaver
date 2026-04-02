@echo off
rem cls
cd MeshAnythingV2
call venv\scripts\activate.bat
python app.py
call venv\scripts\deactivate.bat
cd..
