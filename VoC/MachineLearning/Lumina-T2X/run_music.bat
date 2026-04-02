@echo off
cls
cd Lumina-T2X
call venv\scripts\activate.bat
cd lumina_music
python demo_music.py --ckpt ..\models\Lumina-T2Music\music_generation  --vocoder_ckpt ..\models\Lumina-T2Music\bigvnat --config_path .\configs\lumina-text2music.yaml --sample_rate 16000
cd..
call venv\scripts\deactivate.bat
cd..
