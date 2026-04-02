@echo off

D:
cd "D:\code\delphi\Chaos\Examples\MachineLearning\Text To Image\HunyuanImage-2.1\"

cd HunyuanImage-2.1
call venv\Scripts\activate.bat
python inference.py  --prompt "an alien fleet of spaceships approaching the earth" --seed 763743952 --w 1536 --h 2560 --reprompt 0 --refiner 1 --image_file "D:\\VoC_Output\\Images\\an alien fleet of spaceships approaching the earth [HunyuanImage-2.1 Distilled] 763743952.png" --model hunyuanimage-v2.1-distilled --steps 8
call venv\scripts\deactivate.bat
cd..
