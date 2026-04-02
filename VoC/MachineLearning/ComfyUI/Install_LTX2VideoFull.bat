@echo off




echo *** %time% *** Deleting ComfyUI-LTXVideo directory if it exists
if exist ComfyUI\custom_nodes\ComfyUI-LTXVideo\. rd /S /Q ComfyUI\custom_nodes\ComfyUI-LTXVideo

echo *** %time% *** Deleting Examples\LTX2Video directory if it exists
if exist Examples\LTXVideo\. rd /S /Q Examples\LTXVideo
if exist Examples\LTX2Video\. rd /S /Q Examples\LTX2Video

echo *** %time% *** Cloning ComfyUI-LTXVideo repository
cd ComfyUI
cd custom_nodes
git clone https://github.com/Lightricks/ComfyUI-LTXVideo
cd..
cd..

echo *** %time% *** Installing requirements.txt
call ComfyUI\.venv\scripts\activate.bat
pip install -r ComfyUI\custom_nodes\ComfyUI-LTXVideo\requirements.txt
pip install -U bitsandbytes
pip install accelerate

echo *** %time% *** Extracting Gemma3 models
cd ComfyUI\models\text_encoders\gemma-3-12b-it-qat-q4_0-unquantized
..\..\..\..\7z.exe x gemma-3-12b-it-qat-q4_0-unquantized.rar
del gemma-3-12b-it-qat-q4_0-unquantized.rar
cd..
cd gemma-3-12b-it-bnb-4bit
..\..\..\..\7z.exe x gemma-3-12b-it-bnb-4bit.rar -y
rem del gemma-3-12b-it-bnb-4bit.rar
cd..
cd..
cd..
cd..

call ComfyUI\.venv\scripts\deactivate.bat

echo *** %time% *** Copying example workflows
md Examples\LTX2Video
Robocopy "ComfyUI\custom_nodes\ComfyUI-LTXVideo\example_workflows" "Examples\LTX2Video" /MIR
copy "ComfyUI\custom_nodes\ComfyUI-LTXVideo\example_workflows\assets\*.*" "Examples\LTX2Video"
rd Examples\LTX2Video\assets /s/q
curl -L -o "Examples\LTX2Video\Lower_VRAM_LTX-2_I2V_Distilled_wLora.json" "https://huggingface.co/datasets/Softology-Pro/VoC/resolve/main/Lower_VRAM_LTX-2_I2V_Distilled_wLora.json" -v
curl -L -o "Examples\LTX2Video\Lower_VRAM_LTX-2_T2V_Distilled_wLora.json" "https://huggingface.co/datasets/Softology-Pro/VoC/resolve/main/Lower_VRAM_LTX-2_T2V_Distilled_wLora.json" -v
curl -L -o "Examples\LTX2Video\owls.png" "https://huggingface.co/datasets/Softology-Pro/VoC/resolve/main/owls.png" -v

echo *** %time% *** Finished LTX2Video install
echo.
echo Check the stats for any errors.  Do not assume it worked.
pause

rem Image-to-Video, Text-to-Video, needs >= 32 GB VRAM