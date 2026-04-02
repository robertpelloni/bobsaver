@echo off



if exist models\. rd models /s/q
md models
cd models

md arc2face
cd arc2face
curl -L -o config.json https://huggingface.co/FoivosPar/Arc2Face/resolve/main/arc2face/config.json -v
curl -L -o diffusion_pytorch_model.safetensors https://huggingface.co/FoivosPar/Arc2Face/resolve/main/arc2face/diffusion_pytorch_model.safetensors -v
cd..

md encoder
cd encoder
curl -L -o config.json https://huggingface.co/FoivosPar/Arc2Face/resolve/main/encoder/config.json -v
curl -L -o pytorch_model.bin https://huggingface.co/FoivosPar/Arc2Face/resolve/main/encoder/pytorch_model.bin -v
cd..

curl -L -o antelopev2.zip https://huggingface.co/datasets/Softology-Pro/VoC/resolve/main/antelopev2.zip -v
..\7z x antelopev2.zip
del antelopev2.zip
cd antelopev2
curl -L -o arcface.onnx https://huggingface.co/FoivosPar/Arc2Face/resolve/main/arcface.onnx -v
del glintr100.onnx
cd..

echo.
echo Downloads completed.
echo ***** Scroll up and check for any error messages.  Do not assume the downloads worked. *****
pause
