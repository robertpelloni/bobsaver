@echo off




echo *** %time% *** Downloading example workflows
md Examples
if exist Examples\Hunyuan\. rd Examples\Hunyuan /s/q
md Examples\Hunyuan

cd Examples\Hunyuan
curl -L -o "hunyuan_video_text_to_video.json" "https://comfyanonymous.github.io/ComfyUI_examples/hunyuan_video/hunyuan_video_text_to_video.json" -v
curl -L -o "hunyuan_video_image_to_video.json" "https://comfyanonymous.github.io/ComfyUI_examples/hunyuan_video/hunyuan_video_image_to_video.json" -v
curl -L -o "hunyuan_video_image_to_video_v2.json" "https://comfyanonymous.github.io/ComfyUI_examples/hunyuan_video/hunyuan_video_image_to_video_v2.json" -v
curl -L -o "flux_dev_example.png" "https://comfyanonymous.github.io/ComfyUI_examples/flux/flux_dev_example.png" -v
cd..
cd..

echo *** %time% *** Finished Hunyuan install
echo.
echo Check the stats for any errors.  Do not assume it worked.
pause

rem Image-to-Video, Text-to-Video
