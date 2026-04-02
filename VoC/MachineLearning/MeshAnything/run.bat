@echo off
rem cls
cd MeshAnything
call venv\scripts\activate.bat
python app.py
call venv\scripts\deactivate.bat
cd..
