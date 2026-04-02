@echo off
cls
set "Start=%TIME%"




set "End=%TIME%"
call :timediff Elapsed Start End
echo Finished in %Elapsed%
echo.
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
pause
