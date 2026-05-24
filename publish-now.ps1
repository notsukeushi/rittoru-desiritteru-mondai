$ErrorActionPreference = "Continue"
$RepoName = "rittoru-desiritteru-mondai"
$env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
Set-Location $PSScriptRoot

function Test-GhAuth {
    gh auth status 2>&1 | Out-Null
    return ($LASTEXITCODE -eq 0)
}

if (-not (Test-GhAuth)) {
    Write-Host "Opening GitHub device login..."
    Start-Process "https://github.com/login/device"
    gh auth login --hostname github.com --git-protocol https --web
    if (-not (Test-GhAuth)) {
        Write-Error "GitHub login not completed."
        exit 1
    }
}

$ErrorActionPreference = "Stop"
$owner = gh api user -q .login
Write-Host "Logged in as: $owner"

if (-not (Test-Path .git)) {
    git init -b main
}

git add index.html publish-now.ps1 .gitignore "2026_05_24_文章題_リットルとデシリットル_7問_乱数版_スマホ.html"
$st = git status --porcelain
if ($st) {
    git commit -m "Add liter and deciliter word problems (9 questions)"
}

if (git remote get-url origin 2>$null) { git remote remove origin }
git remote add origin "https://github.com/$owner/$RepoName.git"

gh repo view "$owner/$RepoName" 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) {
    gh repo create $RepoName --public --description "Grade 3 word problems: liters and deciliters"
}

git push -u origin main

gh api -X POST "/repos/$owner/$RepoName/pages" -f "build_type=legacy" -f "source[branch]=main" -f "source[path]=/" 2>&1 | Out-Null

$base = "https://$owner.github.io/$RepoName"
Write-Host "Done: $base/"
