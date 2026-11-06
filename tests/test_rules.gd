extends SceneTree
## Headless rules regression suite. Run: godot --headless --path . --script res://tests/test_rules.gd
var failures := 0
var checks := 0

func _init() -> void:
	_test_opening()
	_test_income_and_decks()
	_test_batch_lifecycle()
	_test_overflow()
	_test_seekers_and_pulse()
	_test_abilities()
	_test_events_and_pause()
	_test_save_roundtrip()
	_test_completion()
	_test_aggregate_distribution()
	_test_catalog()
	print("RULES TESTS: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: " + message)

func near(a: float, b: float, epsilon: float = 0.0001) -> bool:
	return absf(a - b) <= epsilon

func grant(s: PickupRules, id: String, rank: int = -1) -> void:
	s.ranks[s.index[id]] = int(s.entry(id).ranks) if rank < 0 else rank
	s.recalculate()

func fill_identity(s: PickupRules, identity: int, count: int, foil: bool = false, source: int = 0) -> void:
	var key := PickupRules.bucket_key(identity, foil, source, 0)
	s.inventory[key] = int(s.inventory.get(key, 0)) + count
	s.inventory_count += count
	if source == 0:
		s.manual_cards += count
		s.manual_generated += count
	else:
		s.auto_cards += count
		s.auto_generated += count

func _test_opening() -> void:
	var s := PickupRules.new(52)
	check(s.capacity() == 52, "initial capacity exactly 52")
	check(near(s.manual_yield(), 1), "initial manual yield exactly 1")
	check(near(s.deposit_rate(), 13), "initial deposit rate exactly 13")
	check(s.money == 0 and s.deposited == 0, "clean opening counters")
	var made := s.manual_input()
	check(made == 1 and s.inventory_count == 1, "one click produces one card")
	for i in 60:
		s.manual_input()
	check(s.carried() == 52, "ordinary pickup stops at capacity")
	check(s.manual_input() == 0, "no overflow without upgrade")
	check(s.start_deposit(), "deposit starts")
	check(s.manual_input() == 0, "manual pickup paused during deposit")
	s.tick(4.0)
	check(s.deposited == 52 and s.carried() == 0, "52 cards count in four seconds")
	check(s.earned > 0, "deposit pays money")

func _test_income_and_decks() -> void:
	var s := PickupRules.new(7)
	for i in 52:
		fill_identity(s, i, 1)
	s.start_deposit()
	s.process_deposit(52)
	check(s.bound_decks == 1, "all 52 identities bind one deck")
	check(s.missing_count() == 52, "binding consumes one unbound copy each")
	check(near(s.deck_income, 52), "base deck bonus 52")
	check(s.deposited == 52, "deck bonus does not add goal cards")
	var base := s.card_income(12, false, 0, 0, false)
	check(near(base, 13), "King base value 13")
	grant(s, "V03", 2)
	grant(s, "V01", 2)
	grant(s, "V06", 1)
	var expected := (13.0 + 2.0) * (1.0 + 0.3) * 1.2
	check(near(s.card_income(12, false, 0, 0, false), expected), "flat rank and additive global categories")
	var foil := s.card_income(12, true, 0, 0, false)
	check(near(foil, expected * 5.0), "base foil multiplier 5x")
	for i in 52:
		fill_identity(s, i, 3)
	s.start_deposit()
	s.process_deposit(156)
	check(s.bound_decks == 4, "multiple eligible decks bind sequentially/aggregate")

func _test_batch_lifecycle() -> void:
	var s := PickupRules.new(9)
	grant(s, "C01", 4)
	for i in 100:
		fill_identity(s, i % 52, 1)
	s.start_deposit()
	s.process_deposit(20)
	var before := s.deposited
	var remaining := s.batch_remaining
	s.cancel_deposit()
	check(s.deposited == before, "cancel keeps counted cards")
	check(s.inventory_count == remaining and s.batch_remaining == 0, "cancel returns uncounted cards")
	var total_before := s.manual_cards + s.auto_cards
	check(total_before - s.deposited == s.carried(), "card conservation after cancel")
	grant(s, "C06", 2)
	s.start_deposit()
	var rate_before := s.deposit_rate()
	grant(s, "C08", 1)
	check(s.deposit_rate() > rate_before, "mid-deposit rate upgrade affects remaining batch")
	fill_identity(s, 0, 10, false, 1)
	var batch_size := s.batch_remaining
	s.process_deposit(5)
	check(s.batch_remaining == batch_size - 5, "new cards do not join running batch")

func _test_overflow() -> void:
	var s := PickupRules.new(11)
	grant(s, "C05", 1)
	grant(s, "M01", 4)
	for i in 52:
		fill_identity(s, i % 52, 1)
	var made := s.manual_input()
	check(made == 5 and s.carried() == 57, "overflow action grants full yield above capacity")
	check(s.manual_input() == 0, "only stated overflow actions allowed")
	check(s.free_space() == 0, "overflow does not create free space")

func _test_seekers_and_pulse() -> void:
	var s := PickupRules.new(13)
	grant(s, "S01")
	grant(s, "S02", 5)
	check(near(s.seeker_bias(), 0.40), "base seeker plus focus")
	grant(s, "S08")
	check(s.seeker_bias() <= 0.90, "master seeker absolute cap")
	grant(s, "C01", 10)
	for i in 51:
		fill_identity(s, i, 1)
	s.start_deposit()
	s.process_deposit(51)
	check(s.missing_count() == 1, "one missing identity")
	var made := s.generate_cards(200, 0, 0, true)
	var found := false
	for key in s.inventory:
		if PickupRules.decode_bucket(int(key)).identity == 51:
			found = true
	check(found and made == 200, "forced missing generation finds the only missing identity")
	grant(s, "X11")
	grant(s, "X13", 3)
	s.activate_ability(3)
	check(s.pulse_total == 52 and s.pulse_guarantees.size() == 6, "pulse focus guarantees distributed")
	check(s.pulse_guarantees[0] > 1, "guarantees not consecutive at start")
	var before := s.pulse_left
	s.generate_cards(10, 1)
	check(s.pulse_left == before - 10, "generated cards consume pulse charges")

func _test_abilities() -> void:
	var s := PickupRules.new(17)
	grant(s, "X01")
	grant(s, "X03", 1)
	grant(s, "M10")
	s.activate_ability(0)
	var made := s.manual_input()
	check(made == 3, "surge potency 1 resolves 3.5 action equivalents as 3 whole cards")
	check(s.combo == 3, "surge repeated actions build combo")
	check(s.manual_remainder >= 0.0 and s.manual_remainder < 1.0, "fractional surge output retained without extra roll")
	grant(s, "X05")
	grant(s, "X07", 4)
	s.activate_ability(1)
	check(near(s.deposit_rate(), 13.0 * 25.0), "approved express overclock x25 at rank 4")
	grant(s, "X14")
	s.inventory_count = s.capacity()
	check(not s.activate_ability(4), "cyclone blocked at zero free space")
	s.inventory_count = 0
	check(s.activate_ability(4), "cyclone allowed with free space")
	check(s.inventory_count == int(s.capacity() * 0.1), "cyclone collects 10% capacity")
	grant(s, "B04")
	check(near(s.ability_duration(0), 12.5), "club performance extends timed abilities")
	check(near(s.ability_cooldown(4), 90.0), "club performance does not alter instant ability cooldown")

func _test_events_and_pause() -> void:
	var s := PickupRules.new(19)
	s.tutorial = {"pickup": true, "deposit": true, "upgrade": true}
	s.next_event = 0.0
	s.tick_events(0.1)
	check(not s.waiting_event.is_empty() or s.suit_surge_left > 0 or s.foil_flash_left > 0, "event begins after opening tutorial")
	s.waiting_event = {"kind": 4}
	s.interact_event()
	check(near(s.deposit_rush_left, 12), "deposit rush duration")
	var rate := s.deposit_rate()
	check(near(rate, 39), "deposit rush +200% means x3")
	s.waiting_event = {"kind": 5}
	s.cooldowns[0] = 40
	s.interact_event()
	check(near(s.cooldowns[0], 10), "second wind reduces cooldowns by 30")
	s.waiting_event = {"kind": 1, "choices": [0, 1, 2], "duration": 25.0}
	s.interact_event(0)
	check(s.dealer_buff == 0 and near(s.dealer_left, 25), "dealer choice applies")
	s.waiting_event = {"kind": 1, "choices": [1, 2, 3], "duration": 20.0}
	s.interact_event(0)
	check(s.dealer_buff == 1, "new dealer choice replaces old")
	var t := s.active_time
	s.completed = true
	s.tick(10)
	check(s.active_time == t, "completion pauses simulation before endless")

func _test_save_roundtrip() -> void:
	var s := PickupRules.new(23)
	grant(s, "M01", 3)
	grant(s, "A01")
	grant(s, "A09")
	s.manual_input()
	s.generate_cards(20, 1)
	s.start_deposit()
	s.process_deposit(5)
	s.cooldowns[0] = 12.5
	s.waiting_event = {"kind": 4}
	var state := s.to_dict()
	var json := JSON.stringify(state)
	var parsed = JSON.parse_string(json)
	var loaded := PickupRules.new(99)
	check(loaded.load_dict(parsed), "save loads")
	check(loaded.deposited == s.deposited and loaded.money == s.money, "save preserves counters/money")
	check(loaded.batch_remaining == s.batch_remaining and loaded.inventory_count == s.inventory_count, "save preserves batch/inventory")
	check(loaded.r("M01") == 3 and loaded.r("A09") == 1, "save preserves upgrades")
	check(near(loaded.cooldowns[0], 12.5), "save preserves cooldowns")
	check(int(loaded.waiting_event.kind) == 4, "save preserves waiting event")
	var time := loaded.active_time
	loaded.tick(0.0)
	check(loaded.active_time == time, "no offline elapsed production")

func _test_completion() -> void:
	var s := PickupRules.new(29)
	s.deposited = PickupRules.GOAL - 1
	fill_identity(s, 0, 10)
	s.start_deposit()
	s.process_deposit(10)
	check(s.completed and s.deposited == PickupRules.GOAL, "exact goal completes run")
	check(s.batch_remaining == 9, "unprocessed final batch retained")
	check(s.results.has("final_ranks"), "results snapshot final tree")
	s.continue_endless()
	s.tick(1.0)
	check(s.endless and s.deposited > PickupRules.GOAL, "endless resumes retained cards beyond goal")

func _test_aggregate_distribution() -> void:
	var s := PickupRules.new(31)
	grant(s, "V10", 5)
	var n := 200000
	var before_collected := s.manual_cards + s.auto_cards
	s.generate_cards(n, 1, 0, false, true)
	check(s.manual_cards + s.auto_cards == before_collected + n, "aggregate generation conserves collected cards")
	var ranks := PackedInt64Array()
	ranks.resize(13)
	var foils := 0
	for key in s.inventory:
		var meta := PickupRules.decode_bucket(int(key))
		ranks[int(meta.identity) % 13] += int(s.inventory[key])
		if meta.foil:
			foils += int(s.inventory[key])
	var expected := n / 13.0
	var max_dev := 0.0
	for count in ranks:
		max_dev = maxf(max_dev, absf(count - expected) / expected)
	check(max_dev < 0.05, "aggregate ranks remain uniform within 5%% (max dev %.3f)" % max_dev)
	var foil_rate := foils / float(n)
	check(absf(foil_rate - 0.035) < 0.005, "aggregate independent foil rate near 3.5%% (got %.4f)" % foil_rate)
	var mean := 0.0
	var trials := 2000
	for i in trials:
		mean += s._binomial(1000, 0.2)
	mean /= trials
	check(absf(mean - 200.0) < 8.0, "BTPE binomial mean near expectation (got %.1f)" % mean)

func _test_catalog() -> void:
	var s := PickupRules.new(37)
	check(s.entries.size() == 104, "104 named upgrade entries")
	var total_ranks := 0
	for e in s.entries:
		total_ranks += int(e.ranks)
		for p in e.prerequisites:
			check(s.index.has(p.id), "prerequisite exists for " + e.id)
	check(total_ranks == 371, "371 individually purchasable ranks")
	check(near(s.cost("C01"), 25), "band A first cost")
	grant(s, "C01", 1)
	check(near(s.cost("C01"), ceil(25 * 1.65)), "band growth per owned rank")
	grant(s, "C13", 4)
	grant(s, "A03", 7)
	check(s.d("buffer") <= 2.0, "approved buffer cap +200%")
