class_name EssenceLoadingScreen extends Control

signal loading_completed

var config: EssenceConfig
var contenedor: VBoxContainer
var barra_progreso: ProgressBar
var texto_progreso: Label
var logo_carga: TextureRect

# Variables privadas para el manejo de tareas
var _tasks: Array[Callable] = []
var _current_step: int = 0

# ==========================================
# PUBLIC METHODS (API para el Usuario)
# ==========================================

## Añade una sola tarea a la cola de carga
func add_task(task: Callable):
	_tasks.append(task)

## Añade múltiples tareas de golpe
func add_tasks(tasks: Array[Callable]):
	_tasks.append_array(tasks)

## Permite al usuario cambiar el texto de carga manualmente desde sus tareas
func set_status_text(text: String):
	if texto_progreso:
		texto_progreso.text = text

## Inicia el proceso asíncrono
func start_loading(cfg: EssenceConfig):
	config = cfg
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	if not config.show_loading_screen:
		_run_tasks_silently()
		return
		
	_build_ui()
	
	# Fade-in de la UI
	self.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.5)
	tween.finished.connect(_process_next_task)

# ==========================================
# INTERNAL LOGIC (Privado del Framework)
# ==========================================

func _build_ui():
	contenedor = VBoxContainer.new()
	contenedor.alignment = BoxContainer.ALIGNMENT_CENTER
	contenedor.add_theme_constant_override("separation", 20)
	
	if config.loading_logo_type != 3: # 3 es "None"
		logo_carga = TextureRect.new()
		logo_carga.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		logo_carga.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		logo_carga.custom_minimum_size = Vector2(200, 200)
		
		match config.loading_logo_type:
			0: logo_carga.texture = EssenceLoader.get_internImage(EssenceLoader.KeyImage.GODOT)
			1: logo_carga.texture = EssenceLoader.get_internImage(EssenceLoader.KeyImage.EYE) # Cambia EYE por tu logo
			2: logo_carga.texture = EssenceLoader.get_externImage(config.custom_loading_logo_path, true)
		
		contenedor.add_child(logo_carga)

	if config.show_progress_bar:
		barra_progreso = ProgressBar.new()
		barra_progreso.custom_minimum_size = Vector2(500, 30)
		barra_progreso.step = 1.0
		barra_progreso.value = 0.0
		if config.show_progress_text: barra_progreso.show_percentage = false 
		contenedor.add_child(barra_progreso)

	if config.show_progress_text:
		texto_progreso = Label.new()
		texto_progreso.text = "Initializing engine..."
		texto_progreso.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		contenedor.add_child(texto_progreso)

	add_child(contenedor)
	contenedor.set_anchors_and_offsets_preset(Control.PRESET_CENTER)

func _process_next_task():
	if _current_step < _tasks.size():
		# Ejecutar tarea actual
		var task = _tasks[_current_step]
		task.call()
		
		_current_step += 1
		var percentage: float = (float(_current_step) / float(_tasks.size())) * 100.0
		
		if barra_progreso:
			barra_progreso.value = percentage
			
		# Solo actualizamos el texto si el usuario no lo ha cambiado manualmente con set_status_text()
		if texto_progreso and texto_progreso.text.begins_with("Init") or texto_progreso.text.begins_with("Loading"):
			texto_progreso.text = "Loading module %d of %d... (%d%%)" % [_current_step, _tasks.size(), int(percentage)]
		
		# Magia asíncrona: liberamos un fotograma
		await get_tree().process_frame
		
		# Pausa de 0.5s SOLO para la demo, quítala después para que cargue a máxima velocidad
		await get_tree().create_timer(0.5).timeout 
		
		_process_next_task()
	else:
		if texto_progreso:
			texto_progreso.text = "Loading Complete!"
		await get_tree().create_timer(0.5).timeout
		_finish()

func _run_tasks_silently():
	for task in _tasks:
		task.call()
		await get_tree().process_frame
	_finish()

func _finish():
	# Creamos la transición de desvanecimiento (Fade out de 0.5 segundos)
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	
	# Cuando el desvanecimiento termine, entonces sí avisamos al BootBase y nos destruimos
	tween.finished.connect(func():
		loading_completed.emit()
		queue_free()
	)
