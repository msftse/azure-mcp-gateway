You are GitHub Copilot acting as a senior Azure cloud security, networking, and platform engineer.

Design and implement a CUSTOMER-READY, SECURITY-FIRST Azure solution that exposes a Slack MCP Server architecture with STRICT identity-based access, PRIVATE networking only, and FULL Terraform automation.

========================
SECURITY NON-NEGOTIABLES
========================
1) ALL Azure resources must be PRIVATE (no public endpoints).
2) Authentication and authorization must use Azure Entra ID + RBAC ONLY.
   - NO function keys
   - NO shared secrets
   - NO API keys
3) The ONLY client allowed to call the API Gateway is the Azure AI Foundry Agent.
4) The ONLY service allowed to call the Azure Functions backend is the API Gateway.
5) Infrastructure deployment must be FULLY automated via Terraform.
   - Customer clones repo
   - Runs Terraform
   - Entire environment is deployed without manual steps
6) Backend code is OUT OF SCOPE.
   - Create an EMPTY Azure Function App with a placeholder function only.
   - Do NOT implement Slack MCP logic.

================
REQUEST FLOW
================
User
  -> React Frontend (Azure Web App)
    -> Azure AI Foundry Agent (orchestrator)
      -> Azure API Management (Private)
        -> Azure Functions (Private)
          -> (Future Slack MCP logic – not implemented)

The frontend NEVER calls APIM or Functions directly.

================
ARCHITECTURE (PRIVATE ONLY)
================
Frontend:
- React app deployed to Azure App Service.
- App Service must use:
  - VNet Integration
  - Private Endpoint
- No public inbound traffic.
- Used only to interact with the Foundry agent endpoint.

Orchestrator:
- Azure AI Foundry Agent.
- Uses Entra ID (managed identity or app-only identity).
- ONLY allowed caller of APIM.

API Gateway:
- Azure API Management in INTERNAL / VNET mode.
- NO public endpoint.
- Entra ID protected:
  - validate-jwt
  - Single tenant
  - Correct audience
  - Allow-listed client identity ONLY (Foundry agent).
- Uses Managed Identity to call backend Functions.
- Private DNS enabled.

Backend:
- Azure Functions (Python, Linux).
- Private Endpoint ONLY.
- Public access disabled.
- Entra ID authentication enabled:
  - ONLY APIM managed identity allowed.
- Function App contains:
  - One EMPTY HTTP-triggered function
  - No business logic
  - Placeholder response only
- Uses RBAC exclusively (no keys).

Networking:
- Dedicated VNet
- Subnets for:
  - APIM
  - Function App private endpoint
  - App Service integration
- Private DNS zones:
  - privatelink.azurewebsites.net
  - privatelink.azure-api.net (or relevant APIM zones)

================
AUTHENTICATION & AUTHORIZATION
================
APIM Inbound:
- validate-jwt policy
- Accept tokens ONLY if:
  - issuer == tenant
  - audience == api://<apim-api-app-id>
  - appid / azp == Foundry Agent identity
- Reject everything else.

APIM → Functions:
- APIM uses managed identity to acquire Entra ID token.
- Function App Entra ID auth enabled.
- Function accepts tokens ONLY from APIM managed identity.
- No function keys enabled.

================
INFRASTRUCTURE AS CODE (TERRAFORM)
================
Provision EVERYTHING using Terraform with:
- Modules
- dev/prod environments
- No manual portal steps

Terraform must create:
- Resource Group
- Virtual Network + Subnets
- Private DNS Zones + Links
- Azure API Management (internal mode)
- Azure Function App (Linux, Python)
- Storage Account (private endpoint)
- App Service Plan + Web App (private)
- Entra ID App Registration for APIM API
- Managed Identities:
  - APIM MI
  - Function App MI
- RBAC assignments:
  - APIM MI → invoke Function App
  - Foundry Agent identity → call APIM
- Application Insights + Log Analytics
- Secure Terraform backend (Azure Storage, private)

Rules:
- NO secrets in Terraform
- NO keys
- NO public IPs
- Use RBAC everywhere
- Outputs only expose private endpoints / names

================
BACKEND CODE (MINIMAL)
================
Create ONLY:
- Azure Function App scaffold
- One HTTP-triggered function:
  - Returns 200 OK
  - Simple JSON body (e.g., {"status": "placeholder"})
- No Slack logic
- No MCP logic
- No dependencies beyond Azure Functions runtime

================
REPO STRUCTURE
================
/
  infra/
    modules/
      networking/
      apim/
      function_app/
      webapp/
      monitor/
      identity/
    envs/
      dev/
      prod/
  backend/
    function_app/
      host.json
      requirements.txt
      __init__.py
  frontend/
    react_app/
  docs/
    architecture.md
    security-model.md
    deployment.md

================
DOCUMENTATION
================
Generate documentation explaining:
- Private-only design
- Zero-trust identity flow
- Why only Foundry can call APIM
- Why only APIM can call Functions
- How RBAC replaces keys entirely
- How a customer deploys everything using Terraform
- How backend logic can be added later safely

================
DELIVERABLES
================
Produce:
1) Security-first architecture overview
2) Terraform modules + environments
3) APIM configuration + policies
4) Empty Azure Function App scaffold
5) React frontend scaffold
6) Deployment instructions

Design for:
- Enterprise security review
- Customer handoff
- Zero manual configuration
- Future extensibility (Slack MCP later)

BEGIN WITH:
A) Architecture overview
B) Terraform networking + identity
C) APIM setup
D) Function App scaffold
E) Frontend scaffold
F) Documentation
