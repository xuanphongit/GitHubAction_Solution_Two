# Product Context

## Problem Statement
Managing environment variables across multiple deployment environments is a complex task that requires:
- Secure handling of sensitive data
- Consistent configuration across environments
- Easy maintenance and updates
- Support for different configuration formats
- Integration with existing security infrastructure

## Solution
This project provides a GitHub Actions-based solution that:
1. Automatically loads variables from multiple environments
2. Merges variables while handling conflicts
3. Replaces placeholders in configuration files
4. Integrates with Azure Key Vault for secure secret management
5. Supports both XML and placeholder-based configurations

## User Experience Goals
1. **Simplicity**: Easy to understand and use workflow
2. **Reliability**: Consistent and error-free execution
3. **Security**: Proper handling of sensitive data
4. **Maintainability**: Easy to update and modify
5. **Visibility**: Clear feedback on execution status

## How It Works
1. **Variable Loading**:
   - Loads variables from multiple environments (smoke, smoke2, smoke3, smoke4, smoke5)
   - Exports variables to environment context
   - Handles missing or empty variables gracefully

2. **Variable Merging**:
   - Combines variables from different environments
   - Resolves conflicts based on environment priority
   - Creates a unified variable set

3. **Configuration Updates**:
   - Replaces placeholders in web.config and web2.config
   - Supports both XML and #{placeholder}# formats
   - Maintains file structure and formatting

4. **Secret Management**:
   - Integrates with Azure Key Vault
   - Securely retrieves and applies secrets
   - Handles missing or inaccessible secrets gracefully

## Integration Points
1. GitHub Actions workflows
2. Azure Key Vault
3. Configuration files (web.config, web2.config)
4. Environment variables in GitHub 