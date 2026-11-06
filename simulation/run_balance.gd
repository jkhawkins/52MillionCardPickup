extends SceneTree
## Run the six GDD agents against the live rules. Usage:
## godot --headless --path . --script res://simulation/run_balance.gd -- --seed=52 --minutes=240 --out=simulation/results/run.json
var agent_names := ["manual_first", "automation_first", "value_first", "balanced", "low_attention", "high_attention"]

func _init() -> void:
	var seed_value := 52
	var max_minutes := 240.0
	var out := "simulation/results/run.json"
	var only := ""
	var balance_path := "res://data/balance.json"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--seed="): seed_value = int(arg.trim_prefix("--seed="))
		if arg.begins_with("--minutes="): max_minutes = float(arg.trim_prefix("--minutes="))
		if arg.begins_with("--out="): out = arg.trim_prefix("--out=")
		if arg.begins_with("--only="): only = arg.trim_prefix("--only=")
		if arg.begins_with("--balance="): balance_path = arg.trim_prefix("--balance=")
	var report := {"schema_version": 1, "seed": seed_value, "max_minutes": max_minutes, "catalog_hash": PickupRules.catalog_hash(), "balance_path": balance_path, "agents": {}}
	var dt := 0.1
	for name in agent_names:
		if only != "" and name != only:
			continue
		var s := PickupRules.new(seed_value + agent_names.find(name) * 1000, balance_path)
		var agent := BalanceAgent.new(name)
		var start := Time.get_ticks_msec()
		while s.active_time < max_minutes * 60.0 and not s.completed:
			agent.step(s, dt)
		var elapsed := (Time.get_ticks_msec() - start) / 1000.0
		var stats := s.statistics()
		stats["completed"] = s.completed
		stats["completion_minutes"] = s.active_time / 60.0 if s.completed else null
		stats["milestones"] = agent.milestones
		stats["purchases"] = agent.purchases.size()
		var rank_map := {}
		for e in s.entries:
			if s.r(e.id) > 0:
				rank_map[e.id] = s.r(e.id)
		stats["final_ranks"] = rank_map
		stats["wall_seconds"] = elapsed
		stats["max_purchase_wait_seconds"] = agent.max_purchase_wait
		stats["unspent_fraction"] = s.money / maxf(1.0, s.earned)
		report.agents[name] = stats
		print("%s: %s in %.1f min, earned $%s, unspent %.1f%%, wall %.1fs" % [name, "COMPLETE" if s.completed else "incomplete", s.active_time / 60.0, PickupRules.format_number(s.earned), stats.unspent_fraction * 100.0, elapsed])
	DirAccess.make_dir_recursive_absolute(out.get_base_dir())
	var file := FileAccess.open(out, FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	print("Wrote " + out)
	quit(0)
