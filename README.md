# GitHub Actions Environment Variable Management

A robust system for managing environment variables across multiple environments using GitHub Actions. This project provides a secure and automated way to handle configuration variables and secrets across different deployment environments.

## Features

- 🔄 **Multi-Environment Support**: Load variables from multiple environments (smoke, smoke2, smoke3, smoke4, smoke5)
- 🔒 **Secure Secret Management**: Integration with Azure Key Vault for secure secret handling
- 📝 **Flexible Configuration**: Support for both XML and placeholder-based configurations
- 🔄 **Automated Workflow**: Streamlined process for variable loading, merging, and configuration updates
- 🛡️ **Error Handling**: Robust error handling and validation throughout the process
- 🔍 **Testing Infrastructure**: Comprehensive testing of environment variables and configurations
- 🚨 **Security Scanning**: Automated security checks and compliance validation
- 📊 **Monitoring**: Real-time workflow monitoring and metrics collection

## Prerequisites

- GitHub repository with Actions enabled
- Azure subscription with Key Vault
- Required secrets and variables:
  - `AZURE_CREDENTIALS`
  - `KEY_VAULT_NAME`
  - `GH_PAT` (for repository operations)

## Environment Setup

### GitHub Environments
The system supports the following environments:
- smoke
- smoke2
- smoke3
- smoke4
- smoke5
- production

### Required Permissions
- GitHub Actions workflow permissions
- Azure Key Vault access
- Repository access

## Usage

### 1. Configure Environments
Set up your environment variables in GitHub:
1. Go to your repository settings
2. Navigate to Environments
3. Create environments (smoke, smoke2, etc.)
4. Add required variables to each environment

### 2. Configure Azure Key Vault
1. Create an Azure Key Vault
2. Add required secrets
3. Configure access policies
4. Add Azure credentials to GitHub secrets

### 3. Run the Workflow
The workflow can be triggered manually through GitHub Actions:
1. Navigate to Actions tab
2. Select "Enhanced Environment Variable Management"
3. Configure workflow inputs:
   - Environment to process
   - Whether to validate secrets
   - Whether to perform security scan
4. Click "Run workflow"

## Workflow Process

1. **Validation**
   - Validates environment variables and configurations
   - Checks for missing variables and secrets
   - Handles validation errors with retry mechanism

2. **Security Scan**
   - Performs comprehensive security checks
   - Validates configuration security
   - Checks for compliance requirements
   - Handles security issues appropriately

3. **Monitoring**
   - Collects performance metrics
   - Monitors resource usage
   - Tracks workflow execution
   - Alerts on threshold violations

4. **Process Variables**
   - Loads variables from configured environments
   - Merges variables from different environments
   - Updates configuration files
   - Handles processing errors with retry mechanism

5. **Final Monitoring**
   - Performs final workflow monitoring
   - Collects execution metrics
   - Generates workflow report

## Configuration Files

### web.config and web2.config
Example configuration:
```xml
<configuration>
  <appSettings>
    <add key="APIENDPOINT" value="#{APIENDPOINT}#" />
    <add key="ConnectionString" value="#{DATABASECONNECTION}#" />
    <add key="Environment" value="#{Environment}#" />
  </appSettings>
</configuration>
```

### replace.sh
Script for replacing placeholders in configuration files.

## Dependencies

### GitHub Actions
- actions/checkout@v4
- actions/upload-artifact@v4
- actions/download-artifact@v4
- azure/login@v1

### System Tools
- jq
- Azure CLI
- PowerShell 7+
- Bash

## Security Considerations

- Secrets are stored in Azure Key Vault
- Environment variables are properly scoped
- Access is controlled through permissions
- Sensitive data is handled securely
- Regular security scans are performed
- Compliance requirements are validated

## Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For support, please open an issue in the GitHub repository. 