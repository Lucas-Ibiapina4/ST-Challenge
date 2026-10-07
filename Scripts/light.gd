class_name LightEmitter2D
extends Node2D

@onready var raio: RayCast2D = $Raio
@onready var feixe: Line2D = $Feixe

## Quantas vezes o feixe pode refletir
@export var max_reflexoes := 4
## Comprimento de cada trecho do raio
@export var comprimento := 500.0
@export var debug := true

var beam_points = []
#receptores (cristal da porta) atingidos no frame anterior
var _receivers_hit: Dictionary = {}
#guarda o ultimo caminho impresso, para nao repetir o print todo frame
var _ultimo_caminho := ""


func _log(msg: String) -> void:
	if debug:
		print("[EMITTER ", name, "] ", msg)


func _ready() -> void:
	#o RayCast tem que enxergar a Layer 1 (World) e a Layer 4 (Optics)
	raio.set_collision_mask_value(1, true)
	raio.set_collision_mask_value(4, true)
	_log("pronto | mask do raio=%d (deve ser 9)" % raio.collision_mask)


func _physics_process(_delta: float) -> void:
	
	#Criaco do feixe, primeiro ele apaga o desenho de frames anteriores
	#e depois dita que o inicio vai ser na origem do objeto
	beam_points.clear()
	beam_points.append(Vector2.ZERO)
	
	#receptores atingidos neste frame
	var hits := {}
	#caminho do feixe, so para debug
	var caminho := []
	
	#variaveis para montar a "nova" origem, ou seja, o ponto
	#inicial das reflexoes e para onde elas apontam
	var origin = global_position
	var direction: Vector2 = global_transform.y.normalized()
	
	#limpa as excecoes do frame anterior
	raio.clear_exceptions()
	
	for i in range(max_reflexoes):
		#coloca o RayCast na posicao atual (origem da reflexao)
		raio.global_position = origin
		#faz o RayCast apontar para a direcao atual transformando a variavel direction em um angulo
		raio.global_rotation = direction.angle()
		#Diz o quanto o RayCast deve andar antes de parar (comprimento)
		raio.target_position = Vector2(comprimento, 0)
		#atualiza o Raycast com as informacoes de colisao atuais
		raio.force_raycast_update()
		
		if raio.is_colliding():
			#pega o ponto em que a colisao ocorre
			var collision_point = raio.get_collision_point()
			#salva o tipo de objeto com o qual ocorreu a colisao
			var object = raio.get_collider()
			#adiciona o ponto de colisao ao array e transforma ele em uma
			#coordenada local pra gerar o caminho da luz
			beam_points.append(to_local(collision_point))
			var layer_info = object.collision_layer if object is CollisionObject2D else "N/A"
			caminho.append("%s (pai: %s, layer: %s, grupos: %s)" % [
				object.name, 
				object.get_parent().name if object.get_parent() else "Nenhum", 
				layer_info, 
				object.get_groups()
			])
			
			if _no_grupo(object, "cristals"):
				
				#pega a linha normal da superfície do cristal
				var normal = raio.get_collision_normal()
				#essa funcao bounce faz o calculo de como sai a reflexao da luz no cristal
				#utilizando as variaveis direction e normal como parametro
				var reflected = direction.bounce(normal)
				#move a origem pra 1 pixel depois da colisao para que o feixe de luz
				#nao entre em conflito com o colisor do cristal
				origin = collision_point + reflected * 1
				#transforma a reflected na nova direcao do feixe
				direction = reflected
				#evita que o proximo raio colida de novo com o mesmo cristal
				raio.add_exception(object)
			
			elif object.is_in_group("light_receiver"):
				#acertou o cristal da porta: registra e o feixe termina aqui
				hits[object] = true
				break
			
			else:
				#parede/TileMap: o feixe termina aqui
				break
		else:
			#quanto o raio anda caso nao tenha colidido com nada
			var final_point = origin + direction * comprimento
			beam_points.append(to_local(final_point))
			caminho.append("nada")
			break
	
	#devolve o RayCast para a posicao original
	raio.position = Vector2.ZERO
	
	#Efetivamente desenha uma linha que passa por todos os pontos
	feixe.points = PackedVector2Array(beam_points)
	
	#avisa a porta se o feixe comecou ou parou de atingi-la
	_sync_receivers(hits)
	
	var c := " -> ".join(caminho)
	if c != _ultimo_caminho:
		_ultimo_caminho = c
		_log("caminho do feixe: %s" % c)


func _exit_tree() -> void:
	#se o emissor sumir, avisa os receptores
	_sync_receivers({})


#compara os receptores deste frame com os do frame anterior
#e so chama light_entered/light_exited quando algo muda
func _sync_receivers(hits: Dictionary) -> void:
	for r in _receivers_hit:
		if not hits.has(r) and is_instance_valid(r):
			_log("deixou de atingir '%s'" % r.name)
			r.light_exited(self)
	for r in hits:
		if not _receivers_hit.has(r):
			_log("começou a atingir '%s'" % r.name)
			r.light_entered(self)
	_receivers_hit = hits
#verifica se o objeto (ou o pai dele) esta no grupo
func _no_grupo(object: Node, grupo: StringName) -> bool:
	return object.is_in_group(grupo) or (object.get_parent() != null and object.get_parent().is_in_group(grupo))
