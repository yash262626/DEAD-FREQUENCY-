extends Control
# Immediate-mode HUD: health/battery/stamina + the handheld radio receiver face.
var ui

func _draw():
	if ui == null or not ui.hud_on or ui.in_cine: return
	var s = rect_size
	var st = ui.stat
	var f = ui.font(13, "m")
	var x = 28.0; var y = s.y - 34.0
	if ui.compact_radio:
		_minimal(s, st, f)
	# flashlight battery
	elif st.light or st.batt < 25:
		draw_string(f, Vector2(x, y), "LIGHT", Color(1, 1, 1, 0.45))
		for i in 5:
			var on = st.batt > i * 20
			draw_rect(Rect2(x + 52 + i * 11, y - 10, 8, 10), Color(0.9, 0.85, 0.6, 0.75 if on else 0.15))
		draw_string(f, Vector2(x + 114, y), "+%d" % st.cells, Color(1, 1, 1, 0.35))
		y -= 20
	if st.hp < 99.5:
		draw_string(f, Vector2(x, y), "VITAL", Color(1, 1, 1, 0.45))
		draw_rect(Rect2(x + 52, y - 9, 100, 7), Color(1, 1, 1, 0.12))
		draw_rect(Rect2(x + 52, y - 9, st.hp, 7), Color(0.75, 0.2, 0.15, 0.85))
		y -= 20
	if st.stam < 99.0:
		draw_rect(Rect2(s.x / 2 - 60, s.y - 22, 120, 3), Color(1, 1, 1, 0.1))
		draw_rect(Rect2(s.x / 2 - 60, s.y - 22, 1.2 * st.stam, 3), Color(1, 1, 1, 0.5))
	var r = ui.radio_state
	if not r.on or ui.compact_radio: return
	# radio receiver face
	var w = 330.0; var h = 150.0
	var o = Vector2(s.x - w - 26, s.y - h - 26)
	draw_rect(Rect2(o, Vector2(w, h)), Color(0.07, 0.075, 0.07, 0.95))
	draw_rect(Rect2(o, Vector2(w, h)), Color(0.35, 0.36, 0.33), false, 2.0)
	draw_rect(Rect2(o + Vector2(12, 12), Vector2(w - 24, 62)), Color(0.02, 0.05, 0.03))
	# dial scale 87.5 .. 108.0
	var x0 = o.x + 22; var x1 = o.x + w - 22; var yy = o.y + 60
	for i in range(0, 206, 5):
		var fx = lerp(x0, x1, i / 205.0)
		var major = i % 25 == 0
		draw_line(Vector2(fx, yy), Vector2(fx, yy - (12 if major else 6)), Color(0.5, 0.9, 0.6, 0.7), 1.0)
	for mk in [88, 92, 96, 100, 104, 108]:
		draw_string(f, Vector2(lerp(x0, x1, (mk - 87.5) / 20.5) - 9, o.y + 34), str(mk), Color(0.5, 0.9, 0.6, 0.6))
	var nx = lerp(x0, x1, (r.f - 87.5) / 20.5)
	draw_line(Vector2(nx, o.y + 16), Vector2(nx, o.y + 72), Color(1.0, 0.3, 0.2), 2.0)
	var bf = ui.font(26, "m")
	draw_string(bf, o + Vector2(14, 108), "%05.1f MHz" % r.f, Color(0.6, 1.0, 0.7))
	draw_string(f, o + Vector2(14, 132), r.band, Color(0.9, 0.85, 0.6, 0.9))
	# signal bars
	for i in 8:
		var on = r.sig * 8.0 > i
		draw_rect(Rect2(o.x + 196 + i * 10, o.y + 108 - i * 3 - 6, 7, i * 3 + 6), Color(0.6, 1.0, 0.7, 0.9 if on else 0.15))
	# battery
	draw_rect(Rect2(o.x + 284, o.y + 86, 30, 14), Color(1, 1, 1, 0.5), false, 1.0)
	draw_rect(Rect2(o.x + 286, o.y + 88, 26 * r.batt / 100.0, 10), Color(0.9, 0.85, 0.6, 0.8) if r.batt > 20 else Color(0.9, 0.2, 0.15, 0.9))
	# exposure lamp: the more the Listener can hear you, the brighter it burns
	draw_circle(o + Vector2(w - 22, 100 - 78), 5, Color(1.0, 0.15, 0.1, 0.15 + 0.85 * r.danger))

func _minimal(s, st, f):
	# high-quality levels (the reference's clean HUD): bottom right, a torch, its battery and charge; the receiver's
	# own charge while it is on (its frequency is on the set in Daniel's hand)
	var x = s.x - 168.0; var y = s.y - 34.0
	var r = ui.radio_state
	if r.on and r.batt < 100.0:
		draw_string(f, Vector2(x, y - 26), "HX-7  %d%%" % int(round(r.batt)), Color(0.6, 1.0, 0.7, 0.6))
	if not (st.light or st.batt < 25): return
	var c = Color(1, 1, 1, 0.55)
	draw_rect(Rect2(x, y - 10, 18, 7), c)                                    # torch: barrel and head
	draw_colored_polygon(PoolVector2Array([Vector2(x + 18, y - 12), Vector2(x + 26, y - 14), Vector2(x + 26, y + 1), Vector2(x + 18, y - 1)]), c)
	var bx = x + 40
	draw_rect(Rect2(bx, y - 13, 36, 15), c, false, 1.2)
	draw_rect(Rect2(bx + 36, y - 9, 3, 7), c)
	var k = clamp(st.batt / 100.0, 0.0, 1.0)
	draw_rect(Rect2(bx + 2, y - 11, 32 * k, 11), Color(0.92, 0.9, 0.82, 0.8) if st.batt > 20 else Color(0.9, 0.2, 0.15, 0.9))
	draw_string(f, Vector2(bx + 48, y), "%d%%" % int(round(st.batt)), Color(1, 1, 1, 0.6))
	if st.cells > 0: draw_string(f, Vector2(bx + 92, y), "+%d" % st.cells, Color(1, 1, 1, 0.35))
