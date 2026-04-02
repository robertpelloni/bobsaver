@echo off

cd Chain-of-Zoom
call venv\scripts\activate.bat
rem python inference_coz.py -i samples -o inference_results/coz_vlmprompt --rec_type recursive_multiscale --prompt_type vlm --lora_path ckpt/SR_LoRA/model_20001.pkl --vae_path ckpt/SR_VAE/vae_encoder_20001.pt --pretrained_model_name_or_path 'stabilityai/stable-diffusion-3-medium-diffusers' --ram_ft_path ckpt/DAPE/DAPE.pth --ram_path ckpt/RAM/ram_swin_large_14m.pth
python app.py
call venv\scripts\deactivate.bat
cd..
