class_name EssenceBootLogo extends Control

const ES_NAME_CLASS = "EssenceBootLogo"

signal logo_completed

var config: EssenceConfig
var logo_container: VBoxContainer

## Entry point for the splash screen logic
func mostrar_logo(cfg: EssenceConfig):
	config = cfg
	
	# Safety Check: If config is missing, we can't proceed
	if not is_instance_valid(config):
		EssenceError.report(
			"Boot Error", 
			"EssenceConfig is null. Skipping splash screen to avoid crash.", 
			EssenceError.Severity.WARNING
		)
		_finalizar()
		return
		
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	if config.skip_splash_screen:
		EssenceLogger.system_info("[%s] Splash screen skipped by config." % ES_NAME_CLASS)
		_finalizar()
		return
		
	_preparar_logo()
	_animar_logo()

func _preparar_logo():
	logo_container = VBoxContainer.new()
	logo_container.alignment = BoxContainer.ALIGNMENT_CENTER
	logo_container.add_theme_constant_override("separation", 15) 
	
	var logo_rect = TextureRect.new()
	logo_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo_rect.custom_minimum_size = Vector2(200, 200) 
	
	var logo_label = Label.new()
	logo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	logo_label.add_theme_font_size_override("font_size", 24)
	
	var logo_name_for_log: String = ""
	
	match config.logo_type:
		0: 
			logo_rect.texture = EssenceLoader.get_internImage(EssencePaths.KeyImage.GODOT) 
			logo_label.text = "GODOT ENGINE"
			logo_name_for_log = "Godot"
		1: 
			logo_rect.texture = EssenceLoader.get_internImage(EssencePaths.KeyImage.IOPLAZX)
			logo_label.text = "iOPLAZXESSENCE ENGINE"
			logo_name_for_log = "iOplazxEssence"
		2: 
			logo_rect.texture = EssenceLoader.get_externImage(config.custom_logo_path, true)
			logo_label.text = config.custom_logo_text
			logo_name_for_log = "Custom (%s)" % config.custom_logo_path
			
	EssenceLogger.system_info("[%s] Displaying splash logo: %s" % [ES_NAME_CLASS, logo_name_for_log])
			
	logo_container.add_child(logo_rect)
	logo_container.add_child(logo_label)
	
	add_child(logo_container)
	logo_container.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	
	# Center adjustment
	logo_container.position.y -= 40 
	logo_container.modulate.a = 0.0

func _animar_logo():
	if not is_instance_valid(logo_container): 
		_finalizar()
		return
		
	var tween = create_tween()
	# Bind tween to this node to prevent leaks if the scene changes abruptly
	tween.bind_node(self)
	
	tween.tween_property(logo_container, "modulate:a", 1.0, 1.5) 
	tween.tween_interval(1.0) 
	tween.tween_property(logo_container, "modulate:a", 0.0, 1.5) 
	
	tween.finished.connect(_finalizar)

func _finalizar():
	EssenceLogger.system_info("[%s] Splash screen completed." % ES_NAME_CLASS)
	logo_completed.emit()
	queue_free()