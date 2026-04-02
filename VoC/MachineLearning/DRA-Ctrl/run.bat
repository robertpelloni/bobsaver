@echo off
cd DRA-Ctrl
call venv\scripts\activate.bat
rem python gradio_app.py --config configs/gradio.yaml
python gradio_app_hf.py --vram_optimization HighRAM_HighVRAM
call venv\scripts\deactivate.bat
cd..
