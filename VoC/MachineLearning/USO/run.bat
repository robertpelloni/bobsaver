@echo off
cd USO
call venv\scripts\activate.bat
rem set FLUX_DEV=.\weights\FLUX.1-dev\flux1-dev.safetensors
set FLUX_DEV=.\weights\FLUX-dev-fp8\flux1-dev-fp8.safetensors
set AE=.\weights\FLUX.1-dev\ae.safetensors
set T5=.\weights\t5-xxl
set CLIP=.\weights\clip-vit-l14
set LORA=.\weights\USO\uso_flux_v1.0\dit_lora.safetensors
set PROJECTION_MODEL=.\weights\USO\uso_flux_v1.0\projector.safetensors
set SIGLIP_PATH=.\weights\siglip
python app.py --offload --name flux-dev-fp8
call venv\scripts\deactivate.bat
cd..
