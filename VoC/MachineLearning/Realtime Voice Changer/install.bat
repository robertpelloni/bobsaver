@echo off
cls
D:
cd "D:\code\Delphi\Chaos\Examples\MachineLearning\\Realtime Voice Changer\"

echo *** VoC - Deleting MMVCServerSIO directory if it exists
if exist MMVCServerSIO. rd /S /Q MMVCServerSIO

echo *** Downloading Realtime Voice Changer
curl -L -o "MMVCServerSIO_win_onnxgpu-cuda_v.1.5.3.17b.zip" "https://huggingface.co/wok000/vcclient000/resolve/main/MMVCServerSIO_win_onnxgpu-cuda_v.1.5.3.17b.zip" -v

echo *** Unzipping Realtime Voice Changer
7z.exe x MMVCServerSIO_win_onnxgpu-cuda_v.1.5.3.17b.zip
del MMVCServerSIO_win_onnxgpu-cuda_v.1.5.3.17b.zip

echo *** finished Realtime Voice Changer install

echo.
echo *** Scroll up and check for any error messages.  Do not assume the install worked. ***
pause
