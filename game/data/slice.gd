extends Reference
# VERTICAL SLICE — the visual target for the production upgrade (docs/21_VISUAL_AUDIT_AND_VERTICAL_SLICE.md).
# Sublevel 3: the service corridor and the communications room C3-14. The art is an authored scene with baked
# lighting (res://slice/Slice.tscn, built by slice/build_slice.gd); this file is the gameplay on the usual 2 m
# grid, so the player, radio and Listener systems drive it unchanged. "hq" switches on the new first-person
# models and the new Listener.
const N := 99
const DATA = {
	"pal": "comms", "h": 3.8, "art": "res://slice/Slice.tscn", "hq": true, "face": 0,
	"sub": "SUBLEVEL 3 — COMMUNICATIONS", "card_top": "VERTICAL SLICE",
	"music": "drone_c", "amb_loop": "hum", "amb_db": -28.0,
	"map": [
		"###################",
		"##########......k##",
		"##########......k##",
		"##...v.e....uU..k##",
		"##.#######......k##",
		"##.#######...H..k##",
		"##.################",
		"##f################",
		"##.################",
		"##t################",
		"##S################",
		"###################",
	],
	"leg": {
		"t": {"t": "trig", "ev": [
			["DANIEL", "C3-14. If the main receiver down here still works, I can hear what this place heard."],
			["obj", "Find the communications room, C3-14."],
		]},
		"f": {"t": "radio", "f": 101.3, "r": 9.0, "title": "Forecast", "flag": "sl_fore", "lines": [
			["DANIEL? (101.3 MHz)", "When the red light comes on, get under the desk by the south wall. Don't move. Don't breathe."],
			["DANIEL", "...That's my voice."],
		]},
		"e": {"t": "radio", "f": 89.1, "r": 8.0, "title": "Corridor, 1998", "flag": "sl_echo", "lines": [
			["RUIZ (1998)", "Somebody's been in the vent again. The grille's on the floor."],
			["OKAFOR (1998)", "Leave it. Nobody goes in the ducts. Nobody fits in the ducts."],
		]},
		"U": {"t": "use", "p": "console", "noviz": true, "block": true, "prompt": "Power up the main receiver", "size": Vector3(1.2, 1.4, 2.6), "ev": [
			["cine", true], ["sfx", "power_up", 0], ["wait", 1.2],
			["radio_on", true, 89.1], ["loop", "rx", "static", -22], ["wait", 1.0],
			["EVELYN (89.1 MHz)", "If anyone finds this console still running: don't answer it. Whatever calls you on this band is not who it sounds like."],
			["EVELYN (89.1 MHz)", "It doesn't hear our voices. It hears the carrier. Every time we key a transmitter, it learns where we are."],
			["DANIEL", "Evelyn Voss. October '98."],
			["sfx", "glitch", 0], ["art", "energy", "TrofferFlicker", 0.0], ["art", "on", "Beacon"], ["shake", 0.4],
			["unloop", "rx"], ["radio_on", false], ["wait", 0.8],
			["sfx", "metal", 2, 0.6, "v"], ["wait", 1.2],
			["DANIEL", "...Something's in the vent."],
			["listener", "spawn", "v", "watch"], ["cine", false],
			["obj", "Hide under the desk by the south wall. Stay silent."],
			["wait", 2.5], ["listener", "seek", "u"],
			["wait", 34.0],
			["listener", "goto", "v"], ["wait", 9.0], ["listener", "despawn"], ["art", "off", "Beacon"],
			["DANIEL", "...It's gone back up. For now."], ["wait", 1.5],
			["fade", true, 2.0], ["text", "END OF THE VERTICAL SLICE", 4.0], ["menu"],
		]},
		"H": {"t": "hide", "noviz": true, "low": true, "eye": 0.6, "block": true, "prompt": "Hide under the desk", "out": "Come out", "rot": 0, "off": [0.5, 0.3]},
		"v": {"t": "mark"}, "u": {"t": "mark"},
		"k": {"t": "mark", "block": true},
	},
	"start_ev": [
		["music", "drone_c", -14], ["wait", 0.5],
		["DANIEL", "Sublevel three. Everything down here still smells like it's running."],
		["obj", "Find the communications room, C3-14."],
	],
}
