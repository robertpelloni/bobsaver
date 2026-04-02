@echo off
cd MIDI-3D
call venv\Scripts\activate.bat
python gradio_demo.py
call venv\scripts\deactivate.bat
cd..
