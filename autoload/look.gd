extends Node
## Look — pixel-artowy wygląd: duże, wyraziste „piksele” świata gry (z ciemnym konturem
## i podkręconymi kolorami). Pikselizowany jest tylko świat; napisy (nazwy, liczby obrażeń,
## podpowiedzi) i interfejs zostają ostre. F9 włącza/wyłącza efekt.

const BLOCK := 5.0
const TEXT_Z := 101
const SHADER := """
shader_type canvas_item;
uniform sampler2D screen_tex : hint_screen_texture, filter_nearest;
uniform float block = 5.0;
uniform float levels = 9.0;
uniform float edge_thr = 0.2;
vec3 cell_col(vec2 cell, vec2 res_px, float px_size) {
	vec2 o = vec2(px_size) * 0.25;
	vec2 base = (cell + 0.5) * px_size;
	vec3 c = texture(screen_tex, (base + vec2(-o.x, -o.y)) / res_px).rgb;
	c += texture(screen_tex, (base + vec2(o.x, -o.y)) / res_px).rgb;
	c += texture(screen_tex, (base + vec2(-o.x, o.y)) / res_px).rgb;
	c += texture(screen_tex, (base + vec2(o.x, o.y)) / res_px).rgb;
	return c * 0.25;
}
float lum(vec3 c) { return dot(c, vec3(0.299, 0.587, 0.114)); }
void fragment() {
	vec2 res_px = 1.0 / SCREEN_PIXEL_SIZE;
	float px_size = max(1.0, floor(block * res_px.y / 720.0 + 0.5));
	vec2 cell = floor(SCREEN_UV * res_px / px_size);
	vec3 c = cell_col(cell, res_px, px_size);
	// czarny kontur: komórka ciemniejsza od sąsiada, który wyraźnie różni się kolorem
	bool outline = false;
	vec2 nb[4] = vec2[4](vec2(1.0, 0.0), vec2(-1.0, 0.0), vec2(0.0, 1.0), vec2(0.0, -1.0));
	for (int i = 0; i < 4; i++) {
		vec3 n = cell_col(cell + nb[i], res_px, px_size);
		vec3 d = abs(c - n);
		if (max(d.r, max(d.g, d.b)) > edge_thr && lum(c) < lum(n) - 0.03) {
			outline = true;
		}
	}
	// płaskie kolory: nasycenie + ograniczona paleta
	float g = lum(c);
	c = mix(vec3(g), c, 1.35);
	c = floor(clamp(c, 0.0, 1.0) * levels + 0.5) / levels;
	if (outline) {
		c = vec3(0.05, 0.04, 0.06);
	}
	COLOR = vec4(c, 1.0);
}
"""

var enabled := false
var _rect: ColorRect

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rect = ColorRect.new()
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.z_index = 100
	_rect.z_as_relative = false
	var sh := Shader.new()
	sh.code = SHADER
	var mat := ShaderMaterial.new()
	mat.shader = sh
	mat.set_shader_parameter("block", BLOCK)
	_rect.material = mat
	_rect.visible = false
	add_child(_rect)
	get_tree().node_added.connect(_on_node_added)

func _process(_dt: float) -> void:
	var st = Flow.stage
	_rect.visible = enabled and st != null and is_instance_valid(st)
	if _rect.visible:
		var vr := get_viewport().get_visible_rect()
		_rect.position = vr.position
		_rect.size = vr.size

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F9:
		enabled = not enabled

func _on_node_added(n: Node) -> void:
	if n is Label:
		await get_tree().process_frame
		if is_instance_valid(n):
			_setup_label(n)

func _setup_label(l: Label) -> void:
	if not is_instance_valid(l) or not l.is_inside_tree():
		return
	# napisy w świecie (nazwy postaci itp.) rysowane ponad pikselizacją
	if l.get_canvas_layer_node() == null and Flow.stage != null and Flow.stage.is_ancestor_of(l):
		l.z_index = TEXT_Z
		l.z_as_relative = false
		return
	# centrowanie napisów w pionowych układach menu
	if not (l.get_parent() is VBoxContainer):
		return
	if l.horizontal_alignment != HORIZONTAL_ALIGNMENT_LEFT or l.has_meta("keep_left"):
		return
	if l.size_flags_horizontal & Control.SIZE_EXPAND_FILL == 0 and l.size_flags_horizontal != Control.SIZE_FILL:
		return
	var p: Node = l.get_parent()
	while p != null:
		if p is UiHud or p is UiBanner or p is Button:
			return
		p = p.get_parent()
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
