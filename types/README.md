# Volt editor support

Hydroxide's Volt declarations live at [`_Index/volt/volt.d.luau`](../_Index/volt/volt.d.luau). This is a standard Luau definition file; `declare` is valid definition syntax. The Luau LSP loads this file explicitly through Rider's Custom Definitions setting.

In Rider, install the **Luau** plugin, then use **Settings → Languages & Frameworks → Luau → Custom Definitions** to add `_Index/volt/volt.d.luau`. The project setting is already configured for this workspace.

The definitions cover Volt's documented public API. Dynamic values whose exact layout Volt does not document are intentionally typed as `any`; this keeps diagnostics useful without inventing runtime contracts.

To validate the definitions from a terminal, we can use:

```bash
luau-lsp analyze --platform=roblox --definitions @volt=_Index/volt/volt.d.luau path/to/script.luau
```
