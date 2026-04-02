@echo off
 



rd checkpoints /s/q
if not exist checkpoints\. md checkpoints
if not exist checkpoints\ControlNetModel\. md checkpoints\ControlNetModel

curl -L -o "checkpoints\ip-adapter.bin" "https://huggingface.co/InstantX/InstantID/resolve/main/ip-adapter.bin" -v
curl -L -o "checkpoints\ControlNetModel\config.json" "https://huggingface.co/InstantX/InstantID/resolve/main/ControlNetModel/config.json" -v
curl -L -o "checkpoints\ControlNetModel\diffusion_pytorch_model.safetensors" "https://huggingface.co/InstantX/InstantID/resolve/main/ControlNetModel/diffusion_pytorch_model.safetensors" -v

rd models /s/q
if not exist models\. md models

curl -L -o "models\antelopev2.zip" "https://huggingface.co/datasets/Softology-Pro/VoC/resolve/main/antelopev2.zip" -v
cd models
..\7z x antelopev2.zip
del antelopev2.zip
cd..

echo.
echo Downloads completed.
echo ***** Scroll up and check for any error messages.  Do not assume the downloads worked. *****
pause