class_name PickupPersistence
extends RefCounted
## Atomic local saves with a last-known-good backup. Never awards closed time.
const SAVE_PATH := "user://save.json"
const BACKUP_PATH := "user://save.backup.json"
const TEMP_PATH := "user://save.tmp"
const SETTINGS_PATH := "user://settings.json"

static func save_game(rules: PickupRules) -> bool:
	var payload := JSON.stringify(rules.to_dict())
	var file := FileAccess.open(TEMP_PATH, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(payload)
	file.flush()
	file.close()
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.copy_absolute(SAVE_PATH, BACKUP_PATH)
	var err := DirAccess.rename_absolute(TEMP_PATH, SAVE_PATH)
	return err == OK

static func load_game(rules: PickupRules) -> String:
	for path in [SAVE_PATH, BACKUP_PATH]:
		if not FileAccess.file_exists(path):
			continue
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
		if parsed is Dictionary and rules.load_dict(parsed):
			return "restored" if path == SAVE_PATH else "backup"
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.copy_absolute(SAVE_PATH, "user://save.invalid.json")
		return "invalid"
	return "new"

static func default_settings() -> Dictionary:
	return {"hold_to_pickup": true, "reduced_motion": false, "high_contrast": false,
		"floating_numbers": "aggregated", "exact_numbers": false, "new_affordable_indicator": true,
		"ui_scale": 1.0, "music_volume": 0.45, "ambience_volume": 0.35, "effects_volume": 0.65, "ui_volume": 0.55,
		"bindings": {"pickup": [KEY_SPACE, MOUSE_BUTTON_LEFT], "deposit": [KEY_D], "ledger": [KEY_L],
			"upgrades": [KEY_U], "pause": [KEY_ESCAPE], "ability_1": [KEY_1], "ability_2": [KEY_2],
			"ability_3": [KEY_3], "ability_4": [KEY_4], "ability_5": [KEY_5]}}

static func load_settings() -> Dictionary:
	var result := default_settings()
	if FileAccess.file_exists(SETTINGS_PATH):
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(SETTINGS_PATH))
		if parsed is Dictionary:
			for key in parsed:
				if key == "bindings" and parsed[key] is Dictionary:
					for action in result.bindings:
						if parsed[key].has(action) and parsed[key][action] is Array and not parsed[key][action].is_empty():
							var values: Array = []
							for v in parsed[key][action]:
								values.append(int(v))
							result.bindings[action] = values
				elif result.has(key) and typeof(parsed[key]) == typeof(result[key]):
					result[key] = parsed[key]
				elif result.has(key) and result[key] is float and (parsed[key] is float or parsed[key] is int):
					result[key] = float(parsed[key])
	result.ui_scale = clampf(float(result.ui_scale), 0.85, 1.35)
	for key in ["music_volume", "ambience_volume", "effects_volume", "ui_volume"]:
		result[key] = clampf(float(result[key]), 0.0, 1.0)
	return result

static func save_settings(settings: Dictionary) -> bool:
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(settings, "\t"))
	file.close()
	return true

static func event_code(event: InputEvent) -> int:
	if event is InputEventKey:
		return int(event.physical_keycode if event.physical_keycode != 0 else event.keycode)
	if event is InputEventMouseButton:
		return int(event.button_index)
	return 0

static func event_from_code(code: int) -> InputEvent:
	if code >= MOUSE_BUTTON_LEFT and code <= MOUSE_BUTTON_XBUTTON2:
		var mouse := InputEventMouseButton.new()
		mouse.button_index = code
		return mouse
	var key := InputEventKey.new()
	key.physical_keycode = code
	return key

static func code_label(code: int) -> String:
	if code >= MOUSE_BUTTON_LEFT and code <= MOUSE_BUTTON_XBUTTON2:
		return ["", "Left click", "Right click", "Middle click", "Wheel up", "Wheel down", "Wheel left", "Wheel right", "Mouse 4", "Mouse 5"][code]
	return OS.get_keycode_string(code)

static func apply_bindings(settings: Dictionary) -> void:
	var defaults: Dictionary = default_settings().bindings
	for action in defaults:
		var name: String = "cp_" + action
		if InputMap.has_action(name):
			InputMap.erase_action(name)
		InputMap.add_action(name)
		for code in settings.bindings.get(action, defaults[action]):
			var event := event_from_code(int(code))
			if event:
				InputMap.action_add_event(name, event)
