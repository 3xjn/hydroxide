# Live Instance MCP Implementation Plan

**Goal:** Let Codex inspect and execute code in the current Volt-attached Roblox client through an authenticated localhost bridge.

## Architecture

- A standalone Volt auto-execute agent connects to a loopback-only WebSocket endpoint.
- A Bun process hosts both that WebSocket endpoint and a stdio MCP server.
- Every WebSocket session authenticates before accepting requests.
- MCP tools expose connection status, script discovery, source decompilation, and explicit Luau evaluation.
- The bridge is independent from the Hydroxide UI and never uses RakNet.

## Tasks

1. Define and validate the request/response protocol at both trust boundaries.
2. Implement a loopback-only WebSocket bridge with authentication, payload limits, request correlation, and timeouts.
3. Implement the stdio MCP tools and accurate read/write annotations.
4. Implement the Volt auto-execute agent using documented WebSocket and decompile APIs.
5. Add behavioral tests for authentication, request routing, errors, timeouts, and MCP-facing results.
6. Document setup for Volt auto-execute and project-scoped Codex MCP configuration.
7. Run type checking, linting, tests, and the existing Hydroxide checks.

## Tool Contract

- `roblox_status`: report whether a live client is authenticated and identify the place/client.
- `roblox_list_scripts`: discover client-visible and running scripts with optional filtering.
- `roblox_read_script`: resolve a script path and return Volt decompiler output.
- `roblox_eval`: execute an explicit Luau chunk and return a JSON-safe representation of its returned values.

`roblox_eval` is intentionally marked as non-read-only. The remaining tools do not mutate the live game.
