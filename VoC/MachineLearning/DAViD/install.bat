@echo off



echo *** %time% VoC *** Deleting DAViD directory if it exists
if exist DAViD\. rd /S /Q DAViD

echo *** %time% VoC *** Cloning repository
git clone https://github.com/microsoft/DAViD
cd DAViD

echo *** Creating venv
python -m venv venv
call venv\scripts\activate.bat

echo *** %time% *** Installing requirements
python -m pip install --upgrade pip
pip install -r requirement.txt

echo *** VoC - Installing GPU torch
pip uninstall -y torch
pip uninstall -y torch
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts torch==2.7.0+cu128 torchvision torchaudio --extra-index-url https://download.pytorch.org/whl/cu128

echo *** %time% *** Downloading models
md models
cd models
curl -L -o "multi-task-model-vitl16_384.onnx" "https://facesyntheticspubwedata.z6.web.core.windows.net/iccv-2025/models/multi-task-model-vitl16_384.onnx" -v
cd ..
cd ..

echo *** %time% VoC *** Finished DAViD install
echo.
echo Check the stats for any errors.  Do not assume it worked.
pause
