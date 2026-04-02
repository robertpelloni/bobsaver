@echo off
echo Started: %date% %time% 



if exist pretrained\. rd pretrained /s /q
git clone https://huggingface.co/xinyuanc91/SEINE
move SEINE pretrained
cd pretrained
git clone https://huggingface.co/CompVis/stable-diffusion-v1-4

echo Finished: %date% %time% 

echo.
echo Downloads completed.
echo ***** Scroll up and check for any error messages.  Do not assume the downloads worked. *****
pause
D:
