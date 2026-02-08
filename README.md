# Azure MCP Gateway

**Enterprise-Grade, Security-First Azure Solution for Slack MCP Server**

## Overview

This repository contains a complete Infrastructure as Code (IaC) solution for deploying a secure, private Azure architecture that exposes a Slack MCP (Model Context Protocol) Server through Azure API Management, with identity-based authentication and zero public endpoints.

## 🎯 Key Features

- **🔒 Zero-Trust Security**: All authentication via Azure Entra ID + RBAC (no keys, no secrets)
- **🔐 Private Networking**: All Azure resources accessible only via private endpoints
- **🏗️ Infrastructure as Code**: Complete Terraform automation for dev and prod environments
- **🛡️ Defense in Depth**: Network isolation, NSGs, JWT validation, and managed identities
- **📊 Observability**: Integrated Application Insights and Log Analytics
- **🚀 Production-Ready**: Enterprise-grade architecture suitable for customer handoff

## 📋 Architecture

```
User
  → React Frontend (Azure Web App - Private)
    → Azure AI Foundry Agent (Orchestrator)
      → Azure API Management (Internal VNet Mode)
        → Azure Functions (Python - Private)
          → (Future: Slack MCP Server Logic)
```

**Security Highlights**:
- Only Foundry Agent can call APIM (JWT validation)
- Only APIM can call Function App (Managed Identity + RBAC)
- All resources in private VNet with private endpoints
- No public IPs or public access enabled anywhere

See [docs/architecture.md](./docs/architecture.md) for detailed architecture documentation.

## 📁 Repository Structure

```
.
├── docs/
│   ├── architecture.md         # Detailed architecture documentation
│   ├── security-model.md       # Zero-trust security design
│   └── deployment.md           # Deployment guide
├── infra/
│   ├── modules/
│   │   ├── networking/         # VNet, subnets, DNS zones
│   │   ├── monitoring/         # Application Insights, Log Analytics
│   │   ├── identity/           # Entra ID app registrations, MI
│   │   ├── apim/               # API Management with JWT policies
│   │   ├── function_app/       # Azure Functions (private)
│   │   └── webapp/             # Web App (React frontend)
│   └── envs/
│       ├── dev/                # Development environment
│       └── prod/               # Production environment
├── backend/
│   └── function_app/           # Python Function App (placeholder)
├── frontend/
│   └── react_app/              # React frontend scaffold
└── .github/
    └── copilot-instructions.md # Project requirements
```

## 🚀 Quick Start

### Prerequisites

- [Terraform](https://www.terraform.io/downloads) >= 1.5.0
- [Azure CLI](https://docs.microsoft.com/cli/azure/install-azure-cli) >= 2.50.0
- Azure subscription with Owner or Contributor + User Access Administrator roles
- Permissions to create Entra ID App Registrations

### 1. Clone Repository

```bash
git clone https://github.com/your-org/azure-mcp-gateway.git
cd azure-mcp-gateway
```

### 2. Configure Terraform Backend

Create storage account for Terraform state:

```powershell
cd infra/envs/dev
# Run bootstrap script (if available) or create manually
# See docs/deployment.md for detailed instructions
```

### 3. Configure Environment

Copy and edit `terraform.tfvars`:

```bash
cd infra/envs/dev
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values
```

Required variables:
- `subscription_id` - Your Azure subscription ID
- `tenant_id` - Your Entra ID tenant ID
- `apim_publisher_name` - Your organization name
- `apim_publisher_email` - Admin email address

### 4. Deploy Infrastructure

```bash
# Initialize Terraform
terraform init -backend-config=backend-config.tfvars

# Review deployment plan
terraform plan

# Deploy (takes ~30-45 minutes due to APIM provisioning)
terraform apply
```

### 5. Deploy Application Code

**Function App:**
```powershell
cd ../../../backend/function_app
Compress-Archive -Path * -DestinationPath function_app.zip -Force

az functionapp deployment source config-zip `
  --resource-group <resource-group-name> `
  --name <function-app-name> `
  --src function_app.zip
```

**Web App:**
```powershell
cd ../../frontend/react_app
npm install
npm run build
cd build
Compress-Archive -Path * -DestinationPath ../webapp.zip -Force

az webapp deployment source config-zip `
  --resource-group <resource-group-name> `
  --name <webapp-name> `
  --src ../webapp.zip
```

### 6. Verify Deployment

```bash
# Check resources are running
az functionapp show --name <function-app-name> --resource-group <rg> --query state
az webapp show --name <webapp-name> --resource-group <rg> --query state
az apim show --name <apim-name> --resource-group <rg> --query provisioningState

# Get deployment summary
terraform output deployment_summary
```

## 📖 Documentation

Comprehensive documentation is available in the [`docs/`](./docs) directory:

- **[Architecture Overview](./docs/architecture.md)** - Complete architecture design, component details, and flow diagrams
- **[Security Model](./docs/security-model.md)** - Zero-trust security design, authentication flows, threat model, and compliance
- **[Deployment Guide](./docs/deployment.md)** - Step-by-step deployment instructions, troubleshooting, and CI/CD integration

## 🔐 Security Non-Negotiables

This solution enforces the following security requirements:

1. ✅ **ALL resources are private** (no public endpoints)
2. ✅ **Authentication via Entra ID + RBAC ONLY** (no function keys, no shared secrets)
3. ✅ **ONLY Foundry Agent can call APIM** (JWT validation with client ID check)
4. ✅ **ONLY APIM can call Function App** (Managed Identity + RBAC)
5. ✅ **Full Terraform automation** (no manual portal steps)

See [docs/security-model.md](./docs/security-model.md) for detailed security architecture.

## 🏗️ Terraform Modules

The infrastructure is organized into reusable Terraform modules:

| Module | Purpose | Key Resources |
|--------|---------|---------------|
| **networking** | VNet, subnets, NSGs, Private DNS | VNet, Subnets, NSGs, DNS Zones |
| **monitoring** | Observability | Log Analytics, Application Insights |
| **identity** | Entra ID identities | App Registrations, Managed Identities |
| **apim** | API Gateway | APIM (Internal), JWT policies, RBAC |
| **function_app** | Backend compute | Functions, Storage, Private Endpoints |
| **webapp** | Frontend hosting | App Service, VNet Integration |

## 💰 Cost Estimation

### Development Environment
- **Monthly**: ~$100-130 USD
- APIM Developer, Function App Consumption/Basic, Web App Basic

### Production Environment
- **Monthly**: ~$3,100-3,200 USD
- APIM Premium, Function App Elastic Premium, Web App Production tier

Use the [Azure Pricing Calculator](https://azure.microsoft.com/pricing/calculator/) for precise estimates.

## 🔧 Development

### Backend (Function App)

```bash
cd backend/function_app

# Local development
pip install -r requirements.txt
func start

# Test locally
curl http://localhost:7071/api/health
```

See [backend/function_app/README.md](./backend/function_app/README.md)

### Frontend (React App)

```bash
cd frontend/react_app

# Install dependencies
npm install

# Run locally
npm start

# Build for production
npm run build
```

See [frontend/react_app/README.md](./frontend/react_app/README.md)

## 📊 Monitoring & Logging

All resources send logs and metrics to Azure Monitor:

- **Application Insights**: Application logs, traces, requests, exceptions
- **Log Analytics**: Centralized log aggregation and querying
- **Diagnostic Settings**: Enabled on all resources

Query logs using KQL:
```kql
requests
| where timestamp > ago(1h)
| where success == false
| order by timestamp desc
```

## 🚢 CI/CD Integration

### GitHub Actions

Example workflow in `.github/workflows/deploy.yml`:

```yaml
- name: Terraform Apply
  run: |
    cd infra/envs/dev
    terraform init
    terraform apply -auto-approve
```

### Azure DevOps

Example pipeline in `azure-pipelines.yml`:

```yaml
- task: AzureCLI@2
  displayName: 'Deploy Infrastructure'
  inputs:
    azureSubscription: 'Azure-Connection'
    scriptType: 'bash'
    scriptLocation: 'inlineScript'
    inlineScript: |
      cd infra/envs/dev
      terraform apply -auto-approve
```

See [docs/deployment.md](./docs/deployment.md) for complete CI/CD examples.

## 🛠️ Troubleshooting

Common issues and solutions:

| Issue | Solution |
|-------|----------|
| 401 from APIM | Check JWT token audience and Foundry Agent client ID |
| 403 from Function App | Verify APIM MI has RBAC role on Function App |
| DNS resolution fails | Verify Private DNS zones are linked to VNet |
| APIM deployment timeout | APIM takes 25-40 minutes; increase timeout |

See [docs/deployment.md#troubleshooting](./docs/deployment.md#troubleshooting) for detailed troubleshooting guide.

## 🔄 Updating Infrastructure

```bash
cd infra/envs/dev

# Review changes
terraform plan

# Apply changes
terraform apply
```

## 🗑️ Destroying Resources

**⚠️ WARNING**: This deletes ALL resources.

```bash
cd infra/envs/dev
terraform destroy
```

## 🎯 Next Steps

After deployment:

1. **Implement Slack MCP Logic** - Update Function App with actual MCP server code
2. **Configure Foundry Agent** - Integrate with deployed APIM endpoint  
3. **Set Up Monitoring Alerts** - Create dashboards and alerts in Azure Monitor
4. **Security Hardening** - Apply Azure Policies, enable Advanced Threat Protection
5. **Load Testing** - Validate performance under expected load
6. **DR Testing** - Verify backup and restore procedures

## 📝 License

(Add your license here)

## 🤝 Contributing

(Add contribution guidelines here)

## 📧 Support

For issues or questions:
- Review documentation in [`docs/`](./docs)
- Check Azure Service Health
- Open a GitHub issue
- Contact Azure Support (for platform issues)

## 🏆 Credits

Built following Azure best practices for:
- Zero-trust security architecture
- Private networking and isolation
- Infrastructure as Code
- Enterprise-grade observability

---

**Built with ❤️ for enterprise security and Azure best practices**