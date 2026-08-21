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
- Title bar anatomy: generated 24-pixel mark, `Hydroxide` wordmark, and subdued `c.1` version label at the left, then 36-pixel window controls at the right. Do not repeat the product title in the center.
- Tool rail anatomy: 40-pixel tab targets with 22-pixel generated icons and 6-pixel vertical rhythm. Targets never compact below 36 pixels.
- Workspace anatomy: rail tools and the primary page begin on the same 12-pixel top line beneath the title bar. The primary page owns the full remaining workspace. The inert legacy Explorer pane and its nonfunctional filter are not part of the shell.
- Page anatomy: tool controls and results sit inside a 12-pixel page inset. Query bars are 36 pixels high. The page does not receive its own rounded card, outline, or elevation; layout grouping comes from spacing, restrained input surfaces, and one-pixel dividers.
- Signal Spy anatomy: an exact-instance QueryBar precedes the selected-target summary and event filter. It accepts canonical Roblox paths such as `workspace.Door` and `game:GetService("Players").LocalPlayer`, resolves only instance traversal syntax, and submits from either Enter or its 36-pixel `Inspect` action. Invalid paths keep the current target intact and explain the failing segment.
- Home composition: the welcome label, generated mark, and tagline form one centered vertical stack with a 12-pixel rhythm. Resizing preserves their order and spacing instead of positioning each element at an independent percentage of the page.
- The title bar and tool rail remain fixed. Page-owned lists keep their own scrolling. The workspace continues to the shell's bottom edge without a separate status strip.
- The bottom-right resize handle is a transparent 28-pixel target with a small generated grip contained inside the shell corner. Hovering it replaces the default pointer with a compact double-headed NW–SE arrow; the cursor is directional artwork, not an enlarged copy of the grip. Because Roblox overrides `UserInputService.MouseIcon` above interactive GUI, Hydroxide renders this arrow in a pointer-following top-level image while temporarily hiding the system cursor. The arrow remains visible for the complete hover and drag lifecycle, including clamped resizing, then restores the cursor visibility state Hydroxide inherited. Title-bar controls are collapse, maximize/restore, and exit. They share identical target geometry, corner treatment, raster-icon family, and hover behavior; exit alone uses the danger color. Collapse creates the compact reopen target, maximize toggles a viewport-filling state, and exit fully shuts Hydroxide down.
- Normal windows retain the 16-pixel viewport margin, eight-pixel corner radius, and outer stroke. Maximized windows sit flush at viewport origin, fill the complete viewport, and temporarily remove the outer radius and stroke so game pixels cannot leak around or beneath the shell.
- If the Roblox viewport changes while maximized, restored bounds are reclamped so the complete window remains inside the current 16-pixel margin.
- Every shell region uses scale-plus-offset geometry or is recomputed from the current window bounds. Resizing the outer window must never leave legacy 650-by-350 geometry inside it.

## Window lifecycle

- The collapse control condenses Hydroxide into a 36-by-36 reopen chip containing an optically centered 18-by-18 generated Hydroxide mark. The chip stays at the last window x,y; it is not a top-center dock.
- Collapse tweens the same window frame `Position` and `Size` into that chip rect over `Theme.Motion` (120 to 180 milliseconds). After the tween finishes, the window hides and only the chip remains; no title, page, border, or resize-handle pixels may remain onscreen.
- Reopening hides the chip and reverse-tweens the same window frame from the chip rect back to the previous normal or maximized bounds.
- The reopen control has a dark elevated surface, mineral-mint border, visible focus treatment, and a 36-pixel minimum interactive target.
- The exit control is the only destructive title-bar action. It disconnects every Hydroxide-owned global listener, restores every installed hook and injected environment method, destroys the entire interface including the compact launcher, and clears the active `oh` session. A later execution must start from a clean environment.

## Asset contract

`assets/ui/hydroxide-icons.png` is a 256 by 128 transparent atlas with 64-pixel cells. `assets/ui/hydroxide-icons-source.png` preserves the generated source sheet. Cell names and offsets live in `ui/assets.lua`.

`assets/ui/hydroxide-logo.png` is the two-tone Home Page mark. `assets/ui/hydroxide-logo-source.png` preserves the generated source artwork.

`assets/ui/hydroxide-remote-icons.png` is a 256 by 128 transparent atlas for the four Remote Spy type filters and query actions. `assets/ui/hydroxide-remote-icons-source.png` preserves the generated raster source. Remote type filters are icon-only 40-pixel controls with white class artwork, a quiet tinted enabled surface, and no underline or navigation marker; executor class names do not appear as permanent filter labels.

`assets/ui/hydroxide-window-icons.png` is a 256 by 128 transparent atlas for collapse, maximize, restore, exit, and resize. `assets/ui/hydroxide-window-icons-source.png` preserves the generated raster source. Window controls never depend on font glyph coverage or switch visual families between normal and maximized states.

`assets/ui/hydroxide-resize-cursor.png` is a dedicated 24-by-24 transparent raster cursor: a white double-headed NW–SE arrow with a dark outline for contrast over both the shell and the game world. It is intentionally separate from the two-stroke corner grip and loads through the same required `getcustomasset` path as the rest of the raster set.

The runtime asset path is `hydroxide/assets/<branch>/ui-v1/<filename>`. Stable `master` builds reuse their validated local files. Development builds refresh code and artwork from `dev` on every launch, so testers do not see stale assets. Files are written as binary strings and loaded through Volt's required `getcustomasset` API. Missing filesystem or custom-asset support is a startup error. There is no legacy image fallback.

All interface instances, row templates, prompts, overlays, menus, and window controls are created by local Luau modules. Hydroxide must not import external Roblox UI models or template packs. Raster artwork may only come from the generated files under `assets/ui/` through `getcustomasset`.

## Interaction states

- Default: cool-gray icon and text.
- Hover: quiet `Hover` surface with secondary text; hover must not imitate selection.
- Selected tab: rail-colored surface, mint icon, and a two-pixel mint marker on the leading edge. Selected tabs do not add a border, shadow, or raised card.
- Focus: visible mint outline.
- Resize affordance: the corner grip is secondary gray at rest, white on hover, and mint for the complete mouse-down drag. The cursor remains the same directional resize arrow across hover and active states.
- Disabled: muted text at 55 percent opacity.
- Destructive: reserve `Danger` for destructive actions only.
- Transitions: 120 to 180 milliseconds, limited to color, opacity, position, and the collapse/reopen size tween of the existing window frame.

## Accessibility and resilience

- Compact controls keep a 36-pixel pointer target even when their visible glyph is 14 to 22 pixels.
- Primary and secondary text must remain legible over their declared surfaces; muted text is reserved for metadata and inactive chrome.
- Long tool names and object values truncate inside their owned region instead of expanding the shell.
- The title bar and tool rail stay fixed. Only page-owned result lists may scroll.
- The minimum-size shell must retain a usable main pane without horizontal overflow.

## Verification

The local Volt and Roblox clients are available for executor-owned rendering. Source contracts and Lune checks cover hierarchy and geometry; every visual shell change must also be exercised from the `dev` build and verified with fresh open, collapsed, and fully exited captures before sign-off.

## Implementation boundary

The complete interface is source-built. `ui/runtime.lua` owns the live instance tree and reusable templates; feature modules consume that local contract. The title bar, tool rail, workspace, Home composition, resize handle, reopen state, prompts, menus, list rows, and scanner pages must not depend on `rbxassetid://11389137937`, `rbxassetid://5042114982`, or any other imported UI model.

Reusable primitives are: `Surface`, `ActionButton`, `QueryBar`, `FilterPopover`, `Tooltip`, `ScrollList`, `ObjectLabel`, `Dropdown`, `CheckBox`, `Prompt`, `MessageBox`, `ContextMenu`, `Tab`, and `RowTemplate`. `FilterPopover` anchors below its query-bar action, uses a full-width 36-pixel option target, closes on outside click, and reflects shared scanner state. `Tooltip` is the rail's compact hover label: it centers above the hovered tab, falls below only when title-bar clearance would be violated, uses the elevated surface and border treatment, and renders above every page-owned popover, including an open FilterPopover. Each primitive has default, hover, selected, focused, and disabled styling where applicable and uses the token palette above.
