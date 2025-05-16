#!/bin/bash

# Exit on error
set -e

# Enable error tracing
trap 'handle_error $? $LINENO' ERR

# Default values
WORKING_DIR="./migration_workspace"
CHUNK_SIZE_GB=1.5
LOG_FILE="migration_$(date +%Y%m%d_%H%M%S).log"
TIMEOUT=3600  # 1 hour timeout for git operations
MAX_RETRIES=3
CLEANUP_ON_ERROR=true
MAX_FILE_SIZE=100000000  # 100MB in bytes
BFG_VERSION="1.14.0"
BFG_JAR="bfg-$BFG_VERSION.jar"

# Function to handle errors
handle_error() {
    local exit_code=$1
    local line_number=$2
    echo "Error occurred in script at line $line_number with exit code $exit_code" | tee -a "$LOG_FILE"
    
    if [ "$CLEANUP_ON_ERROR" = true ]; then
        cleanup
    fi
    
    exit "$exit_code"
}

# Function to cleanup
cleanup() {
    echo "Performing cleanup..." | tee -a "$LOG_FILE"
    if [ -d "$WORKING_DIR" ]; then
        rm -rf "$WORKING_DIR"
    fi
    if [ -f "$BFG_JAR" ]; then
        rm -f "$BFG_JAR"
    fi
}

# Function to show usage
show_usage() {
    echo "Usage: $0 -a <azure_repo_url> -g <github_repo_url> [-w <working_dir>] [-s <chunk_size_gb>] [-t <timeout>] [-r <max_retries>]"
    echo "Options:"
    echo "  -a    Azure DevOps repository URL (required)"
    echo "  -g    GitHub repository URL (required)"
    echo "  -w    Working directory (default: ./migration_workspace)"
    echo "  -s    Chunk size in GB (default: 1.5)"
    echo "  -t    Timeout in seconds for git operations (default: 3600)"
    echo "  -r    Maximum number of retries for failed operations (default: 3)"
    exit 1
}

# Function to log messages
log_message() {
    local message=$1
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $message" | tee -a "$LOG_FILE"
}

# Function to run git command with timeout and retries
run_git_command() {
    local command=$1
    local retry_count=0
    
    while [ $retry_count -lt $MAX_RETRIES ]; do
        if timeout $TIMEOUT bash -c "$command"; then
            return 0
        else
            retry_count=$((retry_count + 1))
            if [ $retry_count -lt $MAX_RETRIES ]; then
                log_message "Command failed, retrying ($retry_count/$MAX_RETRIES): $command"
                sleep 5
            else
                log_message "Command failed after $MAX_RETRIES retries: $command"
                return 1
            fi
        fi
    done
}

# Function to install dependencies
install_dependencies() {
    log_message "Installing dependencies..."
    
    # Update package list
    sudo apt-get update
    
    # Install required packages
    sudo apt-get install -y \
        git \
        git-lfs \
        default-jre \
        curl \
        wget \
        coreutils
    
    # Configure Git LFS
    git lfs install
    
    # Download BFG
    log_message "Downloading BFG Repo Cleaner..."
    if ! curl -L "https://repo1.maven.org/maven2/com/madgag/bfg/$BFG_VERSION/bfg-$BFG_VERSION.jar" -o "$BFG_JAR"; then
        log_message "Failed to download BFG Repo Cleaner"
        exit 1
    fi
}

# Function to check for large files in current branch
check_large_files_current() {
    log_message "Checking for large files in current branch..."
    local large_files
    large_files=$(git rev-list --objects --all | git cat-file --batch-check='%(objecttype) %(objectname) %(objectsize) %(rest)' | awk -v max_size="$MAX_FILE_SIZE" '$1 == "blob" && $3 > max_size {print $4}')
    
    if [ -n "$large_files" ]; then
        log_message "Found large files in current branch:"
        echo "$large_files" | tee -a "$LOG_FILE"
        return 0
    else
        log_message "No large files found in current branch"
        return 1
    fi
}

# Function to check for large files in history
check_large_files_history() {
    log_message "Checking for large files in history..."
    local large_files
    large_files=$(git rev-list --objects --all | git cat-file --batch-check='%(objecttype) %(objectname) %(objectsize) %(rest)' | awk -v max_size="$MAX_FILE_SIZE" '$1 == "blob" && $3 > max_size {print $4}')
    
    if [ -n "$large_files" ]; then
        log_message "Found large files in history:"
        echo "$large_files" | tee -a "$LOG_FILE"
        return 0
    else
        log_message "No large files found in history"
        return 1
    fi
}

# Function to track large files with Git LFS
track_large_files() {
    local large_files=$1
    log_message "Tracking large files with Git LFS..."
    
    while IFS= read -r file; do
        if [ -f "$file" ]; then
            log_message "Tracking file with Git LFS: $file"
            if ! run_git_command "git lfs track '$file'"; then
                log_message "Failed to track file with Git LFS: $file"
                exit 1
            fi
        fi
    done <<< "$large_files"
    
    # Add .gitattributes
    if ! run_git_command "git add .gitattributes"; then
        log_message "Failed to add .gitattributes"
        exit 1
    fi
    
    if ! run_git_command "git commit -m 'Add Git LFS tracking for large files'"; then
        log_message "Failed to commit .gitattributes"
        exit 1
    fi
}

# Function to remove large files from history using BFG
remove_large_files_from_history() {
    local large_files=$1
    log_message "Removing large files from history using BFG..."
    
    # Create a file with paths to delete
    echo "$large_files" > large-files-to-delete.txt
    
    # Run BFG to delete the files
    if ! java -jar "$BFG_JAR" --delete-files large-files-to-delete.txt .; then
        log_message "Failed to remove large files using BFG"
        exit 1
    fi
    
    # Clean up the repository
    if ! run_git_command "git reflog expire --expire=now --all && git gc --prune=now --aggressive"; then
        log_message "Failed to clean up repository after BFG"
        exit 1
    fi
}

# Function to convert GB to bytes
convert_to_bytes() {
    local gb=$1
    echo $((gb * 1024 * 1024 * 1024))
}

# Function to get repository size
get_repo_size() {
    local repo_path=$1
    git count-objects -vH -- "$repo_path" | grep "size-pack:" | awk '{print $2}'
}

# Parse command line arguments
while getopts "a:g:w:s:t:r:" opt; do
    case $opt in
        a) AZURE_REPO_URL="$OPTARG";;
        g) GITHUB_REPO_URL="$OPTARG";;
        w) WORKING_DIR="$OPTARG";;
        s) CHUNK_SIZE_GB="$OPTARG";;
        t) TIMEOUT="$OPTARG";;
        r) MAX_RETRIES="$OPTARG";;
        ?) show_usage;;
    esac
done

# Check required parameters
if [ -z "$AZURE_REPO_URL" ] || [ -z "$GITHUB_REPO_URL" ]; then
    log_message "Error: Azure repo URL and GitHub repo URL are required"
    show_usage
fi

# Install dependencies
install_dependencies

# Create working directory
if [ ! -d "$WORKING_DIR" ]; then
    mkdir -p "$WORKING_DIR"
fi

# Initialize log file
touch "$LOG_FILE"
log_message "Starting repository migration"
log_message "Azure Repo URL: $AZURE_REPO_URL"
log_message "GitHub Repo URL: $GITHUB_REPO_URL"
log_message "Working Directory: $WORKING_DIR"
log_message "Chunk Size: ${CHUNK_SIZE_GB}GB"

# Configure Git for GitHub Actions
git config --global user.email "github-actions[bot]@users.noreply.github.com"
git config --global user.name "github-actions[bot]"

# Clone the Azure DevOps repository
log_message "Cloning Azure DevOps repository..."
if ! run_git_command "git clone '$AZURE_REPO_URL' '$WORKING_DIR'"; then
    log_message "Failed to clone repository"
    exit 1
fi

cd "$WORKING_DIR" || exit

# Configure git
git config --local core.compression 0
git config --local http.postBuffer 524288000
git config --local http.maxRequestBuffer 100M
git config --local core.packedGitLimit 100m
git config --local core.packedGitWindowSize 100m
git config --local pack.windowMemory 100m
git config --local pack.packSizeLimit 100m
git config --local pack.threads 1
git config --local pack.window 0

# Check for large files in current branch
if check_large_files_current; then
    log_message "Large files found in current branch. Setting up Git LFS..."
    track_large_files "$(check_large_files_current)"
fi

# Check for large files in history
if check_large_files_history; then
    log_message "Large files found in history. Using BFG Repo Cleaner..."
    remove_large_files_from_history "$(check_large_files_history)"
fi

# Get all branches
log_message "Getting all branches..."
branches=$(run_git_command "git branch -r | sed 's/origin\///'")

# Create temporary branch for migration
log_message "Creating temporary branch..."
run_git_command "git checkout -b migration_temp"

# Get all commits
log_message "Getting all commits..."
commits=$(run_git_command "git log --reverse --pretty=format:'%H'")

# Initialize GitHub repository
log_message "Adding GitHub remote..."
run_git_command "git remote add github '$GITHUB_REPO_URL'"

# Calculate chunk size in bytes
chunk_size_bytes=$(convert_to_bytes "$CHUNK_SIZE_GB")
current_chunk_size=0
current_chunk=()
chunk_number=1

# Process commits in chunks
log_message "Processing commits in chunks..."
while IFS= read -r commit; do
    commit_size=$(run_git_command "git show --name-only --pretty=format: '$commit' | git hash-object -w --stdin | git cat-file -s")
    current_chunk_size=$((current_chunk_size + commit_size))
    
    if [ "$current_chunk_size" -gt "$chunk_size_bytes" ]; then
        log_message "Pushing chunk $chunk_number..."
        if ! run_git_command "git push github migration_temp"; then
            log_message "Failed to push chunk $chunk_number"
            exit 1
        fi
        
        current_chunk_size=0
        chunk_number=$((chunk_number + 1))
    fi
    
    current_chunk+=("$commit")
done <<< "$commits"

# Push final chunk if any
if [ ${#current_chunk[@]} -gt 0 ]; then
    log_message "Pushing final chunk..."
    if ! run_git_command "git push github migration_temp"; then
        log_message "Failed to push final chunk"
        exit 1
    fi
fi

# Push all branches
log_message "Pushing all branches..."
while IFS= read -r branch; do
    branch_name=$(echo "$branch" | sed 's/origin\///')
    log_message "Pushing branch: $branch_name"
    if ! run_git_command "git checkout '$branch_name' && git push github '$branch_name'"; then
        log_message "Failed to push branch: $branch_name"
        exit 1
    fi
done <<< "$branches"

# Cleanup
log_message "Cleaning up..."
cleanup

log_message "Migration completed successfully!"
exit 0 