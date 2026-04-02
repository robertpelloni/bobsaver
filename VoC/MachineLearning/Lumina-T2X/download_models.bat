@echo off
 



cd Lumina-T2X
if exist models\. rd models /s/q
if not exist models\. md models
cd models

echo *** Cloning Lumina-T2I models
git clone https://huggingface.co/Alpha-VLLM/Lumina-T2I

echo *** Cloning Lumina-Next-T2I models
git clone https://huggingface.co/Alpha-VLLM/Lumina-Next-T2I

rem echo *** Cloning Lumina-T2Music models
rem git clone https://huggingface.co/Alpha-VLLM/Lumina-T2Music

rem echo *** Cloning Lumina-T2Audio models
rem git clone https://huggingface.co/Alpha-VLLM/Lumina-T2Audio

echo *** Downloading LLaMA models
curl -L -o "Llama-2-7b-hf.rar" "https://huggingface.co/datasets/Softology-Pro/VoC/resolve/main/models2.rar" -v

echo *** Extracting LLaMA models
..\..\7z x Llama-2-7b-hf.rar
del Llama-2-7b-hf.rar

echo *** Downloading gemma models
curl -L -o "gemma-2b.rar" "https://huggingface.co/datasets/Softology-Pro/VoC/resolve/main/models3.rar" -v

echo *** Extracting gemma models
..\..\7z x gemma-2b.rar
del gemma-2b.rar

cd..
echo.
echo Downloads completed.
echo ***** Scroll up and check for any error messages.  Do not assume the downloads worked. *****
pause
