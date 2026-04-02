@echo off
cls
D:
cd "\code\Delphi\Chaos\Examples\MachineLearning\PIFuHD\"

echo *** Downloading models
if exist openpose\models\. rd /S /Q openpose\models
md openpose\models
curl -L -o "openpose\models\openpose_models.rar" "https://huggingface.co/datasets/Softology-Pro/VoC/resolve/main/openpose_models.rar" -v

echo *** Extracting models
cd openpose\models
..\..\7z x openpose_models.rar
del openpose_models.rar
cd..
