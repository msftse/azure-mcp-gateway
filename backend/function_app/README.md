# Azure MCP Gateway - Function App

This directory contains the Azure Function App for the MCP Gateway backend.

## Structure

- `function_app.py` - Main function app with HTTP-triggered endpoints
- `host.json` - Function App host configuration
- `requirements.txt` - Python dependencies

## Endpoints

### GET /api/health
Health check endpoint for monitoring.

**Response:**
```json
{
  "status": "healthy",
  "service": "mcp-gateway"
}
```

### * /api/*
Placeholder endpoint for future Slack MCP Server implementation.

**Note:** This is currently a placeholder. Implement actual MCP server logic here when ready.

## Development

### Local Testing

1. Install Azure Functions Core Tools:
```powershell
npm install -g azure-functions-core-tools@4 --unsafe-perm true
```

2. Create local.settings.json:
```json
{
  "IsEncrypted": false,
  "Values": {
    "AzureWebJobsStorage": "UseDevelopmentStorage=true",
    "FUNCTIONS_WORKER_RUNTIME": "python",
    "AzureWebJobsFeatureFlags": "EnableWorkerIndexing"
  }
}
```

3. Run locally:
```powershell
func start
```

### Deployment

Deploy to Azure Function App:

```powershell
# From this directory
Compress-Archive -Path * -DestinationPath function_app.zip -Force

az functionapp deployment source config-zip `
  --resource-group <resource-group-name> `
  --name <function-app-name> `
  --src function_app.zip
```

Or use GitHub Actions / Azure DevOps pipeline for CI/CD.

## Authentication

The Function App is configured with Azure Entra ID authentication. Only requests with valid Entra ID tokens from the APIM Managed Identity are allowed.

No function keys are used - authentication is purely identity-based.

## Adding MCP Logic

When ready to implement Slack MCP Server:

1. Add MCP SDK dependencies to `requirements.txt`
2. Implement MCP protocol handlers in `function_app.py`
3. Add Slack API credentials to Azure Key Vault
4. Access Key Vault using Function App Managed Identity
5. Update APIM policies if needed for new endpoints

## Environment Variables

Configured via Terraform in the Function App:

- `APPLICATIONINSIGHTS_CONNECTION_STRING` - For logging and monitoring
- `FUNCTIONS_WORKER_RUNTIME=python`
- `WEBSITE_CONTENTOVERVNET=1` - Use private storage
- Additional environment variables can be added via Terraform

## Monitoring

Logs and metrics are sent to Application Insights. Query logs in Azure Portal:

```kql
traces
| where timestamp > ago(1h)
| where severityLevel > 1
| order by timestamp desc
```

## Security Notes

- Function key authentication is **DISABLED**
- Only Entra ID authentication is enabled
- Only APIM Managed Identity can call this Function App
- All traffic flows over private endpoints (no public access)
