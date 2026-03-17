class_name BootBase extends Control

const CONFIG_PATH = "res://_static/EssenceConfig.tres"
var config: EssenceConfig

@onready var logo_rect = $Logo 

func _ready():
	print("--- BOOTBASE: Arrancando ---")
	_cargar_configuracion()
	iniciar_secuencia()

func _cargar_configuracion():
	print("1. Buscando archivo en: ", CONFIG_PATH)
	
	if ResourceLoader.exists(CONFIG_PATH):
		print("2. Archivo encontrado. Intentando transformarlo...")
		var recurso_temporal = load(CONFIG_PATH)
		config = recurso_temporal as EssenceConfig
		
		if config == null:
			print("3. ALERTA: Godot encontró el archivo, pero no reconoce que sea un EssenceConfig. (¿Le falta el script?)")
	else:
		print("2. Archivo NO encontrado en la ruta.")
		
	# EL SALVAVIDAS DEFINITIVO:
	if config == null:
		print("4. Creando configuración de emergencia (Defaults) en RAM para evitar crasheo.")
		config = EssenceConfig.new()
	else:
		print("4. Configuración de usuario cargada con éxito.")

func iniciar_secuencia():
	# Doble protección por si el salvavidas falla
	if config == null:
		print("ERROR FATAL: El salvavidas falló. config sigue siendo nulo.")
		return
		
	print("5. Saltando splash screen?: ", config.skip_splash_screen)
	
	if config.skip_splash_screen:
		_ir_a_advertencia()
		return
		
	_preparar_logo()
	_animar_logo()

func _preparar_logo():
	if logo_rect == null:
		print("ERROR: No se encontró el nodo $Logo")
		return
		
	logo_rect.modulate.a = 0.0 
	
	match config.logo_type:
		0: 
			print("Cargando logo de Godot...")
		1: 
			print("Cargando logo de iOplazx...")
		2: 
			if config.custom_logo_path != "":
				print("Cargando logo personalizado...")
				logo_rect.texture = load(config.custom_logo_path)

func _animar_logo():
	if logo_rect == null: return
	var tween = create_tween()
	tween.tween_property(logo_rect, "modulate:a", 1.0, 1.5) 
	tween.tween_interval(1.0) 
	tween.tween_property(logo_rect, "modulate:a", 0.0, 1.5) 
	tween.finished.connect(_ir_a_advertencia)

func _ir_a_advertencia():
	print("6. El logo terminó. Pasando a la pantalla de Advertencia (Paso 3)...")
