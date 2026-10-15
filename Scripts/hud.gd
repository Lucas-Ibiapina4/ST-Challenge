extends Control
## HUD — mostra a rotação escolhida e as cargas de cristal do andar.
## Só escuta o EventBus; não conhece Player, conjurer nem o andar.

@export var charge_full: Texture2D        ## diamante cheio (disponível)
@export var charge_empty: Texture2D       ## diamante vazado (gasto)
@export var dial_frames: Array[Texture2D] ## 0°, 45°, 90°, 135° (nessa ordem)
@export var pixel_scale := 2.5              ## o CanvasLayer não usa o zoom da câmera

@onready var dial: TextureRect = %RotationDial
@onready var charges: HBoxContainer = %Charges


func _ready() -> void:
	EventBus.crystal_inventory_changed.connect(_on_inventory_changed)
	EventBus.crystal_rotation_changed.connect(_on_rotation_changed)
	_setup_rect(dial)
	_on_rotation_changed(0)


func _on_inventory_changed(remaining: int, max_quota: int, _crystal_type: String) -> void:
	_ensure_icon_count(max_quota)
	for i in charges.get_child_count():
		var icon := charges.get_child(i) as TextureRect
		icon.texture = charge_full if i < remaining else charge_empty


func _on_rotation_changed(step: int) -> void:
	if dial_frames.is_empty():
		return
	dial.texture = dial_frames[step % dial_frames.size()]


## Cria ou remove ícones até ter exatamente "count".
func _ensure_icon_count(count: int) -> void:
	while charges.get_child_count() < count:
		var icon := TextureRect.new()
		_setup_rect(icon)
		charges.add_child(icon)
	while charges.get_child_count() > count:
		var last := charges.get_child(charges.get_child_count() - 1)
		charges.remove_child(last)   # remove já; queue_free sozinho não diminui a contagem
		last.queue_free()


## Configura um TextureRect para pixel art ampliado.
func _setup_rect(rect: TextureRect) -> void:
	rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var base := rect.texture.get_size() if rect.texture else _base_icon_size(rect)
	rect.custom_minimum_size = base * pixel_scale


func _base_icon_size(rect: TextureRect) -> Vector2:
	if rect == dial and not dial_frames.is_empty():
		return dial_frames[0].get_size()
	return charge_full.get_size() if charge_full else Vector2(16, 16)
