import React from "@rbxts/react";
import { DEFAULT_DARK_THEME, ThemeProvider } from "@3xjn/prism";
import type { HydroxideModel } from "./contracts";
import { FilterPopoverIsland } from "./FilterPopover";
import { QueryBar } from "./QueryBar";
import { ResultList } from "./ResultList";

// TODO(prism-window): When Window exists on Prism master (PR 29),
// mount that primitive from @3xjn/prism as the Hydroxide shell (title,
// content slot, optional rail, drag, resize, collapse, maximize, close
// only if onClose is passed) and delete ui/window.lua. Do not compose
// Draggable+Box chrome and do not invent a Hydroxide AppShell.

export function HydroxideIsland({ model }: { readonly model: HydroxideModel }): React.ReactElement {
	return (
		<ThemeProvider theme={DEFAULT_DARK_THEME} density="compact">
			{model.kind === "queryBar" && <QueryBar {...model} />}
			{model.kind === "filterPopover" && <FilterPopoverIsland {...model} />}
			{model.kind === "list" && <ResultList {...model} />}
		</ThemeProvider>
	);
}
