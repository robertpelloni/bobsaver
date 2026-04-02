@echo off
rem cls
cd ai-toolkit
call venv\scripts\activate.bat
python flux_train_ui.py
call venv\scripts\deactivate.bat
cd..
