@echo off
cls
D:
cd "D:\code\delphi\Chaos\Examples\MachineLearning\AnimateDiff SDXL"


set "Start=%TIME%"

if not exist AnimateDiff\models\. goto skip1
echo *** VoC - Backing up existing AnimateDiff\models
move AnimateDiff\models models_backup

:skip1

echo *** VoC - Deleting AnimateDiff directory if it exists
if exist AnimateDiff\. rd /S /Q AnimateDiff

echo *** VoC - AnimateDiff SDXL git clone
git clone -b sdxl https://github.com/guoyww/AnimateDiff/

if not exist models_backup\. goto skip2
echo *** VoC - Restoring AnimateDiff\models
if exist AnimateDiff\models\. rd /S /Q AnimateDiff\models
move models_backup AnimateDiff\models

:skip2

if exist AnimateDiff\models\StableDiffusion\unet\. goto skip3
echo *** VoC - SDXL git clone
echo *** NOTE that this can take a long time with minimal stats.
echo *** Check Task Manager for network usage to verify it is still downloading.
if exist AnimateDiff\models\StableDiffusion\. rd /S /Q AnimateDiff\models\StableDiffusion
git clone https://huggingface.co/stabilityai/stable-diffusion-xl-base-1.0 AnimateDiff/models/StableDiffusion/

:skip3

echo *** VoC - Downloading missing models if required

call download_models.bat

set "End=%TIME%"

call :timediff Elapsed Start End

echo.
echo *** VoC - finished AnimateDiff SDXL install in %Elapsed%

echo.
echo *** Scroll up and check for any error messages.  Do not assume the install worked. ***
pause

exit /b

:: timediff
:: Input and output format is the same format as %TIME%
:: If EndTime is less than StartTime then:
::   EndTime will be treated as a time in the next day
::   in that case, function measures time difference between a maximum distance of 24 hours minus 1 centisecond
::   time elements can have values greater than their standard maximum value ex: 12:247:853.5214
::   provided than the total represented time does not exceed 24*360000 centiseconds
::   otherwise the result will not be meaningful.
:: If EndTime is greater than or equals to StartTime then:
::   No formal limitation applies to the value of elements,
::   except that total represented time can not exceed 2147483647 centiseconds.

:timediff <outDiff> <inStartTime> <inEndTime>
(
    setlocal EnableDelayedExpansion
    set "Input=!%~2! !%~3!"
    for /F "tokens=1,3 delims=0123456789 " %%A in ("!Input!") do set "time.delims=%%A%%B "
)
for /F "tokens=1-8 delims=%time.delims%" %%a in ("%Input%") do (
    for %%A in ("@h1=%%a" "@m1=%%b" "@s1=%%c" "@c1=%%d" "@h2=%%e" "@m2=%%f" "@s2=%%g" "@c2=%%h") do (
        for /F "tokens=1,2 delims==" %%A in ("%%~A") do (
            for /F "tokens=* delims=0" %%B in ("%%B") do set "%%A=%%B"
        )
    )
    set /a "@d=(@h2-@h1)*360000+(@m2-@m1)*6000+(@s2-@s1)*100+(@c2-@c1), @sign=((@d&0x80000000)>>31)&1, @d+=(@sign*24*360000), @h=(@d/360000), @d%%=360000, @m=@d/6000, @d%%=6000, @s=@d/100, @c=@d%%100"
)
(
    if /i %@h% LEQ 9 set "@h=0%@h%"
    if /i %@m% LEQ 9 set "@m=0%@m%"
    if /i %@s% LEQ 9 set "@s=0%@s%"
    if /i %@c% LEQ 9 set "@c=0%@c%"
)
(
    endlocal
    set "%~1=%@h%%time.delims:~0,1%%@m%%time.delims:~0,1%%@s%%time.delims:~1,1%%@c%"
    exit /b
)
