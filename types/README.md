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

The command typechecks with `luau-lsp`, rejects the invalid `ImageButton.TextWrapped` fixture, and runs `tests/*_contracts.luau` with Lune. Roblox API definitions are pinned at [`types/roblox.d.luau`](roblox.d.luau) from [luau-lsp 1.62.0](https://github.com/JohnnyMorganz/luau-lsp/blob/cfa5c378c6370f0eca852910e6fbdf8e4d8921c6/scripts/globalTypes.d.luau).

For editor support, add `_Index/volt/volt.d.luau` and `types/hydroxide.d.luau` as custom definitions in the Luau plugin. Dynamic Volt values whose documented shape is incomplete remain `any` so diagnostics stay useful without inventing runtime contracts.
