@echo off

cd YuE-exllamav2
call venv\scripts\activate.bat

python src/yue/infer.py --stage1_use_exl2 --stage2_use_exl2 --stage2_cache_size 32768 --genre_txt ..\genre.txt --lyrics_txt ..\lyrics.txt --run_n_segments 2 --stage2_batch_size 4 --output_dir . --cuda_idx 0 --max_new_tokens 3000 --seed 0
call venv\scripts\deactivate.bat
cd..
