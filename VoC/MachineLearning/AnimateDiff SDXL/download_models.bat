@echo off
 
D:
cd "D:\code\delphi\Chaos\Examples\MachineLearning\AnimateDiff SDXL"

if not exist AnimateDiff\models\Motion_Module\. md AnimateDiff\models\Motion_Module
if not exist AnimateDiff\models\DreamBooth_LoRA\. md AnimateDiff\models\DreamBooth_LoRA
wget "https://huggingface.co/datasets/Softology-Pro/VoC/resolve/main/animatediffMotion_sdxlV10Beta.ckpt" -O "AnimateDiff\models\Motion_Module\animatediffMotion_sdxlV10Beta.ckpt" -nc --no-check-certificate
wget "https://huggingface.co/datasets/Softology-Pro/VoC/resolve/main/dynavisionXLAllInOneStylized_release0557Bakedvae.safetensors" -O "AnimateDiff\models\DreamBooth_LoRA\dynavisionXLAllInOneStylized_release0557Bakedvae.safetensors" -nc --no-check-certificate
wget "https://huggingface.co/datasets/Softology-Pro/VoC/resolve/main/dreamshaperXL10_alpha2Xl10.safetensors" -O "AnimateDiff\models\DreamBooth_LoRA\dreamshaperXL10_alpha2Xl10.safetensors" -nc --no-check-certificate
wget "https://huggingface.co/datasets/Softology-Pro/VoC/resolve/main/deepblueXL_v020.safetensors" -O "AnimateDiff\models\DreamBooth_LoRA\deepblueXL_v020.safetensors" -nc --no-check-certificate

echo.
echo Downloads completed.
echo ***** Scroll up and check for any error messages.  Do not assume the downloads worked. *****
pause
