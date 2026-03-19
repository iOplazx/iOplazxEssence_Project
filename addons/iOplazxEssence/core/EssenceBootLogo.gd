class_name EssenceBootLogo extends Control

signal logo_completed

var config: EssenceConfig
var logo_container: VBoxContainer

func mostrar_logo(cfg: EssenceConfig):
	config = cfg
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	if config.skip_splash_screen:
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
	
	match config.logo_type:
		0: 
			logo_rect.texture = EssenceLoader.get_internImage(EssenceLoader.KeyImage.GODOT) 
			logo_label.text = "GODOT"
		1: 
			logo_rect.texture = EssenceLoader.get_internImage(EssenceLoader.KeyImage.EYE) # Cambia EYE por tu logo
			logo_label.text = "iOplazxEssence Engine"
		2: 
			logo_rect.texture = EssenceLoader.get_externImage(config.custom_logo_path, true)
			logo_label.text = config.custom_logo_text
			
	logo_container.add_child(logo_rect)
	logo_container.add_child(logo_label)
	
	add_child(logo_container)
	logo_container.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	logo_container.position.y -= 40 
	
	logo_container.modulate.a = 0.0 

func _animar_logo():
	if logo_container == null: return
	var tween = create_tween()
	tween.tween_property(logo_container, "modulate:a", 1.0, 1.5) 
	tween.tween_interval(1.0) 
	tween.tween_property(logo_container, "modulate:a", 0.0, 1.5) 
	tween.finished.connect(_finalizar)

func _finalizar():
	logo_completed.emit()
	queue_free() # ¡Liberamos la RAM del logo!
