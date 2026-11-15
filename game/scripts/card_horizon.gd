extends Control
# Chapter-card backdrop: a smouldering red sky over the facility's skyline and a lattice radio mast whose beacon blinks.
# Drawn in code, so it is sharp at any resolution.
var t := 0.0

func _process(dt):
	t += dt; update()

func _draw():
	var s = rect_size
	var u = s.y / 1080.0
	var hz = s.y * 0.8
	for i in 28:                                          # sky: black overhead, burning dull red at the horizon
		var a = float(i) / 28.0; var b = float(i + 1) / 28.0
		var y0 = hz * pow(a, 0.55); var y1 = hz * pow(b, 0.55); var k = pow(b, 3.2)
		draw_rect(Rect2(0, y0, s.x, y1 - y0 + 1), Color(0.015 + 0.3 * k, 0.01 + 0.028 * k, 0.01 + 0.02 * k))
	var ground = Color(0.012, 0.01, 0.01)
	draw_rect(Rect2(0, hz, s.x, s.y - hz), ground)
	var rng = RandomNumberGenerator.new(); rng.seed = 7      # low buildings, a chimney, a water tower
	var x = 0.0
	while x < s.x:
		var w = rng.randf_range(0.03, 0.1) * s.x; var h = rng.randf_range(0.012, 0.055) * s.y
		draw_rect(Rect2(x, hz - h, w + 1, h + 2), ground)
		if rng.randf() < 0.2: draw_rect(Rect2(x + w * 0.4, hz - h - 0.07 * s.y, 0.008 * s.x, 0.07 * s.y), ground)
		x += w
	var mx = s.x * 0.8; var top = s.y * 0.22; var bw = s.x * 0.04; var n = 16
	for i in n:                                           # the mast: a tapering lattice
		var y0 = lerp(hz, top, float(i) / n); var y1 = lerp(hz, top, float(i + 1) / n)
		var w0 = bw * (1.0 - 0.86 * float(i) / n); var w1 = bw * (1.0 - 0.86 * float(i + 1) / n)
		draw_line(Vector2(mx - w0, y0), Vector2(mx - w1, y1), ground, 3.0 * u); draw_line(Vector2(mx + w0, y0), Vector2(mx + w1, y1), ground, 3.0 * u)
		draw_line(Vector2(mx - w0, y0), Vector2(mx + w1, y1), ground, 1.6 * u); draw_line(Vector2(mx + w0, y0), Vector2(mx - w1, y1), ground, 1.6 * u)
		draw_line(Vector2(mx - w1, y1), Vector2(mx + w1, y1), ground, 1.6 * u)
	var tip = Vector2(mx, top - s.y * 0.05)
	draw_line(Vector2(mx, top), tip, ground, 2.0 * u)
	if fmod(t, 1.7) < 0.85:                               # the beacon
		for r in [[30.0, 0.06], [15.0, 0.18], [6.0, 0.6], [3.0, 1.0]]:
			draw_circle(tip, r[0] * u, Color(1.0, 0.12, 0.08, r[1]))
