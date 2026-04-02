@echo off




echo *** %time% *** Deleting Examples\AnimateDiffEvolved directory if it exists
if exist Examples\AnimateDiffEvolved\. rd /S /Q Examples\AnimateDiffEvolved

echo *** %time% *** Deleting ComfyUI-AnimateDiff-Evolved directory if it exists
if exist ComfyUI\custom_nodes\ComfyUI-AnimateDiff-Evolved\. rd /S /Q ComfyUI\custom_nodes\ComfyUI-AnimateDiff-Evolved

echo *** %time% *** Cloning ComfyUI-AnimateDiff-Evolved repository
cd ComfyUI
cd custom_nodes
git clone https://github.com/Kosinkadink/ComfyUI-AnimateDiff-Evolved
cd..
cd..

echo *** %time% *** Downloading example workflows
md Examples
md Examples\AnimateDiffEvolved
curl -L -o "Examples\AnimateDiffEvolved\AnimateDiff.json" "https://huggingface.co/datasets/Softology-Pro/VoC/resolve/main/AnimateDiff.json" -v
curl -L -o "Examples\AnimateDiffEvolved\AnimateDiff_LoRA.json" "https://huggingface.co/datasets/Softology-Pro/VoC/resolve/main/AnimateDiff_LoRA.json" -v
curl -L -o "Examples\AnimateDiffEvolved\AnimateDiffEvolved.rar" "https://huggingface.co/datasets/Softology-Pro/VoC/resolve/main/AnimateDiffEvolved.rar" -v
cd Examples\AnimateDiffEvolved
..\..\7z.exe x AnimateDiffEvolved.rar
del AnimateDiffEvolved.rar
cd..
cd..

echo *** %time% *** Finished AnimateDiffEvolved install
echo.
echo Check the stats for any errors.  Do not assume it worked.
pause

rem Text-to-Video
