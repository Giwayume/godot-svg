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
| a | Not Yet Supported | |
| altGlyph | Will Not Support | Deprecated |
| altGlyphDef | Will Not Support | Deprecated |
| altGlyphItem | Will Not Support | Deprecated |
| animate | Not Yet Supported | |
| animateMotion | Not Yet Supported | |
| animateTransform | Not Yet Supported | |
| circle | Not Yet Supported |  |
| clipPath | Not Yet Supported | |
| color-profile | Will Not Support | Deprecated |
| cursor | Will Not Support | Deprecated |
| defs | Supported | |
| desc | Supported | Not rendered |
| ellipse | Not Yet Supported | |
| feBlend | Not Yet Supported | |
| feColorMatrix | Not Yet Supported | |
| feComponentTransfer | Not Yet Supported | |
| feComposite | Not Yet Supported | |
| feConvolveMatrix | Not Yet Supported | |
| feDiffuseLighting | Not Yet Supported | |
| feDisplacementMap | Not Yet Supported | |
| feDistantLight | Not Yet Supported | |
| feFlood | Not Yet Supported | |
| feFuncA | Not Yet Supported | |
| feFuncB | Not Yet Supported | |
| feFuncG | Not Yet Supported | |
| feFuncR | Not Yet Supported | |
| feGaussianBlur | Not Yet Supported | |
| feImage | Not Yet Supported | |
| feMerge | Not Yet Supported | |
| feMergeNode | Not Yet Supported | |
| feMorphology | Not Yet Supported | |
| feOffset | Not Yet Supported | |
| fePointLight | Not Yet Supported | |
| feSpecularLighting | Not Yet Supported | |
| feSpotLight | Not Yet Supported | |
| feTile | Not Yet Supported | |
| feTurbulence | Not Yet Supported | |
| filter | Not Yet Supported | |
| font | Will Not Support | Deprecated |
| font-face | Will Not Support | Deprecated |
| font-face-format | Will Not Support | Deprecated |
| font-face-name | Will Not Support | Deprecated |
| font-face-src | Will Not Support | Deprecated |
| font-face-uri | Will Not Support | Deprecated |
| foreignObject | Will Not Support | No use case |
| g | Supported | |
| glyph | Will Not Support | Deprecated |
| glyphRef | Will Not Support | Deprecated |
| hkern | Will Not Support | Deprecated |
| image | Not Yet Supported | |
| line | Not Yet Supported | |
| linearGradient | Not Yet Supported | |
| marker | Not Yet Supported | |
| mask | Not Yet Supported | |
| metadata | Not Yet Supported | |
| missing-glyph | Will Not Support | Deprecated |
| mpath | Not Yet Supported | |
| path | Not Yet Supported | |
| pattern | Not Yet Supported | |
| polygon | Not Yet Supported | |
| polyline | Not Yet Supported | |
| radialGradient | Not Yet Supported | |
| rect | Not Yet Supported | |
| script | Will Not Support | No use case |
| set | Not Yet Supported | |
| stop | Supported | |
| style | Partial Support | Currently element, id, class, descendant selectors are recognized. |
| svg | Partial Support | Need to implement: preserveAspectRatio |
| switch | Not Yet Supported | |
| symbol | Not Yet Supported | |
| text | Not Yet Supported | |
| textPath | Not Yet Supported | |
| title | Supported | Not rendered |
| tref | Will Not Support | Deprecated |
| tspan | Not Yet Supported | |
| use | Not Yet Supported | |
| view | Not Yet Supported | |
| vkern | Will Not Support | Deprecated |

**CORE ATTRIBUTES**

| Name | Support Level | Notes |
|:-----|:--------------|:------|
| id | Supported | |
| lang | Not Yet Supported | |
| tabindex | Will Not Support | No use case |

**STYLING ATTRIBUTES**

| Name | Support Level | Notes |
|:-----|:--------------|:------|
| class | Supported | |
| style | Supported | |

**CONDITIONAL PROCESSING ATTRIBUTES**

| Name | Support Level | Notes |
|:-----|:--------------|:------|
| requiredExtensions | Not Yet Supported | |
| requiredFeatures | Will Not Support | Deprecated |
| systemLanguage | Not Yet Supported | |

**PRESENTATION ATTRIBUTES**

| Name | Support Level | Notes |
|:-----|:--------------|:------|
| clip-path | Not Yet Supported | |
| clip-rule | Not Yet Supported | |
| color | Not Yet Supported | |
| color-interpolation | Not Yet Supported | |
| color-rendering | Not Yet Supported | |
| cursor | Not Yet Supported | |
| display | Not Yet Supported | |
| fill | Supported | |
| fill-opacity | Not Yet Supported | |
| fill-rule | Not Yet Supported | |
| filter | Not Yet Supported | |
| mask | Not Yet Supported | |
| opacity | Not Yet Supported | |
| pointer-events | Not Yet Supported | |
| shape-rendering | Not Yet Supported | |
| stroke | Supported | |
| stroke-dasharray | Not Yet Supported | |
| stroke-dashoffset | Not Yet Supported | |
| stroke-linecap | Not Yet Supported | |
| stroke-linejoin | Partial Support | "arcs" and "miter-clip" is converted to "miter" |
| stroke-miterlimit | Supported | |
| stroke-opacity | Not Yet Supported | |
| stroke-width | Supported | |
| transform | Partial Support | 3D transforms are not supported |
| vector-effect | Not Yet Supported | |
| visibility | Not Yet Supported | |
