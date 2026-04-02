@echo off
setlocal EnableExtensions


REM ==========================================================

REM MUST SAVE AS ANSI or UTF-8 WITHOUT BOM

REM If you see '∩╗┐@echo off' you saved with UTF-8 BOM.

REM ==========================================================

cd /d "%~dp0"

echo.
echo *** Deleting existing VisoMaster directory
if exist "VisoMaster\" rd /S /Q "VisoMaster"

echo.
echo *** Cloning VisoMaster repository
git clone https://github.com/visomaster/VisoMaster
if errorlevel 1 (
  echo ERROR: git clone failed.
  exit /b 1
)

cd /d "%~dp0\VisoMaster"


REM ==========================================================

REM Write requirements.txt (safe line-by-line)

REM ==========================================================
echo.
echo *** Writing requirements.txt
set "REQ=requirements.txt"

> "%REQ%"  echo #core Visomaster
>>"%REQ%" echo #this works on pyhton 3.10 out of the box.
>>"%REQ%" echo #python3.12 works on windows in developer mode as modules must be compiled (onnxsim)
>>"%REQ%" echo #PYTORCH*
>>"%REQ%" echo --extra-index-url=https://download.pytorch.org/whl/nightly/cpu ; sys_platform == 'darwin'
>>"%REQ%" echo --extra-index-url=https://download.pytorch.org/whl/cu128 ; sys_platform != 'darwin'
>>"%REQ%" echo torch==2.7.0
>>"%REQ%" echo torchvision
>>"%REQ%" echo torchaudio
>>"%REQ%" echo.
>>"%REQ%" echo numpy
>>"%REQ%" echo opencv-python
>>"%REQ%" echo scikit-image
>>"%REQ%" echo pillow==9.5.0
>>"%REQ%" echo onnx
>>"%REQ%" echo protobuf
>>"%REQ%" echo psutil
>>"%REQ%" echo onnxruntime-gpu
>>"%REQ%" echo packaging
>>"%REQ%" echo PySide6
>>"%REQ%" echo kornia
>>"%REQ%" echo.
>>"%REQ%" echo tqdm
>>"%REQ%" echo typing_extensions
>>"%REQ%" echo ftfy
>>"%REQ%" echo regex
>>"%REQ%" echo pyvirtualcam
>>"%REQ%" echo numexpr
>>"%REQ%" echo onnxsim
>>"%REQ%" echo requests
>>"%REQ%" echo pyqt-toast-notification
>>"%REQ%" echo qdarkstyle
>>"%REQ%" echo pyqtdarktheme
>>"%REQ%" echo tensorrt==10.6.0 --extra-index-url https://pypi.nvidia.com/
>>"%REQ%" echo tensorrt-cu12_libs
>>"%REQ%" echo tensorrt-cu12_bindings


REM ==========================================================

REM Copy ffmpeg.exe (expects it next to install.bat)

REM ==========================================================
echo.
echo *** Copying ffmpeg.exe
if exist "%~dp0ffmpeg.exe" (
  copy /y "%~dp0ffmpeg.exe" "%~dp0\VisoMaster\dependencies\ffmpeg.exe" >nul
  echo Copied ffmpeg.exe.
) else (
  echo WARNING: ffmpeg.exe not found next to install.bat. Skipping.
)


REM ==========================================================

REM Create convert_ui_to_py.bat (SAFE: prevent % expansion + ! issues)

REM ==========================================================
echo.
echo *** Creating convert_ui_to_py.bat
cd /d "%~dp0\VisoMaster\app\ui\core"

set "OUT=convert_ui_to_py.bat"


REM Disable delayed expansion while WRITING so ! is not eaten.
setlocal DisableDelayedExpansion

> "%OUT%"  echo @echo off
>>"%OUT%" echo setlocal enabledelayedexpansion
>>"%OUT%" echo.
>>"%OUT%" echo REM Always run relative to project root (the folder containing start.bat)
>>"%OUT%" echo cd /d "%%%%~dp0\..\..\.."
>>"%OUT%" echo.
>>"%OUT%" echo :: Define relative paths
>>"%OUT%" echo set "UI_FILE=app\ui\core\MainWindow.ui"
>>"%OUT%" echo set "PY_FILE=app\ui\core\main_window.py"
>>"%OUT%" echo set "QRC_FILE=app\ui\core\media.qrc"
>>"%OUT%" echo set "RCC_PY_FILE=app\ui\core\media_rc.py"
>>"%OUT%" echo.
>>"%OUT%" echo REM Sanity check: PySide6 is installed in the currently active Python
>>"%OUT%" echo python -c "import PySide6" 1^>nul 2^>nul ^|^| ^(
>>"%OUT%" echo   echo ERROR: PySide6 is not installed in this environment.
>>"%OUT%" echo   echo Install it after activating conda env: pip install PySide6
>>"%OUT%" echo   exit /b 1
>>"%OUT%" echo ^)
>>"%OUT%" echo.
>>"%OUT%" echo :: Run PySide6 commands using module entrypoint (no PATH dependency)
>>"%OUT%" echo python -m PySide6.scripts.pyside_tool uic "%%%%UI_FILE%%%%" -o "%%%%PY_FILE%%%%"
>>"%OUT%" echo if errorlevel 1 ^(
>>"%OUT%" echo   echo ERROR: Failed to compile UI file: %%%%UI_FILE%%%%
>>"%OUT%" echo   exit /b 1
>>"%OUT%" echo ^)
>>"%OUT%" echo.
>>"%OUT%" echo python -m PySide6.scripts.pyside_tool rcc "%%%%QRC_FILE%%%%" -o "%%%%RCC_PY_FILE%%%%"
>>"%OUT%" echo if errorlevel 1 ^(
>>"%OUT%" echo   echo ERROR: Failed to compile QRC file: %%%%QRC_FILE%%%%
>>"%OUT%" echo   exit /b 1
>>"%OUT%" echo ^)
>>"%OUT%" echo.
>>"%OUT%" echo :: Define search and replace strings
>>"%OUT%" echo set "searchString=import media_rc"
>>"%OUT%" echo set "replaceString=from app.ui.core import media_rc"
>>"%OUT%" echo.
>>"%OUT%" echo :: Create a temporary file
>>"%OUT%" echo set "tempFile=%%%%PY_FILE%%%%.tmp"
>>"%OUT%" echo.
>>"%OUT%" echo :: Process the file
>>"%OUT%" echo ^(for /f "usebackq delims=" %%%%A in ^("%%%%PY_FILE%%%%"^) do ^(
>>"%OUT%" echo     set "line=%%%%A"
>>"%OUT%" echo     if "^^!line^^!"=="%%%%searchString%%%%" ^(
>>"%OUT%" echo         echo %%%%replaceString%%%%
>>"%OUT%" echo     ^) else ^(
>>"%OUT%" echo         echo ^^!line^^!
>>"%OUT%" echo     ^)
>>"%OUT%" echo ^)^) ^> "%%%%tempFile%%%%"
>>"%OUT%" echo.
>>"%OUT%" echo :: Replace the original file with the temporary file
>>"%OUT%" echo move /y "%%%%tempFile%%%%" "%%%%PY_FILE%%%%"
>>"%OUT%" echo.
>>"%OUT%" echo echo Replacement complete.
>>"%OUT%" echo exit /b 0

endlocal


REM Back to repo root
cd /d "%~dp0\VisoMaster"


REM ==========================================================

REM Create venv and install

REM ==========================================================
echo.
echo *** Creating venv
python -m venv venv
if errorlevel 1 (
  echo ERROR: Failed to create venv.
  exit /b 1
)

echo.
echo *** Activating venv
call venv\Scripts\activate.bat
if errorlevel 1 (
  echo ERROR: Failed to activate venv.
  exit /b 1
)

echo.
echo *** Installing requirements
python -m pip install --upgrade pip
pip install --upgrade --force-reinstall -r requirements.txt
if errorlevel 1 (
  echo ERROR: pip install failed.
  call venv\Scripts\deactivate.bat
  exit /b 1
)


REM ==========================================================

REM Download and extract models

REM ==========================================================
echo.
echo *** Downloading models
curl -L -o model_assets.rar https://huggingface.co/datasets/Softology-Pro/VoC/resolve/main/model_assets.rar
if errorlevel 1 (
  echo ERROR: curl download failed.
  call venv\Scripts\deactivate.bat
  exit /b 1
)

echo.
echo *** Extracting models
if exist "%~dp0\7z.exe" (
  "%~dp0\7z.exe" x model_assets.rar -aoa
) else if exist "..\7z.exe" (
  "..\7z.exe" x model_assets.rar -aoa
) else (
  echo WARNING: 7z.exe not found next to install.bat or one folder up. Extraction skipped.
)

del /q model_assets.rar >nul 2>nul

echo.
echo *** Deactivating venv
call venv\Scripts\deactivate.bat

echo.
echo *** Installation complete
echo *** Scroll up and verify no errors occurred
pause

endlocal
