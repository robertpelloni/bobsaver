@echo off




echo *** %time% *** Deleting Examples\Qwen-Image directory if it exists
if exist Examples\Qwen-Image\. rd /S /Q Examples\Qwen-Image

echo *** %time% *** Downloading example workflows
md Examples\Qwen-Image
curl -L -o "Examples\Qwen-Image\image_qwen_image.json" "https://raw.githubusercontent.com/Comfy-Org/workflow_templates/refs/heads/main/templates/image_qwen_image.json" -v
curl -L -o "Examples\Qwen-Image\image_qwen_image_distill.json" "https://raw.githubusercontent.com/Comfy-Org/example_workflows/main/image/qwen/image_qwen_image_distill.json" -v
curl -L -o "Examples\Qwen-Image\image_qwen_image_edit.json" "https://raw.githubusercontent.com/Comfy-Org/workflow_templates/refs/heads/main/templates/image_qwen_image_edit.json" -v

echo *** %time% *** Finished Qwen-Image install
echo.
echo Check the stats for any errors.  Do not assume it worked.
pause

rem Text-to-Image, Image Editing