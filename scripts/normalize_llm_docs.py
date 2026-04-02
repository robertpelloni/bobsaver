import os
import glob

# Paths to process (the root and submodules)
roots = ['.', 'JWildfire', 'apophysis-j', 'BeatDrop', 'electricsheep', 'geiss', 'MilkDrop3', 'projectm']
files_to_check = ['CLAUDE.md', 'GEMINI.md', 'GPT.md', 'copilot-instructions.md', 'AGENTS.md']

header_template = """> **CRITICAL MANDATE: READ `docs/UNIVERSAL_LLM_INSTRUCTIONS.md` FIRST.**
> This file contains only {model}-specific overrides or notes. You must follow all protocols in the universal document.

"""

for root in roots:
    for filename in files_to_check:
        filepath = os.path.join(root, filename)
        if os.path.exists(filepath):
            with open(filepath, 'r', encoding='utf-8') as f:
                content = f.read()
            
            if "UNIVERSAL_LLM_INSTRUCTIONS.md" not in content:
                model_name = filename.split('.')[0]
                new_content = header_template.format(model=model_name) + content
                with open(filepath, 'w', encoding='utf-8') as f:
                    f.write(new_content)
                print(f"Updated {filepath}")
            else:
                print(f"Skipped {filepath} (Already normalized)")
