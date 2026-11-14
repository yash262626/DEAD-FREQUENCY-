extends Node
# Fully procedural audio. Every sound in DEAD FREQUENCY is synthesised here at
# first launch and cached in user://, so the project ships no audio assets.

const RATE := 22050
const CACHE_VER := 4
var bank := {}
var _pool := []
var _loops := {}
var _music_a: AudioStreamPlayer
var _music_name := ""
var _rng := RandomNumberGenerator.new()

func _ready():
	pause_mode = Node.PAUSE_MODE_PROCESS
	_rng.seed = 1998
	for i in 12:
		var p = AudioStreamPlayer.new(); p.bus = "SFX"; add_child(p); _pool.append(p)
	_music_a = AudioStreamPlayer.new(); _music_a.bus = "Music"; add_child(_music_a)
	_build_bank()

# ------------------------------------------------------------ public api
func play(name: String, db := 0.0, pitch := 1.0, bus := "SFX"):
	if not bank.has(name): return null
	for p in _pool:
		if not p.playing:
			p.stream = bank[name]; p.volume_db = db; p.pitch_scale = pitch; p.bus = bus; p.play()
			return p
	return null

func play3d(name: String, parent: Node, pos: Vector3, db := 0.0, pitch := 1.0, maxd := 30.0):
	if not bank.has(name) or parent == null: return null
	var p = AudioStreamPlayer3D.new()
	p.stream = bank[name]; p.unit_db = db; p.pitch_scale = pitch; p.bus = "SFX"
	p.max_distance = maxd; p.unit_size = 3.0
	p.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_SQUARE_DISTANCE
	parent.add_child(p); p.global_transform.origin = pos; p.play()
	if bank[name].loop_mode == AudioStreamSample.LOOP_DISABLED:
		p.connect("finished", p, "queue_free")
	return p

func loop(id: String, name: String, db := 0.0, pitch := 1.0, bus := "SFX"):
	if not bank.has(name): return
	var p
	if _loops.has(id): p = _loops[id]
	else:
		p = AudioStreamPlayer.new(); add_child(p); _loops[id] = p
	p.bus = bus; p.volume_db = db; p.pitch_scale = pitch
	if p.stream != bank[name] or not p.playing:
		p.stream = bank[name]; p.play()

func loop_vol(id: String, db: float, pitch := -1.0):
	if _loops.has(id):
		_loops[id].volume_db = db
		if pitch > 0: _loops[id].pitch_scale = pitch

func unloop(id: String):
	if _loops.has(id):
		_loops[id].stop(); _loops[id].queue_free(); _loops.erase(id)

func stop_all_loops():
	for id in _loops.keys(): unloop(id)

func music(name: String, db := -8.0):
	if name == _music_name: return
	_music_name = name
	if name == "" or not bank.has(name):
		_music_a.stop(); return
	_music_a.stream = bank[name]; _music_a.volume_db = db; _music_a.play()

# ------------------------------------------------------------ synthesis
func _mk(samples: PoolRealArray, looped := false) -> AudioStreamSample:
	var sp = StreamPeerBuffer.new()
	for v in samples:
		sp.put_16(int(clamp(v, -1.0, 1.0) * 32000.0))
	var s = AudioStreamSample.new()
	s.format = AudioStreamSample.FORMAT_16_BITS; s.mix_rate = RATE; s.stereo = false
	s.data = sp.data_array
	if looped:
		s.loop_mode = AudioStreamSample.LOOP_FORWARD; s.loop_begin = 0; s.loop_end = samples.size()
	return s

func _noise(n: int, lp := 1.0, hp := 0.0) -> PoolRealArray:
	# white noise through one-pole low-pass (lp = 0..1 coefficient) and optional high-pass
	var out = PoolRealArray(); out.resize(n)
	var y = 0.0; var z = 0.0
	for i in n:
		var x = _rng.randf_range(-1.0, 1.0)
		y += lp * (x - y)
		z += hp * (y - z)
		out[i] = y - z if hp > 0.0 else y
	return out

func _gen(name: String):
	var T = TAU / RATE
	var o = PoolRealArray()
	var n = 0
	match name:
		"static":
			n = RATE * 2; o = _noise(n, 0.75, 0.2)
			for i in n:
				var c = 1.0 if _rng.randf() < 0.0015 else 0.0
				o[i] = o[i] * 0.55 + c * _rng.randf_range(-0.9, 0.9)
		"hum":
			n = RATE * 2; o.resize(n)
			for i in n:
				o[i] = 0.30 * sin(50 * T * i) + 0.18 * sin(100 * T * i) + 0.08 * sin(150 * T * i) + 0.03 * sin(400 * T * i)
		"drone_a", "drone_b", "drone_c", "drone_d":
			n = RATE * 8; o.resize(n)
			var fr = {"drone_a": [55.0, 55.75, 82.5, 110.25], "drone_b": [46.25, 49.0, 92.5, 138.75],
				"drone_c": [110.0, 164.75, 220.25, 329.5], "drone_d": [36.75, 55.0, 73.5, 77.875]}[name]
			var nz = _noise(n, 0.02)
			for i in n:
				var t = float(i) / n
				var l1 = 0.5 + 0.5 * sin(TAU * t); var l2 = 0.5 + 0.5 * sin(TAU * t * 3 + 1.3)
				o[i] = 0.22 * sin(fr[0] * T * i) + 0.20 * sin(fr[1] * T * i) + 0.13 * l1 * sin(fr[2] * T * i) \
					+ 0.07 * l2 * sin(fr[3] * T * i) + nz[i] * 1.6 * (0.3 + 0.7 * l2)
		"rain":
			n = RATE * 3; o = _noise(n, 0.5, 0.05)
			for i in n: o[i] *= 0.5
			var k = RATE / 4   # crossfade loop seam
			for i in k:
				var a = float(i) / k
				o[i] = o[i] * a + o[n - k + i] * (1.0 - a)
			o.resize(n - k)
		"thunder":
			n = RATE * 4; o = _noise(n, 0.035)
			for i in n:
				var t = float(i) / RATE
				var e = exp(-t * 0.9) * (0.6 + 0.4 * sin(t * 9.0) * sin(t * 2.3)) * min(1.0, t * 20)
				o[i] = clamp(o[i] * 9.0 * e, -1, 1)
		"step", "step_wet":
			n = int(RATE * (0.16 if name == "step" else 0.35)); o = _noise(n, 0.12 if name == "step" else 0.45, 0.02)
			for i in n:
				var t = float(i) / n
				o[i] = o[i] * (2.2 if name == "step" else 0.9) * exp(-t * (7.0 if name == "step" else 4.0)) * min(1.0, t * 40)
		"door":
			n = int(RATE * 1.1); o.resize(n); var nz2 = _noise(n, 0.08)
			var ph = 0.0
			for i in n:
				var t = float(i) / n
				ph += T * (90.0 + 60.0 * t + 14.0 * sin(t * 40))
				var rumble = nz2[i] * 2.5 * sin(PI * min(1.0, t * 1.25))
				var thud = sin(60 * T * i) * exp(-max(0.0, t - 0.8) * 30) * (1.0 if t > 0.8 else 0.0)
				o[i] = 0.12 * sin(ph) * sin(PI * t) + rumble * 0.6 + thud * 0.7
		"locked":
			n = int(RATE * 0.4); o.resize(n); var nz3 = _noise(n, 0.5)
			for i in n:
				var t = float(i) / RATE
				var e = exp(-t * 60) + (exp(-(t - 0.16) * 60) if t > 0.16 else 0.0)
				o[i] = (nz3[i] * 0.8 + 0.4 * sin(300 * T * i)) * e
		"click":
			n = int(RATE * 0.05); o = _noise(n, 0.6)
			for i in n: o[i] *= exp(-float(i) / n * 9)
		"beep", "beep_hi":
			n = int(RATE * 0.09); o.resize(n); var f = 880.0 if name == "beep" else 1760.0
			for i in n: o[i] = 0.4 * sin(f * T * i) * sin(PI * float(i) / n)
		"pickup":
			n = int(RATE * 0.25); o.resize(n)
			for i in n:
				var t = float(i) / n
				o[i] = 0.3 * sin((520.0 if t < 0.5 else 780.0) * T * i) * exp(-fmod(t, 0.5) * 8)
		"impact":
			n = RATE * 4; o.resize(n); var nz4 = _noise(n, 0.05); var ph2 = 0.0
			for i in n:
				var t = float(i) / RATE
				ph2 += T * (30.0 + 50.0 * exp(-t * 6))
				o[i] = clamp(1.4 * sin(ph2) * exp(-t * 1.1) + nz4[i] * 6.0 * exp(-t * 5), -1, 1)
		"glitch":
			n = int(RATE * 0.5); o.resize(n); var cur = 0.0; var fq = 200.0
			for i in n:
				if i % 300 == 0:
					fq = _rng.randf_range(80, 3000); cur = 1.0 if _rng.randf() < 0.7 else 0.0
				var sq = 1.0 if sin(fq * T * i) > 0 else -1.0
				o[i] = cur * (0.25 * sq + 0.25 * _rng.randf_range(-1, 1))
		"voice":
			n = int(RATE * 1.2); o.resize(n); var ph3 = 0.0
			for i in n:
				var t = float(i) / RATE
				var syl = pow(abs(sin(t * 16.5 + 0.8 * sin(t * 5.1))), 1.5)
				var f0 = 118.0 + 22.0 * sin(t * 7.3) + 9.0 * sin(t * 23.0)
				ph3 += T * f0
				var s = 0.0
				for h in range(1, 9):
					var fh = f0 * h
					var g = exp(-pow((fh - 520.0 - 260.0 * sin(t * 9.0)) / 330.0, 2)) + 0.5 * exp(-pow((fh - 1350.0) / 500.0, 2))
					s += g * sin(ph3 * h)
				o[i] = 0.34 * s * syl
			var k2 = 400
			for i in k2:
				o[i] *= float(i) / k2; o[n - 1 - i] *= float(i) / k2
		"whisper":
			n = int(RATE * 2.0); o = _noise(n, 0.5, 0.15)
			for i in n:
				var t = float(i) / RATE
				o[i] *= 1.4 * pow(abs(sin(t * 11.0 + sin(t * 3.0))), 2.0) * sin(PI * float(i) / n)
		"heart":
			n = RATE; o.resize(n)
			for i in n:
				var t = float(i) / RATE
				var e = exp(-t * 22) + (0.7 * exp(-(t - 0.28) * 22) if t > 0.28 else 0.0)
				o[i] = 0.9 * sin(52 * T * i) * e
		"drip":
			n = int(RATE * 0.2); o.resize(n); var ph4 = 0.0
			for i in n:
				var t = float(i) / n
				ph4 += T * (1500.0 - 700.0 * t)
				o[i] = 0.3 * sin(ph4) * exp(-t * 9)
		"clicks":
			n = int(RATE * 2.0); o.resize(n); var nx = 0; var e2 = 0.0
			for i in n:
				if i >= nx:
					e2 = 1.0; nx = i + int(_rng.randf_range(0.02, 0.22) * RATE)
				e2 *= 0.985
				o[i] = e2 * 0.6 * sin(1900 * T * i + 3.0 * sin(210 * T * i))
			for i in 300: o[n - 1 - i] *= float(i) / 300
		"screech":
			n = int(RATE * 1.6); o.resize(n); var ph5 = 0.0; var nz5 = _noise(n, 0.6, 0.1)
			for i in n:
				var t = float(i) / n
				ph5 += T * (500.0 + 900.0 * t + 180.0 * sin(float(i) * T * 37))
				o[i] = (0.35 * sin(ph5 + 2.5 * sin(ph5 * 0.51)) + 0.3 * nz5[i]) * sin(PI * t)
		"alarm":
			n = RATE; o.resize(n)
			for i in n:
				var f2 = 620.0 if i < n / 2 else 466.0
				o[i] = 0.16 * (1.0 if sin(f2 * T * i) > 0 else -1.0) * (0.6 + 0.4 * sin(TAU * 2 * float(i) / n))
		"breath":
			n = int(RATE * 2.8); o = _noise(n, 0.18, 0.02)
			for i in n:
				var t = float(i) / n
				o[i] *= 2.5 * pow(sin(PI * t), 2) * (0.6 + 0.4 * sin(TAU * t - 1.0))
		"tune":
			n = int(RATE * 0.12); o = _noise(n, 0.8, 0.3)
			for i in n: o[i] *= 0.5 * sin(PI * float(i) / n)
		"power_down", "power_up":
			n = int(RATE * 2.0); o.resize(n); var ph6 = 0.0
			for i in n:
				var t = float(i) / n
				var tt = t if name == "power_up" else 1.0 - t
				ph6 += T * (30.0 + 190.0 * tt * tt)
				o[i] = 0.45 * sin(ph6) * (0.4 + 0.6 * tt) * min(1.0, (1.0 - t) * 8) * min(1.0, t * 30) + 0.1 * sin(ph6 * 3.01) * tt
		"metal":
			n = int(RATE * 1.4); o.resize(n)
			for i in n:
				var t = float(i) / RATE
				o[i] = (0.3 * sin(431 * T * i) + 0.2 * sin(1123 * T * i) + 0.15 * sin(1877 * T * i) + 0.1 * sin(2954 * T * i)) * exp(-t * 4.5)
		"splash":
			n = int(RATE * 0.6); o = _noise(n, 0.4, 0.03)
			for i in n:
				var t = float(i) / n
				o[i] *= 1.2 * exp(-t * 5) * min(1.0, t * 30)
		"knock":
			n = int(RATE * 3.2); o.resize(n); var nzk = _noise(n, 0.15)
			for i in n:
				var t = float(i) / RATE; var e3 = 0.0
				for k in [0.0, 0.32, 0.64]:
					if t >= k: e3 += exp(-(t - k) * 38.0)
				o[i] = (0.9 * sin(95 * T * i) + nzk[i] * 1.5) * e3 * 0.8
		"tram":
			n = RATE * 2; o = _noise(n, 0.06)
			for i in n:
				o[i] = o[i] * 3.0 * (0.7 + 0.3 * sin(TAU * 4 * float(i) / n)) + 0.15 * sin(70 * T * i)
	return _mk(o, name in ["static", "hum", "drone_a", "drone_b", "drone_c", "drone_d", "rain", "heart", "clicks", "alarm", "breath", "tram", "knock"])

const NAMES = ["static", "hum", "drone_a", "drone_b", "drone_c", "drone_d", "rain", "thunder", "step", "step_wet",
	"door", "locked", "click", "beep", "beep_hi", "pickup", "impact", "glitch", "voice", "whisper", "heart", "drip",
	"clicks", "screech", "alarm", "breath", "tune", "power_down", "power_up", "metal", "splash", "tram", "knock"]

func _build_bank():
	var dir = Directory.new()
	var cdir = "user://snd_v%d" % CACHE_VER
	if not dir.dir_exists(cdir): dir.make_dir_recursive(cdir)
	for nm in NAMES:
		var path = "%s/%s.res" % [cdir, nm]
		var s = null
		if ResourceLoader.exists(path): s = ResourceLoader.load(path)
		if s == null:
			s = _gen(nm)
			ResourceSaver.save(path, s)
		bank[nm] = s
