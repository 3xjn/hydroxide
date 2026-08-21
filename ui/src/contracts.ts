export interface ScannerFilterValues {
	ShowGame: boolean;
	ShowRoblox: boolean;
	ShowExecutor: boolean;
}

export interface QueryBarModel {
	readonly kind: "queryBar";
	readonly placeholder?: string;
	readonly value?: string;
	readonly action?: "inspect" | "refresh" | "search";
	readonly actionLabel?: string;
	readonly filter?: ScannerFilterValues;
	readonly onChange?: (value: string) => void;
	readonly onSubmit?: (value: string) => void;
	readonly onAction?: (value: string) => void;
	readonly onFilterChange?: (values: ScannerFilterValues) => void;
}

export interface FilterPopoverModel {
	readonly kind: "filterPopover";
	readonly values: ScannerFilterValues;
	readonly onChange?: (values: ScannerFilterValues) => void;
}

export interface ListRowModel {
	readonly id: string;
	readonly title: string;
	readonly subtitle?: string;
	readonly meta?: string;
	readonly selected?: boolean;
	readonly indent?: number;
	readonly visible?: boolean;
}

export interface ListModel {
	readonly kind: "list";
	readonly rows: readonly ListRowModel[];
	readonly emptyText?: string;
	readonly onPress?: (id: string) => void;
	readonly onRightPress?: (id: string) => void;
}

export type HydroxideModel = QueryBarModel | FilterPopoverModel | ListModel;

export interface HydroxideHandle {
	readonly update: (model: HydroxideModel) => void;
	readonly destroy: () => void;
}

export function defaultFilterValues(values?: Partial<ScannerFilterValues>): ScannerFilterValues {
	return {
		ShowGame: values?.ShowGame !== false,
		ShowRoblox: values?.ShowRoblox === true,
		ShowExecutor: values?.ShowExecutor === true,
	};
}
