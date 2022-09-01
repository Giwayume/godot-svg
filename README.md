# Godot SVG

This Godot plugin renders SVG files at runtime, by using Polygon2D nodes. It achieves the effect of infinite scaling and smooth curves by varying the number of vertices used to draw each shape.

The goal of this plugin is to have a fairly spec-compliant realtime SVG renderer. It is not designed as a way to edit SVG files in Godot after importing them. If you're looking to do that, try this project instead: https://github.com/poke1024/godot_vector_graphics

The advantage of using this plugin is you don't have to compile Godot to install it, and it also implements much more complicated aspects of the SVG spec such as clip paths.

## Usage

1. When importing a SVG into Godot, it defaults to "Import As: Texture". Change this dropdown to "Import As: SVG", then re-import.

2. Now in a 2D scene, add a SVG2D node. Drag & drop your SVG file to the "SVG" property of this node, and you will see the SVG rendered in realtime!

## Support Table

**ELEMENTS**

| Name | Support Level | Notes |
|:-----|:--------------|:------|
| a | ![Status](/docs/partial_support_exclamation.png) Not Yet Supported | |
| altGlyph | ![Status](/docs/not_supported_x.png) Will Not Support | Deprecated |
| altGlyphDef | ![Status](/docs/not_supported_x.png) Will Not Support | Deprecated |
| altGlyphItem | ![Status](/docs/not_supported_x.png) Will Not Support | Deprecated |
| animate | ![Status](/docs/partial_support_exclamation.png) Not Yet Supported | |
| animateMotion | ![Status](/docs/partial_support_exclamation.png) Not Yet Supported | |
| animateTransform | ![Status](/docs/partial_support_exclamation.png) Not Yet Supported | |
| circle | ![Status](/docs/partial_support_exclamation.png) Not Yet Supported |  |
| clipPath | ![Status](/docs/partial_support_exclamation.png) Not Yet Supported | |
| color-profile | ![Status](/docs/not_supported_x.png) Will Not Support | Deprecated |
| cursor | ![Status](/docs/not_supported_x.png) Will Not Support | Deprecated |
| defs | ![Status](/docs/supported_checkmark.png) Supported | |
| desc | ![Status](/docs/supported_checkmark.png) Supported | Not rendered |
| ellipse | ![Status](/docs/partial_support_exclamation.png) Not Yet Supported | |
| feBlend | ![Status](/docs/partial_support_exclamation.png) Not Yet Supported | |
| feColorMatrix | ![Status](/docs/partial_support_exclamation.png) Not Yet Supported | |
| feComponentTransfer | ![Status](/docs/partial_support_exclamation.png) Not Yet Supported | |
| feComposite | ![Status](/docs/partial_support_exclamation.png) Not Yet Supported | |
| feConvolveMatrix | ![Status](/docs/partial_support_exclamation.png) Not Yet Supported | |
| feDiffuseLighting | ![Status](/docs/partial_support_exclamation.png) Not Yet Supported | |
| feDisplacementMap | ![Status](/docs/partial_support_exclamation.png) Not Yet Supported | |
| feDistantLight | ![Status](/docs/partial_support_exclamation.png) Not Yet Supported | |
| feFlood | ![Status](/docs/partial_support_exclamation.png) Not Yet Supported | |
| feFuncA | ![Status](/docs/partial_support_exclamation.png) Not Yet Supported | |
| feFuncB | ![Status](/docs/partial_support_exclamation.png) Not Yet Supported | |
| feFuncG | ![Status](/docs/partial_support_exclamation.png) Not Yet Supported | |
| feFuncR | ![Status](/docs/partial_support_exclamation.png) Not Yet Supported | |
| feGaussianBlur | ![Status](/docs/partial_support_exclamation.png) Not Yet Supported | |
| feImage | ![Status](/docs/partial_support_exclamation.png) Not Yet Supported | |
| feMerge | ![Status](/docs/partial_support_exclamation.png) Not Yet Supported | |
| feMergeNode | ![Status](/docs/partial_support_exclamation.png) Not Yet Supported | |
| feMorphology | ![Status](/docs/partial_support_exclamation.png) Not Yet Supported | |
| feOffset | ![Status](/docs/partial_support_exclamation.png) Not Yet Supported | |
| fePointLight | ![Status](/docs/partial_support_exclamation.png) Not Yet Supported | |
| feSpecularLighting | ![Status](/docs/partial_support_exclamation.png) Not Yet Supported | |
| feSpotLight | ![Status](/docs/partial_support_exclamation.png) Not Yet Supported | |
| feTile | ![Status](/docs/partial_support_exclamation.png) Not Yet Supported | |
| feTurbulence | ![Status](/docs/partial_support_exclamation.png) Not Yet Supported | |
| filter | ![Status](/docs/partial_support_exclamation.png) Not Yet Supported | |
| font | ![Status](/docs/not_supported_x.png) Will Not Support | Deprecated |
| font-face | ![Status](/docs/not_supported_x.png) Will Not Support | Deprecated |
| font-face-format | ![Status](/docs/not_supported_x.png) Will Not Support | Deprecated |
| font-face-name | ![Status](/docs/not_supported_x.png) Will Not Support | Deprecated |
| font-face-src | ![Status](/docs/not_supported_x.png) Will Not Support | Deprecated |
| font-face-uri | ![Status](/docs/not_supported_x.png) Will Not Support | Deprecated |
| foreignObject | ![Status](/docs/not_supported_x.png) Will Not Support | No use case |
| g | ![Status](/docs/supported_checkmark.png) Supported | |
| glyph | ![Status](/docs/not_supported_x.png) Will Not Support | Deprecated |
| glyphRef | ![Status](/docs/not_supported_x.png) Will Not Support | Deprecated |
| hkern | ![Status](/docs/not_supported_x.png) Will Not Support | Deprecated |
| image | ![Status](/docs/partial_support_exclamation.png) Not Yet Supported | |
| line | ![Status](/docs/partial_support_exclamation.png) Not Yet Supported | |
| linearGradient | ![Status](/docs/partial_support_exclamation.png) Not Yet Supported | |
| marker | ![Status](/docs/partial_support_exclamation.png) Not Yet Supported | |
| mask | ![Status](/docs/partial_support_exclamation.png) Not Yet Supported | |
| metadata | ![Status](/docs/partial_support_exclamation.png) Not Yet Supported | |
| missing-glyph | ![Status](/docs/not_supported_x.png) Will Not Support | Deprecated |
| mpath | ![Status](/docs/partial_support_exclamation.png) Not Yet Supported | |
| path | ![Status](/docs/partial_support_exclamation.png) Not Yet Supported | |
| pattern | ![Status](/docs/partial_support_exclamation.png) Not Yet Supported | |
| polygon | ![Status](/docs/partial_support_exclamation.png) Not Yet Supported | |
| polyline | ![Status](/docs/partial_support_exclamation.png) Not Yet Supported | |
| radialGradient | ![Status](/docs/partial_support_exclamation.png) Not Yet Supported | |
| rect | ![Status](/docs/partial_support_exclamation.png) Not Yet Supported | |
| script | ![Status](/docs/not_supported_x.png) Will Not Support | No use case |
| set | ![Status](/docs/partial_support_exclamation.png) Not Yet Supported | |
| stop | ![Status](/docs/supported_checkmark.png) Supported | |
| style | ![Status](/docs/partial_support_exclamation.png) Partial Support | Currently element, id, class, descendant selectors are recognized. |
| svg | ![Status](/docs/partial_support_exclamation.png) Partial Support | Need to implement: preserveAspectRatio |
| switch | ![Status](/docs/partial_support_exclamation.png) Not Yet Supported | |
| symbol | ![Status](/docs/partial_support_exclamation.png) Not Yet Supported | |
| text | ![Status](/docs/partial_support_exclamation.png) Not Yet Supported | |
| textPath | ![Status](/docs/partial_support_exclamation.png) Not Yet Supported | |
| title | ![Status](/docs/supported_checkmark.png) Supported | Not rendered |
| tref | ![Status](/docs/not_supported_x.png) Will Not Support | Deprecated |
| tspan | ![Status](/docs/partial_support_exclamation.png) Not Yet Supported | |
| use | ![Status](/docs/partial_support_exclamation.png) Not Yet Supported | |
| view | ![Status](/docs/partial_support_exclamation.png) Not Yet Supported | |
| vkern | ![Status](/docs/not_supported_x.png) Will Not Support | Deprecated |

**CORE ATTRIBUTES**

| Name | Support Level | Notes |
|:-----|:--------------|:------|
| id | ![Status](/docs/supported_checkmark.png) Supported | |
| lang | ![Status](/docs/partial_support_exclamation.png) Not Yet Supported | |
| tabindex | ![Status](/docs/not_supported_x.png) Will Not Support | No use case |

**STYLING ATTRIBUTES**

| Name | Support Level | Notes |
|:-----|:--------------|:------|
| class | ![Status](/docs/supported_checkmark.png) Supported | |
| style | ![Status](/docs/supported_checkmark.png) Supported | |

**CONDITIONAL PROCESSING ATTRIBUTES**

| Name | Support Level | Notes |
|:-----|:--------------|:------|
| requiredExtensions | ![Status](/docs/partial_support_exclamation.png) Not Yet Supported | |
| requiredFeatures | ![Status](/docs/not_supported_x.png) Will Not Support | Deprecated |
| systemLanguage | ![Status](/docs/partial_support_exclamation.png) Not Yet Supported | |

**PRESENTATION ATTRIBUTES**

| Name | Support Level | Notes |
|:-----|:--------------|:------|
| clip-path | ![Status](/docs/partial_support_exclamation.png) Not Yet Supported | |
| clip-rule | ![Status](/docs/partial_support_exclamation.png) Not Yet Supported | |
| color | ![Status](/docs/partial_support_exclamation.png) Not Yet Supported | |
| color-interpolation | ![Status](/docs/partial_support_exclamation.png) Not Yet Supported | |
| color-rendering | ![Status](/docs/partial_support_exclamation.png) Not Yet Supported | |
| cursor | ![Status](/docs/partial_support_exclamation.png) Not Yet Supported | |
| display | ![Status](/docs/partial_support_exclamation.png) Not Yet Supported | |
| fill | ![Status](/docs/supported_checkmark.png) Supported | |
| fill-opacity | ![Status](/docs/partial_support_exclamation.png) Not Yet Supported | |
| fill-rule | ![Status](/docs/partial_support_exclamation.png) Not Yet Supported | |
| filter | ![Status](/docs/partial_support_exclamation.png) Not Yet Supported | |
| mask | ![Status](/docs/partial_support_exclamation.png) Not Yet Supported | |
| opacity | ![Status](/docs/partial_support_exclamation.png) Not Yet Supported | |
| pointer-events | ![Status](/docs/partial_support_exclamation.png) Not Yet Supported | |
| shape-rendering | ![Status](/docs/partial_support_exclamation.png) Not Yet Supported | |
| stroke | ![Status](/docs/supported_checkmark.png) Supported | |
| stroke-dasharray | ![Status](/docs/partial_support_exclamation.png) Not Yet Supported | |
| stroke-dashoffset | ![Status](/docs/partial_support_exclamation.png) Not Yet Supported | |
| stroke-linecap | ![Status](/docs/partial_support_exclamation.png) Not Yet Supported | |
| stroke-linejoin | ![Status](/docs/supported_checkmark.png) Supported | SVG2 spec "arcs" not yet implemented |
| stroke-miterlimit | ![Status](/docs/supported_checkmark.png) Supported | |
| stroke-opacity | ![Status](/docs/partial_support_exclamation.png) Not Yet Supported | |
| stroke-width | ![Status](/docs/supported_checkmark.png) Supported | |
| transform | ![Status](/docs/partial_support_exclamation.png) Partial Support | 3D transforms are not supported |
| vector-effect | ![Status](/docs/partial_support_exclamation.png) Not Yet Supported | |
| visibility | ![Status](/docs/partial_support_exclamation.png) Not Yet Supported | |
