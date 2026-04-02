@echo off
cd heartlib
call venv\scripts\activate.bat
rem python ./examples/run_music_generation.py --model_path=./ckpt --version="3B"
python app.py
call venv\scripts\deactivate.bat
cd..
