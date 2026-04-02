@echo off



cd Hunyuan3D-2.1
call venv\scripts\activate.bat
python gradio_app.py --model_path tencent/Hunyuan3D-2.1 --subfolder hunyuan3d-dit-v2-1 --texgen_model_path tencent/Hunyuan3D-2.1 --low_vram_mode
call venv\scripts\deactivate.bat
cd..
