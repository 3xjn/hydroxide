import React from "@rbxts/react";
import { Button } from "@prism/components/Button";
import { Input } from "@prism/components/Input";
import { Stack } from "@prism/components/Stack";
import type { QueryBarModel } from "./contracts";
import { FilterPopover } from "./FilterPopover";
import { CONTROL_HEIGHT } from "./theme";

function actionLabel(model: QueryBarModel): string {
	if (model.actionLabel !== undefined) {
		return model.actionLabel;
	}
	if (model.action === "inspect") {
		return "Inspect";
	}
	if (model.action === "search") {
		return "Search";
	}
	return "Refresh";
}

export function QueryBar(model: QueryBarModel): React.ReactElement {
	const value = model.value ?? "";
	const submit = () => model.onSubmit?.(value);
	return (
		<Stack direction="horizontal" gap="sm" width="100%" height={CONTROL_HEIGHT} align="center">
			<Input
				value={value}
				placeholder={model.placeholder}
				fullWidth
				height={CONTROL_HEIGHT}
				onChange={(nextValue) => model.onChange?.(nextValue)}
				Event={{
					FocusLost: ((...args: unknown[]) => {
						const enterPressed = typeIs(args[0], "boolean") ? args[0] : args[1];
						if (enterPressed === true) {
							submit();
						}
					}) as never,
				}}
			/>
			{model.action !== undefined && (
				<Button
					label={actionLabel(model)}
					variant={model.action === "inspect" ? "light" : "outline"}
					color={model.action === "inspect" ? "primary" : "secondary"}
					height={CONTROL_HEIGHT}
					onPress={() => {
						model.onAction?.(value);
						if (model.action === "inspect" || model.action === "search") {
							submit();
						}
					}}
				/>
			)}
			{model.filter !== undefined && <FilterPopover values={model.filter} onChange={model.onFilterChange} />}
		</Stack>
	);
}
