class_name BootBase extends Control

const CONFIG_PATH = "res://_static/EssenceConfig.tres"
var config: EssenceConfig

# Nodos de la escena Boot.tscn (La Demo)
@onready var logo_rect = $Logo
@onready var advertencia_label = $Advertencia

# Nuevos nodos dinámicos que crearemos por código si son necesarios
var icono_advertencia: TextureRect
var boton_ok: Button
var boton_yes: Button
var boton_no: Button

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

# --- NUEVA LÓGICA DE ADVERTENCIA INTERACTIVA ---

func _ir_a_advertencia():
	print("6. Iniciando lógica de Advertencia...")
	
	# 1. ¿El usuario desactivó la advertencia en el Inspector?
	if not config.show_warning_screen or advertencia_label == null:
		print("Advertencia omitida. Saltando a Carga...")
		_ir_a_carga()
		return

	# 2. Configurar el Texto
	if config.use_custom_text:
		advertencia_label.text = config.custom_warning_text
	else:
		advertencia_label.text = "WARNING: This game contains flashing lights and mature themes.\nPlayer discretion is advised."
	
	advertencia_label.modulate.a = 0.0
	
	# 3. Configurar el Ícono (Si lo activó)
	if config.show_warning_icon:
		_crear_icono_advertencia()
		
	# 4. Configurar los Botones (Si los activó)
	if config.button_type > 0:
		_crear_botones_advertencia()

	# 5. Animar la aparición
	var tween = create_tween()
	tween.tween_property(advertencia_label, "modulate:a", 1.0, 1.0)
	if icono_advertencia: tween.parallel().tween_property(icono_advertencia, "modulate:a", 1.0, 1.0)
	if boton_ok: tween.parallel().tween_property(boton_ok, "modulate:a", 1.0, 1.0)
	if boton_yes: tween.parallel().tween_property(boton_yes, "modulate:a", 1.0, 1.0)
	if boton_no: tween.parallel().tween_property(boton_no, "modulate:a", 1.0, 1.0)

	# 6. ¿Esperar al jugador o desaparecer solo?
	if config.button_type == 0:
		# Auto-fade (Sin botones)
		tween.tween_interval(3.0)
		tween.tween_property(advertencia_label, "modulate:a", 0.0, 1.0)
		if icono_advertencia: tween.parallel().tween_property(icono_advertencia, "modulate:a", 0.0, 1.0)
		tween.finished.connect(_ir_a_carga)
	else:
		print("Esperando interacción del jugador...")
		# El Tween termina de aparecer y se detiene. El código espera a que el jugador haga clic en un botón.

# --- FUNCIONES AUXILIARES PARA CREAR UI DINÁMICA ---

func _crear_icono_advertencia():
	icono_advertencia = TextureRect.new()
	icono_advertencia.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icono_advertencia.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icono_advertencia.custom_minimum_size = Vector2(100, 100)
	icono_advertencia.modulate.a = 0.0
	
	# Aquí cargamos los recursos que pusiste en addons/iOplazxEssence/resources/
	match config.warning_icon_type:
		0: icono_advertencia.texture = EssenceLoader.get_internImage(EssenceLoader.KeyImage.WARNING)
		1: icono_advertencia.texture = EssenceLoader.get_internImage(EssenceLoader.KeyImage.EYE)
		2: icono_advertencia.texture = EssenceLoader.get_internImage(EssenceLoader.KeyImage.PLUS18)
		3: icono_advertencia.texture = EssenceLoader.get_externImage(config.custom_warning_icon_path, true)
	
	# Lo añadimos como hijo de la escena para que se vea
	add_child(icono_advertencia)
	# Centramos el icono un poco más arriba del texto
	icono_advertencia.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	icono_advertencia.position.y += 100

func _crear_botones_advertencia():
	# HBoxContainer alinea automáticamente los botones horizontalmente
	var contenedor_botones = HBoxContainer.new()
	contenedor_botones.alignment = BoxContainer.ALIGNMENT_CENTER
	# Separación entre botones
	contenedor_botones.add_theme_constant_override("separation", 20) 
	contenedor_botones.modulate.a = 0.0 
	
	match config.button_type:
		1: # OK
			boton_ok = Button.new()
			boton_ok.text = "OK"
			boton_ok.custom_minimum_size = Vector2(150, 50)
			boton_ok.pressed.connect(_ir_a_carga) # Avanza al siguiente paso
			contenedor_botones.add_child(boton_ok)
			
		2: # Yes / No
			boton_yes = Button.new()
			boton_yes.text = "Yes"
			boton_yes.custom_minimum_size = Vector2(120, 50)
			boton_yes.pressed.connect(_ir_a_carga)
			
			boton_no = Button.new()
			boton_no.text = "No"
			boton_no.custom_minimum_size = Vector2(120, 50)
			boton_no.pressed.connect(get_tree().quit) # Cierra la aplicación
			
			contenedor_botones.add_child(boton_yes)
			contenedor_botones.add_child(boton_no)
			
		3: # Confirm / Reject (Exit)
			var boton_confirm = Button.new()
			boton_confirm.text = "Confirm"
			boton_confirm.custom_minimum_size = Vector2(150, 50)
			boton_confirm.pressed.connect(_ir_a_carga)
			
			var boton_reject = Button.new()
			boton_reject.text = "Reject (Exit)"
			boton_reject.custom_minimum_size = Vector2(150, 50)
			boton_reject.pressed.connect(get_tree().quit)
			
			contenedor_botones.add_child(boton_confirm)
			contenedor_botones.add_child(boton_reject)

	add_child(contenedor_botones)
	contenedor_botones.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	contenedor_botones.position.y -= 80 # Margen desde abajo
	
	# Fade-in de los botones
	var tween = create_tween()
	tween.tween_property(contenedor_botones, "modulate:a", 1.0, 1.0)

func _ir_a_carga():
	print("7. Advertencia terminada. Preparando pantalla de Carga...")
