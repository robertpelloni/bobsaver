@echo off
rem cls
cd ai-toolkit
call venv\scripts\activate.bat
python run.py config/train_lora_flux_24gb.yaml config\train_lora_flux_24gb.yaml
call venv\scripts\deactivate.bat
cd..
