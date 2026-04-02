@echo off
rem cls
cd RC-stable-audio-tools
call venv\scripts\activate.bat
python run_gradio.py --model-config ckpt/model_config.json --ckpt-path ckpt/model.ckpt
call venv\scripts\deactivate.bat
cd..
