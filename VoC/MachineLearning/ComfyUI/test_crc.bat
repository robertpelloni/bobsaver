@echo off
set filename=ComfyUI\models\checkpoints\v1-5-pruned-emaonly-fp16.safetensors
if not exist %filename% goto model1_download
set targetchecksum=cc47d218eacc45829ce8d42e1c6141dc
echo *** Checking hash of "%filename%"
for /f "delims=" %%A in ('certutil -hashfile "%filename%" MD5 ^| find /v ":"') do set "checksum=%%A"
if %checksum%==%targetchecksum% goto model1_skip1
:model1_download
echo Downloading model.
rem wget etc here
goto model1_skip2
:model1_skip1
echo *** "%filename%" passes checksum.  Skipping download.
:model1_skip2
