@echo off
rem cls
cd F5-TTS
call venv\scripts\activate.bat
f5-tts_infer-gradio
call venv\scripts\deactivate.bat
cd..
