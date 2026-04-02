@echo off





echo *** %time% *** Deleting ComfyUI-WanVideoWrapper directory if it exists
if exist ComfyUI\custom_nodes\ComfyUI-WanVideoWrapper\. rd /S /Q ComfyUI\custom_nodes\ComfyUI-WanVideoWrapper

echo *** %time% *** Deleting Examples\WanVideo directory if it exists
if exist Examples\WanVideo\. rd /S /Q Examples\WanVideo

echo *** %time% *** Cloning ComfyUI-WanVideoWrapper repository
cd ComfyUI
cd custom_nodes
git clone https://github.com/kijai/ComfyUI-WanVideoWrapper
cd..
cd..

echo *** %time% *** Installing requirements.txt
call ComfyUI\.venv\scripts\activate.bat
pip install -r ComfyUI\custom_nodes\ComfyUI-WanVideoWrapper\requirements.txt
call ComfyUI\.venv\scripts\deactivate.bat

echo *** %time% *** Copying example workflows
md Examples\WanVideo
copy /Y ComfyUI\custom_nodes\ComfyUI-WanVideoWrapper\example_workflows\*.* Examples\WanVideo\
md Examples\WanVideo\example_inputs
copy /Y ComfyUI\custom_nodes\ComfyUI-WanVideoWrapper\example_workflows\example_inputs\*.* Examples\WanVideo\example_inputs
copy /Y ComfyUI\custom_nodes\ComfyUI-WanVideoWrapper\example_workflows\example_inputs\*.* Examples\WanVideo\example_inputs
curl -L -o "Examples\WanVideo\Vace_Video_Styling.json" "https://huggingface.co/datasets/Softology-Pro/VoC/resolve/main/Vace_Video_Styling.json" -v

echo *** %time% *** Downloading Cakeify LoRA workflow
if exist Examples\WanVideo\wan_img2video_cakeify_lora_workflow.json del Examples\WanVideo\wan_img2video_cakeify_lora_workflow.json
curl -L -o "Examples\WanVideo\wan_img2video_cakeify_lora_workflow.json" "https://huggingface.co/Remade-AI/Cakeify/resolve/main/workflow/wan_img2vid_lora_workflow.json" -v

echo *** %time% *** Downloading Squish LoRA workflow
if exist Examples\WanVideo\wan_img2video_squish_lora_workflow.json del Examples\WanVideo\wan_img2video_squish_lora_workflow.json
curl -L -o "Examples\WanVideo\wan_img2video_squish_lora_workflow.json" "https://huggingface.co/Remade-AI/Squish/resolve/main/workflow/wan_img2video_lora_workflow.json" -v

echo *** %time% *** Finished WanVideo install
echo.
echo Check the stats for any errors.  Do not assume it worked.
pause

rem BUGGY Wan and SkyReels video workflows BUGGY
