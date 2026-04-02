@echo off

echo You can rerun this script to update the installation.

rem echo Moving to AppData\Roaming\so-vits-svc-fork...
rem mkdir "%APPDATA%\so-vits-svc-fork" >nul 2>&1
rem cd "%APPDATA%\so-vits-svc-fork"

rem echo Checking for Python 3.10...

rem py -3.10 --version >nul 2>&1
rem if %errorlevel%==0 (
rem     echo Python 3.10 is already installed.
rem ) else (
rem     echo Python 3.10 is not installed. Downloading installer...
rem     curl https://www.python.org/ftp/python/3.10.10/python-3.10.10-amd64.exe -o python-3.10.10-amd64.exe -v
rem 
rem     echo Installing Python 3.10...
rem     python-3.10.10-amd64.exe /quiet InstallAllUsers=1 PrependPath=1
rem 
rem     echo Cleaning up installer...
rem     del python-3.10.10-amd64.exe
rem )

echo Creating virtual environment...
py -3.10 -m venv venv

echo Updating pip and wheel...
venv\Scripts\python.exe -m pip install --upgrade pip wheel

nvidia-smi >nul 2>&1
if %errorlevel%==0 (
    echo Installing PyTorch with GPU support...
venv\Scripts\pip.exe install torch torchaudio --index-url https://download.pytorch.org/whl/cu118
) else (
    echo Installing PyTorch without GPU support...
    venv\Scripts\pip.exe install torch torchaudio
)

echo Installing so-vits-svc-fork...
venv\Scripts\pip.exe install -U so-vits-svc-fork

echo *** VoC - patching typing_extensions
pip uninstall -y typing_extensions
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts typing_extensions==4.11.0

rem echo Creating shortcut...
rem powershell "$s=(New-Object -COM WScript.Shell).CreateShortcut('%USDRPROFILE%\Desktop\so-vits-svc-fork.lnk');$s.TargetPath='%APPDATA%\so-vits-svc-fork\venv\Scripts\svcg.exe';$s.Save()"

rem echo Creating shortcut to the start menu...
rem powershell "$s=(New-Object -COM WScript.Shell).CreateShortcut('%APPDATA%\Microsoft\Windows\Start Menu\Programs\so-vits-svc-fork.lnk');$s.TargetPath='%APPDATA%\so-vits-svc-fork\venv\Scripts\svcg.exe';$s.Save()"

rem echo Launching so-vits-svc-fork GUI...
rem venv\Scripts\svcg.exe

echo Install done
pause
