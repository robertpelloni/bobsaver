@echo off




echo *** %time% *** Deleting Qwen-Image-Edit-2511-Multiple-Angles-LoRA directory if it exists
if exist ComfyUI\custom_nodes\Qwen-Image-Edit-2511-Multiple-Angles-LoRA\. rd /S /Q ComfyUI\custom_nodes\Qwen-Image-Edit-2511-Multiple-Angles-LoRA

echo *** %time% *** Deleting Examples\QwenImageAngles directory if it exists
if exist Examples\QwenImageAngles\. rd /S /Q Examples\QwenImageAngles

echo *** %time% *** Cloning Qwen-Image-Edit-2511-Multiple-Angles-LoRA repository
cd ComfyUI
cd custom_nodes
git clone https://huggingface.co/fal/Qwen-Image-Edit-2511-Multiple-Angles-LoRA
cd..
cd..

echo *** %time% *** Copying LoRA
copy /Y ComfyUI\custom_nodes\Qwen-Image-Edit-2511-Multiple-Angles-LoRA\qwen-image-edit-2511-multiple-angles-lora.safetensors ComfyUI\models\loras\qwen-image-edit-2511-multiple-angles-lora.safetensors

echo *** %time% *** Downloading example workflow
md Examples
md Examples\QwenImageAngles
curl -L -o "Examples\QwenImageAngles\ShrekPose.png" "https://huggingface.co/datasets/Softology-Pro/VoC/resolve/main/ShrekPose.png" -v
curl -L -o "Examples\QwenImageAngles\comfyui-workflow-multiple-angles.json" "https://huggingface.co/datasets/Softology-Pro/VoC/resolve/main/comfyui-workflow-multiple-angles.json" -v
cd..
cd..

echo *** %time% *** Finished QwenImageAngles install
echo.
echo Check the stats for any errors.  Do not assume it worked.
pause

rem Rotates a 3D view around a 2D image
