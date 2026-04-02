@echo off



echo *** %time% *** Deleting ConceptSliders directory if it exists
if exist ConceptSliders\. rd /S /Q ConceptSliders

echo *** %time% *** Cloning ConceptSliders repository
git lfs install
git clone https://huggingface.co/spaces/baulab/ConceptSliders
cd ConceptSliders

echo *** %time% *** Removing xformers from requirements.txt
type requirements.txt | findstr /v xformers > stripped.txt
del requirements.txt
ren stripped.txt requirements.txt

echo *** %time% *** Removing opencv_python_headless from requirements.txt
type requirements.txt | findstr /v opencv_python_headless > stripped.txt
del requirements.txt
ren stripped.txt requirements.txt

echo *** %time% *** Removing pyadantic from requirements.txt
type requirements.txt | findstr /v pydantic > stripped.txt
del requirements.txt
ren stripped.txt requirements.txt

echo *** %time% *** Creating venv
python -m venv venv

echo *** %time% *** Activating venv
call venv\scripts\activate.bat

echo *** %time% *** Installing requirements
python -m pip install --upgrade pip==24.3.1

echo *** %time% *** Installing requirements
pip install -r requirements.txt
pip install opencv_python_headless==4.7.0.72
pip install pydantic

echo *** %time% *** Patching xformers
pip uninstall -y xformers
rem pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts xformers==0.0.27.post2 --index-url https://download.pytorch.org/whl/cu121
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts xformers==0.0.30

echo *** %time% *** Installing GPU torch
pip uninstall -y torch
pip uninstall -y torch
rem pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts torch==2.4.0+cu121 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts torch==2.7.0+cu128 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128

echo *** VoC - patching typing_extensions
pip uninstall -y typing_extensions
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts typing_extensions==4.11.0

call venv\scripts\deactivate.bat
cd..
echo *** %time% *** Finished sliders install
echo.
echo Check the stats for any errors.  Do not assume it worked.
pause
