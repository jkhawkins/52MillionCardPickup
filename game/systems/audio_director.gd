class_name PickupAudioDirector
extends Node
## Original synthesized stems; layers follow owned systems, never card milestones.
var settings: Dictionary
var effects: Array[AudioStreamPlayer] = []
var ui_players: Array[AudioStreamPlayer] = []
var music: Array[AudioStreamPlayer] = []
var ambience: AudioStreamPlayer
var count_player: AudioStreamPlayer
var effect_index := 0
var ui_index := 0
var count_clock := 0.0
var helper_clock := 0.0
var last_deck := -100.0
var streams: Dictionary = {}

func setup(config: Dictionary) -> void:
	settings = config
	for key in ["pickup", "deposit", "deck", "foil", "buy", "ability", "lucky", "block", "ui", "helper"]:
		var path := "res://assets/audio/%s.wav" % key
		if ResourceLoader.exists(path):
			streams[key] = load(path)
	for i in 8:
		var p := AudioStreamPlayer.new()
		add_child(p)
		effects.append(p)
	for i in 3:
		var p := AudioStreamPlayer.new()
		add_child(p)
		ui_players.append(p)
	for key in ["music_base", "music_helpers", "music_seekers", "music_suits"]:
		var p := AudioStreamPlayer.new()
		add_child(p)
		var path := "res://assets/audio/%s.wav" % key
		if ResourceLoader.exists(path):
			p.stream = load(path)
			if p.stream is AudioStreamWAV:
				p.stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
				p.stream.loop_begin = 0
				p.stream.loop_end = int(p.stream.get_length() * p.stream.mix_rate)
			p.play()
		music.append(p)
	ambience = AudioStreamPlayer.new()
	add_child(ambience)
	if ResourceLoader.exists("res://assets/audio/ambience.wav"):
		ambience.stream = load("res://assets/audio/ambience.wav")
		if ambience.stream is AudioStreamWAV:
			ambience.stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
			ambience.stream.loop_begin = 0
			ambience.stream.loop_end = int(ambience.stream.get_length() * ambience.stream.mix_rate)
		ambience.play()
	count_player = AudioStreamPlayer.new()
	add_child(count_player)
	apply_settings(settings)

func apply_settings(config: Dictionary) -> void:
	settings = config
	for p in music:
		p.volume_db = linear_to_db(maxf(0.0001, float(settings.music_volume))) if float(settings.music_volume) > 0 else -80.0
	if ambience:
		ambience.volume_db = linear_to_db(maxf(0.0001, float(settings.ambience_volume))) if float(settings.ambience_volume) > 0 else -80.0

func play_effect(key: String, pitch: float = 1.0, volume: float = 1.0) -> void:
	if not streams.has(key) or float(settings.effects_volume) <= 0.0:
		return
	var p := effects[effect_index % effects.size()]
	effect_index += 1
	p.stream = streams[key]
	p.pitch_scale = clampf(pitch, 0.5, 2.0)
	p.volume_db = linear_to_db(maxf(0.0001, float(settings.effects_volume) * volume))
	p.play()

func play_ui(key: String = "ui") -> void:
	if not streams.has(key) or float(settings.ui_volume) <= 0.0:
		return
	var p := ui_players[ui_index % ui_players.size()]
	ui_index += 1
	p.stream = streams[key]
	p.volume_db = linear_to_db(maxf(0.0001, float(settings.ui_volume)))
	p.play()

func tick(rules: PickupRules, dt: float, paused: bool) -> void:
	var complexity := 0
	if rules.helper_count() > 0:
		complexity += 1
	if rules.r("S01") or rules.r("V10"):
		complexity += 1
	var suits := int(rules.r("H01") > 0) + int(rules.r("D01") > 0) + int(rules.r("P01") > 0) + int(rules.r("B01") > 0)
	if suits:
		complexity += 1
	for i in music.size():
		var target := float(settings.music_volume) * (0.65 if i == 0 else (0.35 if i <= complexity else 0.0))
		music[i].volume_db = linear_to_db(maxf(0.0001, target)) if target > 0 else -80.0
		music[i].stream_paused = paused
	if ambience:
		ambience.stream_paused = paused
	if paused:
		return
	if rules.batch_remaining > 0:
		count_clock += dt
		var interval := clampf(8.0 / maxf(1.0, rules.deposit_rate()), 0.055, 0.5)
		if count_clock >= interval:
			count_clock = 0.0
			play_effect("deposit", randf_range(0.94, 1.06), 0.32)
	if rules.helper_count() > 0 and rules.free_space() > 0:
		helper_clock += dt
		if helper_clock >= 1.0:
			helper_clock = 0.0
			play_effect("helper", 1.0, 0.12)
	if rules.last_deck_at > last_deck and rules.active_time - rules.last_deck_at < 0.5:
		last_deck = rules.last_deck_at
		play_effect("deck", 1.0, 0.7)
