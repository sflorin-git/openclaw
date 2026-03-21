#!/bin/sh
set -e

# docker-entrypoint.sh — Runs as root, fixes volume permissions, then drops to node.
#
# Coolify (and similar platforms) may mount a persistent volume at
# /home/node/.openclaw that is owned by root. The Dockerfile's build-time
# chown only applies to the image layer, not to runtime volume mounts.
# This entrypoint ensures the directory structure exists and is writable
# by the 'node' user before starting the gateway.

OPENCLAW_HOME="/home/node/.openclaw"
AGENT_DIR="${OPENCLAW_HOME}/agents/main/agent"
GATEWAY_BIND="${OPENCLAW_GATEWAY_BIND:-lan}"
GATEWAY_PORT="${OPENCLAW_GATEWAY_PORT:-18789}"

# 1. Ensure directory structure exists
mkdir -p "${AGENT_DIR}"
chown -R node:node "${OPENCLAW_HOME}"

# 2. Write models.json with OpenRouter provider configuration
if [ -n "${OPENROUTER_API_KEY}" ]; then
  cat > "${AGENT_DIR}/models.json" << MODELS_EOF
{
  "mode": "merge",
  "providers": {
    "openrouter": {
      "baseUrl": "https://openrouter.ai/api/v1",
      "apiKey": "${OPENROUTER_API_KEY}",
      "api": "openai-completions",
      "models": [
        {
          "id": "gpt-5-mini",
          "name": "GPT-5 mini",
          "reasoning": false,
          "input": ["text"],
          "cost": {"input": 0.25, "output": 2.0, "cacheRead": 0.025},
          "contextWindow": 400000,
          "maxTokens": 128000
        },
        {
          "id": "gpt-5.4",
          "name": "GPT-5.4",
          "reasoning": true,
          "input": ["text"],
          "cost": {"input": 2.5, "output": 15.0, "cacheRead": 0.25},
          "contextWindow": 1050000,
          "maxTokens": 128000
        },
        {
          "id": "claude-sonnet-4.6",
          "name": "Claude Sonnet 4.6",
          "reasoning": true,
          "input": ["text"],
          "cost": {"input": 3.0, "output": 15.0, "cacheRead": 0},
          "contextWindow": 1000000,
          "maxTokens": 128000
        },
        {
          "id": "glm-5",
          "name": "GLM-5",
          "reasoning": false,
          "input": ["text"],
          "cost": {"input": 0.8, "output": 2.56, "cacheRead": 0.16},
          "contextWindow": 202752,
          "maxTokens": 128000
        },
        {
          "id": "deepseek-r1-0528",
          "name": "DeepSeek R1 0528",
          "reasoning": true,
          "input": ["text"],
          "cost": {"input": 0.45, "output": 2.15, "cacheRead": 0.225},
          "contextWindow": 163840,
          "maxTokens": 128000
        },
        {
          "id": "devstral-2512",
          "name": "Devstral 2 2512",
          "reasoning": false,
          "input": ["text"],
          "cost": {"input": 0.4, "output": 2.0, "cacheRead": 0},
          "contextWindow": 262144,
          "maxTokens": 128000
        }
      ]
    }
  }
}
MODELS_EOF
  chown node:node "${AGENT_DIR}/models.json"
fi

# 3. Non-loopback Docker deployments need explicit Control UI origins or the
# supported Host-header fallback mode. Cloud deployments typically rely on the
# public host header, so enable the fallback unless the operator already set it.
if [ "${GATEWAY_BIND}" != "loopback" ] && [ -z "${OPENCLAW_CONTROL_UI_FALLBACK}" ]; then
  export OPENCLAW_CONTROL_UI_FALLBACK=true
fi

# 4. Drop privileges and exec the gateway as the 'node' user.
# Docker deployments commonly bootstrap config from env/volumes after first start,
# so allow startup without a pre-existing openclaw.json.
exec gosu node node openclaw.mjs gateway --bind "${GATEWAY_BIND}" --port "${GATEWAY_PORT}" --allow-unconfigured
