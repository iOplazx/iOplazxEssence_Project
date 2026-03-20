class_name EssenceMenuController extends Control

@export_category("Conexión de Botones (UI)")
@export var btn_new_game: Button
@export var btn_continue: Button
@export var btn_settings: Button
@export var btn_exit: Button

@export_category("Rutas de Escenas")
## La escena del primer nivel o cinemática introductoria
@export_file("*.tscn") var new_game_scene: String 
## La escena de configuraciones
@export_file("*.tscn") var settings_scene: String 

func _ready():
	print("EssenceMenuController: Inicializando menú principal...")
	_conectar_botones()
	_verificar_estado_partida()

func _conectar_botones():
	# Solo conectamos los botones que el usuario decidió usar (haciéndolo modular)
	if btn_new_game: 
		btn_new_game.pressed.connect(_on_new_game_pressed)
	if btn_continue: 
		btn_continue.pressed.connect(_on_continue_pressed)
	if btn_settings: 
		btn_settings.pressed.connect(_on_settings_pressed)
	if btn_exit: 
		btn_exit.pressed.connect(_on_exit_pressed)

func _verificar_estado_partida():
	# Aquí a futuro pondremos la lógica: si no hay archivo de guardado, 
	# apagamos el botón de "Continuar" para que no se pueda hacer clic.
	if btn_continue:
		# btn_continue.disabled = true (Lo haremos en la v1.8)
		pass

# ==========================================
# FUNCIONES DE ACCIÓN (Lógica del Framework)
# ==========================================

func _on_new_game_pressed():
	# Si implementamos sonidos UI en el AudioManager:
	# AudioManager.play_ui(cancion_clic)
	
	if new_game_scene != "" and ResourceLoader.exists(new_game_scene):
		print("Iniciando Nuevo Juego...")
		get_tree().change_scene_to_file(new_game_scene)
	else:
		push_error("iOplazxEssence: No se asignó una escena para 'New Game'.")

func _on_continue_pressed():
	print("Cargando partida... (Próximamente)")

func _on_settings_pressed():
	if settings_scene != "" and ResourceLoader.exists(settings_scene):
		print("Abriendo Opciones...")
		get_tree().change_scene_to_file(settings_scene)
	else:
		print("Aviso: Escena de opciones no configurada.")

func _on_exit_pressed():
	print("Cerrando motor desde el menú...")
	get_tree().quit()
