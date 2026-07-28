local fs = require("@lune/fs")

local source = fs.readFile("tools/live-mcp/volt-agent.lua")
local chunk, compileError = loadstring(source, "tools/live-mcp/volt-agent.lua")

assert(chunk, compileError)
print("live-mcp-agent-syntax-contracts-ok")
