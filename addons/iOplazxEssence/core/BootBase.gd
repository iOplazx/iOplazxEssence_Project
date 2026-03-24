class_name BootBase extends Control

const CONFIG_PATH = "res://_static/EssenceConfig.tres"
var config: EssenceConfig

func _ready():
	print("--- iOplazxEssence: Secuencia de Arranque ---")
	_cargar_configuracion()
	_iniciar_fase_logo()

func _cargar_configuracion():
	print("1. Cargando configuración...")
	if ResourceLoader.exists(CONFIG_PATH):
		config = load(CONFIG_PATH) as EssenceConfig
	if config == null:
		config = EssenceConfig.new()

func _iniciar_fase_logo():
	print("2. Iniciando módulo de Logo...")
	var pantalla_logo = EssenceBootLogo.new()
	add_child(pantalla_logo)
	pantalla_logo.logo_completed.connect(_iniciar_fase_advertencia)
	pantalla_logo.mostrar_logo(config)

func _iniciar_fase_advertencia():
	print("3. Iniciando módulo de Advertencia...")
	var pantalla_advertencia = EssenceWarningScreen.new()
	add_child(pantalla_advertencia)
	pantalla_advertencia.warning_completed.connect(_iniciar_fase_carga)
	pantalla_advertencia.mostrar_advertencia(config)

func _iniciar_fase_carga():
	print("4. Iniciando módulo de Carga...")
	var pantalla_carga = EssenceLoadingScreen.new()
	add_child(pantalla_carga)
	pantalla_carga.loading_completed.connect(_finalizar_secuencia)
	
	# ==========================================
	# 1. TAREAS DEL MOTOR (Aquí agregamos el Audio)
	# ==========================================
	pantalla_carga.add_task(Callable(self, "_tarea_motor_nucleo"))
	pantalla_carga.add_task(Callable(self, "_tarea_preparar_audio")) 
	
	# 2. Le preguntamos al juego del usuario si tiene tareas extra
	inject_custom_tasks(pantalla_carga)
	
	# 3. Arrancamos
	pantalla_carga.start_loading(config)

func _finalizar_secuencia():
	print("5. Todo listo. Saltando al Menú Principal...")
	if config.next_scene_path != "" and ResourceLoader.exists(config.next_scene_path):
		get_tree().change_scene_to_file(config.next_scene_path)
	else:
		push_error("iOplazxEssence FATAL: Next Scene Path no configurada.")

# ==========================================
# FUNCIONES VIRTUALES PARA EL USUARIO
# ==========================================
## Sobrescribe esta función en tu Boot.gd para inyectar tareas a la pantalla de carga.
func inject_custom_tasks(loader: EssenceLoadingScreen):
	pass
	
# ==========================================
# TAREAS INTERNAS DEL MOTOR
# ==========================================

func _tarea_motor_nucleo():
	print("-> Cargando núcleo del framework...")
	# Aquí podrías inicializar otras variables globales en el futuro

func _tarea_preparar_audio():
	print("-> Precargando audios globales en RAM...")
	# Usamos las rutas globales para meter los sonidos de UI a la caja fuerte del AudioManager
	AudioManager.cache_audio("ui_space", EssencePaths.AUDIO_UI_SPACE)
	AudioManager.cache_audio("ui_bubble", EssencePaths.AUDIO_UI_BUBBLE)
