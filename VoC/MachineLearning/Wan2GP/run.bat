@echo off

cd Wan2GP
call venv\scripts\activate.bat
python wgp.py --i2v --lora-dir ./loras --lora-dir-i2v ./loras_i2v --lora-dir-hunyuan ./loras_hunyuan --lora-dir-ltxv ./loras_ltxv
call venv\scripts\deactivate.bat
cd..
