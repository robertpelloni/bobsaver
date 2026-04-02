@echo off



if exist DetailGen3D\. rd /S /Q DetailGen3D

echo *** %time% *** Cloning DetailGen3D repository
git clone https://huggingface.co/spaces/VAST-AI/DetailGen3D
cd DetailGen3D

echo *** Creating venv
python -m venv venv
call venv\scripts\activate.bat

echo *** Removing nvdiffrast from requirements.txt
type requirements.txt | findstr /v nvdiffrast > stripped.txt
del requirements.txt
ren stripped.txt requirements.txt

echo *** Removing diso from requirements.txt
type requirements.txt | findstr /v diso > stripped.txt
del requirements.txt
ren stripped.txt requirements.txt

echo *** Removing torch from requirements.txt
type requirements.txt | findstr /v torch > stripped.txt
del requirements.txt
ren stripped.txt requirements.txt

echo *** Removing cvcuda from requirements.txt
type requirements.txt | findstr /v cvcuda > stripped.txt
del requirements.txt
ren stripped.txt requirements.txt

echo *** %time% *** Installing requirements
python -m pip install --upgrade pip==24.3.1
pip install wheel
pip install setuptools
pip install -r requirements.txt
pip install https://huggingface.co/datasets/Softology-Pro/VoC/resolve/main/nvdiffrast-0.3.3-py3-none-any.whl
pip install https://huggingface.co/datasets/Softology-Pro/VoC/resolve/main/diso-0.1.4-cp310-cp310-win_amd64.whl
pip install spaces
pip install torch_cluster

echo *** %time% *** Installing GPU torch
pip uninstall -y torch
pip uninstall -y torch
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts torch==2.7.0+cu128 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128

echo *** %time% *** Patching numpy
pip uninstall -y numpy
pip uninstall -y numpy
pip uninstall -y numpy
pip uninstall -y numpy
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts numpy==1.26.4

echo *** %time% *** Patching pydantic
pip uninstall -y pydantic
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts pydantic==2.10.6

cd ..
echo *** %time% VoC *** Finished DetailGen3D install
echo.
echo Check the stats for any errors.  Do not assume it worked.
pause
