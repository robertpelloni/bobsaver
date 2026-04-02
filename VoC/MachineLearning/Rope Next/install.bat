@echo off

D:
cd "D:\code\delphi\Chaos\Examples\MachineLearning\Rope Next\"
echo *** %time% *** Deleting Rope-Next-Portable_CUDA12_4_TensorRT10_4_Win_1_0 directory if it exists
if exist Rope-Next-Portable_CUDA12_4_TensorRT10_4_Win_1_0\. rd /S /Q Rope-Next-Portable_CUDA12_4_TensorRT10_4_Win_1_0

echo *** %time% *** Downloading zip files
curl -L -o Rope-Next-Portable_CUDA12_4_TensorRT10_4_Win_1_0.7z.001 https://github.com/Alucard24/Rope/releases/download/v.1.0.0/Rope-Next-Portable_CUDA12_4_TensorRT10_4_Win_1_0.7z.001 -v
curl -L -o Rope-Next-Portable_CUDA12_4_TensorRT10_4_Win_1_0.7z.002 https://github.com/Alucard24/Rope/releases/download/v.1.0.0/Rope-Next-Portable_CUDA12_4_TensorRT10_4_Win_1_0.7z.002 -v
curl -L -o Rope-Next-Portable_CUDA12_4_TensorRT10_4_Win_1_0.7z.003 https://github.com/Alucard24/Rope/releases/download/v.1.0.0/Rope-Next-Portable_CUDA12_4_TensorRT10_4_Win_1_0.7z.003 -v

echo *** %time% *** Unzipping zip files
7z x Rope-Next-Portable_CUDA12_4_TensorRT10_4_Win_1_0.7z.001

echo *** %time% *** Deleting zip files
del Rope-Next-Portable_CUDA12_4_TensorRT10_4_Win_1_0.7z.001
del Rope-Next-Portable_CUDA12_4_TensorRT10_4_Win_1_0.7z.002
del Rope-Next-Portable_CUDA12_4_TensorRT10_4_Win_1_0.7z.003

echo *** %time% *** Installing Rope Next
cd Rope-Next-Portable
call Install_Rope_Next.bat

cd ..
echo *** %time% *** Finished Rope Next install
echo.
echo Check the stats for any errors.  Do not assume it worked.
pause
