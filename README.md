# Godot SVG

This Godot 3.5 plugin **renders SVG files at runtime**. It achieves the effect of infinite scaling and smooth curves by calculating the curves in shaders drawn on polygons.

To be clear, Godot already has built-in functionality to import SVGs and display them as rasterized (pixel map) textures in-game. This is likely what you should do 90% of the time instead of using this plugin to render every SVG in your game.

It is **HIGHLY RECOMMENDED** to use this plugin with the GLES3 renderer, as GLES2 does not support many of the functions used to render SVG on the GPU (dFdx/dFdy/fwidth is used for anti-aliasing).

## Alpha Testing Caveats

This software is in early development.

1. **If your SVG has self-intersecting paths, you may see visual bugs. There is a lot of code written to solve this scenario, but it is still being worked on and there are many W3C test suite examples where it is known to not work.**

2. **You may run into a problem where loading certain SVG files causes Godot to freeze, due to the path solver getting stuck in an infinite loop. To prevent this, don't use SVGs with self-intersecting paths or thin strokes.**

3. **Check the support table at the bottom before reporting bugs.**

## Godot Core Issues

Resolving the following issues in Godot core will improve this plugin. Please visit them and give a thumbs up.

1. [OpenGL: MSAA antialiasing is not reimplemented yet](https://github.com/godotengine/godot/issues/69462) - SVGs are drawn on meshes, there are noticable aliasing artifacts especially as you scale out. This will fix that.

2. [Expose _edit_get_rect, _edit_use_rect to gdscript](https://github.com/godotengine/godot-proposals/issues/5289) - SVG2D is set up as a custom node, without this engine feature you cannot resize and rescale it with editor controls (must use the inspector).

## Installation

Copy the `addons/godot-svg` folder in this repository into your Godot project. Make sure the folder sits exactly at the path `res://addons/godot-svg`. If you put it somewhere else, some things like icons may break.

In Godot, go to `Project -> Project Settings -> Plugins` and check the `Enable` checkbox.

## Usage

1. When importing a SVG into Godot, it defaults to "Import As: Texture". Change this dropdown to "Import As: SVG", then re-import.

<p align="center">
    <img src="./docs/tutorial_import_as_svg.png" alt="Visual instructions">
</p>
<br>

2. Now in a 2D scene, add a SVG2D node. Drag & drop your SVG file to the "SVG" property of this node, and you will see the SVG rendered in realtime!

<p align="center">
    <img src="./docs/tutorial_create_svg2d_node.png" alt="Visual instructions">
</p>

### The SVG2D Node

Use in 2D scenes similar to how you would use a *Sprite*. The default size of the SVG2D is determined by the [`viewBox`](https://developer.mozilla.org/en-US/docs/Web/SVG/Attribute/viewBox), [`width`](https://developer.mozilla.org/en-US/docs/Web/SVG/Attribute/width), and [`height`](https://developer.mozilla.org/en-US/docs/Web/SVG/Attribute/height) attributes on the imported [`<svg>`](https://developer.mozilla.org/en-US/docs/Web/SVG/Element/svg) element.

### The SVGRect Node

Use in 2D scenes similar to how you would use a *TextureRect*. How the SVG fits inside of this rectangle is determined by the [`preserveAspectRatio`](https://developer.mozilla.org/en-US/docs/Web/SVG/Attribute/preserveAspectRatio) attribute on the imported [`<svg>`](https://developer.mozilla.org/en-US/docs/Web/SVG/Element/svg) element.


### SVG2D & SVGRect Documentation

These nodes share a similar API.

**PROPERTIES**

| Property Name | Value Type | Notes |
|:-----|:--------------|:------|
| svg | SVG Resource | When importing a SVG file, choose "Import As: SVG". If you try to add a SVG imported as "Texture" here, it will not work. Use Sprite instead for that. |
| fixed_scaling_ratio | float | [This feature may not yet be working as expected]. Setting the value above 0 bakes the resolution of masks so they are not redrawn due to scaling at runtime. A value of 1 means it is drawn to look perfect at 100% view box scale (1:1), and if you zoom in further than that you will see pixellated edges. Setting the value to 0 redraws the mask every frame. |
| antialiased | bool | Whether or not to use the antialiasing to smooth the shape edges. |
| triangulation_method | SVGValueConstant.<br>TriangulationMethod | Delaunay and Earcut are two different triangulation methods used to fill the interior of the shape. Their accuracy and performance characteristics vary based on the situation. It may be more beneficial to choose one or the other depending on the SVG. |
| assume_no_self_intersections | bool | This is an optimization that can make the initial construction/animation of the shape faster by not even attempting to solve for self-intersecting shapes. If there are actual intersections, the shape may not draw or may have rendering artifacts. |
| assume_no_holes | bool | This is an optimization that can make the initial construction/animation of the shape faster by not even attempting to solve for holes. If there are potential holes, they are ignored. |
| disable_render_cache | bool | When you first load a SVG in the editor, it will spend time solving and triangulating the paths. This solution is saved back to the asset for a faster load time. This property disables that process. |


## Performance Considerations

***SVGs vs Sprites***

Godot is generally much faster at drawing raster textures in 2D. Whenever you can get away with it, you should prefer using Sprites with images imported as "Texture" instead of SVGs.

***Scaling***

If your game uses a lot of scaling operations, and you use special features such as masks and patterns that need to be recalculated during re-scale, consider setting fixed_scaling_ratio to a value above 0.

***Masks and Clip Paths***

Using masks and clip paths can quickly bring your game to a crawl. Both are rasterized to the game's output resolution before being applied to shapes. This means mask performance is resolution dependent. A masked shape that takes up the entire screen will take exponentially more time to draw than a smaller masked shape that takes up half the screen.

Setting `opacity < 1` on group (`<g>`) elements is also treated like a mask.

***Stylesheets***

Avoid SVGs that use stylesheets like the plague. (e.g. avoid the `<style>` element). It is technically supported, but it is very expensive to compute up-front. Set inline attributes instead; the inline style attribute (e.g. `<rect style="fill:red">`) is OK to use.

***Animation***

[Note: svg animation not yet implemented] Animating styling attributes that cause the shape of an element to change (such as `stroke-dasharray`, `d`, `r`) will cause the entire shape to be recalculated which can become expensive on a large scale. Animating masked or clip-path shapes regenerates viewport textures on the CPU each frame, which is even more expensive.

***Basic Shapes***

There is a performance benefit to using basic shapes (`circle`, `ellipse`, `rect`, `line`) as opposed to generating the same shape using a `path`, `polygon`, or `polyline`. With the latter, the shapes must be simplified first and have expensive calculations to determine the fill rule.

## Support Table

**ELEMENTS**

| Name | Support Level | Notes |
|:-----|:--------------|:------|
| a | ![Status](./docs/partial_support_exclamation.png) Not Yet Supported | |
| altGlyph | ![Status](./docs/not_supported_x.png) Will Not Support | Deprecated |
| altGlyphDef | ![Status](./docs/not_supported_x.png) Will Not Support | Deprecated |
| altGlyphItem | ![Status](./docs/not_supported_x.png) Will Not Support | Deprecated |
| animate | ![Status](./docs/partial_support_exclamation.png) Not Yet Supported | |
| animateMotion | ![Status](./docs/partial_support_exclamation.png) Not Yet Supported | |
| animateTransform | ![Status](./docs/partial_support_exclamation.png) Not Yet Supported | |
| circle | ![Status](./docs/supported_checkmark.png) Supported |  |
| clipPath | ![Status](./docs/supported_checkmark.png) Supported | |
| color-profile | ![Status](./docs/not_supported_x.png) Will Not Support | Deprecated |
| cursor | ![Status](./docs/not_supported_x.png) Will Not Support | Deprecated |
| defs | ![Status](./docs/supported_checkmark.png) Supported | |
| desc | ![Status](./docs/supported_checkmark.png) Supported | Not rendered |
| ellipse | ![Status](./docs/supported_checkmark.png) Supported | |
| feBlend | ![Status](./docs/partial_support_exclamation.png) Not Yet Supported | |
| feColorMatrix | ![Status](./docs/partial_support_exclamation.png) Not Yet Supported | |
| feComponentTransfer | ![Status](./docs/partial_support_exclamation.png) Not Yet Supported | |
| feComposite | ![Status](./docs/partial_support_exclamation.png) Not Yet Supported | |
| feConvolveMatrix | ![Status](./docs/partial_support_exclamation.png) Not Yet Supported | |
| feDiffuseLighting | ![Status](./docs/partial_support_exclamation.png) Not Yet Supported | |
| feDisplacementMap | ![Status](./docs/partial_support_exclamation.png) Not Yet Supported | |
| feDistantLight | ![Status](./docs/partial_support_exclamation.png) Not Yet Supported | |
| feFlood | ![Status](./docs/partial_support_exclamation.png) Not Yet Supported | |
| feFuncA | ![Status](./docs/partial_support_exclamation.png) Not Yet Supported | |
| feFuncB | ![Status](./docs/partial_support_exclamation.png) Not Yet Supported | |
| feFuncG | ![Status](./docs/partial_support_exclamation.png) Not Yet Supported | |
| feFuncR | ![Status](./docs/partial_support_exclamation.png) Not Yet Supported | |
| feGaussianBlur | ![Status](./docs/partial_support_exclamation.png) Not Yet Supported | |
| feImage | ![Status](./docs/partial_support_exclamation.png) Not Yet Supported | |
| feMerge | ![Status](./docs/partial_support_exclamation.png) Not Yet Supported | |
| feMergeNode | ![Status](./docs/partial_support_exclamation.png) Not Yet Supported | |
| feMorphology | ![Status](./docs/partial_support_exclamation.png) Not Yet Supported | |
| feOffset | ![Status](./docs/partial_support_exclamation.png) Not Yet Supported | |
| fePointLight | ![Status](./docs/partial_support_exclamation.png) Not Yet Supported | |
| feSpecularLighting | ![Status](./docs/partial_support_exclamation.png) Not Yet Supported | |
| feSpotLight | ![Status](./docs/partial_support_exclamation.png) Not Yet Supported | |
| feTile | ![Status](./docs/partial_support_exclamation.png) Not Yet Supported | |
| feTurbulence | ![Status](./docs/partial_support_exclamation.png) Not Yet Supported | |
| filter | ![Status](./docs/partial_support_exclamation.png) Not Yet Supported | |
| font | ![Status](./docs/not_supported_x.png) Will Not Support | Deprecated |
| font-face | ![Status](./docs/not_supported_x.png) Will Not Support | Deprecated |
| font-face-format | ![Status](./docs/not_supported_x.png) Will Not Support | Deprecated |
| font-face-name | ![Status](./docs/not_supported_x.png) Will Not Support | Deprecated |
| font-face-src | ![Status](./docs/not_supported_x.png) Will Not Support | Deprecated |
| font-face-uri | ![Status](./docs/not_supported_x.png) Will Not Support | Deprecated |
| foreignObject | ![Status](./docs/not_supported_x.png) Will Not Support | No use case |
| g | ![Status](./docs/supported_checkmark.png) Supported | |
| glyph | ![Status](./docs/not_supported_x.png) Will Not Support | Deprecated |
| glyphRef | ![Status](./docs/not_supported_x.png) Will Not Support | Deprecated |
| hkern | ![Status](./docs/not_supported_x.png) Will Not Support | Deprecated |
| image | ![Status](./docs/supported_checkmark.png) Supported | Image href must be a relative URL pointing to an image you placed in the project under res://. |
| line | ![Status](./docs/supported_checkmark.png) Supported | |
| linearGradient | ![Status](./docs/supported_checkmark.png) Supported | |
| marker | ![Status](./docs/partial_support_exclamation.png) Not Yet Supported | |
| mask | ![Status](./docs/supported_checkmark.png) Supported | |
| metadata | ![Status](./docs/partial_support_exclamation.png) Not Yet Supported | |
| missing-glyph | ![Status](./docs/not_supported_x.png) Will Not Support | Deprecated |
| mpath | ![Status](./docs/partial_support_exclamation.png) Not Yet Supported | |
| path | ![Status](./docs/supported_checkmark.png) Supported | |
| pattern | ![Status](./docs/supported_checkmark.png) Supported | |
| polygon | ![Status](./docs/supported_checkmark.png) Supported | |
| polyline | ![Status](./docs/supported_checkmark.png) Supported | |
| radialGradient | ![Status](./docs/supported_checkmark.png) Supported | |
| rect | ![Status](./docs/supported_checkmark.png) Supported | |
| script | ![Status](./docs/not_supported_x.png) Will Not Support | No use case |
| set | ![Status](./docs/partial_support_exclamation.png) Not Yet Supported | |
| stop | ![Status](./docs/supported_checkmark.png) Supported | |
| style | ![Status](./docs/partial_support_exclamation.png) Partial Support | Currently element, id, class, descendant selectors are recognized |
| svg | ![Status](./docs/supported_checkmark.png) Supported | |
| switch | ![Status](./docs/partial_support_exclamation.png) Not Yet Supported | |
| symbol | ![Status](./docs/partial_support_exclamation.png) Not Yet Supported | |
| text | ![Status](./docs/partial_support_exclamation.png) Not Yet Supported | |
| textPath | ![Status](./docs/partial_support_exclamation.png) Not Yet Supported | |
| title | ![Status](./docs/supported_checkmark.png) Supported | Not rendered |
| tref | ![Status](./docs/not_supported_x.png) Will Not Support | Deprecated |
| tspan | ![Status](./docs/partial_support_exclamation.png) Not Yet Supported | |
| use | ![Status](./docs/partial_support_exclamation.png) Not Yet Supported | |
| view | ![Status](./docs/partial_support_exclamation.png) Not Yet Supported | |
| vkern | ![Status](./docs/not_supported_x.png) Will Not Support | Deprecated |

**CORE ATTRIBUTES**

| Name | Support Level | Notes |
|:-----|:--------------|:------|
| id | ![Status](./docs/supported_checkmark.png) Supported | |
| lang | ![Status](./docs/partial_support_exclamation.png) Not Yet Supported | |
| tabindex | ![Status](./docs/not_supported_x.png) Will Not Support | No use case |

**STYLING ATTRIBUTES**

| Name | Support Level | Notes |
|:-----|:--------------|:------|
| class | ![Status](./docs/supported_checkmark.png) Supported | |
| style | ![Status](./docs/supported_checkmark.png) Supported | |

**CONDITIONAL PROCESSING ATTRIBUTES**

| Name | Support Level | Notes |
|:-----|:--------------|:------|
| requiredExtensions | ![Status](./docs/partial_support_exclamation.png) Not Yet Supported | |
| requiredFeatures | ![Status](./docs/not_supported_x.png) Will Not Support | Deprecated |
| systemLanguage | ![Status](./docs/partial_support_exclamation.png) Not Yet Supported | |

**PRESENTATION ATTRIBUTES**

| Name | Support Level | Notes |
|:-----|:--------------|:------|
| clip-path | ![Status](./docs/supported_checkmark.png) Supported | Currently supported at the SVG1.1 spec |
| clip-rule | ![Status](./docs/supported_checkmark.png) Supported | Currently supported at the SVG1.1 spec |
| color | ![Status](./docs/partial_support_exclamation.png) Partial Support | Not fully tested |
| color-interpolation | ![Status](./docs/partial_support_exclamation.png) Not Yet Supported | |
| color-rendering | ![Status](./docs/partial_support_exclamation.png) Not Yet Supported | |
| cursor | ![Status](./docs/partial_support_exclamation.png) Not Yet Supported | |
| display | ![Status](./docs/partial_support_exclamation.png) Not Yet Supported | |
| fill | ![Status](./docs/supported_checkmark.png) Supported | |
| fill-opacity | ![Status](./docs/supported_checkmark.png) Supported | |
| fill-rule | ![Status](./docs/supported_checkmark.png) Supported | |
| filter | ![Status](./docs/partial_support_exclamation.png) Not Yet Supported | |
| mask | ![Status](./docs/supported_checkmark.png) Supported | Currently supported at the SVG1.1 spec |
| opacity | ![Status](./docs/supported_checkmark.png) Supported | |
| pointer-events | ![Status](./docs/partial_support_exclamation.png) Not Yet Supported | |
| shape-rendering | ![Status](./docs/partial_support_exclamation.png) Not Yet Supported | |
| stroke | ![Status](./docs/supported_checkmark.png) Supported | |
| stroke-dasharray | ![Status](./docs/supported_checkmark.png) Supported | |
| stroke-dashoffset | ![Status](./docs/supported_checkmark.png) Supported | |
| stroke-linecap | ![Status](./docs/supported_checkmark.png) Supported | |
| stroke-linejoin | ![Status](./docs/supported_checkmark.png) Supported | SVG2 spec "arcs" not yet implemented |
| stroke-miterlimit | ![Status](./docs/supported_checkmark.png) Supported | |
| stroke-opacity | ![Status](./docs/supported_checkmark.png) Supported | |
| stroke-width | ![Status](./docs/supported_checkmark.png) Supported | |
| transform | ![Status](./docs/supported_checkmark.png) Supported | 3D transforms are converted to 2D transforms |
| vector-effect | ![Status](./docs/partial_support_exclamation.png) Not Yet Supported | |
| visibility | ![Status](./docs/supported_checkmark.png) Supported | |
