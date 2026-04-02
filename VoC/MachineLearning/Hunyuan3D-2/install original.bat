@echo off



echo *** %time% *** Deleting Hunyuan3D-2 directory if it exists
if exist Hunyuan3D-2\. rd /S /Q Hunyuan3D-2

echo *** %time% *** Cloning DiffSynth-Studio repository
git clone https://github.com/tencent/Hunyuan3D-2
copy example_list.txt Hunyuan3D-2\demos\example_list.txt
cd Hunyuan3D-2

echo *** %time% *** Creating venv
python -m venv venv

echo *** %time% *** Activating venv
call venv\scripts\activate.bat

echo *** %time% *** Installing requirements
python -m pip install --upgrade pip==24.3.1
pip install -r requirements.txt
pip install sentencepiece
pip install https://huggingface.co/datasets/Softology-Pro/VoC/resolve/main/custom_rasterizer-0.1-cp310-cp310-win_amd64.whl
pip install https://huggingface.co/datasets/Softology-Pro/VoC/resolve/main/mesh_processor-0.0.0-cp310-cp310-win_amd64.whl

echo *** %time% *** Installing GPU torch
pip uninstall -y torch
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts torch==2.5.1+cu124 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu124

echo *** %time% *** Patching typing_extensions
pip uninstall -y typing_extensions
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts typing_extensions==4.11.0

echo *** %time% *** Patching numpy
pip uninstall -y numpy
pip uninstall -y numpy
pip install numpy==1.26.4

call venv\scripts\deactivate.bat
cd ..
echo *** %time% *** Finished Hunyuan3D-2 install
echo.
echo Check the stats for any errors.  Do not assume it worked.
pause
