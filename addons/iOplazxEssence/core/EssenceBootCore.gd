class_name EssenceBootCore extends Control

const CONFIG_PATH = "res://_static/EssenceConfig.tres"
var config: EssenceConfig
var logo_container: VBoxContainer

func _ready():
	print("--- iOplazxEssence: Secuencia de Arranque ---")
	_cargar_configuracion()
	iniciar_secuencia()

func _cargar_configuracion():
	print("1. Cargando configuración...")
	if ResourceLoader.exists(CONFIG_PATH):
		config = load(CONFIG_PATH) as EssenceConfig
		
	if config == null:
		print("ALERTA: Usando configuración de emergencia en RAM.")
		config = EssenceConfig.new()

func iniciar_secuencia():
	if config == null: return
	
	if config.skip_splash_screen:
		_ir_a_advertencia()
		return
		
	_preparar_logo()
	_animar_logo()

func _preparar_logo():
	# Creamos un contenedor dinámico para apilar Logo y Texto
	logo_container = VBoxContainer.new()
	logo_container.alignment = BoxContainer.ALIGNMENT_CENTER
	logo_container.add_theme_constant_override("separation", 15) # Espacio entre logo y texto
	
	var logo_rect = TextureRect.new()
	logo_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo_rect.custom_minimum_size = Vector2(200, 200) # Tamaño grande en el centro
	
	var logo_label = Label.new()
	logo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	# Lógica para elegir imagen y texto
	match config.logo_type:
		0: 
			logo_rect.texture = EssenceLoader.get_internImage(EssenceLoader.KeyImage.GODOT) # Asegúrate de tener GODOT en tu enum
			logo_label.text = "GODOT"
		1: 
			logo_rect.texture = EssenceLoader.get_internImage(EssenceLoader.KeyImage.EYE) # Reemplaza con tu logo real iOplazx
			logo_label.text = "iOplazxEssence Engine"
		2: 
			logo_rect.texture = EssenceLoader.get_externImage(config.custom_logo_path, true)
			logo_label.text = config.custom_logo_text
			
	# Añadimos al contenedor
	logo_container.add_child(logo_rect)
	logo_container.add_child(logo_label)
	
	# Añadimos a la pantalla, centramos y subimos un poco
	add_child(logo_container)
	logo_container.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	logo_container.position.y -= 40 # Lo movemos más arriba como pediste
	
	logo_container.modulate.a = 0.0 

func _animar_logo():
	if logo_container == null: return
	var tween = create_tween()
	tween.tween_property(logo_container, "modulate:a", 1.0, 1.5) 
	tween.tween_interval(1.0) 
	tween.tween_property(logo_container, "modulate:a", 0.0, 1.5) 
	tween.finished.connect(_ir_a_advertencia)

# Función virtual que será sobrescrita (overridden) por el hijo BootBase
func _ir_a_advertencia():
	pass
