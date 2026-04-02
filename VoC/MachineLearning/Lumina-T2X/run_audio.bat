@echo off
cls
cd Lumina-T2X
call venv\scripts\activate.bat
cd lumina_audio
python demo_audio.py --ckpt ..\models\Lumina-T2Audio\audio_generation  --vocoder_ckpt ..\models\Lumina-T2Audio\bigvgan --config_path .\configs\lumina-text2audio.yaml --sample_rate 16000
cd..
call venv\scripts\deactivate.bat
cd..
