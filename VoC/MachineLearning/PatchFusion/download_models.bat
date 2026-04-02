@echo off
 



rd nfs /s/q
if not exist nfs\. md nfs
curl -L -o "nfs\patchfusion_u4k.pt" "https://huggingface.co/datasets/Softology-Pro/VoC/resolve/main/patchfusion_u4k.pt" -v

echo.
echo Downloads completed.
echo ***** Scroll up and check for any error messages.  Do not assume the downloads worked. *****
pause
