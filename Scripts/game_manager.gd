extends Node
## Autoload "GameManager": sabe a ordem dos níveis e pede ao World que troque o andar.
## O World é quem instancia o Floor dentro do LevelContainer.

## Ordem dos níveis. Ajuste os caminhos para os seus arquivos .tscn.
const LEVELS: Array[String] = [
	"res://Scenes/level_01.tscn",
	"res://Scenes/level_02.tscn",
	"res://Scenes/level_03.tscn",
	"res://Scenes/level_04.tscn",
	"res://Scenes/level_05.tscn",
]

var current_level := 0
var _world: Node = null


func _ready() -> void:
	EventBus.level_completed.connect(_on_level_completed)


## Chamado pelo World no _ready dele.
func register_world(world: Node) -> void:
	_world = world
	print("[GAME] world registrado, iniciando no nível %d" % current_level)
	go_to_level(current_level)


func _on_level_completed() -> void:
	print("[GAME] nível %d concluído" % current_level)
	go_to_level(current_level + 1)


func go_to_level(index: int) -> void:
	if index >= LEVELS.size():
		print("[GAME] fim do jogo, a princesa está livre!")
		return  # aqui depois entra a tela de vitória
	if _world == null:
		push_warning("[GAME] World ainda não registrado")
		return
	current_level = index
	var scene: PackedScene = load(LEVELS[index])
	if scene == null:
		push_warning("[GAME] não consegui carregar %s" % LEVELS[index])
		return
	print("[GAME] carregando ", LEVELS[index])
	# deferred: não troca o andar no meio do callback de física da porta
	_world.load_floor.call_deferred(scene)


func reload_level() -> void:
	print("[GAME] recarregando nível %d" % current_level)
	go_to_level(current_level)
