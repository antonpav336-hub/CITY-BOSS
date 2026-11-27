extends Node
## Minimal versioned local save manager. Add domain data as systems arrive.
const SAVE_PATH := "user://city_boss_save.json"
const SAVE_VERSION := 1

func save_game(data: Dictionary) -> bool:
	var payload := {"version": SAVE_VERSION, "data": data}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Cannot open save file for writing: %s" % FileAccess.get_open_error())
		return false
	file.store_string(JSON.stringify(payload))
	return true

func load_game() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return {}
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_error("Cannot open save file for reading.")
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("Save file is invalid; starting a new game.")
		return {}
	if int(parsed.get("version", 0)) > SAVE_VERSION:
		push_warning("Save file was created by a newer game version.")
		return {}
	var data: Variant = parsed.get("data", {})
	return data if typeof(data) == TYPE_DICTIONARY else {}
