class_name PickupSteamBridge
extends RefCounted
## Optional GodotSteam adapter. The standalone build has no SDK dependency.
## Install a GodotSteam build/GDExtension matching the engine, set data/steam.json,
## and export with the Steam feature tag. Never put partner credentials here.
var available := false
var steam: Object = null
var app_id := 0
var mapping: Dictionary = {}
var pending: Array[String] = []

func _init() -> void:
	if FileAccess.file_exists("res://data/steam.json"):
		var config = JSON.parse_string(FileAccess.get_file_as_string("res://data/steam.json"))
		if config is Dictionary and bool(config.get("enabled", false)):
			app_id = int(config.get("app_id", 0))
			mapping = config.get("achievements", {})
	if app_id <= 0 or not Engine.has_singleton("Steam"):
		return
	steam = Engine.get_singleton("Steam")
	if steam == null or not steam.has_method("steamInitEx"):
		steam = null
		return
	var response = steam.call("steamInitEx", app_id, true)
	if response is Dictionary:
		available = int(response.get("status", 1)) == 0
	else:
		available = bool(response)
	if not available:
		push_warning("Steam unavailable; continuing with local achievements.")

func unlock(local_id: String) -> void:
	var api_name := str(mapping.get(local_id, ""))
	if api_name.is_empty():
		return
	if not available:
		if not pending.has(api_name):
			pending.append(api_name)
		return
	_set_achievement(api_name)

func _set_achievement(api_name: String) -> void:
	if steam and steam.has_method("setAchievement"):
		steam.call("setAchievement", api_name)
		if steam.has_method("storeStats"):
			steam.call("storeStats")

func tick() -> void:
	if available and steam and steam.has_method("run_callbacks"):
		steam.call("run_callbacks")
		if not pending.is_empty():
			for name in pending:
				_set_achievement(name)
			pending.clear()

func shutdown() -> void:
	if available and steam and steam.has_method("steamShutdown"):
		steam.call("steamShutdown")
