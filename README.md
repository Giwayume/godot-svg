# Godot SVG

This Godot plugin **renders SVG files at runtime** by using Polygon2D nodes. It achieves the effect of infinite scaling and smooth curves by varying the number of vertices used to draw each shape.

This is the most spec-compliant SVG renderer for Godot. Every other SVG-related project I see only attempts to make simple things like shapes and solid lines work.

## Usage

1. When importing a SVG into Godot, it defaults to "Import As: Texture". Change this dropdown to "Import As: SVG", then re-import.

<div style="text-align: center">
    <img src="./docs/tutorial_import_as_svg.png" alt="Visual instructions">
</div>
<br>

2. Now in a 2D scene, add a SVG2D node. Drag & drop your SVG file to the "SVG" property of this node, and you will see the SVG rendered in realtime!

<div style="text-align: center">
    <img src="./docs/tutorial_create_svg2d_node.png" alt="Visual instructions">
</div>

### The SVG2D Node

**PROPERTIES**

| Property Name | Value Type | Notes |
|:-----|:--------------|:------|
| svg | SVG Resource | When importing a SVG file, choose "Import As: SVG". If you try to add a SVG imported as "Texture" here, it will not work. Use Sprite instead for that. |
| fixed_scaling_ratio | float | If the value is 0, the SVG will be redrawn every time the scale changes so jagged edges are not visible. Setting the value above 0 bakes the resolution of the paths so they are not redrawn due to scaling at runtime. A value of 1 means it is drawn to look perfect at 100% view box scale (1:1), and if you zoom in further than that you will see jagged edges. |


## Performance Considerations

**SVGs vs Sprites**

Godot is much faster at drawing raster textures in 2D. Whenever you can get away with it, you should prefer using Sprites instead of SVGs.

**Scaling**

By default, when the scale of your SVG changes, or the scale of your Camera's viewport changes, the SVG's polygon vertices are recalculated on the CPU so you do not see jaggy edges. There is a performance cost associated with this, **especially** if you zoom in close to large curves. If your game uses a lot of scaling operations, look there first for optimization (set fixed_scaling_ratio to a value above 0).

**Masks and Clip Paths**

Using masks and clip paths can quickly bring your game to a crawl. Both are rasterized to the game's output resolution before being applied to shapes. This means mask performance is resolution dependent. A masked shape that takes up the entire screen will take exponentially more time to draw than a smaller masked shape that takes up half the screen.

**Stylesheets**

Avoid SVGs that use stylesheets like the plague. (e.g. avoid the `<style>` element). It is technically supported, but it is very expensive to compute up-front. Set inline attributes instead; the inline style attribute (e.g. `<rect style="fill:red">`) is OK to use.

**Animation**

Animating styling attributes that cause the shape of an element to change (such as `stroke-dasharray`, `d`, `r`) will cause the entire shape to be recalculated which can become expensive on a large scale. Animating masked or clip-path shapes regenerates viewport textures on the CPU each frame, which is even more expensive.

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
| mask | ![Status](/docs/supported_checkmark.png) Supported | |
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
| clip-path | ![Status](/docs/supported_checkmark.png) Supported | Currently supported at the SVG1.1 spec |
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
| mask | ![Status](/docs/supported_checkmark.png) Supported | Currently supported at the SVG1.1 spec |
| opacity | ![Status](/docs/partial_support_exclamation.png) Not Yet Supported | |
| pointer-events | ![Status](/docs/partial_support_exclamation.png) Not Yet Supported | |
| shape-rendering | ![Status](/docs/partial_support_exclamation.png) Not Yet Supported | |
| stroke | ![Status](/docs/supported_checkmark.png) Supported | |
| stroke-dasharray | ![Status](/docs/supported_checkmark.png) Supported | |
| stroke-dashoffset | ![Status](/docs/supported_checkmark.png) Supported | |
| stroke-linecap | ![Status](/docs/supported_checkmark.png) Supported | |
| stroke-linejoin | ![Status](/docs/supported_checkmark.png) Supported | SVG2 spec "arcs" not yet implemented |
| stroke-miterlimit | ![Status](/docs/supported_checkmark.png) Supported | |
| stroke-opacity | ![Status](/docs/supported_checkmark.png) Supported | |
| stroke-width | ![Status](/docs/supported_checkmark.png) Supported | |
| transform | ![Status](/docs/partial_support_exclamation.png) Partial Support | 3D transforms are not supported |
| vector-effect | ![Status](/docs/partial_support_exclamation.png) Not Yet Supported | |
| visibility | ![Status](/docs/partial_support_exclamation.png) Not Yet Supported | |
