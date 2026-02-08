# Azure MCP Gateway - Frontend

This is a React-based frontend for the Azure MCP Gateway solution.

## Overview

This frontend provides a user interface for interacting with the Azure AI Foundry Agent, which orchestrates communication with the backend MCP server.

## Architecture

```
User → React App → Azure AI Foundry Agent → APIM → Function App
```

The frontend:
- Does NOT call APIM or Function App directly
- Authenticates with Azure Entra ID
- Sends all requests through the Foundry Agent

## Setup

### Prerequisites

- Node.js 18+ and npm
- Azure subscription (for deployment)

### Installation

```bash
cd frontend/react_app
npm install
```

### Configuration

Create a `.env` file:

```env
REACT_APP_FOUNDRY_ENDPOINT=https://your-foundry-endpoint.com
```

### Development

Run locally:

```bash
npm start
```

Runs the app at http://localhost:3000

### Build for Production

```bash
npm run build
```

Creates optimized production build in `build/` directory.

### Deployment to Azure Web App

```powershell
# Build the app
npm run build

# Create deployment package
cd build
Compress-Archive -Path * -DestinationPath ../webapp.zip -Force
cd ..

# Deploy to Azure
az webapp deployment source config-zip `
  --resource-group <resource-group-name> `
  --name <webapp-name> `
  --src webapp.zip
```

## Project Structure

```
src/
  ├── index.js          # Entry point
  ├── index.css         # Global styles
  ├── App.js            # Main application component
  └── App.css           # Application styles
public/
  └── index.html        # HTML template
package.json            # Dependencies and scripts
```

## Features (Placeholder)

- Simple message input form
- Placeholder integration with Foundry Agent
- Clean, responsive UI
- Security-focused information display

## Next Steps

### Implement Foundry Integration

1. Add Azure MSAL library for authentication:
```bash
npm install @azure/msal-browser @azure/msal-react
```

2. Configure MSAL with Entra ID app registration

3. Implement authenticated API calls to Foundry endpoint

4. Handle token acquisition and refresh

### Add Features

- User authentication UI
- Conversation history
- Error handling and retry logic
- Loading states and progress indicators
- Real-time updates (if applicable)

## Security

This application follows security best practices:

- No direct backend API calls
- All authentication handled by Entra ID
- No secrets in client-side code
- HTTPS only (enforced by Azure Web App)
- Private networking (no public access to backend)

## Environment Variables

Set via Azure Web App configuration (Terraform):

- `REACT_APP_FOUNDRY_ENDPOINT` - Azure AI Foundry endpoint URL
- Additional variables as needed

## CI/CD

Integrate with GitHub Actions or Azure DevOps for automated deployment:

1. Build React app
2. Run tests
3. Create deployment package
4. Deploy to Azure Web App
5. Health check verification

## Monitoring

Application logs and client-side errors are sent to Application Insights (configured in Azure Web App).

## License

(Your license here)
