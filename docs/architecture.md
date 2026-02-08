# Azure MCP Gateway - Architecture Overview

## Overview

This solution provides a **security-first, enterprise-grade** Azure architecture for exposing a Slack MCP (Model Context Protocol) Server through a fully private, zero-trust design. All components communicate exclusively over private networking with identity-based authentication.

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                         Azure Tenant                             │
│                                                                   │
│  ┌──────────────┐                                                │
│  │    User      │                                                │
│  └──────┬───────┘                                                │
│         │                                                         │
│         │ HTTPS                                                   │
│         ▼                                                         │
│  ┌──────────────────────────────────────────────────────┐       │
│  │  React Frontend (Azure Web App)                       │       │
│  │  - Private Endpoint Only                              │       │
│  │  - VNet Integration                                   │       │
│  │  - Calls Foundry Agent via Entra ID                   │       │
│  └──────────────────┬───────────────────────────────────┘       │
│                     │                                             │
│                     │ Entra ID Token                              │
│                     ▼                                             │
│  ┌──────────────────────────────────────────────────────┐       │
│  │  Azure AI Foundry Agent (Orchestrator)               │       │
│  │  - Managed Identity / App Identity                    │       │
│  │  - Issues Entra ID tokens for APIM                    │       │
│  └──────────────────┬───────────────────────────────────┘       │
│                     │                                             │
│                     │ Entra ID Token (validate-jwt)               │
│                     ▼                                             │
│  ┌──────────────────────────────────────────────────────┐       │
│  │  Azure API Management (INTERNAL Mode)                │       │
│  │  - Private VNet Deployment                            │       │
│  │  - Entra ID JWT Validation                            │       │
│  │  - Only accepts Foundry Agent tokens                  │       │
│  │  - Uses Managed Identity to call Functions            │       │
│  └──────────────────┬───────────────────────────────────┘       │
│                     │                                             │
│                     │ Entra ID Token (MI)                         │
│                     ▼                                             │
│  ┌──────────────────────────────────────────────────────┐       │
│  │  Azure Functions (Python, Linux)                      │       │
│  │  - Private Endpoint Only                              │       │
│  │  - Entra ID Authentication Enabled                    │       │
│  │  - Only accepts APIM Managed Identity                 │       │
│  │  - Placeholder function (future Slack MCP logic)      │       │
│  └────────────────────────────────────────────────────────┘     │
│                                                                   │
└───────────────────────────────────────────────────────────────────┘
```

## Network Architecture

### Virtual Network Design

- **VNet CIDR**: 10.0.0.0/16
- **Subnets**:
  - `apim-subnet` (10.0.1.0/24) - For Azure API Management
  - `functions-pe-subnet` (10.0.2.0/24) - For Function App Private Endpoints
  - `webapp-integration-subnet` (10.0.3.0/24) - For Web App VNet Integration
  - `storage-pe-subnet` (10.0.4.0/24) - For Storage Account Private Endpoints

### Private DNS Zones

- `privatelink.azurewebsites.net` - For Function App and Web App private endpoints
- `privatelink.azure-api.net` - For API Management
- `privatelink.blob.core.windows.net` - For Storage Account private endpoints
- `privatelink.file.core.windows.net` - For Storage Account file shares
- `privatelink.queue.core.windows.net` - For Storage Account queues
- `privatelink.table.core.windows.net` - For Storage Account tables

All DNS zones are linked to the VNet for private name resolution.

## Component Details

### 1. Frontend (React Web App)

**Technology**: React, hosted on Azure App Service (Linux)

**Security**:
- **NO public endpoint** - accessible only via Private Endpoint
- VNet Integration for outbound connectivity
- Entra ID authentication for accessing Foundry Agent

**Purpose**: User interface for interacting with the AI agent

### 2. Azure AI Foundry Agent

**Technology**: Azure AI Foundry service

**Security**:
- Uses Managed Identity or Service Principal
- Issues Entra ID tokens with specific audience for APIM
- Only authorized identity allowed to call APIM

**Purpose**: Orchestrates requests between frontend and backend MCP services

### 3. Azure API Management (APIM)

**Technology**: Azure API Management (Developer or higher tier for VNet support)

**Deployment Mode**: INTERNAL (private VNet injection)

**Security**:
- Deployed inside VNet (`apim-subnet`)
- **NO public endpoint**
- Inbound policy: `validate-jwt` with:
  - Tenant-specific issuer validation
  - Audience validation (`api://<apim-app-id>`)
  - Client identity validation (only Foundry Agent `appid`)
- Outbound: Uses System-assigned Managed Identity to call Functions
- Entra ID token acquisition for Function App audience

**Purpose**: 
- API gateway and security boundary
- JWT validation and authorization
- Protocol transformation if needed

### 4. Azure Functions (Backend)

**Technology**: Python 3.11, Linux, Azure Functions v4

**Security**:
- **NO public endpoint** - accessible only via Private Endpoint
- Entra ID authentication enabled
- Only accepts tokens from APIM Managed Identity
- Function key authentication **DISABLED**
- RBAC role assignment: APIM MI → Function App (Website Contributor or similar)

**Purpose**: 
- Hosts placeholder HTTP function
- Future home for Slack MCP Server logic (out of scope for initial deployment)

### 5. Supporting Services

#### Storage Account
- Private endpoints for blob, file, queue, table
- Required for Function App operation
- No public access

#### Application Insights + Log Analytics
- Centralized logging and monitoring
- Diagnostic settings enabled on all resources
- Query capability for troubleshooting

## Request Flow

1. **User → Frontend**
   - User accesses React app via private endpoint (or through private network access)

2. **Frontend → Foundry Agent**
   - Frontend authenticates user with Entra ID
   - Sends request to Foundry Agent endpoint

3. **Foundry Agent → APIM**
   - Agent acquires Entra ID token with audience `api://<apim-app-id>`
   - Sends HTTP request to APIM private endpoint with `Authorization: Bearer <token>`

4. **APIM JWT Validation**
   - APIM validates JWT:
     - Correct issuer (tenant)
     - Correct audience
     - Correct client identity (Foundry Agent only)
   - If validation fails → 401 Unauthorized

5. **APIM → Functions**
   - APIM uses its Managed Identity to acquire Entra ID token
   - Token audience: `https://<function-app-name>.azurewebsites.net`
   - Sends request to Function App private endpoint

6. **Function App Authentication**
   - Function App validates Entra ID token
   - Checks token is from APIM Managed Identity
   - If validation fails → 401 Unauthorized

7. **Function Execution**
   - Placeholder function returns `{"status": "placeholder"}`
   - Response flows back through APIM → Foundry → Frontend → User

## Zero-Trust Security Model

### Principle: Verify Explicitly

- **No implicit trust** - every request is authenticated and authorized
- **Identity-based access** - no secrets, no keys, no shared credentials
- **Least privilege** - each component can only access what it needs

### Authentication Flow

```
Foundry Agent Identity
    ↓
  [Entra ID Token with audience: api://<apim-app-id>]
    ↓
  APIM validates + authorizes
    ↓
  APIM Managed Identity
    ↓
  [Entra ID Token with audience: https://<function-app>.azurewebsites.net]
    ↓
  Function App validates + authorizes
```

### Network Isolation

- **All resources in private VNet**
- **No public IPs or endpoints**
- **Private DNS** for name resolution
- **Network Security Groups** can be added for additional subnet-level filtering

## High Availability & Scalability

### APIM
- Internal mode supports zone redundancy (in supported regions)
- Auto-scaling based on load
- Built-in caching capabilities

### Function App
- Elastic Premium or Dedicated App Service Plan
- VNet integration supported
- Horizontal scaling based on demand

### Frontend
- App Service auto-scaling
- Deployment slots for zero-downtime updates

## Disaster Recovery

### Infrastructure as Code
- All infrastructure defined in Terraform
- Can be redeployed to different region
- State stored in Azure Storage (with versioning)

### Data Backup
- Storage Account versioning enabled
- Function App configuration backed up via Terraform state
- APIM configuration exported regularly

## Compliance & Governance

### Azure Policy
- Can enforce:
  - No public IP addresses
  - Mandatory private endpoints
  - Required diagnostic settings
  - Allowed Azure regions

### Entra ID Conditional Access
- Can require:
  - Device compliance
  - MFA for admin access
  - Specific network locations

### Logging & Auditing
- All requests logged to Application Insights
- Diagnostic logs sent to Log Analytics
- Query capability for security investigations
- Retain logs per compliance requirements (default: 30 days)

## Extension Points

### Adding Slack MCP Logic

When ready to implement Slack integration:

1. Update Function App code to implement MCP protocol
2. Add Slack API credentials to Key Vault (accessed via Managed Identity)
3. No infrastructure changes required - authentication model remains the same

### Adding Additional APIs

1. Create new operations in APIM API definition
2. Map to new Function App endpoints
3. Same JWT validation applies automatically

### Multi-Environment Strategy

- `dev` environment: Smaller SKUs, relaxed monitoring
- `prod` environment: Higher SKUs, comprehensive monitoring, potentially multi-region

## Cost Optimization

### Development Environment
- APIM: Developer tier
- Function App: Consumption or Elastic Premium (EP1)
- App Service: B1 or P1v2
- Estimated monthly cost: ~$50-300 USD

### Production Environment
- APIM: Developer or Basic tier (internal mode)
- Function App: Elastic Premium (EP1+) or Dedicated Plan
- App Service: P1v2 or higher
- Added costs for zone redundancy and higher scale
- Estimated monthly cost: ~$500-2000+ USD

### Cost Management
- Use Azure Cost Management for tracking
- Set budget alerts
- Consider reserved instances for predictable workloads
- Monitor actual usage vs. provisioned capacity

## Deployment Strategy

1. **Terraform Backend Setup**: Create storage account for state (can be manual or via bootstrap script)
2. **Entra ID Prerequisites**: May need permissions to create App Registrations
3. **Terraform Apply**: Deploy infrastructure modules
4. **APIM Configuration**: Verify policies are applied
5. **Function Deployment**: Deploy placeholder function code
6. **Frontend Deployment**: Deploy React app
7. **Integration Testing**: Verify end-to-end flow
8. **Monitoring**: Validate logs are flowing to Application Insights

## Troubleshooting

### Common Issues

1. **401 Unauthorized from APIM**
   - Check JWT token audience matches APIM App Registration
   - Verify Foundry Agent identity is in allowlist
   - Review APIM logs in Application Insights

2. **401 Unauthorized from Function App**
   - Verify APIM Managed Identity has RBAC role on Function App
   - Check Function App authentication configuration
   - Ensure token audience matches Function App URL

3. **Cannot resolve private endpoint**
   - Verify Private DNS zones are linked to VNet
   - Check A records exist for private endpoints
   - Test DNS resolution from within VNet

4. **APIM deployment issues**
   - Ensure subnet is large enough (/27 minimum)
   - Verify NSG rules (if any) allow required traffic
   - Check quota limits for APIM instances

## References

- [Azure Private Endpoint](https://learn.microsoft.com/azure/private-link/private-endpoint-overview)
- [Azure API Management VNet Integration](https://learn.microsoft.com/azure/api-management/api-management-using-with-vnet)
- [Azure Functions Private Endpoints](https://learn.microsoft.com/azure/azure-functions/functions-networking-options)
- [Entra ID Authentication for App Service](https://learn.microsoft.com/azure/app-service/overview-authentication-authorization)
- [APIM JWT Validation Policy](https://learn.microsoft.com/azure/api-management/validate-jwt-policy)
