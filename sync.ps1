$ErrorActionPreference = 'Continue'

$repos = @(".", "JWildfire", "apophysis-j", "BeatDrop", "electricsheep", "geiss", "MilkDrop3", "projectm")

foreach ($repo in $repos) {
    Write-Host "========================================="
    Write-Host "Syncing $repo"
    Write-Host "========================================="
    
    Push-Location $repo
    
    # 1. Fetch all
    git fetch --all
    
    # 2. Determine primary branch
    $mainBranch = "main"
    $hasMain = git branch -a | Select-String "remotes/origin/main"
    if (-not $hasMain) {
        $hasMaster = git branch -a | Select-String "remotes/origin/master"
        if ($hasMaster) {
            $mainBranch = "master"
        }
    }
    Write-Host "Primary branch for $repo is $mainBranch"
    
    git checkout $mainBranch
    git pull origin $mainBranch
    
    # 3. Merge robertpelloni branches
    $branches = git branch -a | Where-Object { $_ -match "robertpelloni" }
    foreach ($b in $branches) {
        $bName = $b.Trim() -replace '^\*\s+', '' -replace '^remotes/origin/', ''
        if ($bName -ne $mainBranch -and $bName -notmatch "HEAD") {
            Write-Host "Merging $bName into $mainBranch"
            git merge --no-edit $bName
            if ($LASTEXITCODE -ne 0) {
                Write-Host "Conflict or error merging $bName into $mainBranch, aborting merge..."
                git merge --abort
            }
        }
    }
    
    # 4. Merge upstream if fork
    $remotes = git remote
    if ($remotes -contains "upstream") {
        Write-Host "Merging upstream/$mainBranch"
        git fetch upstream
        git merge --no-edit upstream/$mainBranch
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Conflict or error merging upstream, aborting merge..."
            git merge --abort
        }
    }
    
    # 5. Push primary branch
    Write-Host "Pushing $mainBranch to origin"
    git push origin $mainBranch
    
    # 6. For feature branches, merge main back
    $localBranches = git branch | Where-Object { $_ -match "robertpelloni" }
    foreach ($lb in $localBranches) {
        $lbName = $lb.Trim() -replace '^\*\s+', ''
        if ($lbName -ne $mainBranch) {
            Write-Host "Checking out $lbName to merge $mainBranch back"
            git checkout $lbName
            git merge --no-edit $mainBranch
            if ($LASTEXITCODE -ne 0) {
                Write-Host "Conflict merging $mainBranch into $lbName, aborting..."
                git merge --abort
            }
            git push origin $lbName
        }
    }
    
    # Return to primary branch
    git checkout $mainBranch
    
    Pop-Location
}
Write-Host "Done syncing all repositories."
