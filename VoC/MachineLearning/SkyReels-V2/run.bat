@echo off
cd SkyReels-V2
call venv\Scripts\activate.bat
python generate_video_df.py --model_id "Skywork/SkyReels-V2-DF-1.3B-540P" --resolution 540P --ar_step 0 --base_num_frames 97 --num_frames 257 --overlap_history 17 --prompt "Shrek eating pizza while riding a bicycle in his swamp" --addnoise_condition 20 --offload --seed 0
call venv\scripts\deactivate.bat
cd..
