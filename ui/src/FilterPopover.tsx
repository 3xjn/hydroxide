import React from "@rbxts/react";
import { Button } from "@prism/components/Button";
import { Popover } from "@prism/components/Popover";
import { Stack } from "@prism/components/Stack";
import type { FilterPopoverModel, ScannerFilterValues } from "./contracts";
import { defaultFilterValues } from "./contracts";
import { CONTROL_HEIGHT } from "./theme";

const OPTIONS: readonly { readonly key: keyof ScannerFilterValues; readonly label: string }[] = [
	{ key: "ShowGame", label: "Show game code" },
	{ key: "ShowRoblox", label: "Show Roblox code" },
	{ key: "ShowExecutor", label: "Show executor code" },
];

export function FilterPopover(props: {
	readonly values?: Partial<ScannerFilterValues>;
	readonly onChange?: (values: ScannerFilterValues) => void;
}): React.ReactElement {
	const values = defaultFilterValues(props.values);
	const filtered = values.ShowGame !== true || values.ShowRoblox === true || values.ShowExecutor === true;
	return (
		<Popover
			triggerMode="click"
			closeOnOutsidePress
			placement="bottom"
			align="end"
			width={CONTROL_HEIGHT}
			height={CONTROL_HEIGHT}
			content={
				<Stack direction="vertical" gap="xs" p="sm" width={220}>
					{OPTIONS.map((option) => {
						const enabled = values[option.key] === true;
						return (
							<Button
								key={option.key}
								label={`${enabled ? "✓  " : "    "}${option.label}`}
								variant={enabled ? "light" : "subtle"}
								color={enabled ? "primary" : "secondary"}
								fullWidth
								height={CONTROL_HEIGHT}
								onPress={() => {
									props.onChange?.({
										...values,
										[option.key]: !enabled,
									});
								}}
							/>
						);
					})}
				</Stack>
			}
		>
			<Button
				label="Filter"
				variant={filtered ? "light" : "outline"}
				color={filtered ? "primary" : "secondary"}
				width={CONTROL_HEIGHT}
				height={CONTROL_HEIGHT}
			/>
		</Popover>
	);
}

export function FilterPopoverIsland(model: FilterPopoverModel): React.ReactElement {
	return <FilterPopover values={model.values} onChange={model.onChange} />;
}
