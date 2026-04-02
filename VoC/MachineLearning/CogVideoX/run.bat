@echo off
rem set CC=cl.exe
cd CogVideo
call venv\scripts\activate.bat
python -u -B -W ignore "D:\\code\\Delphi\\Chaos\\Examples\\MachineLearning\\CogVideoX\\CogVideo\\inference\\cli_demo.py" --prompt "A panda, dressed in a small, red jacket and a tiny hat, sits on a wooden stool in a serene bamboo forest. The panda's fluffy paws strum a miniature acoustic guitar, producing soft, melodic tunes. Nearby, a few other pandas gather, watching curiously and some clapping in rhythm. Sunlight filters through the tall bamboo, casting a gentle glow on the scene. The panda's face is expressive, showing concentration and joy as it plays. The background includes a small, flowing stream and vibrant green foliage, enhancing the peaceful and magical atmosphere of this unique musical performance." --seed 0 --model_path "THUDM/CogVideoX-5b" --num_inference_steps 48 --guidance_scale 6 --num_videos_per_prompt 1 --generate_type t2v --dtype "bfloat16" --output_path "D:\VoC Output\Movies\CogVideoX\cvx00001.mp4"
cd..
rem rem set CC=C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Tools\MSVC\14.41.34120\bin\Hostx64\x64
