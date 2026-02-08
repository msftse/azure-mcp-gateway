import azure.functions as func
import logging
import json

app = func.FunctionApp(http_auth_level=func.AuthLevel.ANONYMOUS)

@app.route(route="health", methods=["GET"])
def health_check(req: func.HttpRequest) -> func.HttpResponse:
    """
    Health check endpoint for monitoring and liveness probes.
    
    Returns:
        JSON response with status "healthy"
    """
    logging.info('Health check endpoint called')
    
    return func.HttpResponse(
        json.dumps({"status": "healthy", "service": "mcp-gateway"}),
        mimetype="application/json",
        status_code=200
    )


@app.route(route="api/{*route}", methods=["GET", "POST", "PUT", "DELETE"])
def mcp_endpoint(req: func.HttpRequest) -> func.HttpResponse:
    """
    Placeholder endpoint for future Slack MCP Server implementation.
    
    This is a PLACEHOLDER function. Replace with actual MCP server logic
    when ready to implement Slack integration.
    
    Args:
        req: HTTP request object
        
    Returns:
        JSON response with placeholder message
    """
    logging.info(f'MCP endpoint called: {req.method} {req.url}')
    
    # Extract auth header for logging (DO NOT log full token in production)
    auth_header = req.headers.get('Authorization')
    has_auth = 'Yes' if auth_header and auth_header.startswith('Bearer ') else 'No'
    
    logging.info(f'Authentication present: {has_auth}')
    
    # Placeholder response
    response_data = {
        "status": "placeholder",
        "message": "MCP Server endpoint - awaiting implementation",
        "method": req.method,
        "path": req.route_params.get('route', ''),
        "note": "This is a placeholder. Implement Slack MCP logic here."
    }
    
    return func.HttpResponse(
        json.dumps(response_data),
        mimetype="application/json",
        status_code=200
    )
