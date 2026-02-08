import React, { useState } from 'react';
import './App.css';

function App() {
  const [message, setMessage] = useState('');
  const [response, setResponse] = useState(null);
  const [loading, setLoading] = useState(false);

  const foundryEndpoint = process.env.REACT_APP_FOUNDRY_ENDPOINT || '';

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    setResponse(null);

    try {
      // TODO: Implement actual API call to Foundry Agent
      // This is a placeholder for the integration
      
      // Simulated response
      setTimeout(() => {
        setResponse({
          status: 'success',
          message: 'This is a placeholder response. Integrate with Azure AI Foundry Agent.',
          note: 'Configure REACT_APP_FOUNDRY_ENDPOINT in environment variables'
        });
        setLoading(false);
      }, 1000);

    } catch (error) {
      setResponse({
        status: 'error',
        message: error.message
      });
      setLoading(false);
    }
  };

  return (
    <div className="App">
      <header className="App-header">
        <h1>Azure MCP Gateway</h1>
        <p className="subtitle">Secure, Private MCP Server Interface</p>
      </header>

      <main className="App-main">
        <div className="card">
          <h2>Send Message to AI Agent</h2>
          
          {!foundryEndpoint && (
            <div className="warning">
              ⚠️ Foundry endpoint not configured. Set REACT_APP_FOUNDRY_ENDPOINT environment variable.
            </div>
          )}

          <form onSubmit={handleSubmit}>
            <div className="form-group">
              <label htmlFor="message">Your Message:</label>
              <textarea
                id="message"
                value={message}
                onChange={(e) => setMessage(e.target.value)}
                placeholder="Enter your message here..."
                rows="4"
                required
              />
            </div>
            
            <button type="submit" disabled={loading || !message}>
              {loading ? 'Sending...' : 'Send to Agent'}
            </button>
          </form>

          {response && (
            <div className={`response ${response.status}`}>
              <h3>Response:</h3>
              <pre>{JSON.stringify(response, null, 2)}</pre>
            </div>
          )}
        </div>

        <div className="info-card">
          <h3>About This Application</h3>
          <p>
            This is a React-based frontend for the Azure MCP Gateway. It demonstrates
            a secure, private architecture where:
          </p>
          <ul>
            <li>All communication flows through Azure AI Foundry Agent</li>
            <li>No direct calls to backend APIs</li>
            <li>Enterprise-grade security with Entra ID authentication</li>
            <li>Fully private networking (no public endpoints)</li>
          </ul>
          <p className="note">
            <strong>Note:</strong> This is a scaffold implementation. Integrate with your 
            Azure AI Foundry Agent endpoint to enable full functionality.
          </p>
        </div>
      </main>

      <footer className="App-footer">
        <p>Azure MCP Gateway - Enterprise Security Architecture</p>
      </footer>
    </div>
  );
}

export default App;
