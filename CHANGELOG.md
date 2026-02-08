# Changelog

## [Updated] - 2026-02-08

### Major Changes

#### 1. Consolidated Terraform Structure (Single envs Directory)

**Changed**: Simplified Terraform structure to use a single `infra/envs/` directory with environment-specific `.tfvars` files instead of separate `dev/` and `prod/` folders.

**What Changed:**
- ❌ Removed separate `infra/envs/dev/` and `infra/envs/prod/` directories
- ✅ Single `infra/envs/` directory contains all Terraform configuration
- ✅ Environment-specific variables in `dev.tfvars` and `prod.tfvars`
- ✅ Backend configuration in `backend-config-dev.tfvars` and `backend-config-prod.tfvars`
- ✅ Module paths updated from `../../modules` to `../modules`

**New Structure:**
```
infra/
  ├── modules/
  │   ├── networking/
  │   ├── monitoring/
  │   ├── identity/
  │   ├── apim/
  │   ├── function_app/
  │   └── webapp/
  └── envs/
      ├── main.tf
      ├── variables.tf
      ├── outputs.tf
      ├── dev.tfvars.example
      ├── prod.tfvars.example
      ├── backend-config-dev.tfvars.example
      └── backend-config-prod.tfvars.example
```

**Benefits:**
- Simpler directory structure
- Single source of truth for Terraform configuration
- Easier to maintain and version control
- Clear separation of environment-specific values
- Standard Terraform workflow with `-var-file` flag

**Usage:**
```bash
# Development
terraform init -backend-config=backend-config-dev.tfvars
terraform plan -var-file="dev.tfvars"
terraform apply -var-file="dev.tfvars"

# Production
terraform init -backend-config=backend-config-prod.tfvars
terraform plan -var-file="prod.tfvars"
terraform apply -var-file="prod.tfvars"
```

#### 2. Managed Identity Authentication (No App Registrations)

**Changed**: Simplified authentication to use **only Managed Identities** throughout the solution.

**What Changed:**
- ❌ Removed creation of Entra ID App Registrations
- ✅ All Azure resources use System-assigned Managed Identities (APIM, Function App, Web App)
- ✅ Foundry Agent uses customer-provided Managed Identity (Principal ID)
- ✅ JWT validation in APIM now validates the `oid` (Object ID) claim instead of `appid`
- ✅ Token audience is the Function App URL instead of custom API URI
- ✅ No client secrets, certificates, or app registrations required

**Benefits:**
- Simpler deployment (no Entra ID app creation)
- More secure (no secrets to manage or rotate)
- Zero-configuration token acquisition via Azure IMDS
- Fully managed by Azure platform

**Migration Notes:**
- If you deployed the old version with app registrations, you can safely delete them
- Update `terraform.tfvars` to provide `foundry_agent_principal_id` instead of `foundry_agent_client_id`
- Re-run `terraform apply` to update policies

#### 2. Sweden Central Region

**Changed**: Default deployment region changed from `eastus` to `swedencentral`.

**What Changed:**
- Default `location` variable in dev/prod environments now `swedencentral`
- Example configuration files updated
- Documentation updated to reflect Sweden Central deployment

**Benefits:**
- European data residency compliance
- GDPR alignment
- Lower latency for European users
- Compliance with data sovereignty requirements

**Migration Notes:**
- Existing deployments in other regions are unaffected
- New deployments will default to Sweden Central
- You can override by setting `location = "your-region"` in `terraform.tfvars`

### Files Modified

#### Infrastructure
- `infra/modules/identity/` - Simplified to remove app registration creation
- `infra/modules/apim/main.tf` - Updated JWT validation policy for managed identity
- `infra/modules/function_app/main.tf` - Simplified auth config (no client_id required)
- `infra/envs/dev/` - Updated variables and outputs
- `infra/envs/prod/` - Updated variables and outputs

#### Documentation
- `docs/security-model.md` - Rewritten authentication flow for managed identities
- `docs/deployment.md` - Updated configuration steps
- `docs/architecture.md` - Updated component descriptions
- `README.md` - Updated key features and security model

### Configuration Changes

**Old Configuration:**
```hcl
create_foundry_agent = true
foundry_agent_client_id = "<client-id>"
```

**New Configuration:**
```hcl
foundry_agent_principal_id = "<principal-id>"  # Object ID of Foundry Agent's MI
```

**Old Region:**
```hcl
location = "eastus"
```

**New Region:**
```hcl
location = "swedencentral"
```

### Authentication Flow Changes

**Before:**
```
Foundry Agent (App Registration)
  → Acquires token with scope: api://<apim-app-id>/.default
  → APIM validates appid claim
  → APIM MI calls Function App
```

**After:**
```
Foundry Agent (Managed Identity)
  → Acquires token with resource: https://<function-app>.azurewebsites.net
  → APIM validates oid (Principal ID) claim
  → APIM MI calls Function App
```

### Breaking Changes

⚠️ **Breaking Changes** - Requires configuration updates:

1. **Directory Structure**: `infra/envs/dev/` and `infra/envs/prod/` merged into single `infra/envs/`
2. **Configuration Files**: `terraform.tfvars` → `dev.tfvars` or `prod.tfvars`
3. **Backend Config**: `backend-config.tfvars` → `backend-config-dev.tfvars` or `backend-config-prod.tfvars`
4. **Variable Rename**: `foundry_agent_client_id` → `foundry_agent_principal_id`
5. **Variable Removed**: `create_foundry_agent` (no longer used)
6. **Module Output Changes**: Identity module no longer outputs app registration details
7. **APIM Policy Changes**: JWT validation now checks `oid` instead of `appid`
8. **Terraform Commands**: Must now specify `-var-file` parameter

### Upgrade Path

To upgrade from the previous version:

1. **Backup your current configuration:**
   ```bash
   # If you had custom terraform.tfvars
   cp infra/envs/dev/terraform.tfvars ~/backup-dev.tfvars
   cp infra/envs/prod/terraform.tfvars ~/backup-prod.tfvars  # if it exists
   ```

2. **Get Foundry Agent Principal ID:**
   ```bash
   az identity show --name <identity-name> --resource-group <rg> --query principalId -o tsv
   ```

3. **Pull latest code:**
   ```bash
   git pull origin main
   ```

4. **Create new environment configuration:**
   ```bash
   cd infra/envs
   
   # For dev
   cp dev.tfvars.example dev.tfvars
   cp backend-config-dev.tfvars.example backend-config-dev.tfvars
   
   # For prod (if needed)
   cp prod.tfvars.example prod.tfvars
   cp backend-config-prod.tfvars.example backend-config-prod.tfvars
   ```

5. **Migrate settings from backup:**
   - Copy subscription_id, tenant_id, etc. from backup files
   - Update variable names:
     - `foundry_agent_client_id` → `foundry_agent_principal_id`
   - Remove obsolete variables:
     - `create_foundry_agent`

6. **Re-initialize Terraform:**
   ```bash
   cd infra/envs
   
   # Remove old state
   rm -rf .terraform .terraform.lock.hcl
   
   # Initialize with new backend config
   terraform init -backend-config=backend-config-dev.tfvars
   ```

7. **Plan and apply:**
   ```bash
   terraform plan -var-file="dev.tfvars"
   terraform apply -var-file="dev.tfvars"
   ```

8. **Update Foundry Agent Configuration:**
   ```json
   {
     "authentication": {
       "type": "ManagedIdentity",
       "resource": "https://<function-app>.azurewebsites.net"
     }
   }
   ```

### Rollback

If you need to rollback:
1. Check out the previous commit before these changes
2. Restore your old `terraform.tfvars` configuration
3. Run `terraform apply`

Note: This is not recommended as the managed identity approach is more secure and simpler.
