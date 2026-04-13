class_name BootBase extends Control

const ES_NAME_CLASS = "BootBase"

const CONFIG_PATH = "res://_static/EssenceConfig.tres"
const ROUTES_PATH = "res://_static/RouteConfig.tres"

var config: EssenceConfig
var routes: EssenceRouteConfig

func _ready() -> void:
	EssenceLogger.system_info("[%s] Boot Sequence Initiated..." % ES_NAME_CLASS)
	_cargar_configuracion()
	_iniciar_fase_logo()

func _cargar_configuracion() -> void:
	EssenceLogger.system_info("[%s] Loading configuration resources..." % ES_NAME_CLASS)
	
	if ResourceLoader.exists(CONFIG_PATH):
		config = load(CONFIG_PATH) as EssenceConfig
		
	if config == null:
		EssenceLogger.system_info("[%s] Config missing or corrupt. Generating default config." % ES_NAME_CLASS)
		config = EssenceConfig.new()
		
	if ResourceLoader.exists(ROUTES_PATH):
		routes = load(ROUTES_PATH) as EssenceRouteConfig

func _iniciar_fase_logo() -> void:
	EssenceLogger.system_info("[%s] Starting Logo module..." % ES_NAME_CLASS)
	var pantalla_logo = EssenceBootLogo.new()
	add_child(pantalla_logo)
	
	pantalla_logo.logo_completed.connect(_iniciar_fase_advertencia)
	pantalla_logo.mostrar_logo(config)

func _iniciar_fase_advertencia() -> void:
	EssenceLogger.system_info("[%s] Starting Warning module..." % ES_NAME_CLASS)
	var pantalla_advertencia = EssenceWarningScreen.new()
	add_child(pantalla_advertencia)
	
	pantalla_advertencia.warning_completed.connect(_iniciar_fase_carga)
	pantalla_advertencia.mostrar_advertencia(config)

func _iniciar_fase_carga() -> void:
	EssenceLogger.system_info("[%s] Starting Loading module..." % ES_NAME_CLASS)
	var pantalla_carga = EssenceLoadingScreen.new()
	add_child(pantalla_carga)
	
	pantalla_carga.loading_completed.connect(_finalizar_secuencia)
	
	# ==========================================
	# 1. TAREAS DEL MOTOR (El orden es vital)
	# ==========================================
	pantalla_carga.add_task(_tarea_sistema_archivos)
	pantalla_carga.add_task(_tarea_preparar_idiomas) # <--- Tarea separada para mejor UX
	pantalla_carga.add_task(_tarea_preparar_audio)
	pantalla_carga.add_task(_tarea_motor_nucleo)
	
	# 2. Le preguntamos al juego del usuario si tiene tareas extra
	inject_custom_tasks(pantalla_carga)
	
	# 3. Arrancamos el asincronismo
	pantalla_carga.start_loading(config)

func _finalizar_secuencia() -> void:
	EssenceLogger.system_info("[%s] Boot sequence complete. Transitioning to Main Menu..." % ES_NAME_CLASS)
	
	if routes != null and routes.main_menu_scene != "" and ResourceLoader.exists(routes.main_menu_scene):
		get_tree().change_scene_to_file(routes.main_menu_scene)
	else:
		EssenceError.report(
			"Fatal Route Configuration",
			"The route 'main_menu_scene' is missing or not configured in RouteConfig.tres",
			EssenceError.Severity.CRITICAL
		)

# ==========================================
# FUNCIONES VIRTUALES PARA EL USUARIO
# ==========================================

## Override this function in your GameBoot.gd to inject custom loading tasks.
func inject_custom_tasks(_loader: EssenceLoadingScreen) -> void:
	pass
	
# ==========================================
# TAREAS INTERNAS DEL MOTOR
# ==========================================

func _tarea_sistema_archivos() -> void:
	EssenceLogger.system_info("[%s] Initializing local and remote file systems..." % ES_NAME_CLASS)
	if is_instance_valid(FileManager):
		FileManager.initialize_file_system()
	else:
		EssenceError.report("Missing Autoload", "FileManager not found.", EssenceError.Severity.CRITICAL)

func _tarea_preparar_idiomas() -> void:
	EssenceLogger.system_info("[%s] Scanning and injecting languages..." % ES_NAME_CLASS)
	if is_instance_valid(LanguageManager):
		LanguageManager.scan_all_languages()
		LanguageManager.inject_translations()
		LanguageManager.apply_initial_language()
	else:
		EssenceError.report("Missing Autoload", "LanguageManager not found.", EssenceError.Severity.CRITICAL)

func _tarea_preparar_audio() -> void:
	EssenceLogger.system_info("[%s] Caching global audio assets..." % ES_NAME_CLASS)
	if is_instance_valid(AudioManager):
		AudioManager.cache_audio("ui_space", EssencePaths.AUDIO_UI_SPACE)
		AudioManager.cache_audio("ui_bubble", EssencePaths.AUDIO_UI_BUBBLE)
	else:
		EssenceError.report("Missing Autoload", "AudioManager not found.", EssenceError.Severity.WARNING)

func _tarea_motor_nucleo() -> void:
	EssenceLogger.system_info("[%s] Finalizing framework core..." % ES_NAME_CLASS)
	# Espacio reservado para inicialización de variables globales o estado base 
	