@echo off
cd InfiniteTalk
call venv\scripts\activate.bat
python app.py --ckpt_dir weights/Wan2.1-I2V-14B-480P --wav2vec_dir "weights\chinese-wav2vec2-base" --infinitetalk_dir weights/InfiniteTalk/single/infinitetalk.safetensors --num_persistent_param_in_dit 0 --motion_frame 9
call venv\scripts\deactivate.bat
cd..
