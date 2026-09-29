import express from 'express';

const app = express();
const port = Number(process.env.PORT || 3000);

app.use(express.json({ limit: '1mb' }));
app.use(express.static('public'));

app.get('/healthz', (_req, res) => {
  res.json({ status: 'ok' });
});

app.post('/api/ask', async (req, res) => {
  const question = typeof req.body?.question === 'string' ? req.body.question.trim() : '';

  if (!question) {
    return res.status(400).json({ error: 'Question is required.' });
  }

  try {
    const answer = await askMcp(question);
    return res.json({ answer });
  } catch (error) {
    const details = error instanceof Error ? error.message : String(error);
    return res.status(500).json({
      error: 'Could not query Microsoft Learn MCP Server.',
      details
    });
  }
});

async function askMcp(question) {
  const serverUrl = process.env.MCP_SERVER_URL;
  if (!serverUrl) {
    throw new Error('MCP_SERVER_URL is missing.');
  }

  const authToken = process.env.MCP_AUTH_TOKEN;
  const preferredTool = process.env.MCP_TOOL_NAME || '';
  const queryParamName = process.env.MCP_TOOL_QUERY_PARAM || 'query';

  const { Client } = await import('@modelcontextprotocol/sdk/client/index.js');
  const { StreamableHTTPClientTransport } = await import('@modelcontextprotocol/sdk/client/streamableHttp.js');

  const headers = {};
  if (authToken) {
    headers.Authorization = `Bearer ${authToken}`;
  }

  const transport = new StreamableHTTPClientTransport(new URL(serverUrl), {
    requestInit: {
      headers
    }
  });

  const client = new Client(
    {
      name: 'aks-learn-webapp',
      version: '1.0.0'
    },
    {
      capabilities: {}
    }
  );

  await client.connect(transport);

  try {
    const toolsResponse = await client.listTools();
    const tools = toolsResponse?.tools || [];

    if (!tools.length) {
      throw new Error('No tools exposed by MCP server.');
    }

    const tool = pickTool(tools, preferredTool);
    const args = {
      [queryParamName]: question,
      question,
      q: question
    };

    const result = await client.callTool({
      name: tool.name,
      arguments: args
    });

    const text = extractText(result);
    if (!text) {
      throw new Error('Tool response did not contain text content.');
    }

    return text;
  } finally {
    if (typeof client.close === 'function') {
      await client.close();
    }
  }
}

function pickTool(tools, preferredTool) {
  if (preferredTool) {
    const exact = tools.find((t) => t.name === preferredTool);
    if (exact) {
      return exact;
    }
  }

  const rankedCandidates = ['learn', 'docs', 'documentation', 'search', 'azure', 'aks'];
  const byScore = [...tools].sort((a, b) => scoreTool(b.name, rankedCandidates) - scoreTool(a.name, rankedCandidates));
  return byScore[0];
}

function scoreTool(name, keywords) {
  const lower = String(name || '').toLowerCase();
  return keywords.reduce((score, keyword) => (lower.includes(keyword) ? score + 1 : score), 0);
}

function extractText(result) {
  if (!result) {
    return '';
  }

  if (typeof result.content === 'string') {
    return result.content;
  }

  if (Array.isArray(result.content)) {
    const textParts = result.content
      .map((item) => {
        if (typeof item === 'string') {
          return item;
        }
        if (item && typeof item.text === 'string') {
          return item.text;
        }
        return '';
      })
      .filter(Boolean);

    if (textParts.length) {
      return textParts.join('\n\n');
    }
  }

  if (typeof result.structuredContent === 'string') {
    return result.structuredContent;
  }

  if (result.structuredContent && typeof result.structuredContent === 'object') {
    return JSON.stringify(result.structuredContent, null, 2);
  }

  return '';
}

app.listen(port, () => {
  console.log(`aks-learn-webapp listening on port ${port}`);
});
