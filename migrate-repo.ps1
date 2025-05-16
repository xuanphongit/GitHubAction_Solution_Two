# Script to migrate large repository from Azure DevOps to GitHub
param(
    [Parameter(Mandatory=$true)]
    [string]$AzureRepoUrl,
    
    [Parameter(Mandatory=$true)]
    [string]$GitHubRepoUrl,
    
    [Parameter(Mandatory=$false)]
    [string]$WorkingDir = ".\migration_workspace",
    
    [Parameter(Mandatory=$false)]
    [int]$ChunkSizeGB = 1.5  # Default chunk size in GB (keeping under 2GB limit)
)

# Function to convert GB to bytes
function ConvertToBytes {
    param([int]$GB)
    return $GB * 1GB
}

# Function to get repository size
function Get-RepoSize {
    param([string]$RepoPath)
    $size = (git count-objects -vH -- $RepoPath | Select-String "size-pack:").ToString().Split(":")[1].Trim()
    return [int64]$size
}

# Create working directory
if (-not (Test-Path $WorkingDir)) {
    New-Item -ItemType Directory -Path $WorkingDir | Out-Null
}

# Clone the Azure DevOps repository
Write-Host "Cloning Azure DevOps repository..."
git clone $AzureRepoUrl $WorkingDir
Set-Location $WorkingDir

# Get all branches
$branches = git branch -r | ForEach-Object { $_.Trim() }

# Create temporary branch for migration
git checkout -b migration_temp

# Get all commits
$commits = git log --reverse --pretty=format:"%H" | Out-String -Stream

# Initialize GitHub repository
git remote add github $GitHubRepoUrl

# Calculate chunk size in bytes
$chunkSizeBytes = ConvertToBytes $ChunkSizeGB
$currentChunkSize = 0
$currentChunk = @()
$chunkNumber = 1

# Process commits in chunks
foreach ($commit in $commits) {
    $commitSize = (git show --name-only --pretty=format: $commit | git hash-object -w --stdin | git cat-file -s)
    $currentChunkSize += $commitSize
    
    if ($currentChunkSize -gt $chunkSizeBytes) {
        # Push current chunk
        Write-Host "Pushing chunk $chunkNumber..."
        git push github migration_temp
        
        # Reset for next chunk
        $currentChunkSize = 0
        $chunkNumber++
    }
    
    $currentChunk += $commit
}

# Push final chunk if any
if ($currentChunk.Count -gt 0) {
    Write-Host "Pushing final chunk..."
    git push github migration_temp
}

# Push all branches
Write-Host "Pushing all branches..."
foreach ($branch in $branches) {
    $branchName = $branch.Replace("origin/", "")
    git checkout $branchName
    git push github $branchName
}

# Cleanup
Write-Host "Cleaning up..."
Set-Location ..
Remove-Item -Recurse -Force $WorkingDir

Write-Host "Migration completed successfully!" 