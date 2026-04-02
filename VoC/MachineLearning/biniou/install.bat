@echo off



echo *** %time% *** Deleting biniou directory if it exists
if exist biniou\. rd /S /Q biniou

echo *** %time% *** Cloning biniou repository
git clone https://github.com/Woolverine94/biniou
cd biniou

md outputs
md ssl
md models
md models\Audiocraft

echo *** %time% *** Creating venv
python -m venv venv

echo *** %time% *** Activating venv
call venv\scripts\activate.bat

echo *** %time% *** Installing requirements
python -m pip install --upgrade pip==24.3.1
pip install -r requirements.txt
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts triton-windows==3.5.0.post21

echo *** %time% *** Patching xformers
pip uninstall -y xformers
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts xformers==0.0.30

echo *** %time% *** Installing GPU torch
pip uninstall -y torch
pip uninstall -y torch
rem pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts torch==2.1.0+cu121 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts torch==2.7.0+cu128 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128

echo *** %time% *** Installing llama-cpp-python
pip install llama-cpp-python

echo *** %time% *** Patching typing-extensions
pip uninstall -y typing_extensions
pip install typing_extensions==4.12.2

echo *** %time% *** Patching charset-normalizer
pip uninstall -y charset-normalizer
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts charset-normalizer==3.3.2

echo *** VoC - patching typing_extensions
pip uninstall -y typing_extensions
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts typing_extensions==4.11.0

echo *** VoC - patching pydantic
pip uninstall -y pydantic
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts pydantic==2.10.6

echo *** VoC - patching numpy
pip uninstall -y numpy
pip uninstall -y numpy
pip install --no-cache-dir --ignore-installed --force-reinstall --no-warn-conflicts numpy==1.26.4

call venv\scripts\deactivate.bat
cd ..

echo *** %time% *** Downloading openssl installer
curl -L - o FireDaemon-OpenSSL-x64-3.3.1.exe https://download.firedaemon.com/FireDaemon-OpenSSL/FireDaemon-OpenSSL-x64-3.3.1.exe -v

echo *** %time% *** Installing openssl
FireDaemon-OpenSSL-x64-3.3.1.exe /passive

echo *** %time% *** Creating SSL certificate
"%ProgramW6432%\FireDaemon OpenSSL 3\bin\openssl.exe" req -x509 -newkey rsa:4096 -keyout "biniou\ssl\key.pem" -out "biniou\ssl\cert.pem" -sha256 -days 3650 -nodes -subj "/C=FR/ST=Paris/L=Paris/O=Biniou/OU=/CN="

copy ffmpeg.exe biniou\ffmpeg.exe
copy ffprobe.exe biniou\ffprobe.exe

echo *** %time% *** Finished biniou install
echo.
echo Check the stats for any errors.  Do not assume it worked.
pause
