import os
import subprocess
import sys

# Submodules to process
SUBMODULES = [
    "apophysis-j",
    "BeatDrop",
    "electricsheep",
    "geiss",
    "MilkDrop3",
    "projectm",
    "JWildfire"
]

DEFAULT_TIMEOUT_SEC = 25

def run_git(cmd, cwd=None, timeout=DEFAULT_TIMEOUT_SEC):
    """Executes a git command with timeout and returns the output."""
    try:
        result = subprocess.run(
            ["git"] + cmd,
            cwd=cwd,
            capture_output=True,
            text=True,
            check=False,
            timeout=timeout
        )
        return result
    except subprocess.TimeoutExpired:
        print(f"Warning: git {' '.join(cmd)} timed out after {timeout}s in {cwd}")
        return None
    except Exception as e:
        print(f"Error running git {' '.join(cmd)} in {cwd}: {e}")
        return None

def get_primary_branch(repo_path):
    """Determines if the primary branch is 'main' or 'master'."""
    res = run_git(["branch", "-a"], cwd=repo_path)
    if not res or res.returncode != 0:
        return "main"
    branches = res.stdout
    if "* main" in branches or "remotes/origin/main" in branches:
        return "main"
    return "master"

def sync_repo(name, path):
    print(f"\n--- Syncing {name} ({path}) ---")
    
    # 1. Fetch all with safety timeout
    print("Fetching all...")
    run_git(["fetch", "--all"], cwd=path, timeout=30)
    
    primary = get_primary_branch(path)
    print(f"Primary branch identified as: {primary}")
    
    # 2. Ensure we are on primary
    run_git(["checkout", primary], cwd=path)
    run_git(["pull", "origin", primary], cwd=path, timeout=30)
    
    # 3. Identify feature branches to merge
    res = run_git(["branch", "-r"], cwd=path)
    if not res:
        return
    
    remote_branches = [line.strip() for line in res.stdout.split('\n') if line.strip()]
    feature_patterns = ["origin/copilot-", "origin/wip-", "origin/jules-", "origin/feat/"]
    
    to_merge = []
    for rb in remote_branches:
        if any(pattern in rb for pattern in feature_patterns):
            if primary in rb:
                continue
            to_merge.append(rb)
            
    for branch in to_merge:
        print(f"Merging {branch} into {primary}...")
        res = run_git(["merge", branch], cwd=path)
        if res is None or res.returncode != 0:
            print(f"CONFLICT or timeout encountered while merging {branch}. Attempting to resolve...")
            run_git(["merge", "--abort"], cwd=path)
            print(f"Retrying merge with '-X theirs' for {branch}...")
            res = run_git(["merge", "-X", "theirs", branch, "-m", f"Merge {branch} into {primary} (favoring feature branch)"], cwd=path)
            if res is None or res.returncode != 0:
                print(f"FAILED to merge {branch} even with '-X theirs'. Skipping for now.")
                run_git(["merge", "--abort"], cwd=path)
            else:
                print(f"Successfully merged {branch} with '-X theirs'.")
        else:
            print(f"Successfully merged {branch}.")
            
    # 4. Pull upstream if it's a fork
    res = run_git(["remote"], cwd=path)
    if res and "upstream" in res.stdout:
        print("Syncing with upstream...")
        upstream_res = run_git(["fetch", "upstream"], cwd=path, timeout=30)
        if upstream_res and upstream_res.returncode == 0:
            run_git(["merge", f"upstream/{primary}"], cwd=path)

    # 5. Push changes
    print(f"Pushing {primary} to origin...")
    run_git(["push", "origin", primary], cwd=path, timeout=30)

def main():
    root_path = os.getcwd()
    
    # Sync root repo
    sync_repo("Root", root_path)
    
    # Sync submodules
    for sm in SUBMODULES:
        sm_path = os.path.join(root_path, sm)
        if os.path.exists(sm_path):
            sync_repo(sm, sm_path)
        else:
            print(f"Submodule path not found: {sm_path}")

if __name__ == "__main__":
    main()
