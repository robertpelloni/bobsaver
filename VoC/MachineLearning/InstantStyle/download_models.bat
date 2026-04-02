@echo off
 


if exist models\. rd models /s/q
rem if exist sdxl_models\. rd sdxl_models /s/q
if exist IP-Adapter\. rd IP-Adapter /s/q
git clone https://huggingface.co/h94/IP-Adapter
rem move IP-Adapter/models models
rem move IP-Adapter/sdxl_models sdxl_models
move IP-Adapter/sdxl_models models
rd IP-Adapter /s/q

echo.
echo Downloads completed.
echo ***** Scroll up and check for any error messages.  Do not assume the downloads worked. *****
pause
