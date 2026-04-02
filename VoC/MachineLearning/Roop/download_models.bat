@echo off
cls


echo Downloading required model inswapper_128.onnx
echo to
echo If this download fails, search for another mirror of inswapper_128.onnx and put it in the above directory.
echo.
curl -L -o "inswapper_128.onnx" "https://huggingface.co/MCMLXXXVII/privRoop/resolve/main/inswapper_128.onnx" -v

echo.
echo Downloads completed.
echo ***** Scroll up and check for any error messages.  Do not assume the downloads worked. *****
pause