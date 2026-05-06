class_name EssenceLoadingScreen extends Control

const ES_NAME_CLASS = "EssenceLoadingScreen"

signal loading_completed

var config: EssenceConfig
var contenedor: VBoxContainer
var barra_progreso: ProgressBar
var texto_progreso: Label
var logo_carga: TextureRect

# Task management
var _tasks: Array[Callable] = []
var _current_step: int = 0

# ==========================================
# PUBLIC METHODS (API)
# ==========================================

## Adds a single task to the loading queue
func add_task(task: Callable) -> void:
	_tasks.append(task)

## Adds multiple tasks at once
func add_tasks(tasks: Array[Callable]) -> void:
	_tasks.append_array(tasks)

## Manual status update from external tasks
func set_status_text(text: String) -> void:
	if is_instance_valid(texto_progreso):
		texto_progreso.text = text

## Starts the asynchronous loading process
func start_loading(cfg: EssenceConfig) -> void:
	config = cfg
	
	# Safety check
	if not is_instance_valid(config):
		EssenceError.report("Boot Error", "EssenceConfig is missing in LoadingScreen.", EssenceError.Severity.CRITICAL)
		_finish()
		return
		
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	if not config.show_loading_screen:
		EssenceLogger.system_info("[%s] Loading screen disabled. Running tasks silently..." % ES_NAME_CLASS)
		_run_tasks_silently()
		return
		
	_build_ui()
	
	# Initial Fade-in
	self.modulate.a = 0.0
	var tween = create_tween()
	tween.bind_node(self)
	tween.tween_property(self, "modulate:a", 1.0, 0.4)
	tween.finished.connect(_process_next_task)

# ==========================================
# INTERNAL LOGIC
# ==========================================

func _build_ui() -> void:
	contenedor = VBoxContainer.new()
	contenedor.alignment = BoxContainer.ALIGNMENT_CENTER
	contenedor.add_theme_constant_override("separation", 20)
	
	# 1. Logo Setup
	if config.loading_logo_type != 3: # 3 is "None"
		logo_carga = TextureRect.new()
		logo_carga.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		logo_carga.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		logo_carga.custom_minimum_size = Vector2(200, 200)
		
		match config.loading_logo_type:
			0: logo_carga.texture = EssenceLoader.get_internImage(EssencePaths.KeyImage.GODOT)
			1: logo_carga.texture = EssenceLoader.get_internImage(EssencePaths.KeyImage.IOPLAZX) 
			2: 
				if config.custom_loading_logo != null:
					logo_carga.texture = config.custom_loading_logo
				else:
					EssenceError.report("Logo Custom Mising", "Se seleccionó Custom pero no hay imagen", EssenceError.Severity.WARNING)
					# Aquí puedes poner tu fallback
				
		contenedor.add_child(logo_carga)

	# 2. Progress Bar Setup
	if config.show_progress_bar:
		barra_progreso = ProgressBar.new()
		barra_progreso.custom_minimum_size = Vector2(500, 30)
		barra_progreso.step = 1.0
		barra_progreso.value = 0.0
		if config.show_progress_text: 
			barra_progreso.show_percentage = false 
		contenedor.add_child(barra_progreso)

	# 3. Status Label Setup
	if config.show_progress_text:
		texto_progreso = Label.new()
		texto_progreso.text = "Initializing modules..."
		texto_progreso.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		contenedor.add_child(texto_progreso)

	add_child(contenedor)
	contenedor.set_anchors_and_offsets_preset(Control.PRESET_CENTER)

func _process_next_task() -> void:
	if _current_step < _tasks.size():
		var task = _tasks[_current_step]
		
		# Execute the task
		if task.is_valid():
			task.call()
		
		_current_step += 1
		var percentage: float = (float(_current_step) / float(_tasks.size())) * 100.0
		
		# Update UI
		if is_instance_valid(barra_progreso):
			barra_progreso.value = percentage
			
		if is_instance_valid(texto_progreso):
			# Only overwrite if it's the default text
			if texto_progreso.text.begins_with("Init") or texto_progreso.text.begins_with("Loading"):
				texto_progreso.text = "Loading module %d of %d... (%d%%)" % [_current_step, _tasks.size(), int(percentage)]
		
		# Async magic: Let the engine breathe for one frame
		await get_tree().process_frame
		
		# --- DEMO TIMER ---
		# Comment this line for production speed!
		# await get_tree().create_timer(0.1).timeout 
		
		_process_next_task()
	else:
		_complete_loading()

func _complete_loading() -> void:
	if is_instance_valid(texto_progreso):
		texto_progreso.text = "All modules loaded!"
	
	EssenceLogger.system_info("[%s] All %d tasks completed successfully." % [ES_NAME_CLASS, _tasks.size()])
	
	# Short delay for the user to see the 100%
	await get_tree().create_timer(0.4).timeout
	_finish()

func _run_tasks_silently() -> void:
	for task in _tasks:
		if task.is_valid():
			task.call()
		await get_tree().process_frame
	_finish()

func _finish() -> void:
	var tween = create_tween()
	tween.bind_node(self)
	tween.tween_property(self, "modulate:a", 0.0, 0.4)
	
	tween.finished.connect(func():
		loading_completed.emit()
		queue_free()
	)
