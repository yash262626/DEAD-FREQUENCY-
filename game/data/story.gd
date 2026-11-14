extends Node
# Story registry: chapters, endings, credits, items, achievements.

const TITLES = ["PROLOGUE", "THE ARRIVAL", "THE SILENT WING", "WHAT REMAINS", "BELOW THE SURFACE", "THE VOICES", "NO WAY BACK",
	"THE SIGNAL ROOM", "THE ECHO PROJECT", "DEAD LINE", "WHAT LISTENS", "EVERY VOICE EVER LOST", "02:43", "THE LAST TRANSMISSION"]

const ITEMS = {
	"battery": "Power cell", "medkit": "Medkit", "bottle": "Glass bottle", "radio": "HX-7 field receiver",
	"fuse": "Ceramic fuse", "comms_key": "Comms annex keycard", "med_key": "Medical wing keycard", "res_key": "Quarters master key",
	"valve": "Valve wheel", "crank": "Hand crank", "lab_key": "Research keycard", "tram_fuse": "Traction fuse",
	"hale_badge": "Hale's security badge", "shutdown_key": "Dr. Voss's shutdown key", "archive_key": "Archive keycard",
	"crystal": "Tuning crystal", "tape_reel": "Unlabelled tape reel", "fluid": "Hydraulic fluid",
}

const ACH = {
	"first_signal": "First Contact — receive your first transmission",
	"title2": "Already Inside — reach the communications annex",
	"seen": "It Has No Face — survive the first sighting",
	"door_closed": "Good Listener — leave the door in the quarters shut",
	"all_tapes": "Her Voice — find every recording by Dr. Voss",
	"hale": "The Man at the Door — hear Marcus Hale's last tape",
	"unseen": "107.9 — reveal ten hidden things",
	"no_hunt": "Quiet Feet — finish a chapter without being hunted",
	"end_A": "Ending — Silence", "end_B": "Ending — The Open Door", "end_C": "Ending — The Loop", "end_D": "Ending — The Last Transmission",
	"all_endings": "The Signal Never Ends — see all four endings",
}

# Exact names and roles supplied by the project owner.
const CREDITS = [
	["gap", "40"], ["title", "DEAD FREQUENCY"], ["gap", "120"],
	["head", "GAME DEVELOPMENT"], ["role", "Developed by"], ["name", "YASH AIL"], ["gap", "90"],
	["head", "SOUND DESIGN & AUDIO"], ["role", "Sound Effects by"], ["name", "AJAY GOHIL"], ["gap", "90"],
	["head", "ADDITIONAL GAME DEVELOPMENT"], ["gap", "10"],
	["role", "Game Design & Creative Support"], ["name", "ADARSH GUPTA"], ["gap", "40"],
	["role", "Gameplay Testing & Quality Assurance"], ["name", "TANISH SHETTY"], ["gap", "40"],
	["role", "Environment Design & Production Support"], ["name", "SHUBHAM GAONKAR"], ["gap", "420"],
	["title", "DEAD FREQUENCY"], ["line", "A game developed by YASH AIL"], ["gap", "60"],
	["line", "THANK YOU FOR PLAYING."], ["gap", "20"], ["line", "THE SIGNAL NEVER ENDS."], ["gap", "20"],
]

func chapter_title(n: int) -> String:
	return TITLES[n]

func chapter(n: int) -> Dictionary:
	var d = load("res://data/ch%02d.gd" % n).DATA.duplicate(true)
	d["n"] = n; d["title"] = TITLES[n]
	return d

func ending(id: String) -> Dictionary:
	var d = load("res://data/endings.gd").DATA[id].duplicate(true)
	d["n"] = 14; d["title"] = "ENDING " + id
	return d
