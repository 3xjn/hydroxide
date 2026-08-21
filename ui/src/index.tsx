import React from "@rbxts/react";
import ReactRoblox from "@rbxts/react-roblox";
import type { HydroxideHandle, HydroxideModel } from "./contracts";
import { HydroxideIsland } from "./HydroxideIsland";

function assertModel(model: HydroxideModel): void {
	if (model.kind !== "queryBar" && model.kind !== "filterPopover" && model.kind !== "list") {
		error(`Hydroxide Prism island does not support kind '${tostring((model as { kind: unknown }).kind)}'`);
	}
}

export function mountHydroxide(parent: Instance, initialModel: HydroxideModel): HydroxideHandle {
	assertModel(initialModel);
	const root = ReactRoblox.createLegacyRoot(parent);
	let destroyed = false;
	let model = initialModel;
	const render = () => root.render(<HydroxideIsland model={model} />);
	render();
	return {
		update: (nextModel) => {
			if (destroyed) {
				error("Hydroxide Prism island cannot update after destroy");
			}
			assertModel(nextModel);
			model = nextModel;
			render();
		},
		destroy: () => {
			if (destroyed) {
				return;
			}
			destroyed = true;
			root.unmount();
		},
	};
}

export type { HydroxideHandle, HydroxideModel, ListRowModel, QueryBarModel, FilterPopoverModel, ScannerFilterValues } from "./contracts";
