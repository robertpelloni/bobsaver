@echo off
cd DiffSensei
call venv\scripts\activate.bat
set CUDA_VISIBLE_DEVICES=0
python -m scripts.demo.gradio --config_path configs\model\diffsensei.yaml --inference_config_path configs\inference\diffsensei.yaml --ckpt_path checkpoints\diffsensei
rem python scripts\demo\gradio.py --config_path configs/model/diffsensei.yaml --inference_config_path configs/inference/diffsensei.yaml --ckpt_path checkpoints/diffsensei
call venv\scripts\deactivate.bat
cd..
