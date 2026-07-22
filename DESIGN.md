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

- Default size: 1120 by 680 pixels, clamped to the current viewport with a 16-pixel outer margin.
- Minimum size: 720 by 420 pixels, reduced only when the viewport itself is smaller.
- Title bar: 48 pixels.
- Tool rail: 56 pixels.
- Status bar: 28 pixels.
- Explorer: preserve the current pane and feature flow in this pass.
- The title bar, tool rail, and status bar remain fixed. Page-owned lists keep their own scrolling.
- The bottom-right handle resizes the window. The maximize control toggles a viewport-filling state and restores the prior bounds.

## Asset contract

`assets/ui/hydroxide-icons.png` is a 256 by 128 transparent atlas with 64-pixel cells. `assets/ui/hydroxide-icons-source.png` preserves the generated source sheet. Cell names and offsets live in `ui/assets.lua`.

`assets/ui/hydroxide-logo.png` is the two-tone Home Page mark. `assets/ui/hydroxide-logo-source.png` preserves the generated source artwork.

The runtime asset path is `hydroxide/assets/<branch>/ui-v1/<filename>`. Stable `master` builds reuse their validated local files. Development builds refresh code and artwork from `dev` on every launch, so testers do not see stale assets. Files are written as binary strings and loaded through Volt's required `getcustomasset` API. Missing filesystem or custom-asset support is a startup error. There is no legacy image fallback.

## Interaction states

- Default: cool-gray icon and text.
- Hover: `Hover` surface with primary text.
- Selected: mint icon on `Accent surface`.
- Focus: visible mint outline.
- Disabled: muted text at 55 percent opacity.
- Destructive: reserve `Danger` for destructive actions only.
- Transitions: 120 to 180 milliseconds, limited to color, opacity, and position.

## Implementation boundary

The current shell still comes from `rbxassetid://11389137937`. The first implementation layer restyles that hierarchy and adds window behavior without renaming pages or changing module flow. Replacing the external model with a source-built GUI is a later migration and should happen only after every module-owned object path is captured.
