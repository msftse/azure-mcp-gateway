# Security Model - Zero Trust Architecture

## Executive Summary

This solution implements a **zero-trust security architecture** where:
- **No component trusts any other by default**
- **Every request is authenticated and authorized**
- **No secrets, keys, or shared credentials** are used
- **All resources are private** - no public endpoints
- **Identity is the security perimeter**

## Security Principles

### 1. Verify Explicitly

Every request is authenticated using **Azure Entra ID tokens** (formerly Azure AD). No request proceeds without explicit identity verification.

### 2. Least Privilege Access

Each component has only the minimum permissions required:
- Foundry Agent → Can call APIM only
- APIM Managed Identity → Can invoke Function App only
- Function App → Can access Storage Account only

### 3. Assume Breach

Network isolation ensures that even if one component is compromised:
- Lateral movement is prevented by private networking
- Access requires valid Entra ID tokens
- All actions are logged for forensics

## Authentication & Authorization Architecture

### Layer 1: Foundry Agent → APIM

#### Authentication Method
**Entra ID OAuth 2.0 / OpenID Connect**

#### Identity
- Foundry Agent uses either:
  - **System-assigned Managed Identity**, or
  - **Service Principal (App Registration)**

#### Token Acquisition
```
POST https://login.microsoftonline.com/{tenant-id}/oauth2/v2.0/token
Content-Type: application/x-www-form-urlencoded

grant_type=client_credentials
&client_id={foundry-agent-client-id}
&client_secret={secret-or-certificate}
&scope=api://{apim-app-id}/.default
```

Returns JWT token with:
```json
{
  "aud": "api://{apim-app-id}",
  "iss": "https://sts.windows.net/{tenant-id}/",
  "appid": "{foundry-agent-client-id}",
  "roles": ["API.Access"],
  ...
}
```

#### APIM Validation

APIM inbound policy validates the JWT:

```xml
<inbound>
    <validate-jwt 
        header-name="Authorization" 
        failed-validation-httpcode="401" 
        failed-validation-error-message="Unauthorized">
        <openid-config url="https://login.microsoftonline.com/{tenant-id}/v2.0/.well-known/openid-configuration" />
        <audiences>
            <audience>api://{apim-app-id}</audience>
        </audiences>
        <issuers>
            <issuer>https://sts.windows.net/{tenant-id}/</issuer>
        </issuers>
        <required-claims>
            <claim name="appid" match="any">
                <value>{foundry-agent-client-id}</value>
            </claim>
        </required-claims>
    </validate-jwt>
</inbound>
```

**Validation Checks**:
1. ✅ Token signature is valid (using Microsoft public keys)
2. ✅ Token has not expired
3. ✅ Issuer matches tenant
4. ✅ Audience is `api://{apim-app-id}`
5. ✅ `appid` claim matches Foundry Agent identity
6. ❌ **Any other identity is rejected with 401**

### Layer 2: APIM → Function App

#### Authentication Method
**Entra ID Managed Identity with RBAC**

#### Identity
- APIM uses **System-assigned Managed Identity**
- No credentials stored or managed

#### Token Acquisition (Automatic)

APIM backend policy uses `authentication-managed-identity`:

```xml
<backend>
    <authentication-managed-identity 
        resource="https://{function-app-name}.azurewebsites.net" 
    />
</backend>
```

This automatically:
1. Contacts Azure Instance Metadata Service (IMDS)
2. Acquires Entra ID token for APIM's Managed Identity
3. Token audience: `https://{function-app-name}.azurewebsites.net`
4. Adds token to `Authorization: Bearer` header

#### Function App Validation

Function App is configured with:
```json
{
  "authsettingsV2": {
    "platform": {
      "enabled": true
    },
    "identityProviders": {
      "azureActiveDirectory": {
        "enabled": true,
        "registration": {
          "clientId": "{function-app-client-id}",
          "openIdIssuer": "https://sts.windows.net/{tenant-id}/"
        },
        "validation": {
          "allowedAudiences": [
            "https://{function-app-name}.azurewebsites.net"
          ]
        }
      }
    },
    "login": {
      "tokenStore": {
        "enabled": true
      }
    }
  }
}
```

**Validation Checks**:
1. ✅ Token signature is valid
2. ✅ Token has not expired
3. ✅ Issuer matches tenant
4. ✅ Audience matches Function App URL
5. ✅ Token `oid` (object ID) matches APIM Managed Identity
6. ❌ **Any other identity is rejected with 401**

#### RBAC Authorization

In addition to authentication, APIM Managed Identity requires RBAC role assignment:

```
APIM Managed Identity 
  → "Website Contributor" role 
  → Scope: Function App
```

This allows APIM to:
- Invoke functions
- Read function configuration
- NOT deploy code or change settings (unless needed)

## Network Security

### Private Endpoints

All resources use **Private Endpoints** for connectivity:

| Resource | Private Endpoint | DNS Zone |
|----------|------------------|----------|
| Function App | Yes | privatelink.azurewebsites.net |
| Storage Account (blob) | Yes | privatelink.blob.core.windows.net |
| Storage Account (file) | Yes | privatelink.file.core.windows.net |
| Storage Account (queue) | Yes | privatelink.queue.core.windows.net |
| Storage Account (table) | Yes | privatelink.table.core.windows.net |
| Web App (Frontend) | Yes | privatelink.azurewebsites.net |

### APIM Internal Mode

APIM is deployed with VNet injection:
- **SKU**: Developer or Premium (VNet support required)
- **Mode**: Internal
- **Effect**: APIM has private IP only, no public endpoint

### VNet Security

```
┌─────────────────────────────────────────┐
│          Virtual Network 10.0.0.0/16     │
│                                          │
│  ┌────────────────────────────────────┐ │
│  │ apim-subnet (10.0.1.0/24)          │ │
│  │ - APIM injected here                │ │
│  │ - NSG: Allow HTTPS in from VNet     │ │
│  └────────────────────────────────────┘ │
│                                          │
│  ┌────────────────────────────────────┐ │
│  │ functions-pe-subnet (10.0.2.0/24)  │ │
│  │ - Function App Private Endpoint     │ │
│  │ - NSG: Allow HTTPS from apim-subnet │ │
│  └────────────────────────────────────┘ │
│                                          │
│  ┌────────────────────────────────────┐ │
│  │ webapp-int-subnet (10.0.3.0/24)    │ │
│  │ - Web App VNet Integration          │ │
│  └────────────────────────────────────┘ │
│                                          │
│  ┌────────────────────────────────────┐ │
│  │ storage-pe-subnet (10.0.4.0/24)    │ │
│  │ - Storage Account Private Endpoints │ │
│  └────────────────────────────────────┘ │
└─────────────────────────────────────────┘
```

### Network Security Groups (NSGs)

While NSGs are optional with private endpoints, they can provide defense-in-depth:

**apim-subnet NSG**:
- Allow inbound HTTPS (443) from VNet
- Allow inbound 3443 (management) from Azure
- Deny all other inbound

**functions-pe-subnet NSG**:
- Allow inbound HTTPS (443) from apim-subnet
- Deny all other inbound

## Secret Management

### ❌ What We DON'T Use

- **Function keys** - Disabled
- **Shared secrets** - None
- **Connection strings with keys** - None
- **API subscription keys** - Not used for authentication
- **Service Principal certificates in code** - None

### ✅ What We DO Use

- **Managed Identities** - For all service-to-service auth
- **Azure Key Vault** (future) - For Slack API tokens when needed
  - Accessed via Managed Identity (no keys)
  - RBAC: Function App MI → Key Vault Secrets User role
- **Entra ID Tokens** - Short-lived, cryptographically signed

## Data Protection

### In Transit

- **TLS 1.2+** enforced on all connections
- **HTTPS only** - no HTTP endpoints
- **Private network** - traffic never leaves Azure backbone

### At Rest

- **Storage Account** - Encryption at rest (Microsoft-managed keys)
- **Application Insights** - Data encrypted at rest
- **Function App configuration** - Encrypted

### Sensitive Data Handling

For future Slack integration:
- Slack tokens stored in **Key Vault**
- Retrieved at runtime using Managed Identity
- Never logged or exposed in responses
- Rotate regularly using Key Vault versioning

## Identity Security

### Managed Identities

**System-assigned Managed Identities** used for:
- APIM
- Function App
- Web App (Frontend)

Advantages:
- ✅ Lifecycle tied to resource (deleted with resource)
- ✅ No credential management required
- ✅ Automatic credential rotation
- ✅ Cannot be shared or exfiltrated

### Service Principals

**Foundry Agent** uses Service Principal (App Registration):
- Certificate-based authentication preferred over client secret
- Certificate stored securely (Azure Key Vault or OS certificate store)
- Regular rotation policy

### Entra ID Configuration

**App Registration for APIM API**:
- `api://{apim-app-id}` - Application ID URI
- Exposed API scope: `API.Access`
- Pre-authorized application: Foundry Agent client ID

**RBAC Role Assignments**:
```
APIM Managed Identity
  → Role: Website Contributor (or custom role)
  → Scope: Resource Group or Function App

Function App Managed Identity
  → Role: Storage Blob Data Contributor
  → Scope: Storage Account

Function App Managed Identity (future)
  → Role: Key Vault Secrets User
  → Scope: Key Vault
```

## Threat Model & Mitigations

### Threat: Unauthorized API Access

**Attack**: External attacker tries to call APIM or Function App

**Mitigations**:
- ✅ No public endpoints - not accessible from internet
- ✅ VNet isolation - requires network access
- ✅ Entra ID authentication - requires valid token
- ✅ JWT validation with client ID check - only Foundry Agent allowed

**Result**: 🛡️ Attack blocked at network and identity layers

### Threat: Token Theft/Replay

**Attack**: Attacker steals valid Entra ID token and replays it

**Mitigations**:
- ✅ Tokens are short-lived (default: 1 hour)
- ✅ HTTPS only - encrypted in transit
- ✅ Token bound to specific audience - cannot be reused for other resources
- ✅ Logging - unusual patterns detected in Application Insights

**Result**: 🛡️ Limited window for attack, logged for detection

### Threat: Compromised Function App

**Attack**: Attacker gains code execution in Function App

**Mitigations**:
- ✅ Least privilege - Function App MI has minimal permissions
- ✅ No outbound public access - limited lateral movement
- ✅ Network isolation - cannot reach other resources directly
- ✅ Logging - malicious behavior detected

**Result**: 🛡️ Blast radius contained, lateral movement prevented

### Threat: Insider Threat (Malicious Admin)

**Attack**: Azure admin with excessive permissions

**Mitigations**:
- ✅ RBAC with least privilege - Separation of duties
- ✅ Privileged Identity Management (PIM) - Just-in-time admin access
- ✅ Audit logging - All admin actions logged
- ✅ Entra ID Conditional Access - MFA required for admin roles

**Result**: 🛡️ Detection and accountability, reduced attack surface

### Threat: Denial of Service (DoS)

**Attack**: Flood APIM with requests

**Mitigations**:
- ✅ Private network - limited attack surface
- ✅ APIM rate limiting - Requests per second limits
- ✅ APIM caching - Reduce backend load
- ✅ Azure DDoS Protection - (optional, for public-facing scenarios)

**Result**: 🛡️ Service remains available for legitimate clients

## Compliance & Auditing

### Logging Strategy

**What is logged**:
- All APIM requests (request/response headers, status codes, latency)
- Function App execution logs (invocations, errors, performance)
- Authentication events (token validations, failures)
- RBAC changes (role assignments, permission changes)
- Network flow logs (optional, NSG flow logs)

**Where logs are stored**:
- **Application Insights** - Application logs, traces, metrics
- **Log Analytics Workspace** - Centralized log aggregation
- **Azure Activity Log** - Azure control plane operations

**Retention**:
- Default: 30 days (configurable up to 730 days)
- Long-term: Export to Storage Account for archival

### Security Monitoring

**Key queries** (Log Analytics/KQL):

1. **Failed authentication attempts**:
```kql
AppServiceAuthenticationLogs
| where Result == "Unauthorized"
| summarize count() by Identity, bin(TimeGenerated, 1h)
```

2. **Unusual IP addresses** (for VNet-internal monitoring):
```kql
AppServiceHTTPLogs
| where CIp !startswith "10.0."
| summarize count() by CIp, bin(TimeGenerated, 1h)
```

3. **High error rates**:
```kql
requests
| where success == false
| summarize ErrorCount=count() by bin(timestamp, 5m)
| where ErrorCount > 10
```

### Compliance Frameworks

This architecture supports compliance with:
- **SOC 2** - Security controls, logging, access management
- **ISO 27001** - Information security management
- **HIPAA** - Private networking, encryption, audit logs
- **PCI DSS** - Network segmentation, access controls
- **GDPR** - Data protection, audit trails

### Azure Policy

**Recommended Azure Policies** for enforcement:

1. **Deny public network access**:
   - Effect: Deny
   - Resource types: Storage Account, Function App, etc.
   - Ensures no public endpoints can be created

2. **Require private endpoints**:
   - Effect: Audit or Deny
   - Ensures resources have private endpoints configured

3. **Require diagnostic settings**:
   - Effect: DeployIfNotExists
   - Automatically enables logging to Log Analytics

4. **Allowed locations**:
   - Effect: Deny
   - Restrict resource creation to approved Azure regions

## Security Checklist

Before deploying to production:

- [ ] **All public access disabled** on Function App, Storage Account
- [ ] **APIM deployed in Internal mode** (private VNet)
- [ ] **Private DNS zones created and linked** to VNet
- [ ] **validate-jwt policy configured** on APIM with correct audience
- [ ] **Foundry Agent client ID allowlisted** in APIM policy
- [ ] **APIM Managed Identity assigned** Website Contributor role on Function App
- [ ] **Function App authentication enabled** (Entra ID)
- [ ] **Function keys disabled** (authentication set to Entra ID only)
- [ ] **All diagnostic settings enabled** (send to Log Analytics)
- [ ] **NSGs configured** (optional, for defense-in-depth)
- [ ] **Secrets stored in Key Vault** (if applicable)
- [ ] **Managed Identities used** for all service-to-service auth
- [ ] **TLS 1.2+ enforced** on all resources
- [ ] **No hardcoded credentials** in code or configuration
- [ ] **Azure Policy assignments** to enforce security baselines
- [ ] **Monitoring alerts configured** for security events
- [ ] **Incident response plan documented**

## Future Security Enhancements

### 1. Customer Managed Keys (CMK)

Encrypt data at rest using customer-controlled keys in Key Vault:
- Storage Account encryption
- Function App configuration
- Requires additional RBAC for service principals

### 2. Bring Your Own Key (BYOK) for SSL/TLS

Use custom SSL certificates stored in Key Vault:
- APIM custom domain with private CA cert
- Function App custom domain

### 3. Conditional Access Policies

Require additional contexts for Foundry Agent:
- Specific device compliance
- Specific network location
- Risk-based access

### 4. Private Link for Log Analytics

Send logs over private connection:
- Private endpoint for Log Analytics workspace
- No logs traverse public internet

### 5. Advanced Threat Protection

Enable Azure Defender for:
- App Service (detects malicious requests)
- Storage (detects anomalous access patterns)
- Key Vault (detects suspicious operations)

## Appendix: Security Best Practices

### Development

- **Never commit secrets** to source control
- Use **environment variables** for configuration (loaded from Key Vault)
- Enable **Dependabot** for dependency vulnerability scanning
- Run **static code analysis** (SonarQube, Semgrep)

### Operations

- **Rotate credentials** regularly (Service Principal certificates)
- **Review RBAC assignments** quarterly
- **Patch and update** Function App runtime and dependencies
- **Test disaster recovery** procedures

### Incident Response

- **Detection**: Monitor Application Insights and Log Analytics for anomalies
- **Containment**: Disable compromised identities, block network access
- **Eradication**: Patch vulnerabilities, rotate credentials
- **Recovery**: Restore from known-good Terraform state
- **Lessons Learned**: Update threat model and controls

## References

- [Azure Entra ID Authentication for App Service](https://learn.microsoft.com/azure/app-service/overview-authentication-authorization)
- [API Management JWT Validation](https://learn.microsoft.com/azure/api-management/validate-jwt-policy)
- [Managed Identities for Azure Resources](https://learn.microsoft.com/entra/identity/managed-identities-azure-resources/overview)
- [Azure Private Link](https://learn.microsoft.com/azure/private-link/private-link-overview)
- [Azure Security Baseline for App Service](https://learn.microsoft.com/security/benchmark/azure/baselines/app-service-security-baseline)
