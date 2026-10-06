class_name Door
extends Node2D
## Raiz da cena Door. Escuta o DoorReceiver e libera a TransitionArea2D.

signal opened
signal closed

@export var debug := true

@onready var receiver: DoorReceiver = %DoorReceiver
@onready var transition_area: Area2D = %TransitionArea2D
@onready var sprite: AnimatedSprite2D = get_node_or_null("Sprite")

var _unlocked := false
var _completed := false


func _log(msg: String) -> void:
	if debug:
		print("[DOOR ", name, "] ", msg)


func _ready() -> void:
	_log("receiver=%s | transition_area=%s | sprite=%s" % [receiver, transition_area, sprite])
	if sprite == null:
		push_warning("[DOOR] Nó 'Sprite' (AnimatedSprite2D) não encontrado como filho direto da Door.")
	elif sprite.sprite_frames == null:
		push_warning("[DOOR] Sprite sem SpriteFrames atribuído.")
	else:
		_log("animações disponíveis: %s" % [sprite.sprite_frames.get_animation_names()])

	transition_area.monitoring = false
	receiver.activated.connect(_on_receiver_activated)
	receiver.deactivated.connect(_on_receiver_deactivated)
	receiver.beam_count_changed.connect(_on_beam_count_changed)
	transition_area.body_entered.connect(_on_body_entered)
	_log("sinais conectados | mask da TransitionArea=%d" % transition_area.collision_mask)
	_play("closed")


func _on_receiver_activated() -> void:
	_log("recebeu 'activated' -> destrancando")
	_unlocked = true
	transition_area.set_deferred("monitoring", true)
	_play("open")
	opened.emit()
	if EventBus.has_signal("door_unlocked"):
		EventBus.door_unlocked.emit()
	else:
		push_warning("[DOOR] EventBus não tem o sinal 'door_unlocked'.")


func _on_receiver_deactivated() -> void:
	_log("recebeu 'deactivated' -> trancando")
	_unlocked = false
	transition_area.set_deferred("monitoring", false)
	_play("closed")
	closed.emit()


func _on_beam_count_changed(current: int, required: int) -> void:
	_log("feixes: %d/%d" % [current, required])


func _on_body_entered(body: Node2D) -> void:
	_log("body_entered: '%s' | grupos=%s | unlocked=%s" % [body.name, body.get_groups(), _unlocked])
	if _completed or not _unlocked or not body.is_in_group("player"):
		return
	_completed = true
	transition_area.set_deferred("monitoring", false)
	_log("player entrou -> level_completed")
	if EventBus.has_signal("level_completed"):
		EventBus.level_completed.emit()
	else:
		push_warning("[DOOR] EventBus não tem o sinal 'level_completed'.")


func _play(anim: StringName) -> void:
	if sprite == null or sprite.sprite_frames == null:
		_log("não tocou '%s': sem sprite/SpriteFrames" % anim)
		return
	if not sprite.sprite_frames.has_animation(anim):
		_log("não tocou '%s': animação não existe (nomes diferenciam maiúsculas)" % anim)
		return
	sprite.play(anim)
	_log("tocando animação '%s'" % anim)
