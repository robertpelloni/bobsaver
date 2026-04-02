@echo off




echo *** %time% *** Deleting Examples\Wan2.2 directory if it exists
if exist Examples\Wan2.2\. rd /S /Q Examples\Wan2.2

echo *** %time% *** Deleting ComfyUI-KJNodes directory if it exists
if exist ComfyUI\custom_nodes\ComfyUI-KJNodes\. rd /S /Q ComfyUI\custom_nodes\ComfyUI-KJNodes

echo *** %time% *** Cloning ComfyUI-KJNodes repository
cd ComfyUI
cd custom_nodes
git clone https://github.com/kijai/ComfyUI-KJNodes
cd..
cd..

echo *** %time% *** Downloading example workflows
md Examples\Wan2.2
curl -L -o "Examples\Wan2.2\Wan22.rar" "https://huggingface.co/datasets/Softology-Pro/VoC/resolve/main/Wan22.rar" -v
cd Examples\Wan2.2
..\..\7z.exe x Wan22.rar
del Wan22.rar
cd..
cd..

echo *** %time% *** Finished Wan2.2 install
echo.
echo Check the stats for any errors.  Do not assume it worked.
pause

rem Image-to-Video, Text-to-Video
