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
const TARGETS := [5000, 100000, 1000000, 4000000, 12000000, 28000000, 52000000]

func _init(name: String) -> void:
	policy = name

func manual_rate() -> float:
	match policy:
		"manual_first": return 3.0
		"high_attention": return 3.0
		"balanced": return 2.5
		"value_first": return 2.0
		"automation_first": return 1.0
		"low_attention": return 0.75
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
	# Buy one rank at a time. A small reserve prevents starving the next prerequisite.
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
		# Do not spend the last money on a negligible upgrade when a core node is close.
		if s.money >= s.cost(best) * 0.98:
			s.buy(best)
			purchases.append(best)

func _score(s: PickupRules, id: String) -> float:
	var cost := s.cost(id)
	var throughput := maxf(1.0, s.auto_throughput() + manual_rate() * s.manual_yield())
	var income := maxf(1.0, throughput * 8.0)
	var gain := 0.0
	var branch := id[0]
	match policy:
		"manual_first":
			if branch == "M": gain = throughput * 0.9
			elif id in ["C01", "C06", "C05"]: gain = throughput * 0.5
			elif branch == "A": gain = throughput * (0.15 if s.r("M03") >= 2 else 0.02)
			elif branch == "V": gain = income * 0.08
			elif branch == "C": gain = throughput * 0.2
			elif branch == "X": gain = throughput * 0.25
			else: gain = throughput * 0.05
		"automation_first":
			if branch == "A": gain = throughput * 1.2
			elif branch == "C": gain = throughput * 0.7
			elif branch == "P": gain = throughput * 0.6
			elif branch == "V": gain = income * 0.12
			elif branch == "X": gain = throughput * 0.2
			else: gain = throughput * 0.05
		"value_first":
			if branch in ["V", "H"]: gain = income * 0.9
			elif branch == "S": gain = income * 0.35
			elif branch in ["A", "C", "M"]: gain = throughput * 0.35
			elif branch == "X": gain = income * 0.2
			else: gain = throughput * 0.05
		"low_attention":
			if branch in ["A", "C"]: gain = throughput * 0.8
			elif branch in ["V", "D", "P"]: gain = income * 0.15 + throughput * 0.2
			elif branch == "S": gain = throughput * 0.15
			else: gain = throughput * 0.03
		"high_attention":
			if branch in ["M", "X", "B"]: gain = throughput * 0.9
			elif branch in ["A", "C", "D", "P"]: gain = throughput * 0.7
			elif branch in ["V", "H", "S"]: gain = income * 0.2
			else: gain = throughput * 0.1
		_:
			gain = _balanced_gain(s, id, throughput, income)
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
			use = s.batch_remaining > 0 and (s.deposit_rush_left > 0 or s.batch_full)
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
