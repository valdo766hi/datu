{ lib }:

# MCP server configurations for pi-mcp-adapter.
# https://github.com/nicobailon/pi-mcp-adapter
#
# Special attribute for conditional API keys:
#   apiKeyHeader = { name = "Header-Name"; env = "ENV_VAR_NAME"; };
#   The header is only sent when the env var is set at runtime.

{
  exa = {
    url = "https://mcp.exa.ai/mcp";
    apiKeyHeader = {
      name = "Authorization";
      env = "EXA_API_KEY";
      bearer = true;
    };
  };

  context7 = {
    url = "https://mcp.context7.com/mcp";
    apiKeyHeader = {
      name = "CONTEXT7_API_KEY";
      env = "CONTEXT7_API_KEY";
    };
  };
}
