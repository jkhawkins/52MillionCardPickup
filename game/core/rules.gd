class_name PickupRules
extends RefCounted
## Deterministic, UI-independent simulation. All counts are 64-bit integers.
## Inventory is aggregated by identity/foil/source/lucky metadata, never scene nodes.
signal notice(text: String, kind: String)
signal achievement_unlocked(id: String)
signal run_completed

const GOAL := 52000000
const SUIT_NAMES := ["Hearts", "Diamonds", "Spades", "Clubs"]
const SUIT_SYMBOLS := ["♥", "♦", "♠", "♣"]
const RANK_NAMES := ["A", "2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K"]
const ABILITY_IDS := ["X01", "X05", "X08", "X11", "X14"]
const ABILITY_NAMES := ["Card Surge", "Express Deposit", "Foil Frenzy", "Seeker Pulse", "Card Cyclone"]
const EVENT_NAMES := ["Card Shower", "Lucky Dealer", "Suit Surge", "Foil Flash", "Deposit Rush", "Second Wind"]
const ACHIEVEMENTS := {
	"one_down": ["One Down", "Deposit the first card."],
	"full_house": ["Full House", "Fill the initial 52-card tray."],
	"worth_the_paper": ["Worth the Paper", "Bind the first deck."],
	"shiny": ["Shiny", "Deposit a foil."],
	"helping_hand": ["Helping Hand", "Hire an auto-picker."],
	"do_it_yourself": ["Do It Yourself", "Deposit 10,000 manually picked cards."],
	"well_oiled_table": ["Well-Oiled Table", "Own four helpers."],
	"counting_excellence": ["Counting Excellence", "Reach 1,000 deposited cards per second."],
	"combo_artist": ["Combo Artist", "Hold maximum Combo for 20 seconds."],
	"lucky_streak": ["Lucky Streak", "Trigger three Lucky pickups in five seconds."],
	"four_suits_one_plan": ["Four Suits, One Plan", "Buy a node in every suit branch."],
	"found_it": ["Found It", "Auto-Seek a missing card."],
	"royal_treatment": ["Royal Treatment", "Deposit 1,000 Kings."],
	"foil_collection": ["Foil Collection", "Deposit 52 foils."],
	"event_regular": ["Event Regular", "Interact with every event type."],
	"millionaire": ["Millionaire", "Deposit 1,000,000 cards."],
	"eight_figures": ["Eight Figures", "Deposit 10,000,000 cards."],
	"the_long_count": ["The Long Count", "Complete a batch of at least 100,000 cards."],
	"fully_equipped": ["Fully Equipped", "Own all five active abilities."],
	"52_million_card_pickup": ["52 Million Card Pickup", "Complete the game."]
}

var catalog: Dictionary = {}
var entries: Array = []
var index: Dictionary = {}
var bands: Dictionary = {}
var balance: Dictionary = {}
var ranks := PackedInt32Array()
var rng := RandomNumberGenerator.new()
var money := 0.0
var earned := 0.0
var spent := 0.0
var deposited := 0
var active_time := 0.0
var inventory: Dictionary = {}
var inventory_count := 0
var batch: Dictionary = {}
var batch_remaining := 0
var batch_start_size := 0
var batch_full := false
var batch_elapsed := 0.0
var deposit_credit := 0.0
var auto_delay := 0.0
var auto_enabled := true
var auto_threshold := 1.0
var overflow_used := 0
var manual_remainder := 0.0
var auto_remainder := 0.0
var ledger := PackedInt64Array()
var identity_totals := PackedInt64Array()
var rank_totals := PackedInt64Array()
var suit_totals := PackedInt64Array()
var bound_decks := 0
var deck_income := 0.0
var foil_deposited := 0
var lucky_cards := 0
var lucky_actions := 0
var burst_actions := 0
var manual_inputs := 0
var manual_cards := 0
var auto_cards := 0
var manual_deposited := 0
var auto_deposited := 0
var manual_income := 0.0
var auto_income := 0.0
var manual_generated := 0
var auto_generated := 0
var seeker_replacements := 0
var auto_seeker_cards := 0
var combo := 0.0
var last_manual := -100.0
var combo_was_full := false
var combo_max_hold := 0.0
var manual_history: Array[float] = []
var lucky_history: Array[float] = []
var momentum_until := 0.0
var momentumprocs := 0
var auto_progress := 0.0
var auto_seeker_timer := 0.0
var generated_count := 0
var pulse_left := 0
var pulse_total := 0
var pulse_done := 0
var pulse_bias := 0.0
var pulse_guarantees: Array[int] = []
var cooldowns := PackedFloat64Array()
var durations := PackedFloat64Array()
var ability_activations := PackedInt64Array()
var ability_cards := PackedInt64Array()
var dealer_buff := -1
var dealer_left := 0.0
var dealer_strength := 0.0
var suit_surge := -1
var suit_surge_left := 0.0
var foil_flash_left := 0.0
var deposit_rush_left := 0.0
var next_event := 105.0
var waiting_event: Dictionary = {}
var shower_left := 0.0
var shower_spawn := 0.0
var shower_cards: Array[Dictionary] = []
var shower_id := 0
var event_participation := PackedInt64Array()
var event_offers := PackedInt64Array()
var achievements: Dictionary = {}
var tutorial: Dictionary = {}
var completed := false
var endless := false
var results: Dictionary = {}
var depositing_time := 0.0
var blocked_time := 0.0
var pickup_blocked_time := 0.0
var peak_cps := 0.0
var cps := 0.0
var rate_window := 0.0
var rate_cards := 0
var recent_deposits: Array[Dictionary] = []
var last_card := -1
var last_card_foil := false
var last_pickup_count := 0
var last_pickup_kind := "normal"
var last_deck_at := -100.0
var last_deck_count := 0
var purchase_count := 0
var save_reason := ""
var _missing_cache: Array[int] = []
var _derived: Dictionary = {}

func _init(seed_value: int = 0, balance_path: String = "res://data/balance.json") -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/upgrades.json"))
	catalog = data
	entries = data.entries
	bands = data.bands
	for i in entries.size():
		index[entries[i].id] = i
		ranks.append(0)
	if FileAccess.file_exists(balance_path):
		balance = JSON.parse_string(FileAccess.get_file_as_string(balance_path))
	else:
		balance = {"cost_scales": {}, "node_cost_scales": {}, "helper_rate_scale": 1.0, "deck_bonus_scale": 1.0, "ability_uptime_scale": 1.0}
	ledger.resize(52)
	identity_totals.resize(52)
	rank_totals.resize(13)
	suit_totals.resize(4)
	cooldowns.resize(5)
	durations.resize(5)
	ability_activations.resize(5)
	ability_cards.resize(5)
	event_participation.resize(6)
	event_offers.resize(6)
	if seed_value == 0:
		rng.randomize()
	else:
		rng.seed = seed_value
	next_event = rng.randf_range(90.0, 150.0)
	recalculate()

func r(id: String) -> int:
	return ranks[index[id]]

func rank_of(id: String) -> int:
	return r(id)

func entry(id: String) -> Dictionary:
	return entries[index[id]]

func cost(id: String) -> float:
	var e := entry(id)
	var b: Dictionary = bands[e.band]
	var scale := float(balance.get("cost_scales", {}).get(e.band, 1.0))
	scale *= float(balance.get("node_cost_scales", {}).get(id, 1.0))
	return ceil(float(b.base) * pow(float(b.growth), r(id)) * float(e.cost_multiplier) * scale)

func prerequisites_met(id: String) -> bool:
	for p in entry(id).prerequisites:
		if r(p.id) < int(p.rank):
			return false
	return true

func prerequisite_text(id: String) -> String:
	var parts := PackedStringArray()
	for p in entry(id).prerequisites:
		if r(p.id) < int(p.rank):
			parts.append("%s %s (%d/%d)" % [p.id, entry(p.id).name, r(p.id), int(p.rank)])
	return ", ".join(parts) if not parts.is_empty() else "No prerequisites"

func maxed(id: String) -> bool:
	return r(id) >= int(entry(id).ranks)

func can_buy(id: String) -> bool:
	return not maxed(id) and prerequisites_met(id) and money >= cost(id) and (not completed or endless)

func buy(id: String) -> bool:
	if not can_buy(id):
		return false
	var price := cost(id)
	money -= price
	spent += price
	ranks[index[id]] += 1
	purchase_count += 1
	recalculate()
	tutorial["upgrade"] = true
	if id == "A01":
		unlock("helping_hand")
	if helper_count() >= 4:
		unlock("well_oiled_table")
	var suit_roots := ["H01", "D01", "P01", "B01"]
	var all_suits := true
	for sid in suit_roots:
		all_suits = all_suits and r(sid) > 0
	if all_suits:
		unlock("four_suits_one_plan")
	if r("X01") and r("X05") and r("X08") and r("X11") and r("X14"):
		unlock("fully_equipped")
	if id.begins_with("X") and int(entry(id).ranks) == 1:
		notice.emit("%s unlocked. Use its hotbar slot when ready." % entry(id).name, "ability")
	if id == "M10":
		notice.emit("Combo unlocked: manual pickups build stacks; keep your rhythm.", "combo")
	save_reason = "purchase"
	return true

func recalculate() -> void:
	var helpers := r("A01") + r("A03") + r("P03")
	var buffer := minf(2.0, 0.1 * r("C13") * helpers)
	var cap := 52.0 + 52.0 * r("C01") + 208.0 * r("C02") + 520.0 * r("C03")
	cap *= pow(1.5, r("C04")) * (2.0 if r("C14") else 1.0)
	cap *= (1.0 + 0.2 * r("D01")) * (2.0 if r("D04") else 1.0) * (1.0 + buffer)
	var manual := (1.0 + r("M01")) * (1.0 + 0.25 * r("M02") + 0.25 * r("B01")) * pow(1.5, r("M03"))
	var auto_yield := (1.0 + r("A04") + 0.05 * r("A06") * (r("M01") + r("A04"))) * (1.0 + 0.15 * r("P02")) * (2.0 if r("A14") else 1.0)
	var auto_rate := (1.0 + 0.2 * r("A02")) * pow(1.5, r("A05")) * pow(1.6, r("A08"))
	auto_rate *= (1.0 + 0.2 * r("P01") + 0.1 * r("P03")) * (2.0 if r("A14") else 1.0)
	auto_rate *= float(balance.get("helper_rate_scale", 1.0))
	if r("P04") and not timed_active(0):
		auto_rate *= 1.25
	var bias := minf(0.75 + 0.15 * r("S08"), 0.05 * r("S01") + 0.07 * r("S02") + 0.25 * r("S08"))
	_derived = {"capacity": int(floor(cap)), "helpers": helpers, "buffer": buffer,
		"manual_base": manual, "auto_yield": auto_yield, "auto_base_rate": auto_rate,
		"seeker_bias": bias, "combo_max": 50 + 25 * r("M11") + 10 * r("B02"),
		"hold_rate": 3.0 * (1.0 + 0.1 * r("M04"))}
	refresh_missing()

func d(key: String) -> float:
	return float(_derived.get(key, 0.0))

func capacity() -> int:
	return int(d("capacity"))

func carried() -> int:
	return inventory_count + batch_remaining

func free_space() -> int:
	return maxi(0, capacity() - carried())

func helper_count() -> int:
	return int(d("helpers"))

func combo_max() -> int:
	return int(d("combo_max"))

func combo_yield_bonus() -> float:
	return combo * (0.01 + 0.0025 * r("M13")) * (1.0 + 0.1 * r("B02"))

func combo_income_bonus() -> float:
	return combo * (0.005 + 0.00125 * r("M14"))

func timed_active(slot: int) -> bool:
	return durations[slot] > 0.0

func any_timed_active() -> bool:
	return timed_active(0) or timed_active(1) or timed_active(2)

func manual_yield() -> float:
	var result := d("manual_base") * (1.0 + combo_yield_bonus())
	if active_time < momentum_until:
		result *= 1.0 + 0.2 * r("M08")
	if r("B04") and any_timed_active():
		result *= 1.5
	return result

func auto_yield() -> float:
	var result := d("auto_yield")
	if r("M16"):
		result *= 1.0 + 0.25 * combo_yield_bonus()
	return result

func auto_rate() -> float:
	var result := d("auto_base_rate")
	if batch_remaining > 0:
		result *= 1.0 + 0.15 * r("A07") + (0.25 if r("A14") else 0.0)
	if timed_active(0) and r("X04"):
		result *= 2.5 if r("P04") else 2.0
	if dealer_buff == 1 and dealer_left > 0.0:
		result *= 1.0 + dealer_strength
	return result

func auto_throughput() -> float:
	return helper_count() * auto_rate() * auto_yield()

func seeker_bias(automatic: bool = false) -> float:
	var permanent_cap := 0.75 + 0.15 * r("S08")
	var bias := d("seeker_bias") * (0.15 * r("A13") if automatic else 1.0)
	var temporary := false
	if pulse_left > 0:
		bias = maxf(bias, pulse_bias)
		temporary = true
	if dealer_buff == 3 and dealer_left > 0.0:
		bias += dealer_strength
		temporary = true
	# Temporary abilities may exceed the ordinary cap, never the absolute 90% cap.
	return minf(0.90 if temporary else permanent_cap, bias)

func deposit_momentum() -> float:
	return minf(0.25 + 0.25 * r("C10"), 0.05 * r("C10") * batch_elapsed) if r("C10") else 0.0

func deposit_rate() -> float:
	var rate := 13.0 * (1.0 + 0.25 * r("C06"))
	if batch_start_size >= 520:
		rate *= 1.0 + 0.2 * r("C07")
	if batch_full:
		rate *= 1.0 + 0.3 * r("C09") * (1.0 + 0.2 * r("D03"))
	rate *= 1.0 + deposit_momentum()
	rate *= pow(1.35, r("C08")) * pow(1.6, r("C11")) * pow(2.0, r("C12"))
	if r("C14"):
		rate *= 3.0
	rate *= (1.0 + 0.25 * r("D02")) * (2.0 if r("D04") else 1.0)
	if timed_active(1):
		rate *= 5.0 + 5.0 * r("X07")
	if deposit_rush_left > 0.0:
		rate *= 3.0
	if dealer_buff == 2 and dealer_left > 0.0:
		rate *= 1.0 + dealer_strength
	return rate

func estimated_deposit_time() -> float:
	return batch_remaining / maxf(1.0, deposit_rate()) if batch_remaining > 0 else inventory_count / maxf(1.0, deposit_rate())

func refresh_missing() -> void:
	_missing_cache.clear()
	for i in 52:
		if ledger[i] == 0:
			_missing_cache.append(i)

func missing_count() -> int:
	return _missing_cache.size()

func choose_missing(high_value: bool = false) -> int:
	if _missing_cache.is_empty():
		return -1
	if high_value and rng.randf() < 0.2 * r("S07"):
		var highest := 0
		for identity in _missing_cache:
			highest = maxi(highest, identity % 13)
		var candidates: Array[int] = []
		for identity in _missing_cache:
			if identity % 13 == highest:
				candidates.append(identity)
		return candidates[rng.randi_range(0, candidates.size() - 1)]
	return _missing_cache[rng.randi_range(0, _missing_cache.size() - 1)]

func foil_chance(identity: int) -> float:
	var heart := identity / 13 == 0
	return 0.01 + 0.005 * r("V10") + (0.01 * r("H03") if heart else 0.0) + (0.04 + 0.01 * r("X10") if timed_active(2) else 0.0) + (0.05 if foil_flash_left > 0.0 else 0.0)

static func bucket_key(identity: int, foil: bool, source: int, lucky_rank: int) -> int:
	return identity + (52 if foil else 0) + 104 * source + 208 * lucky_rank

static func decode_bucket(key: int) -> Dictionary:
	return {"identity": key % 52, "foil": (key / 52) % 2 == 1, "source": (key / 104) % 2, "lucky_rank": key / 208}

func generate_cards(requested: int, source: int, lucky_rank: int = 0, forced_missing: bool = false, overflow_allowed: bool = false) -> int:
	var amount := requested if overflow_allowed else mini(requested, free_space())
	if amount <= 0:
		return 0
	if amount > 64:
		return _generate_aggregate(amount, source, lucky_rank, forced_missing)
	for n in amount:
		var identity := rng.randi_range(0, 12) + 13 * rng.randi_range(0, 3)
		var forced := forced_missing
		generated_count += 1
		if pulse_left > 0:
			pulse_done += 1
			pulse_left -= 1
			if pulse_guarantees.has(pulse_done):
				forced = true
		var interval := 100 - 20 * r("S06")
		if r("S06") and generated_count % interval == 0:
			forced = true
		if forced or rng.randf() < seeker_bias(source == 1):
			var found := choose_missing(true)
			if found >= 0:
				identity = found
				seeker_replacements += 1
		var foil := rng.randf() < foil_chance(identity)
		var key := bucket_key(identity, foil, source, lucky_rank)
		inventory[key] = int(inventory.get(key, 0)) + 1
	inventory_count += amount
	if source == 0:
		manual_generated += amount
		manual_cards += amount
	else:
		auto_generated += amount
		auto_cards += amount
	if carried() >= capacity() and capacity() == 52:
		unlock("full_house")
	if carried() < capacity():
		overflow_used = 0
	return amount

## Exact multinomial aggregation for large pickups. Each card still has independent
## uniform rank/suit and an independent foil roll; conditional binomials preserve the
## joint distribution while avoiding one scene/object or RNG loop per late-game card.
func _generate_aggregate(amount: int, source: int, lucky_rank: int, forced_missing: bool) -> int:
	var affected := mini(amount, pulse_left)
	var pulse_forced := 0
	var interval := 100 - 20 * r("S06")
	var guaranteed := 0
	if r("S06"):
		guaranteed = int(floor(float(generated_count + amount) / interval)) - int(floor(float(generated_count) / interval))
	var overlap := 0
	for pos in pulse_guarantees:
		if pos > pulse_done and pos <= pulse_done + affected:
			pulse_forced += 1
			var global_pos := generated_count + (pos - pulse_done)
			if r("S06") and global_pos % interval == 0:
				overlap += 1
	var forced := pulse_forced + guaranteed - overlap
	if forced_missing:
		forced = amount
	forced = clampi(forced, 0, amount)
	var nonforced := amount - forced
	var bias := seeker_bias(source == 1)
	var counts := PackedInt64Array()
	counts.resize(52)
	if _missing_cache.is_empty():
		_fill_multinomial(counts, amount, _all_identities())
	else:
		var replaced := forced + _binomial(nonforced, bias)
		var ordinary := amount - replaced
		seeker_replacements += replaced
		_fill_multinomial(counts, ordinary, _all_identities())
		var high_chance := minf(1.0, 0.2 * r("S07"))
		var high := _binomial(replaced, high_chance)
		var low := replaced - high
		_fill_multinomial(counts, low, _missing_cache)
		if high > 0:
			var highest := 0
			for identity in _missing_cache:
				highest = maxi(highest, identity % 13)
			var high_ids: Array[int] = []
			for identity in _missing_cache:
				if identity % 13 == highest:
					high_ids.append(identity)
			_fill_multinomial(counts, high, high_ids)
	_add_identity_counts(counts, source, lucky_rank)
	generated_count += amount
	pulse_done += affected
	pulse_left -= affected
	inventory_count += amount
	if source == 0:
		manual_generated += amount
	else:
		auto_generated += amount
	if carried() >= capacity() and capacity() == 52:
		unlock("full_house")
	if carried() < capacity():
		overflow_used = 0
	return amount

func _all_identities() -> Array[int]:
	var ids: Array[int] = []
	for i in 52:
		ids.append(i)
	return ids

func _fill_multinomial(counts: PackedInt64Array, total: int, ids: Array[int]) -> void:
	if total <= 0 or ids.is_empty():
		return
	var remaining := total
	for i in ids.size() - 1:
		var take := _binomial(remaining, 1.0 / float(ids.size() - i))
		counts[ids[i]] += take
		remaining -= take
	counts[ids[ids.size() - 1]] += remaining

func _add_identity_counts(counts: PackedInt64Array, source: int, lucky_rank: int) -> void:
	for identity in 52:
		var n := counts[identity]
		if n <= 0:
			continue
		var foils := _binomial(n, foil_chance(identity))
		var ordinary := n - foils
		if ordinary:
			var key := bucket_key(identity, false, source, lucky_rank)
			inventory[key] = int(inventory.get(key, 0)) + ordinary
		if foils:
			var key := bucket_key(identity, true, source, lucky_rank)
			inventory[key] = int(inventory.get(key, 0)) + foils

## Binomial sampler: inversion for small means, BTPE transformed rejection otherwise.
## Kachitvichyanukul & Schmeiser (1988), binomial sampling algorithm BTPE.
func _binomial(n: int, p: float) -> int:
	if n <= 0 or p <= 0.0:
		return 0
	if p >= 1.0:
		return n
	if p > 0.5:
		return n - _binomial(n, 1.0 - p)
	if n * p <= 30.0:
		var q := 1.0 - p
		var px := exp(n * log(q))
		var u := rng.randf()
		var x := 0
		while u > px and x < n:
			u -= px
			x += 1
			px = px * (n - x + 1) * p / (x * q)
		return x
	var r := p
	var q := 1.0 - r
	var fm := n * r + r
	var m := int(floor(fm))
	var p1: float = floor(2.195 * sqrt(n * r * q) - 4.6 * q) + 0.5
	var xm := m + 0.5
	var xl: float = xm - p1
	var xr: float = xm + p1
	var c := 0.134 + 20.5 / (15.3 + m)
	var a: float = (fm - xl) / (fm - xl * r)
	var laml: float = a * (1.0 + a / 2.0)
	a = (xr - fm) / (xr * q)
	var lamr: float = a * (1.0 + a / 2.0)
	var p2: float = p1 * (1.0 + 2.0 * c)
	var p3: float = p2 + c / laml
	var p4: float = p3 + c / lamr
	var nrq := n * r * q
	while true:
		var u: float = rng.randf() * p4
		var v := rng.randf()
		var y := 0
		var accept := false
		var check := false
		if u <= p1:
			y = int(floor(xm - p1 * v + u))
			accept = true
		elif u <= p2:
			var x: float = xl + (u - p1) / c
			v = v * c + 1.0 - absf(m - x + 0.5) / p1
			if v <= 1.0:
				y = int(floor(x))
				check = true
		elif u <= p3:
			if v > 0.0:
				y = int(floor(xl + log(v) / laml))
				if y >= 0:
					v = v * (u - p2) * laml
					check = true
		else:
			if v > 0.0:
				y = int(floor(xr - log(v) / lamr))
				if y <= n:
					v = v * (u - p3) * lamr
					check = true
		if accept:
			return clampi(y, 0, n)
		if not check:
			continue
		var k := absi(y - m)
		if k > 20 and k < nrq / 2.0 - 1.0:
			var rho := (k / nrq) * ((k * (k / 3.0 + 0.625) + 0.16666666666666666) / nrq + 0.5)
			var t := -k * k / (2.0 * nrq)
			var A := log(maxf(v, 1e-300))
			if A < t - rho:
				return clampi(y, 0, n)
			if A > t + rho:
				continue
			var x1 := float(y + 1)
			var f1 := float(m + 1)
			var z := float(n + 1 - m)
			var w := float(n - y + 1)
			var x2 := x1 * x1
			var f2 := f1 * f1
			var z2 := z * z
			var w2 := w * w
			var bound := xm * log(f1 / x1) + (n - m + 0.5) * log(z / w) + (y - m) * log(w * r / (x1 * q))
			bound += (13860.0 - (462.0 - (132.0 - (99.0 - 140.0 / f2) / f2) / f2) / f2) / f1 / 166320.0
			bound += (13860.0 - (462.0 - (132.0 - (99.0 - 140.0 / z2) / z2) / z2) / z2) / z / 166320.0
			bound -= (13860.0 - (462.0 - (132.0 - (99.0 - 140.0 / x2) / x2) / x2) / x2) / x1 / 166320.0
			bound -= (13860.0 - (462.0 - (132.0 - (99.0 - 140.0 / w2) / w2) / w2) / w2) / w / 166320.0
			if A <= bound:
				return clampi(y, 0, n)
		else:
			var s := r / q
			var aa := s * (n + 1)
			var F := 1.0
			if m < y:
				for i in range(m + 1, y + 1):
					F *= aa / i - s
			elif m > y:
				for i in range(y + 1, m + 1):
					F /= aa / i - s
			if v <= F:
				return clampi(y, 0, n)
	return 0

func refresh_combo() -> void:
	last_manual = active_time
	if r("M10"):
		if combo_was_full and combo <= 0.0:
			combo = minf(combo_max(), 10.0 * r("M15"))
			combo_was_full = false
		combo = minf(combo_max(), combo + 1.0)

func register_manual_action(count: int = 1) -> void:
	for i in count:
		manual_history.append(active_time)
	while not manual_history.is_empty() and manual_history[0] < active_time - 3.0:
		manual_history.pop_front()
	if r("M08") and manual_history.size() >= 12:
		momentum_until = active_time + 3.0 + r("M09")
		momentumprocs += 1
		manual_history.clear()

func manual_input(from_shower: bool = false) -> int:
	if completed and not endless:
		return 0
	if batch_remaining > 0:
		tutorial["deposit_block"] = true
		return 0
	var overflow_action := false
	if carried() >= capacity():
		if r("C05") <= 0 or overflow_used >= r("C05") or from_shower:
			tutorial["capacity_block"] = true
			return 0
		overflow_used += 1
		overflow_action = true
	manual_inputs += 1
	# One original input refreshes the decay clock once; Surge's repeated actions add stacks.
	last_manual = active_time
	if r("M10") and combo_was_full and combo <= 0.0:
		combo = minf(combo_max(), 10.0 * r("M15"))
	combo_was_full = false
	var actions := 1
	var fractional := 0.0
	if timed_active(0) and not from_shower:
		var equivalents := 3.0 + 0.5 * r("X03")
		actions = int(floor(equivalents))
		fractional = equivalents - actions
	var total := 0
	var lucky_count := 0
	var burst_count := 0
	register_manual_action(actions)
	for action in actions:
		if r("M10"):
			combo = minf(combo_max(), combo + 1.0)
		var is_burst := r("M05") > 0 and rng.randf() < 0.03 + 0.02 * r("M06") + 0.01 * r("B03")
		var is_lucky := r("M17") > 0 and rng.randf() < minf(1.0, (0.05 + 0.015 * r("M18") + 0.01 * r("B03")) * (2.0 if timed_active(2) else 1.0))
		var output := manual_yield() * (2.0 + r("M07") if is_burst else 1.0)
		if is_lucky:
			output *= 2.0 + 0.5 * r("M19")
			lucky_count += 1
			lucky_actions += 1
			lucky_history.append(active_time)
		if is_burst:
			burst_count += 1
			burst_actions += 1
		var whole := int(floor(output + manual_remainder))
		manual_remainder = output + manual_remainder - whole
		var made := generate_cards(whole, 0, 1 + r("M20") if is_lucky else 0, false, overflow_action)
		total += made
		lucky_cards += made if is_lucky else 0
		ability_cards[0] += made if timed_active(0) else 0
		ability_cards[2] += made if timed_active(2) else 0
	if fractional > 0.0:
		var extra := int(floor(manual_yield() * fractional + manual_remainder))
		manual_remainder += manual_yield() * fractional - extra
		var made := generate_cards(extra, 0, 0, false, overflow_action)
		total += made
		ability_cards[0] += made
	last_pickup_count = total
	last_pickup_kind = "lucky" if lucky_count else ("burst" if burst_count else "normal")
	while not lucky_history.is_empty() and lucky_history[0] < active_time - 5.0:
		lucky_history.pop_front()
	if lucky_history.size() >= 3:
		unlock("lucky_streak")
	tutorial["pickup"] = true
	return total

func start_deposit(manual: bool = true) -> bool:
	if batch_remaining > 0 or inventory_count <= 0 or (completed and not endless):
		return false
	batch = inventory.duplicate()
	batch_remaining = inventory_count
	batch_start_size = inventory_count
	batch_full = inventory_count >= int(ceil(capacity() * 0.9))
	inventory.clear()
	inventory_count = 0
	batch_elapsed = 0.0
	deposit_credit = 0.0
	auto_delay = 1.0 if manual else 0.0
	overflow_used = 0
	tutorial["deposit"] = true
	return true

func cancel_deposit() -> bool:
	if batch_remaining <= 0:
		return false
	for key in batch:
		inventory[key] = int(inventory.get(key, 0)) + int(batch[key])
	inventory_count += batch_remaining
	batch.clear()
	batch_remaining = 0
	batch_start_size = 0
	batch_elapsed = 0.0
	deposit_credit = 0.0
	auto_delay = 1.0
	return true

func card_income(identity: int, foil: bool, source: int, lucky_rank: int, full_batch: bool) -> float:
	var rank := identity % 13
	var suit := identity / 13
	var value := float(rank + 1 + r("V03"))
	var global_additive := 1.0 + 0.15 * r("V01")
	if suit != 0:
		global_additive += 0.08 * r("H02")
	if full_batch:
		global_additive += 0.25 * r("V15") * (1.0 + 0.2 * r("D03"))
	var global := global_additive * pow(1.35, r("V02")) * (3.0 if r("V16") else 1.0)
	var rank_mult := 1.0
	if rank == 0:
		rank_mult = 1.0 + r("V04")
	elif rank <= 9:
		rank_mult = 1.0 + 0.2 * r("V05")
	else:
		rank_mult = (1.0 + 0.2 * r("V06")) * pow(1.5, r("V07"))
	var source_mult := 1.0 + 0.2 * r("V13") if source == 0 else 1.0 + 0.15 * r("A12") + 0.2 * r("V14")
	var suit_mult := 1.0 + (0.25 * r("H01") if suit == 0 else 0.0)
	if suit == suit_surge and suit_surge_left > 0.0:
		suit_mult += 1.0
	var foil_mult := 1.0
	if foil:
		foil_mult = (5.0 + r("V11")) * pow(1.5, r("V12"))
		if suit == 0:
			foil_mult *= 1.0 + 0.25 * r("H03")
	var temporary := 1.0
	if source == 0:
		temporary += combo_income_bonus()
	elif r("M16"):
		temporary += 0.25 * combo_income_bonus()
	if lucky_rank > 0:
		temporary += 0.5 + 0.25 * (lucky_rank - 1)
	if timed_active(2):
		temporary += 0.5 + 0.15 * r("X10")
	if dealer_buff == 0 and dealer_left > 0.0:
		temporary += dealer_strength
	return value * global * rank_mult * source_mult * suit_mult * foil_mult * temporary

func current_deck_income() -> float:
	var value := (52.0 + 52.0 * r("V08")) * pow(1.5, r("V09")) * (2.0 if r("V16") else 1.0)
	value *= float(balance.get("deck_bonus_scale", 1.0))
	if r("H04"):
		value *= 1.0 + 0.25 * r("H01") * 0.25
	if dealer_buff == 0 and dealer_left > 0.0:
		value *= 1.0 + dealer_strength
	return value

func process_deposit(amount: int) -> int:
	if amount <= 0 or batch_remaining <= 0:
		return 0
	if not endless:
		amount = mini(amount, GOAL - deposited)
	var processed := 0
	var bound_now := 0
	var income_now := 0.0
	for key in batch.keys():
		if processed >= amount:
			break
		var take := mini(int(batch[key]), amount - processed)
		if take <= 0:
			continue
		var meta := decode_bucket(int(key))
		var identity: int = meta.identity
		var foil: bool = meta.foil
		var source: int = meta.source
		var income := card_income(identity, foil, source, int(meta.lucky_rank), batch_full) * take
		money += income
		earned += income
		income_now += income
		if source == 0:
			manual_income += income
			manual_deposited += take
		else:
			auto_income += income
			auto_deposited += take
		ledger[identity] += take
		identity_totals[identity] += take
		rank_totals[identity % 13] += take
		suit_totals[identity / 13] += take
		deposited += take
		processed += take
		if foil:
			foil_deposited += take
			unlock("shiny")
		last_card = identity
		last_card_foil = foil
		var decks := ledger[0]
		for i in range(1, 52):
			decks = mini(decks, ledger[i])
		if decks > 0:
			for i in 52:
				ledger[i] -= decks
			bound_decks += decks
			bound_now += decks
			var bonus := current_deck_income() * decks
			money += bonus
			earned += bonus
			deck_income += bonus
			income_now += bonus
			unlock("worth_the_paper")
		batch[key] = int(batch[key]) - take
		if int(batch[key]) == 0:
			batch.erase(int(key))
		if deposited >= GOAL and not endless and not completed:
			complete_run()
			break
	batch_remaining -= processed
	refresh_missing()
	rate_cards += processed
	recent_deposits.append({"time": active_time, "cards": processed})
	while not recent_deposits.is_empty() and float(recent_deposits[0].time) < active_time - 5.0:
		recent_deposits.pop_front()
	if bound_now:
		refresh_missing()
		last_deck_at = active_time
		last_deck_count = bound_now
		notice.emit("%s bound %s · +%s" % ["Deck" if bound_now == 1 else "Decks", str(bound_now), format_number(income_now)], "deck")
	if deposited >= 1:
		unlock("one_down")
	if manual_deposited >= 10000:
		unlock("do_it_yourself")
	if rank_totals[12] >= 1000:
		unlock("royal_treatment")
	if foil_deposited >= 52:
		unlock("foil_collection")
	if deposited >= 1000000:
		unlock("millionaire")
	if deposited >= 10000000:
		unlock("eight_figures")
	if batch_remaining == 0 and not completed:
		if batch_start_size >= 100000:
			unlock("the_long_count")
		batch_start_size = 0
		batch_elapsed = 0.0
		deposit_credit = 0.0
	if carried() < capacity():
		overflow_used = 0
	return processed

func ability_cooldown(slot: int) -> float:
	var base: float = [60.0, 75.0, 120.0, 150.0, 90.0][slot]
	if slot == 1:
		base *= pow(0.95, r("X07"))
		# Owner-approved: Express speed is 5 + 5 per Overclock rank; see deposit_rate().
	if slot == 4:
		base *= pow(0.9, r("X16"))
	return base / maxf(0.1, float(balance.get("ability_uptime_scale", 1.0)))

func ability_duration(slot: int) -> float:
	var base: float = [10.0 + 2.0 * r("X02"), 8.0 + 2.0 * r("X06"), 12.0 + 3.0 * r("X09"), 0.0, 0.0][slot]
	return base * (1.25 if r("B04") else 1.0)

func activate_ability(slot: int) -> bool:
	if slot < 0 or slot >= 5 or not r(ABILITY_IDS[slot]) or cooldowns[slot] > 0.0 or (completed and not endless):
		return false
	if slot == 4 and free_space() <= 0:
		notice.emit("Cyclone needs free capacity.", "blocked")
		return false
	cooldowns[slot] = ability_cooldown(slot)
	ability_activations[slot] += 1
	if slot < 3:
		durations[slot] = ability_duration(slot)
		if slot == 0:
			recalculate()
		notice.emit("%s active" % ABILITY_NAMES[slot], "ability")
	elif slot == 3:
		pulse_total = 52 + 26 * r("X12")
		pulse_left = pulse_total
		pulse_done = 0
		pulse_bias = 0.65 + 0.05 * r("X13")
		pulse_guarantees.clear()
		var guarantees := 2 * r("X13")
		for i in guarantees:
			pulse_guarantees.append(int(floor((i + 1.0) * pulse_total / (guarantees + 1.0))))
		notice.emit("Seeker Pulse: next %d generated cards" % pulse_total, "ability")
	else:
		var amount := int(floor(capacity() * (0.1 + 0.05 * r("X15"))))
		var made := generate_cards(amount, 0)
		ability_cards[4] += made
		last_pickup_count = made
		last_pickup_kind = "cyclone"
		notice.emit("Cyclone collected %s cards" % format_number(made), "ability")
	save_reason = "ability"
	return true

func auto_deposit_threshold_met() -> bool:
	if not r("A09") or not auto_enabled or batch_remaining > 0 or inventory_count <= 0 or auto_delay > 0.0:
		return false
	if inventory_count >= int(ceil(capacity() * auto_threshold)):
		return true
	if r("A11") and inventory_count >= maxi(1, int(capacity() * 0.1)):
		var horizon := 0.25 + 0.25 * r("A11")
		var safety := 0.10 - 0.025 * r("A11")
		var prediction := inventory_count + auto_throughput() * inventory_count / maxf(1.0, deposit_rate()) * horizon
		return prediction >= capacity() * (1.0 - safety)
	return false

func tick(dt: float) -> void:
	if dt <= 0.0 or (completed and not endless):
		return
	active_time += dt
	auto_delay = maxf(0.0, auto_delay - dt)
	for i in 5:
		cooldowns[i] = maxf(0.0, cooldowns[i] - dt)
		if i < 3:
			var was_active := durations[i] > 0.0
			durations[i] = maxf(0.0, durations[i] - dt)
			if i == 0 and was_active and durations[i] == 0.0 and r("P04"):
				recalculate()
	dealer_left = maxf(0.0, dealer_left - dt)
	suit_surge_left = maxf(0.0, suit_surge_left - dt)
	foil_flash_left = maxf(0.0, foil_flash_left - dt)
	deposit_rush_left = maxf(0.0, deposit_rush_left - dt)
	if r("M10") and active_time - last_manual > 1.5 + 0.5 * r("M12"):
		combo = maxf(0.0, combo - 10.0 * pow(0.85, r("M12")) * dt)
		if combo <= 0.0:
			combo_was_full = true
	if combo >= combo_max() - 0.01 and r("M10"):
		combo_max_hold += dt
		if combo_max_hold >= 20.0:
			unlock("combo_artist")
	else:
		combo_max_hold = 0.0
	if helper_count() > 0:
		auto_progress += helper_count() * auto_rate() * dt
		var picks := int(floor(auto_progress))
		if picks > 0:
			auto_progress -= picks
			var output := auto_yield() * picks
			var whole := int(floor(output + auto_remainder))
			auto_remainder = output + auto_remainder - whole
			var made := generate_cards(whole, 1)
			ability_cards[0] += made if timed_active(0) and r("X04") else 0
			ability_cards[2] += made if timed_active(2) else 0
		if carried() >= capacity():
			pickup_blocked_time += dt
	if r("S03"):
		auto_seeker_timer += dt
		var interval := 60.0 * pow(0.85, r("S04"))
		if auto_seeker_timer >= interval:
			if free_space() <= 0:
				auto_seeker_timer = interval
			else:
				auto_seeker_timer = 0.0
				var amount := (1 + r("S05")) * (2 if r("S08") else 1)
				var made := generate_cards(amount, 1, 0, true)
				auto_seeker_cards += made
				if made:
					unlock("found_it")
	if auto_deposit_threshold_met():
		start_deposit(false)
		tutorial["automation"] = true
	if batch_remaining > 0:
		depositing_time += dt
		batch_elapsed += dt
		deposit_credit += deposit_rate() * dt
		var amount := int(floor(deposit_credit))
		if amount > 0:
			deposit_credit -= amount
			process_deposit(amount)
	elif carried() >= capacity():
		blocked_time += dt
		tutorial["capacity_block"] = true
	rate_window += dt
	if rate_window >= 1.0:
		cps = rate_cards / rate_window
		peak_cps = maxf(peak_cps, cps)
		if cps >= 1000.0:
			unlock("counting_excellence")
		rate_cards = 0
		rate_window = 0.0
	tick_events(dt)

func tutorial_opening_done() -> bool:
	return bool(tutorial.get("pickup", false)) and bool(tutorial.get("deposit", false)) and bool(tutorial.get("upgrade", false))

func tick_events(dt: float) -> void:
	if shower_left > 0.0:
		shower_left = maxf(0.0, shower_left - dt)
		shower_spawn -= dt
		if shower_spawn <= 0.0 and shower_left > 0.0:
			shower_spawn = 0.55
			shower_id += 1
			shower_cards.append({"id": shower_id, "x": rng.randf_range(0.12, 0.88), "y": rng.randf_range(0.18, 0.65), "life": 2.4})
		for i in range(shower_cards.size() - 1, -1, -1):
			shower_cards[i].life = float(shower_cards[i].life) - dt
			if float(shower_cards[i].life) <= 0.0:
				shower_cards.remove_at(i)
	if not tutorial_opening_done() or completed and not endless:
		return
	if not waiting_event.is_empty():
		return
	next_event -= dt
	if next_event > 0.0:
		return
	next_event = rng.randf_range(90.0, 150.0)
	var kind := rng.randi_range(0, 4) if rng.randf() > 0.08 else 5
	event_offers[kind] += 1
	if kind == 2:
		suit_surge = rng.randi_range(0, 3)
		suit_surge_left = 20.0
		event_participation[kind] += 1
		notice.emit("Suit Surge: %s income ×2 for 20s" % SUIT_NAMES[suit_surge], "event")
	elif kind == 3:
		foil_flash_left = 15.0
		event_participation[kind] += 1
		notice.emit("Foil Flash: +5 percentage points foil chance for 15s", "event")
	else:
		waiting_event = {"kind": kind}
		if kind == 1:
			var choices := [0, 1, 2, 3]
			for i in range(3, 0, -1):
				var j := rng.randi_range(0, i)
				var tmp = choices[i]
				choices[i] = choices[j]
				choices[j] = tmp
			waiting_event["choices"] = choices.slice(0, 3)
			waiting_event["duration"] = rng.randf_range(20.0, 30.0)
			waiting_event["strength"] = [0.5, 0.5, 1.0, 0.2][0]
		notice.emit("%s is waiting on the table." % EVENT_NAMES[kind], "event")
	check_event_achievement()

func interact_event(choice: int = -1) -> bool:
	if waiting_event.is_empty():
		return false
	var kind := int(waiting_event.kind)
	if kind == 0:
		shower_left = 8.0
		shower_spawn = 0.0
		shower_cards.clear()
	elif kind == 1:
		var choices: Array = waiting_event.choices
		if choice < 0 or choice >= choices.size():
			return false
		dealer_buff = int(choices[choice])
		dealer_left = float(waiting_event.duration)
		dealer_strength = [0.5, 0.5, 1.0, 0.25][dealer_buff]
	elif kind == 4:
		deposit_rush_left = 12.0
	elif kind == 5:
		for i in 5:
			cooldowns[i] = maxf(0.0, cooldowns[i] - 30.0)
	event_participation[kind] += 1
	waiting_event.clear()
	check_event_achievement()
	notice.emit("%s engaged" % EVENT_NAMES[kind], "event")
	save_reason = "event"
	return true

func click_shower(card_id: int) -> bool:
	for i in shower_cards.size():
		if int(shower_cards[i].id) == card_id:
			shower_cards.remove_at(i)
			manual_input(true)
			return true
	return false

func dealer_choice_name(choice: int) -> String:
	return ["+50% income", "+50% helper rate", "+100% deposit rate", "+25pp Seeker bias"][choice]

func check_event_achievement() -> void:
	for count in event_participation:
		if count == 0:
			return
	unlock("event_regular")

func unlock(id: String) -> void:
	if achievements.has(id):
		return
	achievements[id] = active_time
	achievement_unlocked.emit(id)
	notice.emit("Achievement: %s" % ACHIEVEMENTS[id][0], "achievement")

func complete_run() -> void:
	completed = true
	deposit_credit = 0.0
	waiting_event.clear()
	unlock("52_million_card_pickup")
	results = statistics()
	results["final_ranks"] = ranks.duplicate()
	results["completion_time"] = active_time
	results["goal"] = GOAL
	save_reason = "completion"
	run_completed.emit()

func continue_endless() -> void:
	if completed:
		endless = true
		next_event = rng.randf_range(90.0, 150.0)
		save_reason = "endless"

func statistics() -> Dictionary:
	return {"active_time": active_time, "deposited": deposited, "remaining": maxi(0, GOAL - deposited),
		"bound_decks": bound_decks, "money": money, "earned": earned, "spent": spent,
		"manual_cards": manual_cards, "auto_cards": auto_cards, "manual_income": manual_income, "auto_income": auto_income,
		"manual_deposited": manual_deposited, "auto_deposited": auto_deposited, "manual_generated": manual_generated, "auto_generated": auto_generated, "average_cps": deposited / maxf(1.0, active_time), "peak_cps": peak_cps,
		"deposit_utilization": depositing_time / maxf(1.0, active_time), "blocked_time": blocked_time, "pickup_blocked_time": pickup_blocked_time,
		"rank_totals": rank_totals.duplicate(), "suit_totals": suit_totals.duplicate(), "identity_totals": identity_totals.duplicate(),
		"foil_deposited": foil_deposited, "lucky_cards": lucky_cards, "lucky_actions": lucky_actions, "burst_actions": burst_actions,
		"ability_activations": ability_activations.duplicate(), "ability_cards": ability_cards.duplicate(),
		"event_participation": event_participation.duplicate(), "event_offers": event_offers.duplicate(),
		"achievements": achievements.duplicate(true), "deck_income": deck_income, "seeker_replacements": seeker_replacements,
		"auto_seeker_cards": auto_seeker_cards, "manual_inputs": manual_inputs, "purchase_count": purchase_count}

static func format_number(value: float, exact: bool = false) -> String:
	if exact or absf(value) < 10000.0:
		return String.num(value, 0 if absf(value - roundf(value)) < 0.001 else 1).replace(",", "")
	var units := ["", "K", "M", "B", "T", "Qa", "Qi"]
	var v := absf(value)
	var tier := 0
	while v >= 1000.0 and tier < units.size() - 1:
		v /= 1000.0
		tier += 1
	return ("-" if value < 0 else "") + String.num(v, 2 if v < 100 else 1) + units[tier]

static func format_time(seconds: float) -> String:
	var s := int(seconds)
	return "%02d:%02d:%02d" % [s / 3600, (s / 60) % 60, s % 60]

func card_name(identity: int) -> String:
	if identity < 0:
		return "No cards yet"
	return "%s%s" % [RANK_NAMES[identity % 13], SUIT_SYMBOLS[identity / 13]]

func to_dict() -> Dictionary:
	var state := statistics()
	state.merge({"schema_version": 1, "rng_state": str(rng.state), "ranks": ranks, "inventory": inventory,
		"inventory_count": inventory_count, "batch": batch, "batch_remaining": batch_remaining, "batch_start_size": batch_start_size,
		"batch_full": batch_full, "batch_elapsed": batch_elapsed, "deposit_credit": deposit_credit,
		"auto_delay": auto_delay, "auto_enabled": auto_enabled, "auto_threshold": auto_threshold, "overflow_used": overflow_used,
		"manual_remainder": manual_remainder, "auto_remainder": auto_remainder, "ledger": ledger, "combo": combo,
		"last_manual": last_manual, "combo_was_full": combo_was_full, "combo_max_hold": combo_max_hold,
		"manual_history": manual_history, "lucky_history": lucky_history, "momentum_until": momentum_until,
		"auto_progress": auto_progress, "auto_seeker_timer": auto_seeker_timer, "generated_count": generated_count,
		"pulse_left": pulse_left, "pulse_total": pulse_total, "pulse_done": pulse_done, "pulse_bias": pulse_bias, "pulse_guarantees": pulse_guarantees,
		"cooldowns": cooldowns, "durations": durations, "dealer_buff": dealer_buff, "dealer_left": dealer_left, "dealer_strength": dealer_strength,
		"suit_surge": suit_surge, "suit_surge_left": suit_surge_left, "foil_flash_left": foil_flash_left, "deposit_rush_left": deposit_rush_left,
		"next_event": next_event, "waiting_event": waiting_event, "shower_left": shower_left, "shower_spawn": shower_spawn,
		"shower_cards": shower_cards, "shower_id": shower_id, "tutorial": tutorial, "completed": completed, "endless": endless,
		"results": results, "last_card": last_card, "last_card_foil": last_card_foil, "last_deck_at": last_deck_at,
		"last_deck_count": last_deck_count, "catalog_hash": catalog_hash(), "balance_hash": balance_hash()}, true)
	return state

static func catalog_hash() -> String:
	return FileAccess.get_sha256("res://data/upgrades.json")

func balance_hash() -> String:
	return JSON.stringify(balance).sha256_text()

func load_dict(state: Dictionary) -> bool:
	if int(state.get("schema_version", 0)) != 1 or not state.has("ranks") or not state.has("ledger"):
		return false
	if str(state.get("catalog_hash", "")) != catalog_hash():
		return false
	var saved_ranks: Array = state.ranks
	var saved_ledger: Array = state.ledger
	if saved_ranks.size() != entries.size() or saved_ledger.size() != 52:
		return false
	for i in saved_ranks.size():
		var v := int(saved_ranks[i])
		if v < 0 or v > int(entries[i].ranks):
			return false
	for key in ["deposited", "inventory_count", "batch_remaining", "bound_decks"]:
		if int(state.get(key, 0)) < 0:
			return false
	if int(state.inventory_count) + int(state.batch_remaining) != int(state.get("manual_cards", 0)) + int(state.get("auto_cards", 0)) - int(state.deposited):
		return false
	if int(state.get("manual_deposited", 0)) + int(state.get("auto_deposited", 0)) != int(state.deposited):
		return false
	for i in saved_ranks.size():
		ranks[i] = int(saved_ranks[i])
	for i in 52:
		ledger[i] = int(saved_ledger[i])
		identity_totals[i] = int(state.identity_totals[i])
	for i in 13:
		rank_totals[i] = int(state.rank_totals[i])
	for i in 4:
		suit_totals[i] = int(state.suit_totals[i])
	for key in ["money", "earned", "spent", "active_time", "batch_elapsed", "deposit_credit", "auto_delay", "auto_threshold", "overflow_used", "manual_remainder", "auto_remainder", "combo", "last_manual", "combo_max_hold", "momentum_until", "auto_progress", "auto_seeker_timer", "pulse_bias", "next_event", "dealer_left", "dealer_strength", "suit_surge_left", "foil_flash_left", "deposit_rush_left", "shower_left", "shower_spawn", "deck_income", "manual_income", "auto_income", "peak_cps", "last_deck_at", "depositing_time", "blocked_time", "pickup_blocked_time"]:
		set(key, float(state.get(key, 0.0)))
	for key in ["deposited", "inventory_count", "batch_remaining", "batch_start_size", "bound_decks", "foil_deposited", "lucky_cards", "lucky_actions", "burst_actions", "manual_inputs", "manual_cards", "auto_cards", "manual_deposited", "auto_deposited", "manual_generated", "auto_generated", "seeker_replacements", "auto_seeker_cards", "generated_count", "pulse_left", "pulse_total", "pulse_done", "shower_id", "last_card", "last_deck_count", "purchase_count"]:
		set(key, int(state.get(key, 0)))
	for key in ["batch_full", "auto_enabled", "combo_was_full", "completed", "endless", "last_card_foil"]:
		set(key, bool(state.get(key, false)))
	dealer_buff = int(state.get("dealer_buff", -1))
	suit_surge = int(state.get("suit_surge", -1))
	inventory = _int_keys(state.get("inventory", {}))
	batch = _int_keys(state.get("batch", {}))
	achievements = state.get("achievements", {}).duplicate(true)
	tutorial = state.get("tutorial", {}).duplicate(true)
	waiting_event = state.get("waiting_event", {}).duplicate(true)
	results = state.get("results", {}).duplicate(true)
	shower_cards.clear()
	for item in state.get("shower_cards", []):
		shower_cards.append(item)
	for key in ["manual_history", "lucky_history"]:
		var arr: Array[float] = []
		for v in state.get(key, []):
			arr.append(float(v))
		set(key, arr)
	pulse_guarantees.clear()
	for v in state.get("pulse_guarantees", []):
		pulse_guarantees.append(int(v))
	for key in ["cooldowns", "durations"]:
		var arr: PackedFloat64Array = get(key)
		for i in mini(5, state.get(key, []).size()):
			arr[i] = float(state[key][i])
	for key in ["ability_activations", "ability_cards", "event_participation", "event_offers"]:
		var arr: PackedInt64Array = get(key)
		for i in mini(arr.size(), state.get(key, []).size()):
			arr[i] = int(state[key][i])
	if state.has("rng_state"):
		rng.state = int(state.rng_state)
	recalculate()
	return true

func _int_keys(value: Dictionary) -> Dictionary:
	var out := {}
	for key in value:
		out[int(key)] = int(value[key])
	return out
