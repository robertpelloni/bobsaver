@echo off
cd EveryDream2trainer
echo.
echo *** VoC - activating venv
call activate_venv.bat
echo.
echo *** VoC - converting models
python utils/convert_original_stable_diffusion_to_diffusers.py --scheduler_type ddim --original_config_file v1-inference.yaml --image_size 512 --checkpoint_path sd_v1-5_vae.ckpt --prediction_type epsilon --upcast_attn False --dump_path ckpt_cache/sd_v1-5_vae"
python utils/convert_original_stable_diffusion_to_diffusers.py --scheduler_type ddim --original_config_file v2-inference-v.yaml --image_size 768 --checkpoint_path v2-1_768-nonema-pruned.ckpt --prediction_type v_prediction --upcast_attn False --dump_path "ckpt_cache/v2-1_768-nonema-pruned"
python utils/convert_original_stable_diffusion_to_diffusers.py --scheduler_type ddim --original_config_file v2-inference.yaml --image_size 512 --checkpoint_path 512-base-ema.ckpt --prediction_type epsilon --upcast_attn False --dump_path "ckpt_cache/512-base-ema"
echo.
echo *** VoC - finished model conversion
