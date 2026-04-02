@echo off




echo *** %time% *** Deleting Examples\Cosmos directory if it exists
if exist Examples\Cosmos\. rd /S /Q Examples\Cosmos

echo *** %time% *** Downloading COSMOS models
md ComfyUI\models\diffusion_models
md ComfyUI\models\text_encoders
md ComfyUI\models\vae

rem skip model downloads?
if "%1"=="" goto download_models
echo *** VoC - skipping model downloads
goto skip_models
:download_models

:skip_models

echo *** %time% *** Downloading example workflow
md Examples
md Examples\Cosmos
if exist Examples\Cosmos\COSMOS.json del Examples\Cosmos\COSMOS.json
curl -L -o "Examples\Cosmos\Cosmos.json" "https://gist.github.com/comfyanonymous/2f57adabe5a22b36a21ae024306daddb/raw/378944646e97018cb83bf3883ae645920e1c48fd/cosmos_test_workflow.json" -v

echo *** %time% *** Finished COSMOS install
echo.
echo Check the stats for any errors.  Do not assume it worked.
pause

rem Text-to-Video
