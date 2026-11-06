class_name PickupTableArt
extends Control
var rules: PickupRules
var settings: Dictionary
var clock := 0.0
var felt: Texture2D
var helper_texture: Texture2D
var pickup_pulse := 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if ResourceLoader.exists("res://assets/art/felt.png"):
		felt = load("res://assets/art/felt.png")
	if ResourceLoader.exists("res://assets/art/helper.svg"):
		helper_texture = load("res://assets/art/helper.svg")

func _process(delta: float) -> void:
	clock += delta
	pickup_pulse = maxf(0.0, pickup_pulse - delta * 3.0)
	queue_redraw()

func _draw() -> void:
	if rules == null:
		return
	var rect := Rect2(Vector2.ZERO, size)
	draw_rect(rect, Color("123d30"))
	if felt:
		draw_texture_rect(felt, rect, false, Color(1, 1, 1, 0.92))
	# Brass inlay and felt stitching.
	var inset := rect.grow(-14)
	draw_rect(inset, Color(0.80, 0.66, 0.38, 0.38), false, 2.0)
	draw_rect(inset.grow(-6), Color(0.85, 0.76, 0.52, 0.12), false, 1.0)
	var center := size * Vector2(0.5, 0.47)
	# Purchased racks evolve along the back edge.
	var rack_ranks := rules.r("C01") + rules.r("C02") * 2 + rules.r("C03") * 3 + rules.r("C04") * 4
	var rack_count := mini(8, int(ceil(rack_ranks / 3.0)))
	for i in rack_count:
		var pos := Vector2(40 + i * 54, 34)
		draw_rect(Rect2(pos, Vector2(44, 24)), Color("0a271f"))
		draw_rect(Rect2(pos, Vector2(44, 24)), Color("b58b45"), false, 2.0)
		for j in 4:
			draw_line(pos + Vector2(7 + j * 9, 4), pos + Vector2(7 + j * 9, 20), Color("e8dfc8"), 3.0)
	# Counting rollers appear with deposit upgrades.
	if rules.r("C06") > 0:
		var roller_count := mini(5, 1 + rules.r("C08") + rules.r("C11"))
		for i in roller_count:
			var pos := Vector2(size.x - 70, 50 + i * 30)
			draw_rect(Rect2(pos, Vector2(42, 16)), Color("263b35"))
			draw_rect(Rect2(pos, Vector2(42, 16)), Color("c9a55c"), false, 1.0)
			var shift := fmod(clock * (30 if rules.batch_remaining > 0 else 0), 10)
			for j in 4:
				draw_line(pos + Vector2(4 + j * 10 + shift, 2), pos + Vector2(4 + j * 10 + shift, 14), Color("71877b"), 2.0)
	# Helpers are representative, never one node per card.
	var helpers := mini(11, rules.helper_count())
	for i in helpers:
		var angle := PI * (0.15 + 0.7 * float(i) / maxf(1, helpers - 1))
		var pos := center + Vector2(cos(angle) * size.x * 0.36, sin(angle) * size.y * 0.30)
		if not bool(settings.get("reduced_motion", false)) and rules.free_space() > 0:
			pos.y += sin(clock * 3.0 + i) * 2.0
		if helper_texture:
			draw_texture_rect(helper_texture, Rect2(pos - Vector2(28, 28), Vector2(56, 56)), false)
		else:
			draw_circle(pos, 16, Color("b58b45"))
			draw_circle(pos + Vector2(-5, -2), 3, Color("f4e8bd"))
			draw_circle(pos + Vector2(5, -2), 3, Color("f4e8bd"))
	# Seeker lens.
	if rules.r("S01"):
		var lens := Vector2(size.x - 72, size.y - 76)
		draw_circle(lens, 24, Color(0.15, 0.35, 0.30, 0.8))
		draw_arc(lens, 24, 0, TAU, 40, Color("c9a55c"), 3.0)
		draw_line(lens + Vector2(17, 17), lens + Vector2(34, 34), Color("b58b45"), 7.0)
		draw_string(ThemeDB.fallback_font, lens + Vector2(-12, 6), "S", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("e4c783"))
	# Foil tray.
	if rules.r("V10"):
		draw_rect(Rect2(36, size.y - 76, 72, 36), Color("314b46"))
		draw_rect(Rect2(36, size.y - 76, 72, 36), Color("b9d8d2"), false, 2.0)
	# Central carried stack: readable representative cards plus exact counter in UI.
	var stack := mini(9, int(ceil(rules.carried() / maxf(1.0, rules.capacity() / 9.0))))
	if rules.last_card >= 0:
		stack = maxi(1, stack)
	if stack > 0:
		for i in range(stack - 1, -1, -1):
			var spread := Vector2(i * 3.0 - stack * 1.5, -i * 2.0)
			var card_rect := Rect2(center - Vector2(62, 86) + spread, Vector2(124, 172))
			var identity := rules.last_card if i == 0 else (rules.last_card + i * 7) % 52
			draw_card(card_rect, identity, i == 0 and rules.last_card_foil)
	else:
		var empty := Rect2(center - Vector2(62, 86), Vector2(124, 172))
		draw_rect(empty, Color(0.04, 0.16, 0.12, 0.45))
		draw_rect(empty, Color(0.85, 0.76, 0.52, 0.35), false, 2.0)
		draw_string(ThemeDB.fallback_font, center + Vector2(-38, 6), "PICK UP", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.9, 0.86, 0.72, 0.6))
	if pickup_pulse > 0 and not bool(settings.get("reduced_motion", false)):
		draw_arc(center, 100 + (1 - pickup_pulse) * 30, 0, TAU, 48, Color(0.9, 0.8, 0.5, pickup_pulse * 0.35), 2.0)
	# Deck ring celebration, aggregated even when thousands bind together.
	var deck_age: float = rules.active_time - rules.last_deck_at
	if deck_age >= 0 and deck_age < 1.6 and not bool(settings.get("reduced_motion", false)):
		var alpha := clampf(1.6 - deck_age, 0, 1)
		for i in 52:
			var angle := TAU * i / 52.0 + deck_age * 0.3
			var radius := 150.0 + sin(deck_age / 1.6 * PI) * 35.0
			var pos := center + Vector2(cos(angle), sin(angle)) * radius
			draw_rect(Rect2(pos - Vector2(5, 8), Vector2(10, 16)), Color(0.96, 0.92, 0.80, alpha * 0.8))
	# Suit-themed control lamps communicate owned systems without color alone.
	var roots := ["H01", "D01", "P01", "B01"]
	var symbols := ["♥", "♦", "♠", "♣"]
	for i in 4:
		var pos := Vector2(size.x * 0.32 + i * 58, size.y - 34)
		var owned: bool = rules.r(roots[i]) > 0
		draw_circle(pos, 15, Color(0.03, 0.12, 0.09, 0.8))
		draw_arc(pos, 15, 0, TAU, 24, Color("c9a55c") if owned else Color("496356"), 2.0)
		draw_string(ThemeDB.fallback_font, pos + Vector2(-8, 6), symbols[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("f0e6cc") if owned else Color("6f8377"))

func draw_card(rect: Rect2, identity: int, foil: bool) -> void:
	var high := bool(settings.get("high_contrast", false))
	var paper := Color("ffffff") if high else Color("f7f1df")
	var suit := identity / 13
	var red := suit < 2
	var ink := Color("9d2018") if red else Color("101815")
	if high:
		ink = Color("b00000") if red else Color("000000")
	draw_rect(Rect2(rect.position + Vector2(4, 6), rect.size), Color(0, 0, 0, 0.28))
	draw_rect(rect, paper)
	draw_rect(rect, Color("c9a55c") if foil else Color("d8cfb8"), false, 2.0 if foil else 1.0)
	if foil and not bool(settings.get("reduced_motion", false)):
		var shine := 0.10 + 0.08 * sin(clock * 2.0)
		draw_rect(rect.grow(-3), Color(0.45, 0.85, 0.80, shine))
	var font := ThemeDB.fallback_font
	var rank: String = PickupRules.RANK_NAMES[identity % 13]
	var symbol: String = PickupRules.SUIT_SYMBOLS[suit]
	draw_string(font, rect.position + Vector2(9, 25), rank, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, ink)
	draw_string(font, rect.position + Vector2(9, 45), symbol, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, ink)
	draw_string(font, rect.position + Vector2(rect.size.x * 0.5 - 18, rect.size.y * 0.62), symbol, HORIZONTAL_ALIGNMENT_LEFT, -1, 46, ink)
	draw_string(font, rect.position + Vector2(rect.size.x - 28, rect.size.y - 12), rank, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, ink)
	if foil:
		draw_string(font, rect.position + Vector2(rect.size.x - 42, 20), "F", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("7a5b16"))
