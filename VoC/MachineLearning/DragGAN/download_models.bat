@echo off
cls



echo Downloading required models...
echo.
curl -L -o "checkpoints/stylegan2_lions_512_pytorch.pkl" "https://storage.googleapis.com/self-distilled-stylegan/lions_512_pytorch.pkl" -v
curl -L -o "checkpoints/stylegan2_dogs_1024_pytorch.pkl" "https://storage.googleapis.com/self-distilled-stylegan/dogs_1024_pytorch.pkl" -v
curl -L -o "checkpoints/stylegan2_horses_256_pytorch.pkl" "https://storage.googleapis.com/self-distilled-stylegan/horses_256_pytorch.pkl" -v
curl -L -o "checkpoints/stylegan2_elephants_512_pytorch.pkl" "https://storage.googleapis.com/self-distilled-stylegan/elephants_512_pytorch.pkl" -v
curl -L -o "checkpoints/stylegan2-ffhq-512x512.pkl" "https://api.ngc.nvidia.com/v2/models/nvidia/research/stylegan2/versions/1/files/stylegan2-ffhq-512x512.pkl" -v
curl -L -o "checkpoints/stylegan2-afhqcat-512x512.pkl" "https://api.ngc.nvidia.com/v2/models/nvidia/research/stylegan2/versions/1/files/stylegan2-afhqcat-512x512.pkl" -v
curl -L -o "checkpoints/stylegan2-car-config-f.pkl" "http://d36zk2xti64re0.cloudfront.net/stylegan2/networks/stylegan2-car-config-f.pkl" -v
curl -L -o "checkpoints/stylegan2-cat-config-f.pkl" "http://d36zk2xti64re0.cloudfront.net/stylegan2/networks/stylegan2-cat-config-f.pkl" -v

echo.
echo Downloads completed.
echo ***** Scroll up and check for any error messages.  Do not assume the downloads worked. *****
pause