@echo off
rem cls
cd stable-audio-tools
call venv\scripts\activate.bat
python run_gradio.py --ckpt-path ".\ckpt\model.ckpt" --model-config ".\ckpt\model_config.json"
