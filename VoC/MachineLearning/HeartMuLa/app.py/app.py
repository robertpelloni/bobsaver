import os
import tempfile
import torch
import gradio as gr
from huggingface_hub import hf_hub_download, snapshot_download
import spaces

# Download models from HuggingFace Hub on startup
def download_models():
    """Download all required model files from HuggingFace Hub."""
    cache_dir = os.environ.get("HF_HOME", os.path.expanduser("/tmp"))
    model_dir = os.path.join(cache_dir, "heartmula_models")

    if not os.path.exists(model_dir):
        os.makedirs(model_dir, exist_ok=True)

    # Download HeartMuLaGen (tokenizer and gen_config)
    print("Downloading HeartMuLaGen files...")
    for filename in ["tokenizer.json", "gen_config.json"]:
        hf_hub_download(
            repo_id="HeartMuLa/HeartMuLaGen",
            filename=filename,
            local_dir=model_dir,
        )

    # Download HeartMuLa-oss-3B
    print("Downloading HeartMuLa-oss-3B...")
    snapshot_download(
        repo_id="HeartMuLa/HeartMuLa-oss-3B",
        local_dir=os.path.join(model_dir, "HeartMuLa-oss-3B"),
    )

    # Download HeartCodec-oss
    print("Downloading HeartCodec-oss...")
    snapshot_download(
        repo_id="HeartMuLa/HeartCodec-oss",
        local_dir=os.path.join(model_dir, "HeartCodec-oss"),
    )

    print("All models downloaded successfully!")
    return model_dir

from heartlib import HeartMuLaGenPipeline

model_dir = download_models()

# Determine device and dtype
if torch.cuda.is_available():
    device = torch.device("cuda")
    dtype = torch.bfloat16
else:
    device = torch.device("cpu")
    dtype = torch.float32

print(f"Loading pipeline on {device} with {dtype}...")
pipe = HeartMuLaGenPipeline.from_pretrained(
    model_dir,
    device=device,
    dtype=dtype,
    version="3B",
)
print("Pipeline loaded successfully!")


@spaces.GPU(duration=130)
def generate_music(
    lyrics: str,
    tags: str,
    max_duration_seconds: int,
    temperature: float,
    topk: int,
    cfg_scale: float,
    progress=gr.Progress(track_tqdm=True),
):
    """Generate music from lyrics and tags."""
    if not lyrics.strip():
        raise gr.Error("Please enter some lyrics!")

    if not tags.strip():
        raise gr.Error("Please enter at least one tag!")

    # Create a temporary file for output
    with tempfile.NamedTemporaryFile(suffix=".mp3", delete=False) as f:
        output_path = f.name

    max_audio_length_ms = max_duration_seconds * 1000

    with torch.no_grad():
        pipe(
            {
                "lyrics": lyrics,
                "tags": tags,
            },
            max_audio_length_ms=max_audio_length_ms,
            save_path=output_path,
            topk=topk,
            temperature=temperature,
            cfg_scale=cfg_scale,
        )

    return output_path


# Example lyrics
EXAMPLE_LYRICS = """[Intro]

[Verse]
The sun creeps in across the floor
I hear the traffic outside the door
The coffee pot begins to hiss
It is another morning just like this

[Prechorus]
The world keeps spinning round and round
Feet are planted on the ground
I find my rhythm in the sound

[Chorus]
Every day the light returns
Every day the fire burns
We keep on walking down this street
Moving to the same steady beat
It is the ordinary magic that we meet

[Verse]
The hours tick deeply into noon
Chasing shadows, chasing the moon
Work is done and the lights go low
Watching the city start to glow

[Bridge]
It is not always easy, not always bright
Sometimes we wrestle with the night
But we make it to the morning light

[Chorus]
Every day the light returns
Every day the fire burns
We keep on walking down this street
Moving to the same steady beat

[Outro]
Just another day
Every single day"""

EXAMPLE_TAGS = "piano,happy,uplifting,pop"

# Build the Gradio interface
with gr.Blocks(
    title="HeartMuLa Music Generator",
) as demo:
    gr.Markdown(
        """
        # HeartMuLa Music Generator

        Generate music from lyrics and tags using [HeartMuLa](https://github.com/HeartMuLa/heartlib),
        an open-source music foundation model.

        **Instructions:**
        1. Enter your lyrics with structure tags like `[Verse]`, `[Chorus]`, `[Bridge]`, etc.
        2. Add comma-separated tags describing the music style (e.g., `piano,happy,romantic`)
        3. Adjust generation parameters as needed
        4. Click "Generate Music" and wait for your song!

        *Note: Generation can take several minutes depending on the duration.*
        """
    )

    with gr.Row():
        with gr.Column(scale=1):
            lyrics_input = gr.Textbox(
                label="Lyrics",
                placeholder="Enter lyrics with structure tags like [Verse], [Chorus], etc.",
                lines=20,
                value=EXAMPLE_LYRICS,
            )

            tags_input = gr.Textbox(
                label="Tags",
                placeholder="piano,happy,romantic,synthesizer",
                value=EXAMPLE_TAGS,
                info="Comma-separated tags describing the music style",
            )

            with gr.Accordion("Advanced Settings", open=False):
                max_duration = gr.Slider(
                    minimum=30,
                    maximum=240,
                    value=120,
                    step=10,
                    label="Max Duration (seconds)",
                    info="Maximum length of generated audio",
                )

                temperature = gr.Slider(
                    minimum=0.1,
                    maximum=2.0,
                    value=0.8,
                    step=0.1,
                    label="Temperature",
                    info="Higher = more creative, Lower = more consistent",
                )

                topk = gr.Slider(
                    minimum=1,
                    maximum=100,
                    value=50,
                    step=1,
                    label="Top-K",
                    info="Number of top tokens to sample from",
                )

                cfg_scale = gr.Slider(
                    minimum=1.0,
                    maximum=5.0,
                    value=3.5,
                    step=0.1,
                    label="CFG Scale",
                    info="Classifier-free guidance scale",
                )

            generate_btn = gr.Button("Generate Music", variant="primary", size="lg")

        with gr.Column(scale=1):
            audio_output = gr.Audio(
                label="Generated Music",
                type="filepath",
            )

            gr.Markdown(
                """
                Each category has an Importance percentage representing its "Selection Probability" during training.

                    Training Frequency: Tags were "sampled" during training. Genre was included 95% of the time, while Instrument was only included 25%.
                    Model Expectations: The model expects a Genre tag to function correctly. Without it, the generation lacks a clear structural anchor.
                    Influence vs. Stability: Higher percentages equal higher stability. A 95% tag (Genre) is a "Strong Anchor," while a 10% tag (Topic) is a "Weak Hint" that may be ignored if it conflicts with stronger tags.
                    The Strategy: For maximum control, lean heavily on the top 4 categories (Genre, Timbre, Gender, Mood). Use lower-percentage tags only as "seasoning" once the main structure is set.

                Official Categories

                    GENRE (95% - MANDATORY)
                    Examples: Pop, Rock, Electronic, Hiphop, Jazz, Classical, Techno, Trance, Ambient.
                    TIMBRE (50% - Sound Texture)
                    Examples: Soft, Warm, Husky, Bright, Dark, Distorted.
                    GENDER (37% - Vocal Character)
                    Examples: Male, Female.
                    MOOD (32% - Emotional Vibe)
                    Examples: Happy, Sad, Energetic, Joyful, Melancholic, Relaxing, Dark.
                    INSTRUMENT (25% - Dominant Sounds)
                    Examples: Piano, Synthesizer, Acoustic Guitar, Electric Guitar, Bass, Drums, Strings, Violin.
                    SCENE (20% - Listening Context)
                    Examples: Dance, Workout, Dating, Study, Cinematic, Party.
                    REGION (12% - Cultural Influence)
                    Examples: K-pop, Latin, Western.
                    TOPIC (10% - Lyrical Theme)
                    Examples: Love, Summer, Heartbreak.

                Prompting Strategy: "Less is More"

                To maintain a strong anchor and avoid "Probability Interference," avoid conflicting tags.

                    Semantic Conflict: Prompting "Rock, Jazz" splits the model's attention, often resulting in "muddy" or generic arrangements.
                    Anchor Stability: One strong anchor provides a clear map. Multiple genres create conflicting maps, causing the AI to lose focus.
                    Recommendation: Select only one tag per category. Be precise rather than broad.

                Recommended Format

                Use a comma-separated list.

                Examples:

                    Electronic, Techno, Synthesizer, Dark, High Energy, Club
                    Pop, Piano, Female, Sad, Soft, Love, Acoustic
                """
            )

    generate_btn.click(
        fn=generate_music,
        inputs=[
            lyrics_input,
            tags_input,
            max_duration,
            temperature,
            topk,
            cfg_scale,
        ],
        outputs=audio_output,
    )

    gr.Markdown(
        """
        ---
        **Model:** [HeartMuLa-oss-3B](https://huggingface.co/HeartMuLa/HeartMuLa-oss-3B) |
        **Paper:** [arXiv](https://arxiv.org/abs/2601.10547) |
        **Code:** [GitHub](https://github.com/HeartMuLa/heartlib)

        *Licensed under Apache 2.0*
        """
    )



demo.launch()
