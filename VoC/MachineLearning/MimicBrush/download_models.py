from huggingface_hub import snapshot_download
snapshot_download(repo_id="xichenhku/cleansd", local_dir="./cleansd")
print('=== Pretrained SD weights downloaded ===')
snapshot_download(repo_id="xichenhku/MimicBrush", local_dir="./MimicBrush")
print('=== MimicBrush weights downloaded ===')
