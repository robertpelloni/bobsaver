@echo off
set PHONEMIZER_ESPEAK_LIBRARY=C:\Program Files\eSpeak NG\libespeak-ng.dll
cd Zonos-for-windows
call venv\Scripts\activate.bat
python gradio_interface.py
call venv\scripts\deactivate.bat
cd..
