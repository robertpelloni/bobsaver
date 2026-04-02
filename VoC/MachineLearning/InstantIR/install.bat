@echo off



echo *** %time% *** Deleting InstantIR directory if it exists
if exist InstantIR\. rd /S /Q InstantIR

echo *** %time% *** Cloning DiffSynth-Studio repository
git clone https://github.com/instantX-research/InstantIR
cd InstantIR

rem echo *** %time% *** Removing flash-attn from requirements.txt
rem type requirements.txt | findstr /v flash-attn > stripped.txt
rem del requirements.txt
rem ren stripped.txt requirements.txt

rem echo *** %time% *** Removing flash-attn from pyproject.toml
rem type pyproject.toml | findstr /v flash-attn > stripped.txt
rem del pyproject.toml
rem ren stripped.txt pyproject.toml

echo *** %time% *** Creating venv
python -m venv venv

echo *** %time% *** Activating venv
call venv\scripts\activate.bat

echo *** %time% *** Installing requirements
python -m pip install --upgrade pip==24.3.1
pip install -r requirements.txt

echo *** %time% *** Installing GPU torch
pip uninstall -y torch
rem pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts torch==2.4.1+cu121 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121
rem pip install --pre torch==2.7.0.dev20250311 torchvision torchaudio --index-url https://download.pytorch.org/whl/nightly/cu128
pip install torch==2.7.0+cu128 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128

echo *** %time% *** Patching huggingface-hub
pip uninstall -y huggingface-hub
pip install huggingface-hub==0.25.0

echo *** VoC - patching typing_extensions
pip uninstall -y typing_extensions
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts typing_extensions==4.11.0

echo *** VoC - patching pydantic
pip uninstall -y pydantic
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts pydantic==2.10.6

echo *** %time% *** Downloading models
md models
cd models
git clone https://huggingface.co/InstantX/InstantIR
cd..

call venv\scripts\deactivate.bat
cd ..
echo *** %time% *** Finished InstantIR install
echo.
echo Check the stats for any errors.  Do not assume it worked.
pause
