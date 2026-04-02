@echo off




echo *** %time% *** Deleting Examples\DiscoDiffusion directory if it exists
if exist Examples\DiscoDiffusion\. rd /S /Q Examples\DiscoDiffusion
md Examples\DiscoDiffusion

echo *** %time% *** Installing requirements.txt
call ComfyUI\.venv\scripts\activate.bat
pip install ftfy
pip install timm

call ComfyUI\.venv\scripts\deactivate.bat

echo *** %time% *** Downloading example workflows
if exist Examples\DiscoDiffusion\DiscoDiffusion.json del Examples\DiscoDiffusion\DiscoDiffusion.json
curl -L -o "Examples\DiscoDiffusion\DiscoDiffusion.json" "https://huggingface.co/datasets/Softology-Pro/VoC/resolve/main/DiscoDiffusion.json" -v

echo *** %time% *** Finished DiscoDiffusion install
echo.
echo Check the stats for any errors.  Do not assume it worked.
pause

rem Text-to-Image