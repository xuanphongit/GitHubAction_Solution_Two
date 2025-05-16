# Project Brief: Azure DevOps to GitHub Repository Migration

## Project Overview
This project aims to create an automated solution for migrating large repositories from Azure DevOps to GitHub, with special handling for repositories exceeding GitHub's 2GB push limit.

## Core Requirements
1. Migrate entire repository history from Azure DevOps to GitHub
2. Handle repositories larger than 2GB by splitting into manageable chunks
3. Preserve all branches and commit history
4. Handle large files (>100MB) appropriately:
   - Move current large files to Git LFS
   - Remove historical large files using BFG Repo Cleaner
5. Provide detailed logging and error handling
6. Run as a GitHub Action for automation

## Technical Constraints
- GitHub's 2GB push limit per operation
- GitHub's 100MB file size limit
- Need to handle authentication for both Azure DevOps and GitHub
- Must work in GitHub Actions environment (Ubuntu runner)

## Success Criteria
1. Complete repository migration with all history intact
2. All branches successfully migrated
3. Large files properly handled (either in LFS or removed)
4. Detailed logs available for troubleshooting
5. Automated process that can be triggered via GitHub Actions 