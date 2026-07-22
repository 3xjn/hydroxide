# Hydroxide visual system

## Direction

Hydroxide should feel like a precise debugging instrument inside Roblox: dark, compact, low-chroma, and readable. The existing page structure and tools stay intact. The shell becomes larger, resizable, and capable of a full-screen state.

The signature visual is the open Hydroxide ring paired with one mineral-mint accent. Avoid neon, gradients, glass effects, large radii, and decorative dashboard cards.

## Tokens

| Role | Value |
| --- | --- |
| Canvas | `#0B0E12` |
| Rail | `#0E1217` |
| Panel | `#11171D` |
| Elevated panel | `#151C23` |
| Hover | `#192129` |
| Border | `#29323A` |
| Text | `#F3F6F7` |
| Secondary text | `#A7B0B8` |
| Muted text | `#6F7982` |
| Accent | `#62D6AD` |
| Accent surface | `#17352D` |
| Danger | `#E66B6E` |
| Warning | `#EAB33D` |

Use Gotham for interface text and Code for technical values. The spacing scale is 4, 8, 12, 16, and 24 pixels. Corners use 4 to 7 pixels. Interactive targets are at least 36 by 36 pixels.

## Window layout

- Visual reference: `design/hydroxide-home-redesign-v1.png`. It is the shell contract for the fully source-built interface.
- Default size: 1120 by 680 pixels, clamped to the current viewport with a 16-pixel outer margin.
- Minimum size: 720 by 420 pixels, reduced only when the viewport itself is smaller.
- Title bar: 48 pixels.
- Tool rail: 56 pixels.
- Status bar: 28 pixels.
- Title bar anatomy: generated 32-pixel mark and `Hydroxide` wordmark at the left, centered version title, then 36-pixel window controls at the right.
- Tool rail anatomy: 44-pixel tab targets with 28-pixel generated icons and 8-pixel vertical rhythm. On constrained-height viewports, targets may compact to 40 pixels but never below 36 pixels.
- Workspace anatomy: tool page and Explorer form a list-detail pair with a 12-pixel gutter. Explorer is 26 percent of the workspace, clamped from 200 to 288 pixels.
- Home composition: the welcome label, generated mark, and tagline share one centered vertical axis at approximately 24, 48, and 70 percent of the page height.
- The title bar, tool rail, and status bar remain fixed. Page-owned lists keep their own scrolling.
- The bottom-right handle resizes the window. The maximize control toggles a viewport-filling state and restores the prior bounds.
- Every shell region uses scale-plus-offset geometry or is recomputed from the current window bounds. Resizing the outer window must never leave legacy 650-by-350 geometry inside it.

## Window lifecycle

- The close control condenses Hydroxide into a 52-by-52 top-center reopen button using the generated Hydroxide mark.
- Closing explicitly hides the full window after the 150-millisecond transition; no title, page, status, border, or resize-handle pixels may remain onscreen.
- Reopening explicitly hides the compact button and restores the previous normal or maximized bounds.
- The reopen control has a dark elevated surface, mineral-mint border, visible focus treatment, and a 36-pixel minimum interactive target.

## Asset contract

`assets/ui/hydroxide-icons.png` is a 256 by 128 transparent atlas with 64-pixel cells. `assets/ui/hydroxide-icons-source.png` preserves the generated source sheet. Cell names and offsets live in `ui/assets.lua`.

`assets/ui/hydroxide-logo.png` is the two-tone Home Page mark. `assets/ui/hydroxide-logo-source.png` preserves the generated source artwork.

The runtime asset path is `hydroxide/assets/<branch>/ui-v1/<filename>`. Stable `master` builds reuse their validated local files. Development builds refresh code and artwork from `dev` on every launch, so testers do not see stale assets. Files are written as binary strings and loaded through Volt's required `getcustomasset` API. Missing filesystem or custom-asset support is a startup error. There is no legacy image fallback.

All interface instances, row templates, prompts, overlays, menus, and window controls are created by local Luau modules. Hydroxide must not import external Roblox UI models or template packs. Raster artwork may only come from the generated files under `assets/ui/` through `getcustomasset`.

## Interaction states

- Default: cool-gray icon and text.
- Hover: `Hover` surface with primary text.
- Selected: mint icon on `Accent surface`.
- Focus: visible mint outline.
- Disabled: muted text at 55 percent opacity.
- Destructive: reserve `Danger` for destructive actions only.
- Transitions: 120 to 180 milliseconds, limited to color, opacity, and position.

## Implementation boundary

The complete interface is source-built. `ui/runtime.lua` owns the live instance tree and reusable templates; feature modules consume that local contract. The title bar, tool rail, workspace panes, Home composition, status bar, resize handle, reopen state, prompts, menus, list rows, and scanner pages must not depend on `rbxassetid://11389137937`, `rbxassetid://5042114982`, or any other imported UI model.

Reusable primitives are: `Surface`, `ActionButton`, `QueryBar`, `ScrollList`, `ObjectLabel`, `Dropdown`, `CheckBox`, `Prompt`, `MessageBox`, `ContextMenu`, `Tab`, and `RowTemplate`. Each primitive has default, hover, selected, focused, and disabled styling where applicable and uses the token palette above.
