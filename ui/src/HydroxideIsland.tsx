import React from "@rbxts/react";
import { Image, ThemeProvider, Window } from "@3xjn/prism";
import type { HydroxideModel, WindowModel } from "./contracts";
import { FilterPopoverIsland } from "./FilterPopover";
import { QueryBar } from "./QueryBar";
import { ResultList } from "./ResultList";
import {
	HYDROXIDE_THEME,
	WINDOW_BACKGROUND,
	WINDOW_HEIGHT,
	WINDOW_MIN_HEIGHT,
	WINDOW_MIN_WIDTH,
	WINDOW_WIDTH,
} from "./theme";

function HostFrame({ onMount }: { readonly onMount?: (instance: Frame) => void }): React.ReactElement {
	return (
		<frame
			BackgroundTransparency={1}
			BorderSizePixel={0}
			Size={UDim2.fromScale(1, 1)}
			ref={(instance) => {
				if (instance !== undefined) {
					onMount?.(instance);
				}
			}}
		/>
	);
}

function HydroxidePrismWindow({ model }: { readonly model: WindowModel }): React.ReactElement {
	return (
		<Window
			title={model.title ?? "Hydroxide"}
			width={model.width ?? WINDOW_WIDTH}
			height={model.height ?? WINDOW_HEIGHT}
			minWidth={model.minWidth ?? WINDOW_MIN_WIDTH}
			minHeight={model.minHeight ?? WINDOW_MIN_HEIGHT}
			bg={WINDOW_BACKGROUND}
			onClose={model.onClose}
			leading={model.logo !== undefined ? <Image src={model.logo} width={24} height={24} /> : undefined}
			rail={<HostFrame onMount={model.onRail} />}
			ref={(instance) => {
				if (instance !== undefined) {
					instance.Name = "Base";
					model.onRoot?.(instance);
				}
			}}
		>
			<HostFrame onMount={model.onContent} />
		</Window>
	);
}

export function HydroxideIsland({ model }: { readonly model: HydroxideModel }): React.ReactElement {
	return (
		<ThemeProvider theme={HYDROXIDE_THEME} density="compact">
			{model.kind === "window" && <HydroxidePrismWindow model={model} />}
			{model.kind === "queryBar" && <QueryBar {...model} />}
			{model.kind === "filterPopover" && <FilterPopoverIsland {...model} />}
			{model.kind === "list" && <ResultList {...model} />}
		</ThemeProvider>
	);
}
