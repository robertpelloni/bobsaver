@echo off
cd Qwen3-TTS
call venv\scripts\activate.bat
python app.py
rem qwen-tts-demo Qwen/Qwen3-TTS-12Hz-1.7B-Base --device cuda:0  --ip 127.0.0.1 --port 7860
call venv\scripts\deactivate.bat
cd..
