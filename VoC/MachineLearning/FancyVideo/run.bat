@echo off
rem cls
cd FancyVideo
call venv\scripts\activate.bat
python demo.py --config temp\yaml.yaml
call venv\scripts\deactivate.bat
cd..
