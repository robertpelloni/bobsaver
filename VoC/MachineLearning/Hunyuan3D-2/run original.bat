@echo off
cd Hunyuan3D-2
call venv\scripts\activate.bat
python gradio_app.py --enable_t23d
call venv\scripts\deactivate.bat
cd..
