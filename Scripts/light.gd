extends Node2D

@onready var raio: RayCast2D = $Raio
@onready var feixe: Line2D = $Feixe
@export var portal: Node2D


var beam_points = []

func _process(delta:):
	
	#Criaco do feixe, primeiro ele apaga o desenho de frames anteriores
	#e depois dita que o inicio vai ser na origem do objeto
	beam_points.clear()
	beam_points.append(Vector2.ZERO)
	
	#variaveis para montar a "nova" origem, ou seja, o ponto
	#inicial das reflexoes e para onde elas apontam
	var origin = global_position
	var direction: Vector2 = global_transform.y.normalized()
	
	for i in range(4):
		#coloca o RayCast na posicao atual (origem da reflexao)
		raio.global_position = origin
		#faz o RayCast apontar para a direcao atual transformando a variavel direction em um angulo
		raio.global_rotation = direction.angle()
		#Diz o quanto o RayCast deve andar antes de parar (comprimento)
		raio.target_position = Vector2(500, 0)
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
			
			if object.is_in_group("cristals"):
				
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
			
			#elif object.is_in_group("key"):
				#portal.activate_portal()
				
			#else:
				#portal.deactivate_portal()
		else:
			#quanto o raio anda caso nao tenha colidido com nada
			var final_point = origin + direction * 500
			beam_points.append(to_local(final_point))
			break
		
	#Efetivamente desenha uma linha que passa por todos os pontos
	feixe.points = PackedVector2Array(beam_points)
