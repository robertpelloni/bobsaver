@echo off




echo *** %time% *** Deleting ComfyUI-Ovi directory if it exists
if exist ComfyUI\custom_nodes\Ovi\. rd /S /Q ComfyUI\custom_nodes\Ovi

echo *** %time% *** Deleting Examples\Ovi directory if it exists
if exist Examples\Ovi\. rd /S /Q Examples\Ovi

echo *** %time% *** Cloning ComfyUI-Ovi repository
cd ComfyUI
cd custom_nodes
git clone https://github.com/snicolast/ComfyUI-Ovi
cd..
cd..

echo *** %time% *** Installing requirements.txt
call ComfyUI\.venv\scripts\activate.bat
pip install setuptools
pip install -r ComfyUI\custom_nodes\ComfyUI-Ovi\requirements.txt
call ComfyUI\.venv\scripts\deactivate.bat

echo *** %time% *** Downloading example workflow
md Examples
md Examples\Ovi
curl -L -o "Examples\Ovi\ScarlettJohansson1024x1024.png" "https://huggingface.co/datasets/Softology-Pro/VoC/resolve/main/ScarlettJohansson1024x1024.png" -v
curl -L -o "Examples\Ovi\Ovi.json" "https://huggingface.co/datasets/Softology-Pro/VoC/resolve/main/Ovi.json" -v
cd..
cd..

echo *** %time% *** Finished Ovi install
echo.
echo Check the stats for any errors.  Do not assume it worked.
pause

rem Text-to-Audio-Video or Image-to-Audio-Video
