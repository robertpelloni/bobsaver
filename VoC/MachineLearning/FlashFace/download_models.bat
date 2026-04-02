@echo off
 


rd cache /s/q

git clone https://huggingface.co/shilongz/FlashFace-SD1.5

move FlashFace-SD1.5 cache

echo.
echo Downloads completed.
echo ***** Scroll up and check for any error messages.  Do not assume the downloads worked. *****
pause
