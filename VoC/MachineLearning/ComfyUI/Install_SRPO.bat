@echo off




rem echo *** %time% *** Deleting ComfyUI\custom_nodes\ComfyUI_ExtraModels directory if it exists
rem if exist ComfyUI\custom_nodes\ComfyUI_ExtraModels\. rd /S /Q ComfyUI\custom_nodes\ComfyUI_ExtraModels

echo *** %time% *** Downloading example workflow
md Examples
if exist Examples\SRPO\. rd Examples\SRPO /s/q
md Examples\SRPO

if exist Examples\SRPO\SRPO_workflow.json del Examples\SRPO\SRPO_workflow.json
curl -L -o "Examples\SRPO\SRPO_workflow.json" "https://huggingface.co/datasets/Softology-Pro/VoC/resolve/main/SRPO_workflow.json" -v

echo *** %time% *** Finished SRPO install
echo.
echo Check the stats for any errors.  Do not assume it worked.
pause

rem Text-to-Image
