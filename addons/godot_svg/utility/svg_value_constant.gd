class_name SVGValueConstant

const AUTO = "auto"
const NONE = "none"
const MEET = "meet"
const SLICE = "slice"

const MID = "mid"
const MIN = "min"
const MAX = "max"

const CONTEXT_FILL = "context-fill"
const CONTEXT_STROKE = "context-stroke"

const VISIBLE = "visible"
const HIDDEN = "hidden"
const COLLAPSE = "collapse"

const NON_SCALING_STROKE = "non-scaling-stroke"
const NON_SCALING_SIZE = "non-scaling-size"
const NON_ROTATION = "non-rotation"
const FIXED_POSITION = "fixed-position"

const USER_SPACE_ON_USE = "userSpaceOnUse"
const OBJECT_BOUNDING_BOX = "objectBoundingBox"

const PAD = "pad"
const REFLECT = "reflect"
const REPEAT = "repeat"

const BUTT = "butt"
const ROUND = "round"
const SQUARE = "square"

const ARCS = "arcs"
const BEVEL = "bevel"
const MITER = "miter"
const MITER_CLIP = "miter-clip"

const SPACING = "spacing"
const SPACING_AND_GLYPHS = "spacingAndGlyphs"

const NON_ZERO = "nonzero"
const EVEN_ODD = "evenodd"

const INHERIT = "inherit"
const CURRENT_COLOR = "currentColor"

const MEDIA = "media"
const INDEFINITE = "indefinite"

const ALWAYS = "always"
const WHEN_NOT_ACTIVE = "whenNotActive"
const NEVER = "never"

const DISCRETE = "discrete"
const LINEAR = "linear"
const PACED = "paced"
const SPLINE = "spline"

const REPLACE = "replace"
const SUM = "sum"

enum PathCommand {
	MOVE_TO,
	LINE_TO,
	HORIZONTAL_LINE_TO,
	VERTICAL_LINE_TO,
	CUBIC_BEZIER_CURVE,
	SMOOTH_CUBIC_BEZIER_CURVE,
	QUADRATIC_BEZIER_CURVE,
	SMOOTH_QUADRATIC_BEZIER_CURVE,
	ELLIPTICAL_ARC_CURVE,
	CLOSE_PATH
}
enum PathCoordinate {
	ABSOLUTE,
	RELATIVE
}

enum TriangulationMethod {
	DELAUNAY = 0,
	EARCUT = 1,
}

const GLOBAL_ATTRIBUTE_NAMES = [
	"id",
	"lang",
	"tabindex",
	"class",
	"style",
	"required_extensions",
	"required_features",
	"system_language",
	"clip_path",
	"clip_rule",
	"color",
	"color_interpolation",
	"color_rendering",
	"cursor",
	"display",
	"fill",
	"fill_opacity",
	"fill_rule",
	"filter",
	"mask",
	"opacity",
	"pointer_events",
	"shape_rendering",
	"stroke",
	"stroke_dasharray",
	"stroke_dashoffset",
	"stroke_linecap",
	"stroke_linejoin",
	"stroke_miterlimit",
	"stroke_opacity",
	"stroke_width",
	"transform",
	"vector_effect",
	"visibility",
]

const GLOBAL_INHERITED_ATTRIBUTE_NAMES = [
	"lang",
	"tabindex",
	"required_extensions",
	"required_features",
	"system_language",
	"clip_rule",
	"color",
	"color_interpolation",
	"color_rendering",
	"cursor",
	"display",
	"fill",
	"fill_opacity",
	"fill_rule",
	"filter",
	"pointer_events",
	"shape_rendering",
	"stroke",
	"stroke_dasharray",
	"stroke_dashoffset",
	"stroke_linecap",
	"stroke_linejoin",
	"stroke_miterlimit",
	"stroke_opacity",
	"stroke_width",
	"vector_effect",
	"visibility",
]

const CSS_COLOR_NAMES = {
	"aqua": Color("#00FFFF"),
	"black": Color("#000000"),
	"blue": Color("#0000FF"),
	"fuchsia": Color("#FF00FF"),
	"gray": Color("#808080"),
	"grey": Color("#808080"),
	"green": Color("#008000"),
	"lime": Color("#00FF00"),
	"maroon": Color("#800000"),
	"navy": Color("#000080"),
	"olive": Color("#808000"),
	"purple": Color("#800080"),
	"red": Color("#FF0000"),
	"silver": Color("#C0C0C0"),
	"teal": Color("#008080"),
	"white": Color("#FFFFFF"),
	"yellow": Color("#FFFF00"),
	"aliceblue": Color("#F0F8FF"),
	"antiquewhite": Color("#FAEBD7"),
	"aquamarine": Color("#7FFFD4"),
	"beige": Color("#F5F5DC"),
	"bisque": Color("#FFE4C4"),
	"blanchedalmond": Color("#FFEBCD"),
	"blueviolet": Color("#8A2BE2"),
	"brown": Color("#A52A2A"),
	"burlywood": Color("#DEB887"),
	"cadetblue": Color("#5F9EA0"),
	"chartreuse": Color("#7FFF00"),
	"chocolate": Color("#D2691E"),
	"coral": Color("#FF7F50"),
	"cornflowerblue": Color("#6495ED"),
	"cornsilk": Color("#FFF8DC"),
	"crimson": Color("#DC143C"),
	"cyan": Color("#00FFFF"),
	"darkblue": Color("#00008B"),
	"darkcyan": Color("#008B8B"),
	"darkgoldenrod": Color("#B8860B"),
	"darkgray": Color("#A9A9A9"),
	"darkgreen": Color("#006400"),
	"darkkhaki": Color("#BDB76B"),
	"darkmagenta": Color("#8B008B"),
	"darkolivegreen": Color("#556B2F"),
	"darkorange": Color("#FF8C00"),
	"darkorchid": Color("#9932CC"),
	"darkred": Color("#8B0000"),
	"darksalmon": Color("#E9967A"),
	"darkseagreen": Color("#8FBC8F"),
	"darkslateblue": Color("#483D8B"),
	"darkslategray": Color("#2F4F4F"),
	"darkturquoise": Color("#00CED1"),
	"darkviolet": Color("#9400D3"),
	"deeppink": Color("#FF1493"),
	"deepskyblue": Color("#00BFFF"),
	"dimgray": Color("#696969"),
	"dodgerblue": Color("#1E90FF"),
	"firebrick": Color("#B22222"),
	"floralwhite": Color("#FFFAF0"),
	"forestgreen": Color("#228B22"),
	"gainsboro": Color("#DCDCDC"),
	"ghostwhite": Color("#F8F8FF"),
	"gold": Color("#FFD700"),
	"goldenrod": Color("#DAA520"),
	"greenyellow": Color("#ADFF2F"),
	"honeydew": Color("#F0FFF0"),
	"hotpink": Color("#FF69B4"),
	"indianred": Color("#CD5C5C"),
	"indigo": Color("#4B0082"),
	"ivory": Color("#FFFFF0"),
	"khaki": Color("#F0E68C"),
	"lavender": Color("#E6E6FA"),
	"lavenderblush": Color("#FFF0F5"),
	"lawngreen": Color("#7CFC00"),
	"lemonchiffon": Color("#FFFACD"),
	"lightblue": Color("#ADD8E6"),
	"lightcoral": Color("#F08080"),
	"lightgoldenrodyellow": Color("#FAFAD2"),
	"lightgreen": Color("#90EE90"),
	"lightgrey": Color("#D3D3D3"),
	"lightpink": Color("#FFB6C1"),
	"lightsalmon": Color("#FFA07A"),
	"lightseagreen": Color("#20B2AA"),
	"lightskyblue": Color("#87CEFA"),
	"lightslategray": Color("#778899"),
	"lightsteelblue": Color("#B0C4DE"),
	"lightyellow": Color("#FFFFE0"),
	"limegreen": Color("#32CD32"),
	"linen": Color("#FAF0E6"),
	"magenta": Color("#FF00FF"),
	"mediumaquamarine": Color("#66CDAA"),
	"mediumblue": Color("#0000CD"),
	"mediumorchid": Color("#BA55D3"),
	"mediumpurple": Color("#9370DB"),
	"mediumseagreen": Color("#3CB371"),
	"mediumslateblue": Color("#7B68EE"),
	"mediumspringgreen": Color("#00FA9A"),
	"mediumturquoise": Color("#48D1CC"),
	"mediumvioletred": Color("#C71585"),
	"midnightblue": Color("#191970"),
	"mintcream": Color("#F5FFFA"),
	"mistyrose": Color("#FFE4E1"),
	"moccasin": Color("#FFE4B5"),
	"navajowhite": Color("#FFDEAD"),
	"navyblue": Color("#9FAFDF"),
	"oldlace": Color("#FDF5E6"),
	"olivedrab": Color("#6B8E23"),
	"orange": Color("#FFA500"),
	"orangered": Color("#FF4500"),
	"orchid": Color("#DA70D6"),
	"palegoldenrod": Color("#EEE8AA"),
	"palegreen": Color("#98FB98"),
	"paleturquoise": Color("#AFEEEE"),
	"palevioletred": Color("#DB7093"),
	"papayawhip": Color("#FFEFD5"),
	"peachpuff": Color("#FFDAB9"),
	"peru": Color("#CD853F"),
	"pink": Color("#FFC0CB"),
	"plum": Color("#DDA0DD"),
	"powderblue": Color("#B0E0E6"),
	"rosybrown": Color("#BC8F8F"),
	"royalblue": Color("#4169E1"),
	"saddlebrown": Color("#8B4513"),
	"salmon": Color("#FA8072"),
	"sandybrown": Color("#FA8072"),
	"seagreen": Color("#2E8B57"),
	"seashell": Color("#FFF5EE"),
	"sienna": Color("#A0522D"),
	"skyblue": Color("#87CEEB"),
	"slateblue": Color("#6A5ACD"),
	"slategray": Color("#708090"),
	"snow": Color("#FFFAFA"),
	"springgreen": Color("#00FF7F"),
	"steelblue": Color("#4682B4"),
	"tan": Color("#008080"),
	"thistle": Color("#D8BFD8"),
	"tomato": Color("#FF6347"),
	"turquoise": Color("#40E0D0"),
	"violet": Color("#EE82EE"),
	"wheat": Color("#F5DEB3"),
	"whitesmoke": Color("#F5F5F5"),
	"yellowgreen": Color("#9ACD32"),
}
