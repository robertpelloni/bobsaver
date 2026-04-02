@echo off
cls



if exist AIGC_pretrain\. rd AIGC_pretrain /s/q
md AIGC_pretrain
cd AIGC_pretrain

md stable-diffusion-xl-base-1.0
cd stable-diffusion-xl-base-1.0
curl -L -o sd_xl_base_1.0_0.9vae.safetensors https://huggingface.co/stabilityai/stable-diffusion-xl-base-1.0/resolve/main/sd_xl_base_1.0_0.9vae.safetensors -v

cd..
md SUPIR_cache
cd SUPIR_cache
curl -L -o SUPIR-v0F.ckpt https://huggingface.co/datasets/Softology-Pro/VoC/resolve/main/SUPIR-v0F.ckpt -v
curl -L -o SUPIR-v0Q.ckpt https://huggingface.co/datasets/Softology-Pro/VoC/resolve/main/SUPIR-v0Q.ckpt -v

cd..
cd..

echo Downloads complete
pause
