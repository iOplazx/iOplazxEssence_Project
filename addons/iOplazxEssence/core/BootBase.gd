class_name BootBase extends Control

const CONFIG_PATH = "res://_static/EssenceConfig.tres"
var config: EssenceConfig

# Nodos de la escena Boot.tscn (La Demo)
@onready var logo_rect = $Logo

# Nuevos nodos para la pantalla de carga
var pantalla_carga_container: VBoxContainer
var barra_progreso: ProgressBar
var texto_progreso: Label
var logo_carga: TextureRect

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
	
	# 1. Tareas del Motor (Ocultas al usuario)
	pantalla_carga.add_task(Callable(self, "_tarea_motor_1"))
	pantalla_carga.add_task(Callable(self, "_tarea_motor_2"))
	
	# 2. Le preguntamos al juego del usuario si tiene tareas extra
	inject_custom_tasks(pantalla_carga)
	
	# 3. Arrancamos
	pantalla_carga.start_loading(config)

func _ir_a_carga():
	print("7. Preparando pantalla de Carga...")
	# Como el componente EssenceWarningScreen hizo queue_free() de sí mismo, 
	# la memoria RAM ya está limpia automáticamente. No necesitamos borrar nodos aquí.

	if not config.show_loading_screen:
		print("Pantalla de carga omitida por configuración. Saltando al motor asíncrono...")
		_iniciar_carga_asincrona()
		return
		
	_crear_ui_carga()

func _crear_ui_carga():
	# Usamos un VBoxContainer para apilar Logo -> Barra -> Texto verticalmente
	pantalla_carga_container = VBoxContainer.new()
	pantalla_carga_container.alignment = BoxContainer.ALIGNMENT_CENTER
	pantalla_carga_container.add_theme_constant_override("separation", 20)
	
	# 1. Logo de Carga (Opcional)
	if config.loading_logo_type != 3: # 3 es "None"
		logo_carga = TextureRect.new()
		logo_carga.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		logo_carga.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		logo_carga.custom_minimum_size = Vector2(200, 200)
		
		match config.loading_logo_type:
			0: logo_carga.texture = load("res://icon.svg") # Logo de Godot temporal
			1: logo_carga.texture = load("res://icon.svg") # Aquí irá tu logo iOplazx
			2: logo_carga.texture = EssenceLoader.get_externImage(config.custom_loading_logo_path, true)
		
		pantalla_carga_container.add_child(logo_carga)

	# 2. Barra de Progreso Nativa
	if config.show_progress_bar:
		barra_progreso = ProgressBar.new()
		barra_progreso.custom_minimum_size = Vector2(500, 30)
		barra_progreso.step = 1.0
		barra_progreso.value = 0.0
		# Si vamos a usar nuestro propio texto abajo, apagamos el porcentaje nativo de la barra
		if config.show_progress_text:
			barra_progreso.show_percentage = false 
			
		pantalla_carga_container.add_child(barra_progreso)

	# 3. Texto de Progreso
	if config.show_progress_text:
		texto_progreso = Label.new()
		texto_progreso.text = "Iniciando framework... 0%"
		texto_progreso.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		pantalla_carga_container.add_child(texto_progreso)

	# Añadimos todo el bloque a la pantalla y lo centramos
	add_child(pantalla_carga_container)
	pantalla_carga_container.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	pantalla_carga_container.modulate.a = 0.0
	
	# Animamos la aparición y, al terminar, disparamos el motor de tareas asíncronas
	var tween = create_tween()
	tween.tween_property(pantalla_carga_container, "modulate:a", 1.0, 0.5)
	tween.finished.connect(_iniciar_carga_asincrona)

# --- EL CEREBRO ASÍNCRONO ---
# Array que guardará las funciones (tareas) a ejecutar
var tareas_de_carga: Array[Callable] = []
var paso_actual: int = 0

func _iniciar_carga_asincrona():
	print("8. Iniciando motor de tareas asíncronas...")
	
	# 1. Definimos la lista de tareas del framework base.
	# En Godot 4, 'Callable' guarda la referencia a una función.
	tareas_de_carga = [
		Callable(self, "_tarea_cargar_subsistemas"),
		Callable(self, "_tarea_preparar_audio"),
		Callable(self, "_tarea_cargar_inventarios"),
		Callable(self, "_tarea_preparar_menu")
		# Aquí puedes añadir los 70 pasos que necesites
	]
	
	# Iniciamos el bucle que recorrerá la lista
	_procesar_siguiente_tarea()

func _procesar_siguiente_tarea():
	if paso_actual < tareas_de_carga.size():
		# 1. Ejecutar la tarea actual
		var tarea = tareas_de_carga[paso_actual]
		tarea.call()
		
		# 2. Calcular el porcentaje (0.0 a 100.0)
		paso_actual += 1
		var porcentaje: float = (float(paso_actual) / float(tareas_de_carga.size())) * 100.0
		
		# 3. Actualizar la Interfaz Visual
		if config.show_progress_bar and barra_progreso:
			barra_progreso.value = porcentaje
			
		if config.show_progress_text and texto_progreso:
			texto_progreso.text = "Cargando módulo %d de %d... (%d%%)" % [paso_actual, tareas_de_carga.size(), int(porcentaje)]
		
		# 4. MAGIA DE OPTIMIZACIÓN: Esperar al siguiente fotograma.
		# Esto libera el procesador por una fracción de segundo para que 
		# la RAM y la GPU dibujen la barra moviéndose fluidamente sin tirones.
		await get_tree().process_frame
		
		# (Opcional) Pausa artificial solo para ver la barra en esta prueba
		# Quita esta línea cuando tengas tareas reales pesadas
		await get_tree().create_timer(0.5).timeout 
		
		# 5. Llamada recursiva para la siguiente tarea
		_procesar_siguiente_tarea()
	else:
		# Ya no hay más tareas, hemos llegado al 100%
		_finalizar_carga()

# --- TAREAS DE EJEMPLO DEL FRAMEWORK ---

func _tarea_cargar_subsistemas():
	print("-> Ejecutando paso 1: Subsistemas...")
	# Lógica pesada aquí

func _tarea_preparar_audio():
	print("-> Ejecutando paso 2: Audio...")
	# Lógica pesada aquí

func _tarea_cargar_inventarios():
	print("-> Ejecutando paso 3: Bases de datos...")
	# Lógica pesada aquí

func _tarea_preparar_menu():
	print("-> Ejecutando paso 4: Interfaz de usuario...")
	# Lógica pesada aquí

func _finalizar_carga():
	if config.show_progress_text and texto_progreso:
		texto_progreso.text = "¡Carga Completa!"
		
	print("9. 100% alcanzado. Cambiando de escena...")
	
	# Pausa de medio segundo para que el jugador alcance a leer "Carga Completa"
	await get_tree().create_timer(0.5).timeout 
	
	# AQUÍ ESTÁ EL SALTO REAL
	if config.next_scene_path != "" and ResourceLoader.exists(config.next_scene_path):
		get_tree().change_scene_to_file(config.next_scene_path)
	else:
		push_error("iOplazxEssence FATAL: No se configuró una 'Next Scene Path' en EssenceConfig.tres o la ruta es incorrecta.")
		
		


# ==========================================
# FUNCIONES VIRTUALES PARA EL USUARIO
# ==========================================
## Sobrescribe esta función en tu Boot.gd para inyectar tareas a la pantalla de carga.
func inject_custom_tasks(loader: EssenceLoadingScreen):
	
	pass
	
# ==========================================
# TAREAS INTERNAS DEL MOTOR (Ejemplos)
# ==========================================
func _tarea_motor_1():
	print("Cargando núcleo del framework...")
func _tarea_motor_2():
	print("Preparando manejador de escenas...")

func _finalizar_secuencia():
	print("5. Todo listo. Saltando al Menú Principal...")
	if config.next_scene_path != "" and ResourceLoader.exists(config.next_scene_path):
		get_tree().change_scene_to_file(config.next_scene_path)
	else:
		push_error("iOplazxEssence FATAL: Next Scene Path no configurada.")
