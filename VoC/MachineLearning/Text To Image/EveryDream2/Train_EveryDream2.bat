@echo off
cd EveryDream2trainer
echo.
echo *** VoC - activating venv
call activate_venv.bat
echo.
echo *** VoC - starting training
python train.py --resume_ckpt "sd_v1-5_vae" --max_epochs 50 --data_root "" --lr_scheduler cosine --project_name myproj --batch_size 2 --sample_steps 200 --lr 3e-6 --ckpt_every_n_minutes 10 --clip_grad_norm 1 --resolution 512 --useadam8bit
echo.
echo *** VoC - finished training
