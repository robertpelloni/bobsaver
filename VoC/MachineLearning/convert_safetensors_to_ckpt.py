import torch
from safetensors.torch import load_file
import sys
import os

def convert_safetensors_to_ckpt(safetensors_path, ckpt_path):
    """
    Converts a .safetensors model file to a .ckpt model file.
    """
    if not os.path.exists(safetensors_path):
        print(f"Error: Input file not found at {safetensors_path}")
        return

    print(f"Loading {safetensors_path}...")
    # Load the state dictionary from the safetensors file
    try:
        state_dict = load_file(safetensors_path)
    except Exception as e:
        print(f"Error loading safetensors file: {e}")
        return

    print(f"Saving to {ckpt_path}...")
    # Save the state dictionary as a PyTorch checkpoint (ckpt) file
    try:
        torch.save(state_dict, ckpt_path)
        print("Conversion successful!")
    except Exception as e:
        print(f"Error saving ckpt file: {e}")

if __name__ == "__main__":
    # Define input and output paths
    input_file = "your_model_name.safetensors"
    output_file = "converted_model_name.ckpt"
    
    # Check if a custom filename was provided as a command line argument
    if len(sys.argv) > 1:
        input_file = sys.argv[1]
        if len(sys.argv) > 2:
            output_file = sys.argv[2]
        else:
            output_file = os.path.splitext(input_file)[0] + ".ckpt"

    convert_safetensors_to_ckpt(input_file, output_file)
