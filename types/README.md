# Luau type checking

Hydroxide pins `luau-lsp` and Lune in [`rokit.toml`](../rokit.toml). The repository check analyzes the redesigned context-menu source against matching Roblox API definitions, Hydroxide's dynamic `import` declaration, and the Volt executor declarations in [`_Index/volt/volt.d.luau`](../_Index/volt/volt.d.luau).

For first-time setup, we can use:

```bash
rokit install
```

Before pushing, we can run the same command as CI:

```bash
bash scripts/check.sh
```

The command performs four checks: the real context-menu source must pass strict analysis, an intentionally invalid `ImageButton.TextWrapped` fixture must fail for the expected reason, the Lune UI/runtime contracts must pass, and stale-session shutdown must remain non-fatal. Roblox API definitions are downloaded from the commit matching the pinned `luau-lsp` release and verified by SHA-256 before use.

For editor support, add `_Index/volt/volt.d.luau` and `types/hydroxide.d.luau` as custom definitions in the Luau plugin. Dynamic Volt values whose documented shape is incomplete remain `any` so diagnostics stay useful without inventing runtime contracts.
