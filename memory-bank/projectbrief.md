# Project Brief: GitHub Actions Environment Variable Management

## Project Overview
This project implements a robust system for managing environment variables across multiple environments using GitHub Actions. It provides a secure and automated way to handle configuration variables and secrets across different deployment environments.

## Core Requirements
1. Load environment variables from multiple environments (smoke, smoke2, smoke3, smoke4, smoke5)
2. Merge variables from different environments
3. Replace placeholders in configuration files (web.config, web2.config)
4. Integrate with Azure Key Vault for secure secret management
5. Support variable replacement in both XML and placeholder formats

## Project Goals
- Automate environment variable management
- Ensure secure handling of sensitive data
- Provide consistent configuration across environments
- Enable easy maintenance and updates of environment variables
- Support multiple configuration file formats

## Success Criteria
- Successful loading of variables from all environments
- Proper merging of variables without conflicts
- Accurate replacement of placeholders in config files
- Secure handling of secrets from Azure Key Vault
- Reliable workflow execution with proper error handling 