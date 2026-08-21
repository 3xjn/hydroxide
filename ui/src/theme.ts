import { DEFAULT_DARK_THEME } from "@prism/theme";
import type { ThemeOverride } from "@prism/theme";

const canvas = Color3.fromRGB(11, 14, 18);
const panel = Color3.fromRGB(17, 23, 29);
const elevated = Color3.fromRGB(21, 28, 35);
const hover = Color3.fromRGB(25, 33, 41);
const border = Color3.fromRGB(41, 50, 58);
const text = Color3.fromRGB(243, 246, 247);
const secondary = Color3.fromRGB(167, 176, 184);
const muted = Color3.fromRGB(111, 121, 130);
const accent = Color3.fromRGB(98, 214, 173);
const accentSurface = Color3.fromRGB(23, 53, 45);
const danger = Color3.fromRGB(230, 107, 110);
const warning = Color3.fromRGB(234, 179, 61);

const dark = DEFAULT_DARK_THEME;

export const HYDROXIDE_THEME: ThemeOverride = {
	colors: {
		palette: dark.colors.palette,
		primary: {
			main: accent,
			light: accentSurface,
			dark: accent,
			contrast: canvas,
		},
		secondary: dark.colors.secondary,
		error: {
			main: danger,
			light: dark.colors.error.light,
			dark: danger,
			contrast: canvas,
		},
		warning: {
			main: warning,
			light: dark.colors.warning.light,
			dark: warning,
			contrast: canvas,
		},
		info: dark.colors.info,
		success: {
			main: accent,
			light: accentSurface,
			dark: accent,
			contrast: canvas,
		},
		text: {
			primary: text,
			secondary,
			disabled: muted,
			inverse: canvas,
		},
		background: {
			default: canvas,
			surface: elevated,
			raised: panel,
		},
		border: {
			subtle: border,
			default: border,
			strong: muted,
		},
		action: {
			hover,
			pressed: hover,
			disabled: muted,
			disabledBackground: elevated,
		},
	},
	motion: {
		duration: {
			instant: 0,
			fast: 0.12,
			normal: 0.16,
			slow: 0.18,
		},
	},
};

export const CONTROL_HEIGHT = 36;
export const ROW_HEIGHT = 36;
