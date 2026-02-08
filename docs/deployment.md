# Deployment Guide

## Overview

This guide walks through deploying the Azure MCP Gateway solution using Terraform. The entire infrastructure is deployed via Infrastructure as Code (IaC) - no manual portal steps required.

## Prerequisites

### 1. Required Tools

- **Terraform** >= 1.5.0
  ```powershell
  # Install via Chocolatey (Windows)
  choco install terraform
  
  # Or download from https://www.terraform.io/downloads
  ```

- **Azure CLI** >= 2.50.0
  ```powershell
  # Install via MSI installer
  # Download from https://aka.ms/installazurecliwindows
  ```

- **Git**
  ```powershell
  choco install git
  ```

- **PowerShell** 7+ (or Bash on Linux/macOS)

### 2. Azure Subscription

- Active Azure subscription
- Permissions to create resources and assign RBAC roles
- Recommended: Owner or Contributor + User Access Administrator roles

### 3. Entra ID Permissions

- Permission to create App Registrations (Service Principals)
- Permission to grant API permissions
- Typically requires **Application Administrator** role or higher

## Step 1: Clone Repository

```powershell
git clone https://github.com/your-org/azure-mcp-gateway.git
cd azure-mcp-gateway
```

## Step 2: Azure Authentication

Authenticate with Azure CLI:

```powershell
# Login
az login

# Select subscription
az account set --subscription "<subscription-id-or-name>"

# Verify
az account show
```

## Step 3: Configure Terraform Backend (One-Time Setup)

The Terraform state is stored in Azure Storage for team collaboration and state locking.

### Option A: Automated Bootstrap (Recommended)

```powershell
cd infra/envs
.\bootstrap.ps1  # If available
```

This script creates:
- Resource Group for Terraform state
- Storage Account (with private access)
- Blob Container for state files
- Outputs backend configuration

### Option B: Manual Setup

1. Create storage account:
```powershell
$RESOURCE_GROUP = "rg-terraform-state"
$LOCATION = "eastus"
$STORAGE_ACCOUNT = "sttfstate$(Get-Random -Minimum 10000 -Maximum 99999)"

az group create --name $RESOURCE_GROUP --location $LOCATION

az storage account create `
  --name $STORAGE_ACCOUNT `
  --resource-group $RESOURCE_GROUP `
  --location $LOCATION `
  --sku Standard_LRS `
  --encryption-services blob `
  --https-only true `
  --min-tls-version TLS1_2 `
  --allow-blob-public-access false

$ACCOUNT_KEY = az storage account keys list --resource-group $RESOURCE_GROUP --account-name $STORAGE_ACCOUNT --query '[0].value' -o tsv

az storage container create `
  --name tfstate `
  --account-name $STORAGE_ACCOUNT `
  --account-key $ACCOUNT_KEY
```

2. Create `backend-config-dev.tfvars`:
```hcl
resource_group_name  = "rg-terraform-state"
storage_account_name = "<your-storage-account-name>"
container_name       = "tfstate"
key                  = "dev.terraform.tfstate"
```

## Step 4: Configure Environment Variables

Create `infra/envs/dev.tfvars`:

```hcl
# Azure settings
subscription_id = "<your-subscription-id>"
tenant_id       = "<your-tenant-id>"
location        = "swedencentral"  # Sweden Central region
environment     = "dev"

# Resource naming
project_name = "mcpgw"  # Short name for resource prefixing

# Networking
vnet_address_space = ["10.0.0.0/16"]

# APIM
apim_sku_name     = "Developer"  # Use "Premium" for production
apim_publisher    = "Your Organization"
apim_publisher_email = "admin@yourorg.com"

# Function App
function_app_runtime = "python"
function_app_version = "3.11"

# Frontend
webapp_sku = "B1"  # Basic tier, use P1v2+ for production

# Foundry Agent Managed Identity
# Provide the Principal ID (Object ID) of your Foundry Agent's Managed Identity
# Leave empty for dev/testing to allow any managed identity
foundry_agent_principal_id = ""  # Or "<principal-id-guid>"

# Tags
tags = {
  Environment = "dev"
  Project     = "Azure MCP Gateway"
  ManagedBy   = "Terraform"
  CostCenter  = "Engineering"
  Region      = "Sweden Central"
}
```

**Security Note**: Do NOT commit `dev.tfvars` or `prod.tfvars` to source control if it contains sensitive values. Add to `.gitignore`.

## Step 5: Initialize Terraform

**For Development:**
```powershell
cd infra/envs

# Initialize with backend configuration
terraform init -backend-config=backend-config-dev.tfvars

# Or if using local backend for testing
terraform init
```

**For Production:**
```powershell
cd infra/envs

# Initialize with production backend configuration
terraform init -backend-config=backend-config-prod.tfvars
```

Expected output:
```
Initializing modules...
Initializing the backend...
Initializing provider plugins...
- Finding latest version of hashicorp/azurerm...
- Finding latest version of hashicorp/azuread...
...
Terraform has been successfully initialized!
```

## Step 6: Review Deployment Plan

**Development:**
```powershell
terraform plan -var-file="dev.tfvars" -out=tfplan
```

**Production:**
```powershell
terraform plan -var-file="prod.tfvars" -out=tfplan
```

This generates an execution plan showing:
- Resources to be created
- Estimated costs (if using Infracost)
- No changes should show on first run

Review the plan carefully:
- ✅ Verify resource names follow naming conventions
- ✅ Check that public access is disabled on all resources
- ✅ Ensure APIM is in Internal mode
- ✅ Confirm RBAC role assignments are correct

## Step 7: Deploy Infrastructure

```powershell
terraform apply tfplan
```

Deployment takes approximately **30-45 minutes** due to:
- APIM provisioning (~25-30 minutes)
- Private endpoints creation
- DNS propagation

Progress:
```
azurerm_resource_group.main: Creating...
azurerm_resource_group.main: Creation complete after 2s
module.networking.azurerm_virtual_network.main: Creating...
module.networking.azurerm_virtual_network.main: Creation complete after 8s
...
module.apim.azurerm_api_management.main: Creating...
module.apim.azurerm_api_management.main: Still creating... [10m0s elapsed]
module.apim.azurerm_api_management.main: Still creating... [20m0s elapsed]
module.apim.azurerm_api_management.main: Creation complete after 28m12s
...
Apply complete! Resources: 45 added, 0 changed, 0 destroyed.
```

## Step 8: Capture Outputs

After deployment, Terraform outputs important values:

```powershell
terraform output
```

Expected outputs:
```
apim_name = "apim-mcpgw-dev-12345"
apim_private_ip = "10.0.1.5"
function_app_name = "func-mcpgw-dev-12345"
function_app_url = "https://func-mcpgw-dev-12345.azurewebsites.net"
webapp_name = "app-mcpgw-dev-12345"
resource_group_name = "rg-mcpgw-dev"
apim_api_app_id = "api://abcd1234-5678-90ef-ghij-klmnopqrstuv"
foundry_agent_client_id = "12345678-abcd-efgh-ijkl-mnopqrstuvwx"
```

**Save these values** - you'll need them for configuration and testing.

## Step 9: Deploy Function App Code

```powershell
# Navigate to backend directory
cd ..\..\..\backend\function_app

# Create deployment package
Compress-Archive -Path * -DestinationPath function_app.zip -Force

# Deploy to Function App
az functionapp deployment source config-zip `
  --resource-group rg-mcpgw-dev `
  --name func-mcpgw-dev-12345 `
  --src function_app.zip
```

Wait for deployment:
```
Getting scm site credentials for zip deployment
Creating zip deployment
Deployment endpoint responded with status code 202
{
  "active": true,
  "author": "N/A",
  "complete": true,
  "deployer": "ZipDeploy",
  "end_time": "2026-02-08T...",
  "id": "...",
  "is_readonly": true,
  "is_temp": false,
  "last_success_end_time": "2026-02-08T...",
  "message": "Created via a push deployment",
  "progress": "",
  "received_time": "2026-02-08T...",
  "site_name": "func-mcpgw-dev-12345",
  "start_time": "2026-02-08T...",
  "status": 4,
  "status_text": ""
}
```

## Step 10: Deploy Frontend Code

```powershell
# Navigate to frontend directory
cd ..\frontend\react_app

# Install dependencies
npm install

# Build production bundle
npm run build

# Deploy to Web App
cd build
Compress-Archive -Path * -DestinationPath ../webapp.zip -Force
cd ..

az webapp deployment source config-zip `
  --resource-group rg-mcpgw-dev `
  --name app-mcpgw-dev-12345 `
  --src webapp.zip
```

## Step 11: Verify Deployment

### 11.1 Check Resource Health

```powershell
# Function App running?
az functionapp show `
  --name func-mcpgw-dev-12345 `
  --resource-group rg-mcpgw-dev `
  --query "state" -o tsv
# Expected: Running

# Web App running?
az webapp show `
  --name app-mcpgw-dev-12345 `
  --resource-group rg-mcpgw-dev `
  --query "state" -o tsv
# Expected: Running

# APIM provisioned?
az apim show `
  --name apim-mcpgw-dev-12345 `
  --resource-group rg-mcpgw-dev `
  --query "provisioningState" -o tsv
# Expected: Succeeded
```

### 11.2 Verify Private Endpoints

```powershell
# List private endpoints
az network private-endpoint list `
  --resource-group rg-mcpgw-dev `
  --query "[].{Name:name, ProvisioningState:provisioningState}" -o table
```

Expected:
```
Name                          ProvisioningState
----------------------------  -------------------
pe-func-mcpgw-dev-12345       Succeeded
pe-st-mcpgw-dev-12345-blob    Succeeded
pe-st-mcpgw-dev-12345-file    Succeeded
pe-webapp-mcpgw-dev-12345     Succeeded
```

### 11.3 Test Function Endpoint (via APIM)

Since everything is private, testing requires either:
- **Option A**: Deploy a test VM in the same VNet
- **Option B**: Use Azure Bastion to connect to VNet
- **Option C**: Temporarily enable public access for testing (not recommended)

**Option A: Test VM** (Recommended for validation)

```powershell
# Create test VM
az vm create `
  --resource-group rg-mcpgw-dev `
  --name vm-test-dev `
  --image Ubuntu2204 `
  --vnet-name vnet-mcpgw-dev `
  --subnet apim-subnet `
  --public-ip-address "" `
  --admin-username azureuser `
  --generate-ssh-keys

# Connect via Azure Bastion (if deployed) or private connection
# From VM, test APIM endpoint:
curl -H "Authorization: Bearer <entra-id-token>" \
  https://10.0.1.5/mcp/health
```

### 11.4 Check Logs

```powershell
# Function App logs
az monitor app-insights query `
  --app <app-insights-name> `
  --analytics-query "traces | where timestamp > ago(1h) | order by timestamp desc | take 20" `
  --resource-group rg-mcpgw-dev

# APIM logs
az monitor app-insights query `
  --app <app-insights-name> `
  --analytics-query "requests | where timestamp > ago(1h) | project timestamp, name, resultCode, duration | order by timestamp desc" `
  --resource-group rg-mcpgw-dev
```

## Step 12: Configure Foundry Agent

### 12.1 Get Foundry Agent Managed Identity Principal ID

If you haven't already, identify your Foundry Agent's Managed Identity:

```powershell
# If using system-assigned MI on a resource
az resource show \
  --ids /subscriptions/<sub-id>/resourceGroups/<rg>/providers/Microsoft.CognitiveServices/accounts/<foundry-name> \
  --query identity.principalId -o tsv

# If using user-assigned MI
az identity show \
  --name <identity-name> \
  --resource-group <rg> \
  --query principalId -o tsv
```

Save this Principal ID - you'll need it for the `foundry_agent_principal_id` variable.

### 12.2 Update Terraform Configuration (if not done initially)

If you deployed without configuring the Foundry Agent Principal ID:

1. Edit `infra/envs/dev/terraform.tfvars`:
   ```hcl
   foundry_agent_principal_id = "<principal-id-from-step-12.1>"
   ```

2. Re-apply Terraform:
   ```powershell
   cd infra/envs/dev
   terraform apply
   ```

   This updates the APIM JWT validation policy to only accept tokens from your Foundry Agent.

### 12.3 Configure Foundry Agent to Call APIM

In your Foundry Agent configuration, use Managed Identity authentication:

```json
{
  "mcpServer": {
    "endpoint": "https://<apim-private-ip>/mcp",
    "authentication": {
      "type": "ManagedIdentity",
      "resource": "https://<function-app-name>.azurewebsites.net"
    }
  }
}
```

The Foundry Agent will automatically acquire tokens using its Managed Identity via IMDS.

**Note**: Replace `<apim-private-ip>` with the APIM private IP from Terraform outputs.

## Production Deployment

### Using Production Configuration

```powershell
cd infra/envs

# Copy and edit production configuration
cp prod.tfvars.example prod.tfvars
cp backend-config-prod.tfvars.example backend-config-prod.tfvars
# Edit prod.tfvars and backend-config-prod.tfvars with your values

# Initialize with production backend
terraform init -backend-config=backend-config-prod.tfvars

# Plan with production variables
terraform plan -var-file="prod.tfvars"

# Apply with production variables
terraform apply -var-file="prod.tfvars"
```

### Production Configuration Differences

The `prod.tfvars.example` includes production-ready defaults:

```hcl
environment = "prod"

# Use production-grade SKUs
apim_sku_name = "Premium_1"  # For VNet + zone redundancy
webapp_sku    = "P1v3"
function_app_plan_sku = "EP1"  # Elastic Premium

# Enable zone redundancy (if using Premium APIM)
# enable_apim_zones = true
# apim_availability_zones = ["1", "2", "3"]

# Stricter networking
enable_nsgs = true

# Enhanced logging
log_retention_days = 90  # Longer retention for compliance
```
```hcl
environment = "prod"

# Use production-grade SKUs
apim_sku_name = "Premium"  # For VNet + zone redundancy
webapp_sku    = "P1v3"
function_app_plan_sku = "EP1"  # Elastic Premium

# Enable zone redundancy
enable_apim_zones = true
apim_availability_zones = ["1", "2", "3"]

# Stricter networking
enable_nsgs = true
allowed_ip_ranges = []  # No public IPs allowed

# Additional security
enable_waf = true
enable_ddos_protection = true
```

### Production Checklist

Before deploying to production:

- [ ] Update `terraform.tfvars` with production SKUs
- [ ] Configure separate Terraform backend for prod state
- [ ] Enable Azure Backup for Function App configuration
- [ ] Set up monitoring alerts in Azure Monitor
- [ ] Configure budget alerts in Azure Cost Management
- [ ] Review all RBAC role assignments
- [ ] Validate disaster recovery procedures
- [ ] Complete security review (see Security Checklist in security-model.md)
- [ ] Document runbook for incident response
- [ ] Set up PagerDuty/OpsGenie for on-call

## Troubleshooting

### Issue: Terraform Backend Initialization Fails

**Error**: 
```
Error: Failed to get existing workspaces: storage account not found
```

**Solution**: 
- Verify backend-config.tfvars has correct storage account name
- Ensure you have access to the storage account
- Run bootstrap script if storage account doesn't exist

### Issue: APIM Deployment Times Out

**Error**: 
```
Error: waiting for creation of API Management Service: context deadline exceeded
```

**Solution**: 
- APIM can take up to 45 minutes to provision
- Increase timeout: `terraform apply -timeout=60m`
- Check Azure Service Health for regional issues

### Issue: Private Endpoint DNS Resolution Fails

**Error**: 
```
curl: (6) Could not resolve host: func-mcpgw-dev.azurewebsites.net
```

**Solution**: 
- Verify Private DNS zones are created and linked to VNet
- Check A records exist in Private DNS zones:
  ```powershell
  az network private-dns record-set a list `
    --resource-group rg-mcpgw-dev `
    --zone-name privatelink.azurewebsites.net
  ```
- Ensure you're testing from within the VNet

### Issue: 401 Unauthorized from APIM

**Error**: 
```
HTTP 401 Unauthorized
{"error": "invalid_token"}
```

**Solution**: 
- Verify Entra ID token has correct audience: `api://<apim-app-id>`
- Check APIM validate-jwt policy configuration
- Confirm Foundry Agent client ID is in allowlist
- Review APIM trace logs in Azure Portal

### Issue: 403 Forbidden from Function App

**Error**: 
```
HTTP 403 Forbidden
```

**Solution**: 
- Verify APIM Managed Identity has RBAC role on Function App
- Check Function App authentication configuration
- Ensure Entra ID authentication is enabled on Function App
- Review Function App authentication logs

### Issue: Terraform State Locked

**Error**: 
```
Error: Error acquiring the state lock
```

**Solution**: 
```powershell
# Force unlock (use with caution)
terraform force-unlock <lock-id>
```

## Updating Infrastructure

### Apply Configuration Changes

```powershell
# Make changes to .tf files or tfvars files
cd infra/envs

# Review changes (specify environment)
terraform plan -var-file="dev.tfvars"
# or
terraform plan -var-file="prod.tfvars"

# Apply changes
terraform apply -var-file="dev.tfvars"
# or  
terraform apply -var-file="prod.tfvars"
```

### Add New Resources

1. Create or update module in `infra/modules/`
2. Reference module in environment configuration
3. Run `terraform plan` to review
4. Apply changes with `terraform apply`

## Destroying Infrastructure


# Review what will be destroyed
terraform plan -destroy -var-file="dev.tfvars"

# Destroy all resources
terraform destroy -var-file="dev.tfvars"
```

Confirm with `yes` when prompted.

**Note**: This does NOT delete:
- Terraform state storage account (intentional, for history)
- Any resources created outside Terraform
**Note**: This does NOT delete:
- Terraform state storage account (intentional, for history)
- Any resources created outside Terraform
- Azure AD resources (App Registrations) - may need manual cleanup

## CI/CD Integration (Optional)

### GitHub Actions

Example workflow (`.github/workflows/deploy.yml`):

```yaml
name: Deploy Infrastructure

on:
  push:
    branches: [main]
    paths:
      - 'infra/**'
  workflow_dispatch:

permissions:
  id-token: write  # For OIDC authentication
  contents: read

jobs:
  terraform:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Azure Login (OIDC)
        uses: azure/login@v1
        with:
          client-id: ${{ secrets.AZURE_CLIENT_ID }}
          tenant-id: ${{ secrets.AZURE_TENANT_ID }}
          subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
      
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v2
        with:
          terraform_version: 1.5.0
      
      - name: Terraform Init
        run: terraform init
        working-directory: infra/envs/dev
      
      - name: Terraform Plan
        run: terraform plan -out=tfplan
        working-directory: infra/envs/dev
      
      - name: Terraform Apply
        run: terraform apply tfplan
        working-directory: infra/envs/dev
```

### Azure DevOps

Example pipeline (`azure-pipelines.yml`):

```yaml
trigger:
  branches:
    include:
      - main
  paths:
    include:
      - infra/**

pool:
  vmImage: 'ubuntu-latest'

variables:
  - group: terraform-variables  # Variable group with secrets

steps:
- task: AzureCLI@2
  displayName: 'Terraform Init'
  inputs:
    azureSubscription: 'Azure-ServiceConnection'
    scriptType: 'bash'
    scriptLocation: 'inlineScript'
    inlineScript: |
      cd infra/envs/dev
      terraform init

- task: AzureCLI@2
  displayName: 'Terraform Plan'
  inputs:
    azureSubscription: 'Azure-ServiceConnection'
    scriptType: 'bash'
    scriptLocation: 'inlineScript'
    inlineScript: |
      cd infra/envs/dev
      terraform plan -out=tfplan

- task: AzureCLI@2
  displayName: 'Terraform Apply'
  inputs:
    azureSubscription: 'Azure-ServiceConnection'
    scriptType: 'bash'
    scriptLocation: 'inlineScript'
    inlineScript: |
      cd infra/envs/dev
      terraform apply tfplan
```

## Cost Estimation

### Development Environment

Estimated monthly costs:
- APIM (Developer): ~$50 USD
- Function App (Consumption): ~$0-10 USD (based on usage)
- Storage Account: ~$1-5 USD
- Application Insights: ~$5-20 USD
- Web App (B1): ~$13 USD
- Private Endpoints: ~$7/endpoint x 4 = ~$28 USD
- **Total: ~$100-130 USD/month**

### Production Environment

Estimated monthly costs:
- APIM (Premium, 2 units): ~$2,800 USD
- Function App (Elastic Premium EP1): ~$145 USD
- Storage Account: ~$5-20 USD
- Application Insights: ~$20-100 USD
- Web App (P1v3): ~$110 USD
- Private Endpoints: ~$28 USD
- **Total: ~$3,100-3,200 USD/month**

Use [Azure Pricing Calculator](https://azure.microsoft.com/pricing/calculator/) for precise estimates.

## Next Steps

After successful deployment:

1. **Implement Slack MCP Logic** - Update Function App with actual MCP server code
2. **Configure AI Foundry Agent** - Integrate with deployed APIM endpoint
3. **Set Up Monitoring** - Create dashboards and alerts in Azure Monitor
4. **Document Runbook** - Operational procedures for the team
5. **Security Hardening** - Apply Azure Policies, enable Advanced Threat Protection
6. **Load Testing** - Validate performance under expected load
7. **Disaster Recovery Testing** - Verify backup and restore procedures

## Support

For issues or questions:
- Review [Architecture Documentation](./architecture.md)
- Review [Security Model](./security-model.md)
- Check Azure Service Health
- Open GitHub issue (if using public repo)
- Contact Azure Support (for platform issues)

## References

- [Terraform Azure Provider Documentation](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Azure CLI Reference](https://learn.microsoft.com/cli/azure/)
- [Azure APIM Terraform Examples](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/api_management)
- [Azure Functions Deployment](https://learn.microsoft.com/azure/azure-functions/functions-deployment-technologies)
