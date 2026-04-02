@echo off
rem cls
cd invoke-training
call venv\scripts\activate.bat
invoke-train-ui
call venv\scripts\deactivate.bat
cd..
