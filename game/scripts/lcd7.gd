extends Control
# The HX-7's backlit seven-segment display: lit segments over faint unlit ones (the ghost "888.8" of a real LCD),
# a slight italic slant, the band name and a ten-step signal meter. Drawn into the receiver's screen texture.
var text := "089.1"
var band := ""
var bars := 0.0
var font: Font
const SEG = {"0": "abcdef", "1": "bc", "2": "abged", "3": "abgcd", "4": "fgbc", "5": "afgcd", "6": "afgedc", "7": "abc",
	"8": "abcdefg", "9": "abcdfg", "-": "g", " ": ""}
const LIT = Color(0.56, 1.0, 0.6)
const DIM = Color(0.1, 0.2, 0.1)
const BG = Color(0.035, 0.075, 0.035)

func _draw():
	draw_rect(Rect2(Vector2(), rect_size), BG)
	draw_rect(Rect2(Vector2(6, 6), rect_size - Vector2(12, 12)), Color(0.05, 0.11, 0.05))     # backlight panel
	var x = 30.0; var y = 20.0; var w = 64.0; var h = 116.0; var t = 13.0
	var shown = text if text.length() >= 5 else text.pad_zeros(5)
	for ch in shown:
		if ch == ".":
			draw_circle(Vector2(x - 8 + 2, y + h - t * 0.5), 7.5, LIT); x += 6; continue
		for s in "abcdefg":
			_seg(s, x, y, w, h, t, LIT if s in SEG.get(ch, "") else DIM)
		x += w + 22
	if font:
		draw_string(font, Vector2(390, 132), "MHz", Color(0.4, 0.85, 0.46))
		draw_string(font, Vector2(30, 182), band, LIT if band != "" else DIM)
	for i in 10:
		var on = bars * 10.0 > i + 0.2
		draw_rect(Rect2(310 + i * 18, 196 - i * 3, 12, 8 + i * 3), LIT if on else DIM)

func _slant(p: Vector2, y0: float, h: float) -> Vector2:
	return Vector2(p.x + (y0 + h - p.y) * 0.1, p.y)

func _bar(a: Vector2, b: Vector2, t: float, horiz: bool, y0: float, h: float, c: Color):
	var pts = PoolVector2Array()
	if horiz:
		pts = PoolVector2Array([a + Vector2(t * 0.5, 0), b + Vector2(-t * 0.5, 0), b + Vector2(0, t * 0.5), b + Vector2(-t * 0.5, t), a + Vector2(t * 0.5, t), a + Vector2(0, t * 0.5)])
	else:
		pts = PoolVector2Array([a + Vector2(0, t * 0.5), a + Vector2(t * 0.5, 0), a + Vector2(t, t * 0.5), b + Vector2(t, -t * 0.5), b + Vector2(t * 0.5, 0), b + Vector2(0, -t * 0.5)])
	var out = PoolVector2Array()
	for p in pts: out.append(_slant(p, y0, h))
	draw_colored_polygon(out, c)

func _seg(s: String, x: float, y: float, w: float, h: float, t: float, c: Color):
	var g = 2.5   # gap between segments
	match s:
		"a": _bar(Vector2(x + g, y), Vector2(x + w - g, y), t, true, y, h, c)
		"g": _bar(Vector2(x + g, y + h * 0.5 - t * 0.5), Vector2(x + w - g, y + h * 0.5 - t * 0.5), t, true, y, h, c)
		"d": _bar(Vector2(x + g, y + h - t), Vector2(x + w - g, y + h - t), t, true, y, h, c)
		"f": _bar(Vector2(x, y + g), Vector2(x, y + h * 0.5 - g), t, false, y, h, c)
		"e": _bar(Vector2(x, y + h * 0.5 + g), Vector2(x, y + h - g), t, false, y, h, c)
		"b": _bar(Vector2(x + w - t, y + g), Vector2(x + w - t, y + h * 0.5 - g), t, false, y, h, c)
		"c": _bar(Vector2(x + w - t, y + h * 0.5 + g), Vector2(x + w - t, y + h - g), t, false, y, h, c)
