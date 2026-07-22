# Hydroxide visual system

## Direction

Hydroxide should feel like a precise debugging instrument inside Roblox: dark, compact, low-chroma, and readable. It is for developers tracing how remotes, closures, scripts, modules, upvalues, and constants connect, so the interface should favor fast scanning and stable spatial memory over decorative chrome. The existing page structure and tools stay intact. The shell is resizable and capable of a full-screen state.

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

Use Gotham for interface text and Code for technical values. The spacing scale is 4, 8, 12, 16, 20, and 24 pixels. Corners use 4 to 8 pixels. Interactive targets are at least 36 by 36 pixels; artwork inside compact targets is intentionally smaller and optically centered.

## Window layout

- Visual reference: `design/hydroxide-home-redesign-v1.png`. It is the shell contract for the fully source-built interface.
- Default size: 1120 by 680 pixels, clamped to the current viewport with a 16-pixel outer margin.
- Minimum size: 720 by 420 pixels, reduced only when the viewport itself is smaller.
- Title bar: 44 pixels.
- Tool rail: 52 pixels.
- Status bar: 24 pixels.
- Title bar anatomy: generated 24-pixel mark, `Hydroxide` wordmark, and subdued `c.1` version label at the left, then 36-pixel window controls at the right. Do not repeat the product title in the center.
- Tool rail anatomy: 40-pixel tab targets with 22-pixel generated icons and 6-pixel vertical rhythm. Targets never compact below 36 pixels.
- Workspace anatomy: the list-detail workspace sits 12 pixels away from the shell chrome on every side. Tool page and Explorer use a 12-pixel gutter. Explorer is 25 percent of the workspace, clamped from 224 to 272 pixels.
- Page anatomy: tool controls and results sit inside a 12-pixel page inset. Query bars are 36 pixels high. Layout grouping comes from spacing, tonal surfaces, and one-pixel dividers rather than nested cards.
- Home composition: the welcome label, generated mark, and tagline share one centered vertical axis at approximately 24, 48, and 70 percent of the page height.
- The title bar, tool rail, and status bar remain fixed. Page-owned lists keep their own scrolling.
- The bottom-right handle resizes the window. The maximize control toggles a viewport-filling state and restores the prior bounds.
- Every shell region uses scale-plus-offset geometry or is recomputed from the current window bounds. Resizing the outer window must never leave legacy 650-by-350 geometry inside it.

## Window lifecycle

- The close control condenses Hydroxide into a 36-by-36 top-center reopen target containing an optically centered 18-by-18 generated Hydroxide mark.
- Closing atomically hides the full window before the compact control enters; no title, page, status, border, or resize-handle pixels may remain onscreen during or after the transition.
- Reopening atomically hides the compact control and restores the previous normal or maximized bounds.
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

## Accessibility and resilience

- Compact controls keep a 36-pixel pointer target even when their visible glyph is 14 to 22 pixels.
- Primary and secondary text must remain legible over their declared surfaces; muted text is reserved for metadata and inactive chrome.
- Long tool names and object values truncate inside their owned region instead of expanding the shell.
- The title bar, tool rail, status bar, and Explorer stay fixed. Only page-owned result lists and Explorer content may scroll.
- The minimum-size shell must retain a usable main pane and Explorer without horizontal overflow.

## Accepted verification debt

The local workspace cannot render the executor-owned Roblox surface. Source contracts and Lune checks cover hierarchy and geometry, but collapse animation, client chrome ownership, and final optical spacing require a fresh screenshot from the `dev` build before visual sign-off.

## Implementation boundary

The complete interface is source-built. `ui/runtime.lua` owns the live instance tree and reusable templates; feature modules consume that local contract. The title bar, tool rail, workspace panes, Home composition, status bar, resize handle, reopen state, prompts, menus, list rows, and scanner pages must not depend on `rbxassetid://11389137937`, `rbxassetid://5042114982`, or any other imported UI model.

Reusable primitives are: `Surface`, `ActionButton`, `QueryBar`, `ScrollList`, `ObjectLabel`, `Dropdown`, `CheckBox`, `Prompt`, `MessageBox`, `ContextMenu`, `Tab`, and `RowTemplate`. Each primitive has default, hover, selected, focused, and disabled styling where applicable and uses the token palette above.
