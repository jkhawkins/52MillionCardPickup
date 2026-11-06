extends Control
## One-screen casino worktable. The simulation owns rules; this script owns presentation/input.
const INK := Color("efe7d2")
const MUTED := Color("a8b5a4")
const GOLD := Color("c9a55c")
const PANEL := Color("0c211a")
const PANEL_LIGHT := Color("143126")
const RED := Color("c65b4e")

var rules: PickupRules
var settings: Dictionary
var audio: PickupAudioDirector
var steam: PickupSteamBridge
var paused := false
var modal_kind := ""
var capture_action := ""
var holding_pickup := false
var hold_clock := 0.0
var ui_clock := 0.0
var save_clock := 0.0
var celebration_left := 0.0
var selected_upgrade := ""
var affordable_seen: Dictionary = {}
var toast_queue: Array[Dictionary] = []
var toast_left := 0.0
var floaters: Array[Dictionary] = []
var float_clock := 0.0
var float_cards := 0
var float_kind := "normal"
var shower_buttons: Dictionary = {}
var event_signature := ""
var upgrade_buttons: Dictionary = {}
var upgrade_labels: Dictionary = {}
var branch_filter := "All"
var font_body: Font
var font_display: Font

var top_goal: Label
var top_remaining: Label
var top_money: Label
var top_cps: Label
var top_time: Label
var save_status: Label
var inv_label: Label
var inv_bar: ProgressBar
var deposit_button: Button
var deposit_bar: ProgressBar
var deposit_info: Label
var ledger_mini: Label
var ledger_button: Button
var auto_toggle: CheckButton
var threshold_box: HBoxContainer
var smart_label: Label
var helper_label: Label
var combo_bar: ProgressBar
var combo_label: Label
var buff_label: Label
var stats_label: Label
var ability_buttons: Array[Button] = []
var ability_bars: Array[ProgressBar] = []
var table: PickupTableArt
var event_box: VBoxContainer
var event_title: Label
var event_choices: HBoxContainer
var shower_layer: Control
var toast_label: Label
var floater_label: Label
var tutorial_pickup: Label
var tutorial_deposit: Label
var tutorial_upgrade: Label
var tutorial_ledger: Label
var modal_layer: Control
var modal_panel: PanelContainer
var modal_title: Label
var modal_content: VBoxContainer
var modal_scroll: ScrollContainer
var upgrade_scroll: ScrollContainer
var upgrade_list: VBoxContainer
var filter_option: OptionButton

func _ready() -> void:
	settings = PickupPersistence.load_settings()
	PickupPersistence.apply_bindings(settings)
	if ResourceLoader.exists("res://assets/fonts/Inter.ttf"):
		font_body = load("res://assets/fonts/Inter.ttf")
	if ResourceLoader.exists("res://assets/fonts/LibreBaskerville.ttf"):
		font_display = load("res://assets/fonts/LibreBaskerville.ttf")
	theme = _make_theme()
	rules = PickupRules.new()
	var loaded := PickupPersistence.load_game(rules)
	rules.notice.connect(_on_notice)
	rules.achievement_unlocked.connect(_on_achievement)
	rules.run_completed.connect(_on_completed)
	audio = PickupAudioDirector.new()
	add_child(audio)
	audio.setup(settings)
	steam = PickupSteamBridge.new()
	for id in rules.achievements:
		steam.unlock(id)
	_build_ui()
	_apply_settings()
	if loaded == "backup":
		_on_notice("Recovered the last good autosave.", "save")
	elif loaded == "invalid":
		_on_notice("Save could not be read. A fresh table is ready; the unreadable file was preserved as save.invalid.json.", "save")
	if rules.completed and not rules.endless:
		_open_modal("results")
	get_window().min_size = Vector2i(1120, 630)
	get_tree().auto_accept_quit = false

func _make_theme() -> Theme:
	var t := Theme.new()
	if font_body:
		t.default_font = font_body
	t.default_font_size = 15
	t.set_color("font_color", "Label", INK)
	t.set_color("font_color", "Button", INK)
	t.set_color("font_hover_color", "Button", Color("fff5d8"))
	t.set_color("font_pressed_color", "Button", GOLD)
	t.set_color("font_disabled_color", "Button", Color("708073"))
	t.set_color("font_color", "CheckBox", INK)
	t.set_color("font_color", "OptionButton", INK)
	var normal := StyleBoxFlat.new()
	normal.bg_color = PANEL_LIGHT
	normal.border_color = Color("3a5545")
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(5)
	normal.content_margin_left = 12
	normal.content_margin_right = 12
	normal.content_margin_top = 8
	normal.content_margin_bottom = 8
	t.set_stylebox("normal", "Button", normal)
	var hover := normal.duplicate()
	hover.bg_color = Color("1d4433")
	hover.border_color = GOLD
	t.set_stylebox("hover", "Button", hover)
	var pressed := normal.duplicate()
	pressed.bg_color = Color("284f3b")
	t.set_stylebox("pressed", "Button", pressed)
	var disabled := normal.duplicate()
	disabled.bg_color = Color("10271e")
	disabled.border_color = Color("263b30")
	t.set_stylebox("disabled", "Button", disabled)
	var focus := StyleBoxFlat.new()
	focus.bg_color = Color.TRANSPARENT
	focus.border_color = Color("f2d58a")
	focus.set_border_width_all(2)
	focus.set_corner_radius_all(5)
	t.set_stylebox("focus", "Button", focus)
	t.set_stylebox("focus", "CheckBox", focus)
	t.set_stylebox("focus", "OptionButton", focus)
	var panel := StyleBoxFlat.new()
	panel.bg_color = PANEL
	panel.border_color = Color("2c4638")
	panel.set_border_width_all(1)
	panel.set_corner_radius_all(8)
	panel.content_margin_left = 14
	panel.content_margin_right = 14
	panel.content_margin_top = 12
	panel.content_margin_bottom = 12
	t.set_stylebox("panel", "PanelContainer", panel)
	var bar_bg := StyleBoxFlat.new()
	bar_bg.bg_color = Color("071710")
	bar_bg.set_corner_radius_all(4)
	t.set_stylebox("background", "ProgressBar", bar_bg)
	var bar_fg := StyleBoxFlat.new()
	bar_fg.bg_color = GOLD
	bar_fg.set_corner_radius_all(4)
	t.set_stylebox("fill", "ProgressBar", bar_fg)
	t.set_color("font_color", "ProgressBar", INK)
	t.set_constant("separation", "VBoxContainer", 8)
	t.set_constant("separation", "HBoxContainer", 8)
	return t

func _panel_style(bg: Color, border: Color, radius: int = 6) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(1)
	s.set_corner_radius_all(radius)
	s.content_margin_left = 10
	s.content_margin_right = 10
	s.content_margin_top = 7
	s.content_margin_bottom = 7
	return s

func _label(text: String, size: int = 15, color: Color = INK, display: bool = false) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	if display and font_display:
		l.add_theme_font_override("font", font_display)
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return l

func _button(text: String, callback: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.pressed.connect(callback)
	b.focus_mode = Control.FOCUS_ALL
	return b

func _body(text: String) -> RichTextLabel:
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.text = text
	r.fit_content = true
	r.scroll_active = false
	r.custom_minimum_size.y = 40
	r.add_theme_color_override("default_color", INK)
	return r

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color("081710")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 16
	root.offset_top = 12
	root.offset_right = -16
	root.offset_bottom = -12
	root.add_theme_constant_override("separation", 10)
	add_child(root)
	_build_top(root)
	var middle := HBoxContainer.new()
	middle.size_flags_vertical = Control.SIZE_EXPAND_FILL
	middle.add_theme_constant_override("separation", 12)
	root.add_child(middle)
	_build_upgrades(middle)
	_build_center(middle)
	_build_right(middle)
	_build_bottom(root)
	toast_label = _label("", 15, Color("f5df9c"))
	toast_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	toast_label.offset_left = 420
	toast_label.offset_right = -360
	toast_label.offset_top = -154
	toast_label.offset_bottom = -120
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(toast_label)
	floater_label = _label("", 24, Color("f6e6a8"), true)
	floater_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(floater_label)
	_build_modal_layer()

func _build_top(root: VBoxContainer) -> void:
	var p := PanelContainer.new()
	p.custom_minimum_size.y = 88
	root.add_child(p)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 24)
	p.add_child(h)
	var title := VBoxContainer.new()
	title.custom_minimum_size.x = 285
	h.add_child(title)
	title.add_child(_label("52 MILLION", 25, GOLD, true))
	title.add_child(_label("C A R D   P I C K U P", 12, MUTED))
	var goal := VBoxContainer.new()
	goal.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(goal)
	goal.add_child(_label("LIFETIME DEPOSITED", 11, MUTED))
	top_goal = _label("0 / 52,000,000", 27, INK, true)
	goal.add_child(top_goal)
	top_remaining = _label("52,000,000 cards remaining", 12, MUTED)
	goal.add_child(top_remaining)
	var cash := VBoxContainer.new()
	cash.custom_minimum_size.x = 190
	h.add_child(cash)
	cash.add_child(_label("TABLE BANK", 11, MUTED))
	top_money = _label("$0", 26, GOLD, true)
	cash.add_child(top_money)
	top_cps = _label("0 cards/s", 12, MUTED)
	cash.add_child(top_cps)
	var meta := VBoxContainer.new()
	meta.custom_minimum_size.x = 140
	h.add_child(meta)
	top_time = _label("00:00:00", 16, INK)
	meta.add_child(top_time)
	save_status = _label("Local autosave", 11, MUTED)
	meta.add_child(save_status)
	var pause := _button("Pause  [Esc]", _toggle_pause)
	meta.add_child(pause)

func _build_upgrades(middle: HBoxContainer) -> void:
	var p := PanelContainer.new()
	p.custom_minimum_size.x = 365
	middle.add_child(p)
	var v := VBoxContainer.new()
	p.add_child(v)
	var header := HBoxContainer.new()
	v.add_child(header)
	var v2 := VBoxContainer.new()
	v2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(v2)
	v2.add_child(_label("The Upgrade Tree", 20, GOLD, true))
	v2.add_child(_label("104 entries · every path stays open", 11, MUTED))
	filter_option = OptionButton.new()
	filter_option.custom_minimum_size.x = 112
	for name in ["All", "Capacity", "Manual", "Automation", "Value", "Seekers", "Suits"]:
		filter_option.add_item(name)
	filter_option.item_selected.connect(func(i): branch_filter = ["All", "C", "M", "A", "V", "S", "Suits"][i]; _refresh_upgrade_visibility())
	header.add_child(filter_option)
	tutorial_upgrade = _label("Start with Wide Grip, Deep Pockets, Quick Count or Premium Stock.", 12, Color("d8c58a"))
	tutorial_upgrade.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tutorial_upgrade.custom_minimum_size.y = 34
	v.add_child(tutorial_upgrade)
	upgrade_scroll = ScrollContainer.new()
	upgrade_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	upgrade_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(upgrade_scroll)
	upgrade_list = VBoxContainer.new()
	upgrade_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	upgrade_list.add_theme_constant_override("separation", 5)
	upgrade_scroll.add_child(upgrade_list)
	var last_branch := ""
	var last_suit := ""
	for e in rules.entries:
		var branch: String = e.branch
		var parent: String = e.parent_branch
		if branch == "Active Abilities":
			branch = {"C": "Capacity & Deposit", "M": "Manual, Combo & Luck", "A": "Automation", "V": "Value, Decks & Foils", "S": "Card Seekers"}[parent]
		if branch != last_branch:
			var heading := _label(branch.to_upper(), 12, GOLD)
			heading.custom_minimum_size.y = 30
			heading.set_meta("branch", _branch_key(branch))
			upgrade_list.add_child(heading)
			last_branch = branch
			last_suit = ""
		if e.suit_branch != "" and e.suit_branch != last_suit:
			var sh := _label(e.suit_branch, 12, MUTED)
			sh.set_meta("branch", "Suits")
			upgrade_list.add_child(sh)
			last_suit = e.suit_branch
		var b := Button.new()
		b.custom_minimum_size.y = 54
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.clip_text = true
		b.tooltip_text = _upgrade_tooltip(e.id)
		b.pressed.connect(_on_upgrade_pressed.bind(e.id))
		b.mouse_entered.connect(func(): selected_upgrade = e.id; _refresh_upgrade_styles())
		b.focus_entered.connect(func(): selected_upgrade = e.id; _refresh_upgrade_styles())
		b.set_meta("branch", _branch_key(branch))
		upgrade_list.add_child(b)
		upgrade_buttons[e.id] = b
		var row := HBoxContainer.new()
		row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		row.offset_left = 10
		row.offset_right = -10
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(row)
		var texts := VBoxContainer.new()
		texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		texts.mouse_filter = Control.MOUSE_FILTER_IGNORE
		texts.add_theme_constant_override("separation", 0)
		row.add_child(texts)
		var name_label := _label("", 14, INK)
		name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		texts.add_child(name_label)
		var effect_label := _label("", 10, MUTED)
		effect_label.clip_text = true
		effect_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		texts.add_child(effect_label)
		var cost_label := _label("", 13, GOLD)
		cost_label.custom_minimum_size.x = 74
		cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		cost_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(cost_label)
		upgrade_labels[e.id] = [name_label, effect_label, cost_label]
	_refresh_upgrade_visibility()

func _branch_key(branch: String) -> String:
	return {"Capacity & Deposit": "C", "Manual, Combo & Luck": "M", "Automation": "A", "Value, Decks & Foils": "V", "Card Seekers": "S", "Suit Specializations": "Suits"}.get(branch, "All")

func _refresh_upgrade_visibility() -> void:
	for child in upgrade_list.get_children():
		child.visible = branch_filter == "All" or str(child.get_meta("branch", "")) == branch_filter

func _upgrade_tooltip(id: String) -> String:
	var e := rules.entry(id)
	var rank := rules.r(id)
	var text := "[b]%s · %s[/b]\n%s\nRank %d / %d\n" % [id, e.name, e.effect, rank, int(e.ranks)]
	if rank < int(e.ranks):
		text += "Next rank: %s\nCost: $%s\n" % [e.effect, _num(rules.cost(id), true)]
		text += "Requires: " + rules.prerequisite_text(id)
	else:
		text += "Fully owned."
	if id == "C13":
		text += "\nCurrent bonus +%d%% · cap +200%%" % int(rules.d("buffer") * 100)
	if id == "X03":
		text += "\nApproved: fractional output adds cards, not extra Combo/Lucky rolls."
	return text

func _on_upgrade_pressed(id: String) -> void:
	selected_upgrade = id
	if rules.buy(id):
		audio.play_ui("buy")
		_on_notice("%s → rank %d" % [rules.entry(id).name, rules.r(id)], "buy")
		_save_game("purchase")
	else:
		audio.play_ui()
		if not rules.prerequisites_met(id):
			_on_notice("Path: " + rules.prerequisite_text(id), "locked")
		elif rules.maxed(id):
			_on_notice("%s is fully owned." % rules.entry(id).name, "info")
		else:
			_on_notice("Need $%s more for %s." % [_num(rules.cost(id) - rules.money, true), rules.entry(id).name], "locked")
	_refresh_upgrade_styles()

func _refresh_upgrade_styles() -> void:
	for id in upgrade_buttons:
		var b: Button = upgrade_buttons[id]
		var labels: Array = upgrade_labels[id]
		var rank := rules.r(id)
		var maxed := rules.maxed(id)
		var unlocked := rules.prerequisites_met(id)
		var affordable := rules.can_buy(id)
		labels[0].text = "%s  %s" % [id, rules.entry(id).name] + ("  ✓" if maxed else "")
		labels[1].text = rules.entry(id).effect
		labels[2].text = "OWNED" if maxed else "$" + _num(rules.cost(id))
		labels[2].add_theme_color_override("font_color", GOLD if affordable else MUTED)
		var border := Color("2c4638")
		var bg := Color("10271e")
		if maxed:
			bg = Color("183326")
			border = Color("4a6b50")
		elif affordable:
			bg = Color("1d3d2c")
			border = Color("9d8548")
		elif not unlocked:
			bg = Color("0d2019")
			border = Color("263b30")
		if selected_upgrade == id:
			border = Color("f0d28a")
		elif selected_upgrade != "" and not unlocked:
			for p in rules.entry(selected_upgrade).prerequisites:
				if p.id == id:
					border = Color("d08d55")
		if bool(settings.new_affordable_indicator) and affordable and not affordable_seen.has(id + str(rank)):
			labels[2].text = "• " + labels[2].text
		b.add_theme_stylebox_override("normal", _panel_style(bg, border, 4))
		b.tooltip_text = _upgrade_tooltip(id)
		if affordable:
			affordable_seen[id + str(rank)] = true

func _build_center(middle: HBoxContainer) -> void:
	var center := VBoxContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	middle.add_child(center)
	var table_panel := PanelContainer.new()
	table_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	table_panel.add_theme_stylebox_override("panel", _panel_style(Color("123d30"), Color("4a6349"), 10))
	center.add_child(table_panel)
	var overlay := Control.new()
	overlay.clip_contents = true
	table_panel.add_child(overlay)
	table = PickupTableArt.new()
	table.rules = rules
	table.settings = settings
	table.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(table)
	var table_heading := _label("THE WORKTABLE", 12, Color(0.9, 0.85, 0.68, 0.7))
	table_heading.position = Vector2(24, 70)
	table_heading.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(table_heading)
	tutorial_pickup = _label("Click the felt or hold Space to pick up your first card.", 14, Color("f2df9f"))
	tutorial_pickup.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	tutorial_pickup.offset_left = 24
	tutorial_pickup.offset_right = -24
	tutorial_pickup.offset_top = -76
	tutorial_pickup.offset_bottom = -44
	tutorial_pickup.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tutorial_pickup.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(tutorial_pickup)
	var carried := _label("", 13, MUTED)
	carried.name = "CarriedCaption"
	carried.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	carried.position = Vector2(-100, 110)
	carried.custom_minimum_size.x = 200
	carried.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	carried.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(carried)
	event_box = VBoxContainer.new()
	event_box.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	event_box.offset_left = 70
	event_box.offset_right = -70
	event_box.offset_top = 96
	event_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(event_box)
	event_title = _label("", 16, Color("f5df9c"), true)
	event_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	event_box.add_child(event_title)
	event_choices = HBoxContainer.new()
	event_choices.alignment = BoxContainer.ALIGNMENT_CENTER
	event_box.add_child(event_choices)
	shower_layer = Control.new()
	shower_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shower_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(shower_layer)

func _build_right(middle: HBoxContainer) -> void:
	var p := PanelContainer.new()
	p.custom_minimum_size.x = 310
	middle.add_child(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 9)
	p.add_child(v)
	v.add_child(_label("Inventory & Counting", 19, GOLD, true))
	inv_label = _label("0 / 52 cards", 22, INK)
	v.add_child(inv_label)
	inv_bar = ProgressBar.new()
	inv_bar.custom_minimum_size.y = 18
	inv_bar.max_value = 100
	inv_bar.show_percentage = false
	v.add_child(inv_bar)
	deposit_button = _button("Deposit  [D]", _toggle_deposit)
	deposit_button.custom_minimum_size.y = 52
	deposit_button.add_theme_font_size_override("font_size", 18)
	v.add_child(deposit_button)
	tutorial_deposit = _label("Fill the tray, then count cards into the ledger.", 11, Color("d8c58a"))
	tutorial_deposit.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tutorial_deposit.custom_minimum_size.y = 30
	v.add_child(tutorial_deposit)
	deposit_bar = ProgressBar.new()
	deposit_bar.custom_minimum_size.y = 14
	deposit_bar.max_value = 100
	deposit_bar.show_percentage = false
	v.add_child(deposit_bar)
	deposit_info = _label("13 cards/s · manual pickup pauses while counting", 11, MUTED)
	deposit_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	deposit_info.custom_minimum_size.y = 32
	v.add_child(deposit_info)
	v.add_child(HSeparator.new())
	ledger_button = _button("Deck Ledger  [L]", func(): _open_modal("ledger"))
	v.add_child(ledger_button)
	ledger_mini = _label("0 / 52 identities · 0 decks bound", 12, MUTED)
	ledger_mini.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ledger_mini.custom_minimum_size.y = 34
	v.add_child(ledger_mini)
	tutorial_ledger = _label("Open the ledger to see which identities are missing.", 11, Color("d8c58a"))
	tutorial_ledger.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tutorial_ledger.custom_minimum_size.y = 30
	v.add_child(tutorial_ledger)
	v.add_child(HSeparator.new())
	auto_toggle = CheckButton.new()
	auto_toggle.text = "Auto-deposit"
	auto_toggle.toggled.connect(func(on): rules.auto_enabled = on; rules.auto_delay = 0.0; _save_game("settings"))
	v.add_child(auto_toggle)
	threshold_box = HBoxContainer.new()
	threshold_box.add_theme_constant_override("separation", 4)
	v.add_child(threshold_box)
	for value in [0.25, 0.5, 0.75, 1.0]:
		var b := _button("%d%%" % int(value * 100), _set_threshold.bind(value))
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.add_theme_font_size_override("font_size", 12)
		threshold_box.add_child(b)
	smart_label = _label("Threshold controls unlock with A10.", 11, MUTED)
	smart_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	smart_label.custom_minimum_size.y = 28
	v.add_child(smart_label)
	v.add_child(HSeparator.new())
	helper_label = _label("No helpers yet", 12, MUTED)
	helper_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	helper_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(helper_label)
	var help := _button("How to play", func(): _open_modal("instructions"))
	v.add_child(help)

func _build_bottom(root: VBoxContainer) -> void:
	var p := PanelContainer.new()
	p.custom_minimum_size.y = 116
	root.add_child(p)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 14)
	p.add_child(h)
	var abilities := HBoxContainer.new()
	abilities.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(abilities)
	for i in 5:
		var slot := VBoxContainer.new()
		slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slot.add_theme_constant_override("separation", 3)
		abilities.add_child(slot)
		var b := _button("", _activate_ability.bind(i))
		b.custom_minimum_size.y = 58
		b.add_theme_font_size_override("font_size", 12)
		b.clip_text = false
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		slot.add_child(b)
		ability_buttons.append(b)
		var bar := ProgressBar.new()
		bar.custom_minimum_size.y = 7
		bar.max_value = 100
		bar.show_percentage = false
		slot.add_child(bar)
		ability_bars.append(bar)
	var combo := VBoxContainer.new()
	combo.custom_minimum_size.x = 250
	h.add_child(combo)
	combo_label = _label("Combo locked · M10", 13, GOLD)
	combo.add_child(combo_label)
	combo_bar = ProgressBar.new()
	combo_bar.custom_minimum_size.y = 14
	combo_bar.show_percentage = false
	combo.add_child(combo_bar)
	buff_label = _label("No active effects", 11, MUTED)
	buff_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	buff_label.custom_minimum_size.y = 34
	combo.add_child(buff_label)
	stats_label = _label("", 11, MUTED)
	stats_label.custom_minimum_size.x = 185
	stats_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	h.add_child(stats_label)

func _build_modal_layer() -> void:
	modal_layer = Control.new()
	modal_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal_layer.visible = false
	add_child(modal_layer)
	var dim := ColorRect.new()
	dim.color = Color(0.01, 0.04, 0.03, 0.86)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal_layer.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal_layer.add_child(center)
	modal_panel = PanelContainer.new()
	modal_panel.custom_minimum_size = Vector2(980, 720)
	modal_panel.add_theme_stylebox_override("panel", _panel_style(Color("0e281f"), GOLD, 10))
	center.add_child(modal_panel)
	var v := VBoxContainer.new()
	modal_panel.add_child(v)
	var header := HBoxContainer.new()
	v.add_child(header)
	modal_title = _label("", 26, GOLD, true)
	modal_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(modal_title)
	var close := _button("Close", _close_modal)
	header.add_child(close)
	modal_scroll = ScrollContainer.new()
	modal_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	modal_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(modal_scroll)
	modal_content = VBoxContainer.new()
	modal_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	modal_content.add_theme_constant_override("separation", 12)
	modal_scroll.add_child(modal_content)

func _input(event: InputEvent) -> void:
	if capture_action != "":
		if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
			capture_action = ""
			_open_modal("controls")
			get_viewport().set_input_as_handled()
			return
		if (event is InputEventKey or event is InputEventMouseButton) and event.pressed:
			var code := PickupPersistence.event_code(event)
			if code != 0:
				_assign_binding(capture_action, code)
				capture_action = ""
				_open_modal("controls")
				get_viewport().set_input_as_handled()
			return
	if event.is_action_pressed("cp_pause"):
		if modal_kind != "":
			_close_modal()
		else:
			_toggle_pause()
		get_viewport().set_input_as_handled()
		return
	if modal_kind != "" or paused:
		return
	if event.is_action_pressed("cp_deposit"):
		_toggle_deposit()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("cp_ledger"):
		_open_modal("ledger")
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("cp_upgrades"):
		upgrade_scroll.grab_focus()
		if upgrade_list.get_child_count() > 0:
			for child in upgrade_list.get_children():
				if child is Button and child.visible:
					child.grab_focus()
					break
		get_viewport().set_input_as_handled()
	for i in 5:
		if event.is_action_pressed("cp_ability_%d" % (i + 1)):
			_activate_ability(i)
			get_viewport().set_input_as_handled()
	if event.is_action_pressed("cp_pickup"):
		var mouse_event := event is InputEventMouseButton
		if not mouse_event or table.get_global_rect().has_point(get_global_mouse_position()):
			_do_pickup()
			holding_pickup = true
			hold_clock = 0.0
			get_viewport().set_input_as_handled()
	if event.is_action_released("cp_pickup"):
		holding_pickup = false

func _process(delta: float) -> void:
	if rules == null:
		return
	steam.tick()
	var sim_paused := paused or (modal_kind != "" and modal_kind != "ledger")
	if not sim_paused:
		if holding_pickup and bool(settings.hold_to_pickup):
			hold_clock += delta
			var interval := 1.0 / rules.d("hold_rate")
			while hold_clock >= interval:
				hold_clock -= interval
				_do_pickup()
		var steps := int(ceil(delta / 0.05))
		var dt := delta / maxf(1, steps)
		for i in steps:
			rules.tick(dt)
		if rules.save_reason != "":
			_save_game(rules.save_reason)
			rules.save_reason = ""
		save_clock += delta
		if save_clock >= 10.0:
			save_clock = 0.0
			_save_game("autosave")
	if celebration_left > 0.0:
		celebration_left -= delta
		if celebration_left <= 0.0:
			_open_modal("results")
	audio.tick(rules, delta, sim_paused)
	ui_clock += delta
	if ui_clock >= 0.1:
		ui_clock = 0.0
		_refresh_ui()
		_refresh_upgrade_styles()
		_refresh_events()
	_update_floaters(delta)
	if toast_left > 0.0:
		toast_left -= delta
		if toast_left <= 0.0:
			toast_label.text = ""
	if toast_label.text == "" and not toast_queue.is_empty():
		var next: Dictionary = toast_queue.pop_front()
		toast_label.text = next.text
		toast_left = 2.6

func _do_pickup() -> void:
	if paused or modal_kind != "":
		return
	var made := rules.manual_input()
	if made > 0:
		table.pickup_pulse = 1.0
		var pitch := 1.0 + minf(0.35, rules.combo / maxf(1, rules.combo_max()) * 0.35)
		audio.play_effect("lucky" if rules.last_pickup_kind == "lucky" else "pickup", pitch, 0.65)
		float_cards += made
		float_kind = rules.last_pickup_kind
	else:
		if rules.batch_remaining > 0:
			audio.play_effect("block", 1.0, 0.25)
		elif rules.carried() >= rules.capacity():
			audio.play_effect("block", 0.9, 0.35)

func _toggle_deposit() -> void:
	if rules.batch_remaining > 0:
		rules.cancel_deposit()
		_on_notice("Deposit cancelled. Counted cards stay deposited; the rest return to the tray.", "info")
	else:
		if rules.start_deposit(true):
			audio.play_effect("deposit", 0.8, 0.5)
		else:
			audio.play_effect("block", 1.0, 0.3)
	_save_game("deposit")

func _set_threshold(value: float) -> void:
	if not rules.r("A10"):
		_on_notice("Threshold Controls (A10) unlocks 25/50/75/100%.", "locked")
		return
	rules.auto_threshold = value
	rules.auto_delay = 0.0
	audio.play_ui()
	_save_game("settings")

func _activate_ability(slot: int) -> void:
	if rules.activate_ability(slot):
		audio.play_effect("ability", 1.0 + slot * 0.06, 0.6)
		_save_game("ability")
	else:
		audio.play_ui()

func _refresh_ui() -> void:
	top_goal.text = "%s / %s" % [_num(rules.deposited, bool(settings.exact_numbers)), _num(PickupRules.GOAL, bool(settings.exact_numbers))]
	top_remaining.text = "%s cards remaining%s" % [_num(maxi(0, PickupRules.GOAL - rules.deposited), true), " · ENDLESS" if rules.endless else ""]
	top_money.text = "$" + _num(rules.money)
	top_cps.text = "%s cards/s · peak %s" % [_num(rules.cps), _num(rules.peak_cps)]
	top_time.text = PickupRules.format_time(rules.active_time)
	inv_label.text = "%s / %s cards" % [_num(rules.carried(), true), _num(rules.capacity(), true)]
	inv_bar.value = 100.0 * rules.carried() / maxf(1, rules.capacity())
	if rules.batch_remaining > 0:
		deposit_button.text = "Cancel deposit  [D]"
		deposit_bar.value = 100.0 * (1.0 - rules.batch_remaining / maxf(1, rules.batch_start_size))
		deposit_info.text = "%s left · %s cards/s · %.1fs\nMomentum +%d%%%s" % [_num(rules.batch_remaining), _num(rules.deposit_rate()), rules.estimated_deposit_time(), int(rules.deposit_momentum() * 100), " · FULL BATCH" if rules.batch_full else ""]
	else:
		deposit_button.text = "Deposit %s  [D]" % _num(rules.inventory_count)
		deposit_button.disabled = rules.inventory_count == 0 or (rules.completed and not rules.endless)
		deposit_bar.value = 0
		deposit_info.text = "%s cards/s · est. %.1fs\nManual pickup pauses while counting" % [_num(rules.deposit_rate()), rules.estimated_deposit_time()]
	ledger_mini.text = "%d / 52 identities · %s decks bound\nSeeker bias %d%% · %d missing" % [52 - rules.missing_count(), _num(rules.bound_decks), int(rules.seeker_bias() * 100), rules.missing_count()]
	auto_toggle.disabled = not rules.r("A09")
	auto_toggle.set_pressed_no_signal(rules.auto_enabled and rules.r("A09") > 0)
	for i in threshold_box.get_child_count():
		var b: Button = threshold_box.get_child(i)
		b.disabled = not rules.r("A10")
		var value: float = [0.25, 0.5, 0.75, 1.0][i]
		b.text = ("▶ " if is_equal_approx(rules.auto_threshold, value) else "") + "%d%%" % int(value * 100)
	smart_label.text = ("Smart Thresholds %d/3 · predictive counting" % rules.r("A11")) if rules.r("A11") else ("Auto-deposit at %d%% capacity" % int(rules.auto_threshold * 100) if rules.r("A09") else "Auto-depositor unlocks with A09.")
	if rules.helper_count():
		helper_label.text = "%d helpers · %.1f picks/s each\n%s cards/s · yield %.1f\n%s" % [rules.helper_count(), rules.auto_rate(), _num(rules.auto_throughput()), rules.auto_yield(), "BLOCKED · tray full" if rules.free_space() == 0 else ("Counting while helpers pick" if rules.batch_remaining > 0 else "Picking into free capacity")]
	else:
		helper_label.text = "No helpers yet.\nAuto-Picker (A01) needs Deep Pockets I and Wide Grip I."
	if rules.r("M10"):
		combo_label.text = "Combo %d / %d" % [int(rules.combo), rules.combo_max()]
		combo_bar.max_value = rules.combo_max()
		combo_bar.value = rules.combo
	else:
		combo_label.text = "Combo locked · M10"
		combo_bar.max_value = 50
		combo_bar.value = 0
	var buffs := PackedStringArray()
	if rules.timed_active(0): buffs.append("Surge %.0fs" % rules.durations[0])
	if rules.timed_active(1): buffs.append("Express %.0fs" % rules.durations[1])
	if rules.timed_active(2): buffs.append("Frenzy %.0fs" % rules.durations[2])
	if rules.pulse_left > 0: buffs.append("Pulse %d cards" % rules.pulse_left)
	if rules.dealer_left > 0: buffs.append("Dealer: %s %.0fs" % [rules.dealer_choice_name(rules.dealer_buff), rules.dealer_left])
	if rules.suit_surge_left > 0: buffs.append("%s ×2 %.0fs" % [PickupRules.SUIT_NAMES[rules.suit_surge], rules.suit_surge_left])
	if rules.foil_flash_left > 0: buffs.append("Foil Flash %.0fs" % rules.foil_flash_left)
	if rules.deposit_rush_left > 0: buffs.append("Deposit Rush %.0fs" % rules.deposit_rush_left)
	buff_label.text = " · ".join(buffs) if not buffs.is_empty() else "No active effects"
	stats_label.text = "Manual yield %.1f\nHold %.1f/s · foil %.1f%%\nUtilization %d%% · blocked %ds" % [rules.manual_yield(), rules.d("hold_rate"), rules.foil_chance(0) * 100, int(rules.depositing_time / maxf(1, rules.active_time) * 100), int(rules.blocked_time)]
	for i in 5:
		var b := ability_buttons[i]
		var owned := rules.r(PickupRules.ABILITY_IDS[i]) > 0
		b.disabled = not owned or rules.cooldowns[i] > 0 or (rules.completed and not rules.endless)
		if not owned:
			b.text = "%d\n%s\nLocked · %s" % [i + 1, PickupRules.ABILITY_NAMES[i], PickupRules.ABILITY_IDS[i]]
			ability_bars[i].value = 0
		elif rules.cooldowns[i] > 0:
			b.text = "%d · %s\n%.0fs" % [i + 1, PickupRules.ABILITY_NAMES[i], rules.cooldowns[i]]
			ability_bars[i].value = 100.0 * (1.0 - rules.cooldowns[i] / rules.ability_cooldown(i))
		else:
			b.text = "%d · %s\nREADY" % [i + 1, PickupRules.ABILITY_NAMES[i]]
			ability_bars[i].value = 100
		b.tooltip_text = _ability_tooltip(i)
	tutorial_pickup.visible = not bool(rules.tutorial.get("pickup", false))
	tutorial_deposit.visible = not bool(rules.tutorial.get("deposit", false))
	tutorial_upgrade.visible = not bool(rules.tutorial.get("upgrade", false))
	tutorial_ledger.visible = not bool(rules.tutorial.get("ledger", false))
	var caption := table.get_node_or_null("CarriedCaption") as Label
	if caption:
		caption.text = "%s carried" % _num(rules.carried(), true)
		caption.position = Vector2(table.size.x * 0.5 - 100, table.size.y * 0.47 + 108)
	if modal_kind == "ledger":
		_refresh_ledger_modal()

func _ability_tooltip(slot: int) -> String:
	var id: String = PickupRules.ABILITY_IDS[slot]
	var text := "%s\n%s\n" % [PickupRules.ABILITY_NAMES[slot], rules.entry(id).effect]
	if rules.r(id):
		text += "Cooldown %.0fs" % rules.ability_cooldown(slot)
		if slot < 3:
			text += " · duration %.0fs" % rules.ability_duration(slot)
		if slot == 3:
			text += " · %d cards, %d%% bias" % [52 + 26 * rules.r("X12"), int((0.65 + 0.05 * rules.r("X13")) * 100)]
		if slot == 4:
			text += " · %s cards" % _num(int(rules.capacity() * (0.1 + 0.05 * rules.r("X15"))))
	else:
		text += "Requires: " + rules.prerequisite_text(id)
	return text

func _refresh_events() -> void:
	var signature := JSON.stringify(rules.waiting_event)
	if signature == event_signature:
		_refresh_shower_positions()
		return
	event_signature = signature
	for child in event_choices.get_children():
		event_choices.remove_child(child)
		child.queue_free()
	event_title.text = ""
	if not rules.waiting_event.is_empty():
		var kind := int(rules.waiting_event.kind)
		event_title.text = PickupRules.EVENT_NAMES[kind]
		if kind == 1:
			for i in 3:
				var choice := int(rules.waiting_event.choices[i])
				var b := _button("%s\n%.0fs" % [rules.dealer_choice_name(choice), rules.waiting_event.duration], _engage_event.bind(i))
				event_choices.add_child(b)
		else:
			var prompt: String = {"0": "Start the shower", "4": "Ring the bell", "5": "Take a second wind"}.get(str(kind), "Engage")
			event_choices.add_child(_button(prompt, _engage_event.bind(-1)))
	_refresh_shower_positions()

func _refresh_shower_positions() -> void:
	# Shower buttons are persistent while active; reduced motion keeps them stationary.
	var alive: Dictionary = {}
	for item in rules.shower_cards:
		var id := int(item.id)
		alive[id] = true
		if not shower_buttons.has(id):
			var b := _button("＋", _click_shower.bind(id))
			b.custom_minimum_size = Vector2(48, 62)
			b.add_theme_font_size_override("font_size", 24)
			b.tooltip_text = "Shower card: one pickup, limited by capacity"
			shower_layer.add_child(b)
			shower_buttons[id] = b
		var b: Button = shower_buttons[id]
		var x := float(item.x) * shower_layer.size.x
		var y := float(item.y) * shower_layer.size.y
		if not bool(settings.reduced_motion):
			y += (2.4 - float(item.life)) * 22.0
		b.position = Vector2(x - 24, y - 31)
	for id in shower_buttons.keys():
		if not alive.has(id):
			shower_buttons[id].queue_free()
			shower_buttons.erase(id)

func _engage_event(choice: int) -> void:
	if rules.interact_event(choice):
		audio.play_effect("ability", 1.2, 0.5)
		_refresh_events()

func _click_shower(id: int) -> void:
	if rules.click_shower(id):
		audio.play_effect("pickup", 1.2, 0.5)

func _update_floaters(delta: float) -> void:
	float_clock += delta
	if float_clock >= 0.35 and float_cards > 0:
		if str(settings.floating_numbers) != "off":
			var text := "+%s" % _num(float_cards)
			if rules.last_pickup_kind == "lucky": text += " LUCKY"
			elif rules.last_pickup_kind == "burst": text += " BURST"
			floater_label.text = text
			floater_label.modulate.a = 1.0
			var pos := table.get_global_rect().get_center() + Vector2(80, -40)
			floater_label.position = pos
			if not bool(settings.reduced_motion):
				floater_label.position.y -= 18
		float_cards = 0
		float_clock = 0.0
	if floater_label.modulate.a > 0:
		floater_label.modulate.a = maxf(0, floater_label.modulate.a - delta * 1.4)
		if not bool(settings.reduced_motion):
			floater_label.position.y -= delta * 22

func _on_notice(text: String, kind: String) -> void:
	if kind == "deck" or kind == "achievement" or kind == "ability" or kind == "event" or kind == "save":
		toast_queue.append({"text": text, "kind": kind})
		if toast_queue.size() > 5:
			toast_queue.pop_front()

func _on_achievement(id: String) -> void:
	steam.unlock(id)

func _on_completed() -> void:
	celebration_left = 2.4
	holding_pickup = false
	audio.play_effect("deck", 0.9, 1.0)
	_save_game("completion")

func _save_game(reason: String) -> void:
	if PickupPersistence.save_game(rules):
		save_status.text = "Saved · " + reason
	else:
		save_status.text = "SAVE FAILED"
		_on_notice("Could not write the local save. Check disk space and permissions.", "save")

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_WM_CLOSE_REQUEST:
		if rules:
			_save_game("focus")
			holding_pickup = false
			if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
				paused = true
		if what == NOTIFICATION_WM_CLOSE_REQUEST:
			if steam:
				steam.shutdown()
			get_tree().quit()
	if what == NOTIFICATION_APPLICATION_FOCUS_IN:
		if rules and modal_kind == "" and not bool(get_meta("user_paused", false)):
			paused = false

func _toggle_pause() -> void:
	if modal_kind != "":
		_close_modal()
		return
	paused = true
	set_meta("user_paused", true)
	holding_pickup = false
	_save_game("pause")
	_open_modal("pause")

func _close_modal() -> void:
	if modal_kind == "results" and rules.completed and not rules.endless:
		return
	modal_kind = ""
	capture_action = ""
	modal_layer.visible = false
	paused = false
	set_meta("user_paused", false)
	holding_pickup = false

func _open_modal(kind: String) -> void:
	modal_kind = kind
	capture_action = ""
	holding_pickup = false
	modal_layer.visible = true
	paused = kind != "ledger"
	for child in modal_content.get_children():
		modal_content.remove_child(child)
		child.queue_free()
	match kind:
		"pause": _build_pause_modal()
		"settings": _build_settings_modal()
		"controls": _build_controls_modal()
		"ledger": _build_ledger_modal()
		"instructions": _build_instructions_modal()
		"achievements": _build_achievements_modal()
		"results": _build_results_modal()
		"fresh": _build_fresh_modal()
	await get_tree().process_frame
	if modal_content.get_child_count() > 0:
		var first := modal_content.get_child(0)
		if first is Button:
			first.grab_focus()

func _build_pause_modal() -> void:
	modal_title.text = "Table paused"
	modal_content.add_child(_body("Timers, helpers, cooldowns and events are stopped. No offline progress is calculated."))
	modal_content.add_child(_button("Resume", _close_modal))
	modal_content.add_child(_button("Settings & accessibility", func(): _open_modal("settings")))
	modal_content.add_child(_button("Remap controls", func(): _open_modal("controls")))
	modal_content.add_child(_button("Achievements", func(): _open_modal("achievements")))
	modal_content.add_child(_button("How to play", func(): _open_modal("instructions")))
	modal_content.add_child(_button("Save now", func(): _save_game("manual")))
	modal_content.add_child(_button("Start a fresh run…", func(): _open_modal("fresh")))
	modal_content.add_child(_button("Quit to desktop", func(): _save_game("quit"); steam.shutdown(); get_tree().quit()))

func _build_settings_modal() -> void:
	modal_title.text = "Settings & accessibility"
	modal_content.add_child(_button("Back", func(): _open_modal("pause")))
	var checks := [["hold_to_pickup", "Hold-to-pickup (no rapid clicking required)"], ["reduced_motion", "Reduced motion / no falling or flashing effects"], ["high_contrast", "High-contrast card faces"], ["exact_numbers", "Exact main counter instead of abbreviations"], ["new_affordable_indicator", "Mark newly affordable upgrade ranks"]]
	for pair in checks:
		var c := CheckButton.new()
		c.text = pair[1]
		c.button_pressed = bool(settings[pair[0]])
		c.toggled.connect(func(on): settings[pair[0]] = on; _apply_settings())
		modal_content.add_child(c)
	var floats := OptionButton.new()
	for name in ["aggregated", "off"]:
		floats.add_item("Floating numbers: " + name)
	floats.select(["aggregated", "off"].find(str(settings.floating_numbers)))
	floats.item_selected.connect(func(i): settings.floating_numbers = ["aggregated", "off"][i]; _apply_settings())
	modal_content.add_child(floats)
	_add_slider("UI scale", "ui_scale", 0.85, 1.35, 0.05)
	for pair in [["Music", "music_volume"], ["Ambience", "ambience_volume"], ["Effects", "effects_volume"], ["Interface", "ui_volume"]]:
		_add_slider(pair[0], pair[1], 0.0, 1.0, 0.05)
	modal_content.add_child(_button("Reset contextual tutorial", func(): rules.tutorial.clear(); _save_game("tutorial"); _on_notice("Tutorial prompts reset.", "save")))

func _add_slider(title: String, key: String, low: float, high: float, step: float) -> void:
	var row := HBoxContainer.new()
	var label := _label(title, 15, INK)
	label.custom_minimum_size.x = 180
	row.add_child(label)
	var slider := HSlider.new()
	slider.min_value = low
	slider.max_value = high
	slider.step = step
	slider.value = float(settings[key])
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(slider)
	var value := _label("%.2f" % slider.value, 14, GOLD)
	value.custom_minimum_size.x = 60
	row.add_child(value)
	slider.value_changed.connect(func(v): settings[key] = v; value.text = "%.2f" % v; _apply_settings())
	modal_content.add_child(row)

func _apply_settings() -> void:
	PickupPersistence.save_settings(settings)
	PickupPersistence.apply_bindings(settings)
	get_window().content_scale_factor = float(settings.ui_scale)
	if audio:
		audio.apply_settings(settings)
	if table:
		table.settings = settings
		table.queue_redraw()

func _build_controls_modal() -> void:
	modal_title.text = "Remap controls"
	modal_content.add_child(_body("Select an action, then press a key or mouse button. Escape cancels rebinding. A conflicting binding is swapped to the old key."))
	modal_content.add_child(_button("Back", func(): _open_modal("settings")))
	var names := {"pickup": "Pick up / hold", "deposit": "Start or cancel deposit", "ledger": "Deck Ledger", "upgrades": "Focus upgrade tree", "pause": "Pause / settings", "ability_1": "Card Surge", "ability_2": "Express Deposit", "ability_3": "Foil Frenzy", "ability_4": "Seeker Pulse", "ability_5": "Card Cyclone"}
	for action in names:
		var row := HBoxContainer.new()
		var l := _label(names[action], 15, INK)
		l.custom_minimum_size.x = 260
		row.add_child(l)
		var codes: Array = settings.bindings[action]
		var labels := PackedStringArray()
		for code in codes:
			labels.append(PickupPersistence.code_label(int(code)))
		var b := _button(" / ".join(labels), _begin_capture.bind(action))
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(b)
		modal_content.add_child(row)
	modal_content.add_child(_button("Restore default controls", func(): settings.bindings = PickupPersistence.default_settings().bindings; _apply_settings(); _open_modal("controls")))

func _begin_capture(action: String) -> void:
	capture_action = action
	for child in modal_content.get_children():
		modal_content.remove_child(child)
		child.queue_free()
	modal_content.add_child(_body("Press the new key or mouse button for [b]%s[/b].\nEscape cancels." % action))

func _assign_binding(action: String, code: int) -> void:
	var old: Array = settings.bindings[action]
	for other in settings.bindings:
		if other == action:
			continue
		var codes: Array = settings.bindings[other]
		if codes.has(code):
			settings.bindings[other] = old.duplicate()
	settings.bindings[action] = [code]
	_apply_settings()

func _build_ledger_modal() -> void:
	modal_title.text = "Deck Ledger"
	var summary := _body("")
	summary.name = "LedgerSummary"
	modal_content.add_child(summary)
	modal_content.add_child(_body("Each cell shows unbound copies. [b]Missing[/b] means zero unbound copies; collected cards in your tray do not count until deposited. One copy of all 52 identities binds a deck automatically."))
	var grid := GridContainer.new()
	grid.columns = 14
	grid.name = "LedgerGrid"
	grid.add_theme_constant_override("h_separation", 5)
	grid.add_theme_constant_override("v_separation", 5)
	modal_content.add_child(grid)
	grid.add_child(_label("", 12))
	for rank in PickupRules.RANK_NAMES:
		var l := _label(rank, 13, GOLD)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.custom_minimum_size.x = 58
		grid.add_child(l)
	for suit in 4:
		grid.add_child(_label(PickupRules.SUIT_SYMBOLS[suit], 22, RED if suit < 2 else INK))
		for rank in 13:
			var cell := Label.new()
			cell.name = "Cell_%d" % (suit * 13 + rank)
			cell.custom_minimum_size = Vector2(58, 54)
			cell.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			cell.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			cell.add_theme_font_size_override("font_size", 13)
			grid.add_child(cell)
	modal_content.add_child(_button("Back to the table", _close_modal))
	_refresh_ledger_modal()

func _refresh_ledger_modal() -> void:
	rules.tutorial["ledger"] = true
	var summary := modal_content.get_node_or_null("LedgerSummary") as RichTextLabel
	if summary:
		summary.text = "[b]%s decks bound[/b] · %d missing identities · Seeker bias %d%%\nUnbound copies are consumed by binding. Extra copies remain. Deck bonus: $%s per deck." % [_num(rules.bound_decks, true), rules.missing_count(), int(rules.seeker_bias() * 100), _num(rules.current_deck_income())]
	var grid := modal_content.get_node_or_null("LedgerGrid") as GridContainer
	if grid == null:
		return
	for suit in 4:
		for rank in 13:
			var identity := suit * 13 + rank
			var cell := grid.get_node_or_null("Cell_%d" % identity) as Label
			if cell:
				var count := rules.ledger[identity]
				cell.text = PickupRules.RANK_NAMES[rank] + "\n" + ("MISSING" if count == 0 else _num(count))
				cell.add_theme_stylebox_override("normal", _panel_style(Color("3a241c") if count == 0 else Color("17382a"), Color("a16b45") if count == 0 else Color("3f6048"), 4))
				cell.tooltip_text = "%s · %s unbound · %s lifetime deposited" % [rules.card_name(identity), _num(count, true), _num(rules.identity_totals[identity], true)]

func _build_instructions_modal() -> void:
	modal_title.text = "How to play"
	modal_content.add_child(_body("""[b]The loop[/b]
1. Click the felt or hold Space to pick up cards. You begin with one card per action and room for exactly 52.
2. Press D or Deposit. Cards count individually into money, the goal and the Deck Ledger. Manual pickup pauses; helpers keep picking into freed space.
3. One unbound copy of every rank and suit binds a deck and pays a bonus. Extra copies stay for later decks.
4. Buy upgrades one rank at a time. Every entry is visible from the start; locked entries show their prerequisite path.
5. Use abilities, Combo, Lucky pickups and positive events to coordinate bursts. Deposit card 52,000,000 to finish.

[b]Important details[/b]
• Foils are worth more money but still count as one ordinary identity.
• Lucky extra cards each roll their own identity and foil.
• Overflow Tray allows extra final manual actions above capacity; helpers never overflow.
• Cancelling a deposit keeps counted cards and returns the rest. Nothing is destroyed.
• Auto-deposit thresholds use current capacity. Smart Thresholds can start earlier to avoid a stranded full tray.
• Card Surge repeats manual actions; Express Deposit speeds counting; Foil Frenzy boosts foils/Lucky/income; Seeker Pulse biases upcoming identities; Card Cyclone fills free space.
• Pause stops all gameplay timers. Closing the game never awards offline production.
• Achievements are cosmetic. There is no prestige, offline grind or required second run.

[b]Accessibility[/b]
Hold-to-pickup, remappable keyboard/mouse controls, reduced motion, high-contrast cards, scalable UI, aggregated floating numbers and four volume controls are in Settings."""))
	modal_content.add_child(_button("Back", _close_modal))

func _build_achievements_modal() -> void:
	modal_title.text = "Cosmetic achievements"
	modal_content.add_child(_body("Badges annotate the run. They grant no money, cards or throughput."))
	for id in PickupRules.ACHIEVEMENTS:
		var unlocked := rules.achievements.has(id)
		var info: Array = PickupRules.ACHIEVEMENTS[id]
		var row := _body("[%s] [b]%s[/b] — %s%s" % ["✓" if unlocked else "·", info[0], info[1], "  (%s)" % PickupRules.format_time(float(rules.achievements[id])) if unlocked else ""])
		modal_content.add_child(row)
	modal_content.add_child(_button("Back", func(): _open_modal("pause")))

func _build_results_modal() -> void:
	modal_title.text = "52 Million Card Pickup"
	var s: Dictionary = rules.results if not rules.results.is_empty() else rules.statistics()
	var time := float(s.get("completion_time", s.active_time))
	modal_content.add_child(_body("[b]The last card is counted.[/b]\n%s active time · %s cards · %s decks bound" % [PickupRules.format_time(time), _num(s.deposited, true), _num(s.bound_decks, true)]))
	modal_content.add_child(_body("""[b]Money[/b]
Earned $%s · spent $%s · unspent $%s (%.1f%%)
Deck bonuses contributed $%s.

[b]Sources[/b]
Manual: %s deposited cards · $%s
Automatic: %s deposited cards · $%s
Manual inputs: %s · Lucky actions: %s · Lucky cards: %s · Burst actions: %s

[b]Throughput[/b]
Average %s cards/s · peak %s cards/s
Deposit utilization %.1f%% · full-tray blocked %s
Helper pickup blocked %s

[b]Cards[/b]
Foils deposited: %s · Seeker replacements: %s · Auto-Seeker cards: %s""" % [
		_num(s.earned, true), _num(s.spent, true), _num(s.money, true), 100.0 * float(s.money) / maxf(1, float(s.earned)), _num(s.deck_income, true),
		_num(s.get("manual_deposited", s.manual_cards), true), _num(s.manual_income, true), _num(s.get("auto_deposited", s.auto_cards), true), _num(s.auto_income, true),
		_num(s.manual_inputs, true), _num(s.lucky_actions, true), _num(s.lucky_cards, true), _num(s.burst_actions, true),
		_num(s.average_cps), _num(s.peak_cps), float(s.deposit_utilization) * 100, PickupRules.format_time(float(s.blocked_time)), PickupRules.format_time(float(s.pickup_blocked_time)),
		_num(s.foil_deposited, true), _num(s.seeker_replacements, true), _num(s.auto_seeker_cards, true)]))
	var ranks_text := "[b]By rank[/b]\n"
	for i in 13:
		ranks_text += "%s: %s   " % [PickupRules.RANK_NAMES[i], _num(s.rank_totals[i], true)]
	ranks_text += "\n\n[b]By suit[/b]\n"
	for i in 4:
		ranks_text += "%s %s: %s\n" % [PickupRules.SUIT_SYMBOLS[i], PickupRules.SUIT_NAMES[i], _num(s.suit_totals[i], true)]
	modal_content.add_child(_body(ranks_text))
	var abilities_text := "[b]Abilities[/b] (cards generated during effects are an estimate of burst contribution)\n"
	for i in 5:
		abilities_text += "%s: %s activations · %s cards\n" % [PickupRules.ABILITY_NAMES[i], _num(s.ability_activations[i], true), _num(s.ability_cards[i], true)]
	abilities_text += "\n[b]Events[/b]\n"
	for i in 6:
		abilities_text += "%s: %s participated / %s offered\n" % [PickupRules.EVENT_NAMES[i], _num(s.event_participation[i], true), _num(s.event_offers[i], true)]
	modal_content.add_child(_body(abilities_text))
	var final_ranks = s.get("final_ranks", rules.ranks)
	var tree_text := "[b]Final upgrade tree[/b]\n"
	var last_branch := ""
	for i in rules.entries.size():
		var e: Dictionary = rules.entries[i]
		if e.branch != last_branch:
			tree_text += "\n" + e.branch + "\n"
			last_branch = e.branch
		tree_text += "%s %s %d/%d   " % [e.id, e.name, int(final_ranks[i]), int(e.ranks)]
	modal_content.add_child(_body(tree_text))
	var badges := "[b]Cosmetic achievements[/b]\n"
	for id in s.achievements:
		badges += "✓ " + PickupRules.ACHIEVEMENTS[id][0] + "\n"
	modal_content.add_child(_body(badges))
	var actions := HBoxContainer.new()
	actions.add_child(_button("Continue in Endless Mode", func(): rules.continue_endless(); modal_kind = ""; modal_layer.visible = false; paused = false; _save_game("endless")))
	actions.add_child(_button("Begin a fresh run…", func(): modal_kind = "fresh"; _open_modal("fresh")))
	modal_content.add_child(actions)

func _build_fresh_modal() -> void:
	modal_title.text = "Start a fresh run?"
	modal_content.add_child(_body("This replaces the current local run. Settings and remapped controls are kept. There is no prestige bonus."))
	modal_content.add_child(_button("Yes, clear the table and start over", _fresh_run))
	modal_content.add_child(_button("Keep this run", func(): _open_modal("results") if rules.completed and not rules.endless else _open_modal("pause")))

func _fresh_run() -> void:
	rules = PickupRules.new()
	rules.notice.connect(_on_notice)
	rules.achievement_unlocked.connect(_on_achievement)
	rules.run_completed.connect(_on_completed)
	table.rules = rules
	affordable_seen.clear()
	toast_queue.clear()
	modal_kind = ""
	modal_layer.visible = false
	paused = false
	_save_game("fresh")
	_refresh_ui()
	_refresh_upgrade_styles()

func _num(value, exact: bool = false) -> String:
	if exact:
		var negative: bool = float(value) < 0
		var text := str(int(absf(float(value))))
		var out := ""
		var count := 0
		for i in range(text.length() - 1, -1, -1):
			out = text[i] + out
			count += 1
			if count % 3 == 0 and i > 0:
				out = "," + out
		return ("-" if negative else "") + out
	return PickupRules.format_number(float(value))
