@echo off
cd Step1X-Edit
call venv\Scripts\activate.bat
rem python inference.py --input_dir examples --model_path models --json_path examples\prompt_en.json --output_dir output_en --seed 1234 --size_level 1024 --offload --quantized
python gradio_app.py --model_path models --offload --quantized
call venv\scripts\deactivate.bat
cd..
