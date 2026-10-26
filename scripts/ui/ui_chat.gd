class_name UiChat
extends CanvasLayer
## Czat graczy w grze wieloosobowej (LAN/online). Enter albo / otwiera pole tekstowe.
## Komendy: /msg nick wiadomość — prywatnie, /wymiana — wymiana przedmiotów, /pomoc.

const MAX_LINES := 8
const SHOW_TIME := 9.0

var _log: VBoxContainer
var _edit: LineEdit
var _box: PanelContainer
var _lines: Array = []   # {l: Label, t: float}
var _trade_pending := false

func _ready() -> void:
	layer = 45
	process_mode = Node.PROCESS_MODE_ALWAYS
	var root := Control.new()
	UiKit.full(root)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	_box = UiKit.panel(Color(0.05, 0.04, 0.08, 0.5), 6)
	_box.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_box.offset_left = 14.0
	_box.offset_bottom = -14.0
	_box.offset_top = -190.0
	_box.offset_right = 520.0
	_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_box)
	var v := UiKit.vbox(2)
	_box.add_child(v)
	_log = UiKit.vbox(1)
	_log.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_log.alignment = BoxContainer.ALIGNMENT_END
	v.add_child(_log)
	_edit = LineEdit.new()
	_edit.max_length = 200
	_edit.placeholder_text = "Napisz wiadomość…  /msg nick tekst  ·  /wymiana  ·  /pomoc"
	_edit.visible = false
	_edit.text_submitted.connect(_submit)
	v.add_child(_edit)
	Net.chat_received.connect(_on_chat)
	Net.trade_received.connect(_on_trade)
	visible = false

func _process(delta: float) -> void:
	var active := Net.has_peer() and Flow.stage != null and is_instance_valid(Flow.stage)
	visible = active
	if not active:
		if _edit.visible:
			_close_edit()
		return
	var typing := _edit.visible
	for e in _lines.duplicate():
		e["t"] = float(e["t"]) + delta
		var l: Label = e["l"]
		var a := 1.0 if typing else clampf((SHOW_TIME - float(e["t"])) / 1.5, 0.0, 1.0)
		l.modulate.a = a
	_box.visible = typing or _lines.any(func(e): return float(e["t"]) < SHOW_TIME)

func _unhandled_input(event: InputEvent) -> void:
	if not visible or _edit.visible or not (event is InputEventKey) or not event.is_pressed() or event.is_echo():
		return
	if Flow.overlay != null and is_instance_valid(Flow.overlay):
		return
	var k := (event as InputEventKey).keycode
	if k == KEY_ENTER or k == KEY_KP_ENTER or k == KEY_SLASH:
		get_viewport().set_input_as_handled()
		_open_edit("/" if k == KEY_SLASH else "")

func _open_edit(prefill: String) -> void:
	GameState.chat_typing = true
	_box.visible = true
	_edit.visible = true
	_edit.text = prefill
	_edit.grab_focus()
	_edit.caret_column = prefill.length()

func _close_edit() -> void:
	GameState.chat_typing = false
	_edit.visible = false
	_edit.release_focus()

func _input(event: InputEvent) -> void:
	if _edit.visible and event.is_pressed() and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_close_edit()

func say(text: String, col: Color = UiKit.TEXT) -> void:
	var l := UiKit.label(text, 15, col)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(480, 0)
	_log.add_child(l)
	_lines.append({"l": l, "t": 0.0})
	while _lines.size() > MAX_LINES:
		var old: Dictionary = _lines.pop_front()
		(old["l"] as Label).queue_free()

func _submit(text: String) -> void:
	_close_edit()
	text = Net.clean_text(text)
	if text == "":
		return
	if text.begins_with("/"):
		_command(text)
		return
	say("%s: %s" % [Net.my_name, text], UiKit.TEXT)
	Net.send_chat(text)

func _command(text: String) -> void:
	var parts := text.substr(1).split(" ", false, 2)
	var cmd := String(parts[0]).to_lower() if parts.size() > 0 else ""
	match cmd:
		"msg", "w", "pm":
			if parts.size() < 3:
				say("Użycie: /msg nick wiadomość", UiKit.BAD)
				return
			var nick := String(parts[1])
			var msg := String(parts[2]).strip_edges()
			if not Net.is_remote_nick(nick):
				say("Nie ma takiego gracza: %s" % nick, UiKit.BAD)
				return
			say("[do %s] %s" % [Net.remote_nick, msg], Color(0.9, 0.6, 1.0))
			Net.send_chat(msg, nick)
		"wymiana", "trade":
			if _trade_pending:
				say("Zaproszenie do wymiany już wysłane.", UiKit.DIM)
				return
			_trade_pending = true
			Net.send_trade("request")
			say("Wysłano propozycję wymiany do %s…" % Net.remote_nick, UiKit.ACCENT)
		"pomoc", "help":
			say("/msg nick tekst — prywatna wiadomość", UiKit.ACCENT)
			say("/wymiana — wymiana przedmiotów z drugim graczem", UiKit.ACCENT)
		_:
			say("Nieznana komenda. Wpisz /pomoc.", UiKit.BAD)

func _on_chat(from: String, text: String, private: bool) -> void:
	if private:
		say("[od %s] %s" % [from, text], Color(0.9, 0.6, 1.0))
	else:
		say("%s: %s" % [from, text], UiKit.TEXT)

func _on_trade(kind: String, _data: Dictionary) -> void:
	match kind:
		"request":
			if Flow.overlay != null and is_instance_valid(Flow.overlay):
				Net.send_trade("decline")
				return
			var ui := UiChoice.new()
			ui.setup("%s proponuje wymianę przedmiotów. Zgadzasz się?" % Net.remote_nick, [{"text": "Zgadzam się"}, {"text": "Odmawiam"}], UiKit.ACCENT)
			ui.chosen.connect(func(i: int):
				if i == 0:
					Net.send_trade("accept")
					await get_tree().process_frame
					_open_trade()
				else:
					Net.send_trade("decline"))
			Flow.open_dialog(ui)
		"accept":
			if _trade_pending:
				_trade_pending = false
				_open_trade()
		"decline":
			if _trade_pending:
				_trade_pending = false
				say("%s odmówił wymiany." % Net.remote_nick, UiKit.BAD)

func _open_trade() -> void:
	var t := UiTrade.new()
	Flow.open_dialog(t)
