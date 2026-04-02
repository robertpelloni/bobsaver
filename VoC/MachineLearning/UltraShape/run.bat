@echo off
cd UltraShape
call venv\scripts\activate.bat
python scripts/gradio_app.py  --ckpt ./checkpoints/ultrashape_v1.pt
call venv\scripts\deactivate.bat
cd..
