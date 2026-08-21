import React from "@rbxts/react";
import { Box, Pressable, ScrollArea, Stack, Text, theme } from "@3xjn/prism";
import type { ListModel, ListRowModel } from "./contracts";
import { ROW_HEIGHT } from "./theme";

function Row(props: {
	readonly row: ListRowModel;
	readonly onPress?: (id: string) => void;
	readonly onRightPress?: (id: string) => void;
}): React.ReactElement {
	const indent = props.row.indent ?? 0;
	return (
		<Pressable
			width="100%"
			height={ROW_HEIGHT}
			p="sm"
			bg={props.row.selected === true ? theme.primary.light : theme.background.surface}
			onPress={() => props.onPress?.(props.row.id)}
			Event={{
				MouseButton2Click: () => props.onRightPress?.(props.row.id),
			}}
			layoutOrder={indent}
		>
			<Stack direction="horizontal" gap="sm" width="100%" height="100%" align="center">
				{indent > 0 && <Box width={indent * 12} height={1} bgTransparency={1} />}
				<Text text={props.row.title} size="sm" truncate="atend" width="100%" />
				{props.row.subtitle !== undefined && props.row.subtitle !== "" && (
					<Text text={props.row.subtitle} size="xs" color={theme.text.secondary} truncate="atend" />
				)}
				{props.row.meta !== undefined && props.row.meta !== "" && (
					<Text text={props.row.meta} size="xs" color={theme.text.disabled} />
				)}
			</Stack>
		</Pressable>
	);
}

export function ResultList(model: ListModel): React.ReactElement {
	const rows = model.rows.filter((row) => row.visible !== false);
	return (
		<ScrollArea width="100%" height="100%" direction="vertical" automaticCanvasSize={Enum.AutomaticSize.Y} canvasSize={new UDim2(0, 0, 0, 0)}>
			<Stack direction="vertical" gap="xs" width="100%" p="xs">
				{rows.size() === 0 && model.emptyText !== undefined && (
					<Text text={model.emptyText} size="sm" color={theme.text.disabled} />
				)}
				{rows.map((row) => (
					<Row key={row.id} row={row} onPress={model.onPress} onRightPress={model.onRightPress} />
				))}
			</Stack>
		</ScrollArea>
	);
}
