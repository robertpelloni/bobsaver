@echo off
cd kokoro-tts
call venv\Scripts\activate.bat
kokoro-tts  "D:\Frankenstein.epub" "D:\VoC_Output\Sounds\Kokoro\Frankenstein.mp3" --speed 1.0 --lang en-us --voice af_alloy --format mp3 --debug
call venv\scripts\deactivate.bat
cd..
