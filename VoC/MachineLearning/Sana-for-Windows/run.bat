@echo off
cd Sana-for-Windows
call venv\Scripts\activate.bat
set DEMO_PORT=15432 
rem 600M model
rem python app/app_sana.py --server_name 127.0.0.1 --config=configs/sana_config/1024ms/Sana_600M_img1024.yaml --model_path=hf://Efficient-Large-Model/Sana_600M_1024px_ControlNet_HED/checkpoints/Sana_600M_1024px_ControlNet_HED.pth --image_size=1024
rem 1600M model
rem python app/app_sana.py --share --config=configs/sana_config/1024ms/Sana_1600M_img1024.yaml --model_path=hf://Efficient-Large-Model/Sana_1600M_1024px/checkpoints/Sana_1600M_1024px.pth --image_size=1024
python app/app_sana.py --share --config=configs/sana_config/1024ms/Sana_1600M_img1024.yaml --model_path=hf://Efficient-Large-Model/Sana_1600M_1024px/checkpoints/Sana_1600M_1024px.pth --image_size=1024
call venv\scripts\deactivate.bat
cd..
