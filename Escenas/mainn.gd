extends Node2D

@export var platform_scene: PackedScene
@export var coin_scene: PackedScene    # ← NUEVA export
var coin_count: int = 0
var coins: Array = []
var player: CharacterBody2D

var highest_platform_y: float = 0.0
const PLATFORM_GAP_MIN = 120.0
const PLATFORM_GAP_MAX = 200.0
const PLATFORMS_AHEAD = 8
const SCREEN_WIDTH = 720.0
const PLATFORM_MARGIN = 50.0

var platforms: Array = []
var final_score: int = 0

# Referencias a la UI (deben existir en Main.tscn)
@onready var score_label: Label = $UILayer/ScoreLabel
@onready var coin_label: Label = $UILayer/CoinLabel   # ← NUEVA referencia
@onready var game_over_panel: Control = $UILayer/GameOverPanel

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	coin_label.text = "🪙 0"
	coin_count = 0
	# Buscar el Player recursivamente
	player = _find_player(self)
	if player == null:
		push_error("No se encontró ningún CharacterBody2D en la escena.")
		return
	
	print("Player encontrado: ", player)
	
	# Conectar señales
	player.fell_off_screen.connect(game_over)
	player.score_updated.connect(_on_score_updated)
	
	# Generar plataformas iniciales
	var start_y = player.global_position.y + 200.0
	for i in range(10):
		var y = start_y + i * 150.0
		var x = randf_range(PLATFORM_MARGIN, SCREEN_WIDTH - PLATFORM_MARGIN)
		spawn_platform(Vector2(x, y))
	
	highest_platform_y = start_y
	
	# UI inicial
	game_over_panel.visible = false
	score_label.text = "0"

func _find_player(node: Node) -> CharacterBody2D:
	if node is CharacterBody2D:
		return node
	for child in node.get_children():
		var result = _find_player(child)
		if result != null:
			return result
	return null

func _process(_delta):
	if player == null:
		return
	
	# Generar plataformas ARRIBA
	while highest_platform_y > player.global_position.y - (PLATFORMS_AHEAD * 150.0):
		var new_y = highest_platform_y - randf_range(PLATFORM_GAP_MIN, PLATFORM_GAP_MAX)
		var new_x = randf_range(PLATFORM_MARGIN, SCREEN_WIDTH - PLATFORM_MARGIN)
		spawn_platform(Vector2(new_x, new_y))
		highest_platform_y = new_y
	
	# Limpiar plataformas que quedaron muy abajo
	for plat in platforms.duplicate():
		if plat.global_position.y > player.global_position.y + 800.0:
			platforms.erase(plat)
			plat.queue_free()
	
	for coin in coins.duplicate():
		if is_instance_valid(coin) and coin.global_position.y > player.global_position.y + 800.0:
			coins.erase(coin)
			coin.queue_free()
		elif not is_instance_valid(coin):
			coins.erase(coin)   # ya fue recogida (queue_free)

func spawn_platform(pos: Vector2):
	var plat = platform_scene.instantiate()
	plat.global_position = pos
	add_child(plat)
	platforms.append(plat)
	
	 # 60% de probabilidad de generar una moneda sobre esta plataforma
	if randf() < 0.6:
		spawn_coin(Vector2(pos.x + randf_range(-30, 30), pos.y - 40))
	# 15% de probabilidad extra de moneda flotando entre plataformas
	elif randf() < 0.15:
		spawn_coin(Vector2(pos.x + randf_range(-100, 100), pos.y - randf_range(60, 100)))

func _on_score_updated(new_score: int):
	final_score = new_score
	score_label.text = str(new_score)
	
func spawn_coin(pos: Vector2):
	print("spawn_coin llamado en: ", pos, " | coin_scene: ", coin_scene)   # ← temporal
	if coin_scene == null:
		return
	var coin = coin_scene.instantiate()
	coin.global_position = pos
	coin.coin_collected.connect(_on_coin_collected)
	add_child(coin)
	coins.append(coin)

func game_over():
	# Desconectar para evitar más updates
	if player.score_updated.is_connected(_on_score_updated):
		player.score_updated.disconnect(_on_score_updated)
	
	# Mostrar panel
	game_over_panel.visible = true
	game_over_panel.get_node("GameOverLabel").text = "GAME OVER"
	game_over_panel.get_node("RestartLabel").text = "Pulsa ESPACIO para reiniciar\nPuntuación: %d   Monedas: %d" % [final_score, coin_count]
	
	get_tree().paused = true

func _input(event):
	if get_tree().paused:
		if event.is_action_pressed("ui_accept"):
			restart_game()

func _on_coin_collected():
	coin_count += 1
	coin_label.text = "🪙 " + str(coin_count)
	# Aquí podrías reproducir un sonido de moneda
	
func restart_game():
	get_tree().paused = false
	get_tree().reload_current_scene()
