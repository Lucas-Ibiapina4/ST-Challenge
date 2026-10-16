extends Control
## HUD — mostra o dial de rotação do andar e as cargas de cristal.
## Só escuta o EventBus; não conhece Player, conjurer nem o andar.
##
## O dial é um frame único por estado. Como a arte já traz círculo, cristal e
## bolinhas desenhados juntos, o frame certo depende de duas coisas: o ângulo
## escolhido e quais rotações o andar liberou. Os frames de cada estágio de
## desbloqueio ficam num RotationDialSet (ver dial_sets).

@export var charge_full: Texture2D         ## diamante cheio (disponível)
@export var charge_empty: Texture2D        ## diamante vazado (gasto)
@export var pixel_scale := 2.5             ## o CanvasLayer não usa o zoom da câmera

## Um RotationDialSet por estágio de desbloqueio: [0], [0,2], [0,1,2],
## [0,1,2,3]. A ordem da lista não importa — o estágio é escolhido pelo
## conjunto de rotações que o andar libera, não pela posição aqui.
@export var dial_sets: Array[RotationDialSet] = []

@onready var dial: TextureRect = %RotationDial
@onready var charges: HBoxContainer = %Charges

## key() do RotationDialSet → o próprio Resource, montado uma vez.
var _sets_by_key := {}


func _ready() -> void:
	_index_dial_sets()
	EventBus.crystal_inventory_changed.connect(_on_inventory_changed)
	EventBus.crystal_rotation_changed.connect(_on_rotation_changed)
	_setup_rect(dial)
	# Sem chute inicial: o HUD não sabe quais rotações existem antes do andar
	# carregar. Fica escondido até a primeira emissão.
	dial.visible = false


func _index_dial_sets() -> void:
	for set in dial_sets:
		if set == null:
			continue
		if not set.is_valid():
			push_warning("HUD: RotationDialSet com steps e frames de tamanhos diferentes")
			continue
		_sets_by_key[set.key()] = set


func _on_inventory_changed(remaining: int, max_quota: int, _crystal_type: String) -> void:
	_ensure_icon_count(max_quota)
	for i in charges.get_child_count():
		var icon := charges.get_child(i) as TextureRect
		icon.texture = charge_full if i < remaining else charge_empty


## Escolhe o frame pelo estágio do andar e pelo ângulo atual.
func _on_rotation_changed(step: int, allowed_steps: Array) -> void:
	var set := _set_for(allowed_steps)
	if set == null:
		push_warning("HUD: nenhum RotationDialSet para %s" % [allowed_steps])
		dial.visible = false
		return
	var frame := set.frame_for(step)
	if frame == null:
		push_warning("HUD: estágio %s sem frame para o passo %d" % [set.key(), step])
		return
	dial.texture = frame
	dial.visible = true


## Casa o conjunto liberado pelo andar com um estágio de arte.
func _set_for(allowed_steps: Array) -> RotationDialSet:
	var sorted := []
	for s in allowed_steps:
		sorted.append(int(s))
	sorted.sort()
	var key: String = ",".join(sorted.map(func(s): return str(s)))
	return _sets_by_key.get(key)


## Cria ou remove ícones de carga até ter exatamente "count".
func _ensure_icon_count(count: int) -> void:
	while charges.get_child_count() < count:
		var icon := TextureRect.new()
		icon.texture = charge_full   # textura antes do setup: o tamanho vem dela
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


## O dial reserva o tamanho do maior estágio, para a HUD não pular de largura
## quando a fase libera mais bolinhas.
func _base_icon_size(rect: TextureRect) -> Vector2:
	if rect == dial:
		var biggest := Vector2.ZERO
		for set in dial_sets:
			if set != null and not set.frames.is_empty() and set.frames[0] != null:
				biggest = biggest.max(set.frames[0].get_size())
		if biggest != Vector2.ZERO:
			return biggest
	return charge_full.get_size() if charge_full else Vector2(16, 16)
