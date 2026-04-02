@echo off


set PYTHONIOENCODING=utf-8
set PYTHONUNBUFFERED=TRUE
set PYTHONLEGACYWINDOWSSTDIO=utf-8




call .venv\scripts\activate.bat
cd StreamingT2V\t2v_enhanced\
python inference.py --prompt="" --negative_prompt="" --base_model=AnimateDiff --num_steps=50 --num_frames=50 --image_guidance=9.0 --chunk=24 --overlap=8 --seed=0 --offload_models
