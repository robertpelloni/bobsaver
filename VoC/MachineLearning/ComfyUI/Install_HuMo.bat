@echo off




echo *** %time% *** Downloading example workflows
md Examples
if exist Examples\HuMo\. rd Examples\HuMo /s/q
md Examples\HuMo

cd Examples\HuMo
curl -L -o "HuMo.rar" "https://huggingface.co/datasets/Softology-Pro/VoC/resolve/main/HuMo.rar" -v
..\..\7z x HuMo.rar
del HuMo.rar
cd..
cd..

echo *** %time% *** Finished HuMo install
echo.
echo Check the stats for any errors.  Do not assume it worked.
pause

rem Multimodal text, image and audio to video
