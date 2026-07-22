# Hydroxide visual system

## Direction

Hydroxide should feel like a precise debugging instrument inside Roblox: dark, compact, low-chroma, and readable. It is for developers tracing how remotes, closures, scripts, modules, upvalues, and constants connect, so the interface should favor fast scanning and stable spatial memory over decorative chrome. The functional tool pages stay intact; empty legacy surfaces do not. The shell is resizable and capable of a full-screen state.

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
- Workspace anatomy: rail tools and the primary page begin on the same 12-pixel top line beneath the title bar. The primary page owns the full remaining workspace. The inert legacy Explorer pane and its nonfunctional filter are not part of the shell.
- Page anatomy: tool controls and results sit inside a 12-pixel page inset. Query bars are 36 pixels high. The page does not receive its own rounded card, outline, or elevation; layout grouping comes from spacing, restrained input surfaces, and one-pixel dividers.
- Home composition: the welcome label, generated mark, and tagline share one centered vertical axis at approximately 24, 48, and 70 percent of the page height.
- The title bar, tool rail, and status bar remain fixed. Page-owned lists keep their own scrolling.
- The bottom-right resize handle is a transparent 28-pixel target with a small muted grip contained inside the shell corner; it never creates a colored block over the status bar. Title-bar controls are collapse, maximize/restore, and exit. They share identical target geometry, corner treatment, typography, and hover behavior; exit alone uses the danger color. Collapse creates the compact reopen target, maximize toggles a viewport-filling state, and exit fully shuts Hydroxide down.
- If the Roblox viewport changes while maximized, restored bounds are reclamped so the complete window remains inside the current 16-pixel margin.
- Every shell region uses scale-plus-offset geometry or is recomputed from the current window bounds. Resizing the outer window must never leave legacy 650-by-350 geometry inside it.

## Window lifecycle

- The collapse control condenses Hydroxide into a 36-by-36 top-center reopen target containing an optically centered 18-by-18 generated Hydroxide mark.
- Closing atomically hides the full window before the compact control enters; no title, page, status, border, or resize-handle pixels may remain onscreen during or after the transition.
- Reopening atomically hides the compact control and restores the previous normal or maximized bounds.
- The reopen control has a dark elevated surface, mineral-mint border, visible focus treatment, and a 36-pixel minimum interactive target.
- The exit control is the only destructive title-bar action. It disconnects every Hydroxide-owned global listener, restores every installed hook and injected environment method, destroys the entire interface including the compact launcher, and clears the active `oh` session. A later execution must start from a clean environment.

## Asset contract

`assets/ui/hydroxide-icons.png` is a 256 by 128 transparent atlas with 64-pixel cells. `assets/ui/hydroxide-icons-source.png` preserves the generated source sheet. Cell names and offsets live in `ui/assets.lua`.

`assets/ui/hydroxide-logo.png` is the two-tone Home Page mark. `assets/ui/hydroxide-logo-source.png` preserves the generated source artwork.

`assets/ui/hydroxide-remote-icons.png` is a 256 by 128 transparent atlas for the four Remote Spy type filters and query actions. `assets/ui/hydroxide-remote-icons-source.png` preserves the generated raster source. Remote type filters are icon-only 40-pixel controls with distinct enabled and hover states; executor class names do not appear as permanent filter labels.

The runtime asset path is `hydroxide/assets/<branch>/ui-v1/<filename>`. Stable `master` builds reuse their validated local files. Development builds refresh code and artwork from `dev` on every launch, so testers do not see stale assets. Files are written as binary strings and loaded through Volt's required `getcustomasset` API. Missing filesystem or custom-asset support is a startup error. There is no legacy image fallback.

All interface instances, row templates, prompts, overlays, menus, and window controls are created by local Luau modules. Hydroxide must not import external Roblox UI models or template packs. Raster artwork may only come from the generated files under `assets/ui/` through `getcustomasset`.

## Interaction states

- Default: cool-gray icon and text.
- Hover: quiet `Hover` surface with secondary text; hover must not imitate selection.
- Selected tab: rail-colored surface, mint icon, and a two-pixel mint marker on the leading edge. Selected tabs do not add a border, shadow, or raised card.
- Focus: visible mint outline.
- Disabled: muted text at 55 percent opacity.
- Destructive: reserve `Danger` for destructive actions only.
- Transitions: 120 to 180 milliseconds, limited to color, opacity, and position.

## Accessibility and resilience

- Compact controls keep a 36-pixel pointer target even when their visible glyph is 14 to 22 pixels.
- Primary and secondary text must remain legible over their declared surfaces; muted text is reserved for metadata and inactive chrome.
- Long tool names and object values truncate inside their owned region instead of expanding the shell.
- The title bar, tool rail, and status bar stay fixed. Only page-owned result lists may scroll.
- The minimum-size shell must retain a usable main pane without horizontal overflow.

## Verification

The local Volt and Roblox clients are available for executor-owned rendering. Source contracts and Lune checks cover hierarchy and geometry; every visual shell change must also be exercised from the `dev` build and verified with fresh open, collapsed, and fully exited captures before sign-off.

## Implementation boundary

The complete interface is source-built. `ui/runtime.lua` owns the live instance tree and reusable templates; feature modules consume that local contract. The title bar, tool rail, workspace, Home composition, status bar, resize handle, reopen state, prompts, menus, list rows, and scanner pages must not depend on `rbxassetid://11389137937`, `rbxassetid://5042114982`, or any other imported UI model.

Reusable primitives are: `Surface`, `ActionButton`, `QueryBar`, `ScrollList`, `ObjectLabel`, `Dropdown`, `CheckBox`, `Prompt`, `MessageBox`, `ContextMenu`, `Tab`, and `RowTemplate`. Each primitive has default, hover, selected, focused, and disabled styling where applicable and uses the token palette above.
