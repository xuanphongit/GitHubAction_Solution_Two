# Technical Context

## Technologies Used
- **Bash Scripting**: Core migration logic
- **Git**: Repository operations
- **Git LFS**: Large file storage
- **BFG Repo Cleaner**: Historical large file removal
- **GitHub Actions**: Automation platform
- **Ubuntu**: Runner environment

## Development Setup
1. **Local Development**:
   - Ubuntu-based environment
   - Git
   - Git LFS
   - Java Runtime Environment (for BFG)
   - Bash shell

2. **GitHub Actions Environment**:
   - Ubuntu-latest runner
   - Pre-installed: Git, curl, wget
   - Auto-installed: Git LFS, Java, coreutils

## Dependencies
1. **System Dependencies**:
   - git
   - git-lfs
   - default-jre
   - curl
   - wget
   - coreutils

2. **Authentication**:
   - Azure DevOps PAT (Personal Access Token)
   - GitHub Token (automatically provided by GitHub Actions)

## Technical Constraints
1. **GitHub Limits**:
   - 2GB push limit per operation
   - 100MB file size limit
   - Rate limits on API calls

2. **Azure DevOps**:
   - Authentication via PAT
   - API rate limits

3. **Git LFS**:
   - Storage limits based on GitHub plan
   - Bandwidth limits

## Configuration
1. **Script Parameters**:
   - Azure repo URL
   - GitHub repo URL
   - Chunk size (default: 1.5GB)
   - Timeout (default: 3600s)
   - Max retries (default: 3)

2. **Git Configuration**:
   - Compression disabled
   - Increased buffer sizes
   - Optimized pack settings

## Security Considerations
1. **Authentication**:
   - PAT stored as GitHub secrets
   - GitHub token automatically managed
   - No hardcoded credentials

2. **File Handling**:
   - Secure cleanup of temporary files
   - Proper handling of large files
   - Safe removal of historical data 