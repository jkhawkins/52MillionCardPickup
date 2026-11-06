class_name BalanceAgent
extends RefCounted
## Six deterministic playstyles using the exact live PickupRules formulas/costs.
var policy := "balanced"
var manual_clock := 0.0
var decision_clock := 0.0
var ability_clock := 0.0
var opportunity := 0
var purchases: Array[String] = []
var milestones: Array[Dictionary] = []
var next_milestone := 0
var purchase_wait := 0.0
var max_purchase_wait := 0.0
const TARGETS := [5000, 100000, 1000000, 4000000, 12000000, 28000000, 52000000]

func _init(name: String) -> void:
	policy = name

func manual_rate() -> float:
	match policy:
		"manual_first": return 3.0
		"high_attention": return 3.0
		"balanced": return 2.5
		"value_first": return 2.0
		"automation_first": return 1.25
		"low_attention": return 1.5
	return 2.0

func step(s: PickupRules, dt: float) -> void:
	if s.completed and not s.endless:
		return
	manual_clock += dt
	var interval := 1.0 / manual_rate()
	while manual_clock >= interval:
		manual_clock -= interval
		s.manual_input()
	# Before A09, a human presses Deposit; agents must do the same instead of idling at capacity.
	if not s.r("A09") and s.batch_remaining == 0 and s.inventory_count >= s.capacity():
		s.start_deposit(true)
	purchase_wait += dt
	max_purchase_wait = maxf(max_purchase_wait, purchase_wait)
	decision_clock += dt
	if decision_clock >= 0.5:
		decision_clock = 0.0
		_buy_decision(s)
	ability_clock += dt
	if ability_clock >= 1.0:
		ability_clock = 0.0
		_ability_decision(s)
	_event_decision(s)
	s.tick(dt)
	while next_milestone < TARGETS.size() and s.deposited >= TARGETS[next_milestone]:
		milestones.append({"cards": TARGETS[next_milestone], "time": s.active_time, "money": s.money, "cps": s.cps})
		next_milestone += 1

func _buy_decision(s: PickupRules) -> void:
	# Buy one affordable rank at a time. Evaluating only affordable nodes keeps the
	# harness fast; policies still save implicitly by scoring progress per money.
	if s.completed and not s.endless:
		return
	var best := ""
	var best_score := -1.0
	for e in s.entries:
		var id: String = e.id
		if not s.can_buy(id):
			continue
		var score := _score(s, id)
		if score > best_score:
			best_score = score
			best = id
	if best != "":
		s.buy(best)
		purchases.append(best)
		purchase_wait = 0.0

func _score(s: PickupRules, id: String) -> float:
	var cost := s.cost(id)
	var throughput := maxf(1.0, s.auto_throughput() + manual_rate() * s.manual_yield())
	var income := maxf(1.0, throughput * 8.0)
	# Every policy estimates the same live marginal progress; preferences only weight branches.
	var gain := _balanced_gain(s, id, throughput, income)
	var branch := id[0]
	var weight := 1.0
	match policy:
		"manual_first":
			match branch:
				"M": weight = 1.5
				"B": weight = 1.2
				"X": weight = 1.1
				"C": weight = 0.8
				"A": weight = 0.5 if s.r("M03") < 2 else 0.8
				"V": weight = 0.7
				"S": weight = 0.5
				_: weight = 0.6
		"automation_first":
			match branch:
				"A": weight = 1.3
				"C", "P": weight = 1.1
				"D", "V": weight = 1.0
				"X": weight = 0.8
				"M": weight = 0.85
				_: weight = 0.75
		"value_first":
			match branch:
				"V": weight = 1.3
				"H": weight = 1.1
				"S": weight = 0.95
				"D": weight = 1.0
				"A", "C", "M": weight = 1.2
				"X": weight = 0.9
				_: weight = 0.75
		"low_attention":
			match branch:
				"A", "C": weight = 1.0
				"D", "P", "V", "S", "M": weight = 1.0
				"X": weight = 0.9
				_: weight = 0.9
		"high_attention":
			match branch:
				"M": weight = 1.25
				"X": weight = 1.35
				"B": weight = 1.15
				"A", "C", "D", "P": weight = 1.0
				_: weight = 0.9
	gain *= weight
	# Prerequisite paths get a temporary bonus so agents do not ignore required roots.
	for e in s.entries:
		for p in e.prerequisites:
			if p.id == id and s.r(id) < int(p.rank) and s.money >= s.cost(id) * 0.5:
				gain *= 1.25
	return gain / pow(cost, 0.92)

func _balanced_gain(s: PickupRules, id: String, throughput: float, income: float) -> float:
	var before_rate := s.deposit_rate()
	var before_auto := s.auto_throughput()
	var before_manual := s.manual_yield()
	var before_income := s.card_income(6, false, 1, 0, true)
	var old := s.r(id)
	s.ranks[s.index[id]] = old + 1
	s.recalculate()
	var after_rate := s.deposit_rate()
	var after_auto := s.auto_throughput()
	var after_manual := s.manual_yield()
	var after_income := s.card_income(6, false, 1, 0, true)
	s.ranks[s.index[id]] = old
	s.recalculate()
	var pickup_gain := (after_auto - before_auto) + manual_rate() * (after_manual - before_manual)
	var deposit_gain := maxf(0.0, after_rate - before_rate) * 0.35
	var income_gain := maxf(0.0, after_income - before_income) / maxf(1.0, before_income) * income * 0.25
	return pickup_gain + deposit_gain + income_gain + throughput * 0.02

func _ability_decision(s: PickupRules) -> void:
	if policy == "low_attention":
		opportunity += 1
		if opportunity % 4 != 0:
			return
	for i in 5:
		if not s.r(PickupRules.ABILITY_IDS[i]) or s.cooldowns[i] > 0.0:
			continue
		var use := false
		match i:
			0: use = policy in ["manual_first", "high_attention", "balanced"] or s.r("X04")
			1: use = s.batch_remaining > 0 or s.inventory_count >= s.capacity() * 0.75
			2: use = policy != "automation_first" or s.auto_throughput() > 100
			3: use = s.missing_count() > 8
			4: use = s.free_space() >= s.capacity() * 0.1
		if policy == "high_attention" and i == 1:
			use = s.batch_remaining > 0 and (s.deposit_rush_left > 0 or s.batch_full or s.inventory_count >= s.capacity() * 0.9)
		if use:
			s.activate_ability(i)

func _event_decision(s: PickupRules) -> void:
	if policy == "low_attention":
		return
	if not s.waiting_event.is_empty():
		var kind := int(s.waiting_event.kind)
		if kind == 1:
			var choices: Array = s.waiting_event.choices
			var pick := 0
			if s.auto_throughput() > manual_rate() * s.manual_yield() and choices.has(1):
				pick = choices.find(1)
			elif choices.has(2):
				pick = choices.find(2)
			s.interact_event(pick)
		else:
			s.interact_event()
	for item in s.shower_cards.duplicate():
		s.click_shower(int(item.id))
