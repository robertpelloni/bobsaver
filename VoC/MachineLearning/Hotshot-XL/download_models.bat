@echo off
cls



echo *** VoC - Deleting Hotshot-XL directory if it exists
if exist Hotshot-XL. rd /S /Q Hotshot-XL

echo *** VoC - git clone Hotshot-XL
git clone https://huggingface.co/hotshotco/Hotshot-XL

echo.
echo Downloads completed.
echo ***** Scroll up and check for any error messages.  Do not assume the downloads worked. *****
pause
D:
