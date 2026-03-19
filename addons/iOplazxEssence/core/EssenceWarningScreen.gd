class_name EssenceWarningScreen extends Control

# Esta señal es la que le gritará al BootBase: "¡Ya terminé!"
signal warning_completed 

var config: EssenceConfig
var advertencia_label: Label
var icono_advertencia: TextureRect
var contenedor_botones_advertencia: HBoxContainer
var boton_ok: Button
var boton_yes: Button
var boton_no: Button

func mostrar_advertencia(cfg: EssenceConfig):
	config = cfg
	# Hacemos que este control ocupe toda la pantalla
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	self.modulate.a = 0.0 # Hacemos TODO invisible
	
	if not config.show_warning_screen:
		print("Advertencia omitida. Saltando a Carga...")
		_finalizar()
		return

	# 1. Crear el texto dinámicamente
	advertencia_label = Label.new()
	advertencia_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	if config.use_custom_text:
		advertencia_label.text = config.custom_warning_text
	else:
		advertencia_label.text = "WARNING: This game contains flashing lights and mature themes.\nPlayer discretion is advised."
	
	add_child(advertencia_label)
	advertencia_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)

	# 2. Crear ícono y botones si están activados
	if config.show_warning_icon:
		_crear_icono_advertencia()
		
	if config.button_type > 0:
		_crear_botones_advertencia()

	# 3. Animar TODO de un solo golpe (Ahorro de CPU)
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 1.0)

	if config.button_type == 0:
		tween.tween_interval(3.0)
		tween.tween_property(self, "modulate:a", 0.0, 1.0)
		tween.finished.connect(_finalizar)
	else:
		print("Esperando interacción del jugador...")

func _crear_icono_advertencia():
	icono_advertencia = TextureRect.new()
	icono_advertencia.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icono_advertencia.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icono_advertencia.custom_minimum_size = Vector2(100, 100)
	
	match config.warning_icon_type:
		0: icono_advertencia.texture = EssenceLoader.get_internImage(EssenceLoader.KeyImage.WARNING)
		1: icono_advertencia.texture = EssenceLoader.get_internImage(EssenceLoader.KeyImage.EYE)
		2: icono_advertencia.texture = EssenceLoader.get_internImage(EssenceLoader.KeyImage.PLUS18)
		3: icono_advertencia.texture = EssenceLoader.get_externImage(config.custom_warning_icon_path, true)
	
	add_child(icono_advertencia)
	icono_advertencia.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	icono_advertencia.position.y += 100

func _crear_botones_advertencia():
	contenedor_botones_advertencia = HBoxContainer.new()
	contenedor_botones_advertencia.alignment = BoxContainer.ALIGNMENT_CENTER
	contenedor_botones_advertencia.add_theme_constant_override("separation", 20) 
	
	match config.button_type:
		1: # OK
			boton_ok = Button.new()
			boton_ok.text = "OK"
			boton_ok.custom_minimum_size = Vector2(150, 50)
			boton_ok.pressed.connect(_finalizar) 
			contenedor_botones_advertencia.add_child(boton_ok)
		2: # Yes / No
			boton_yes = Button.new()
			boton_yes.text = "Yes"
			boton_yes.custom_minimum_size = Vector2(120, 50)
			boton_yes.pressed.connect(_finalizar)
			boton_no = Button.new()
			boton_no.text = "No"
			boton_no.custom_minimum_size = Vector2(120, 50)
			boton_no.pressed.connect(get_tree().quit) 
			contenedor_botones_advertencia.add_child(boton_yes)
			contenedor_botones_advertencia.add_child(boton_no)
		3: # Confirm / Reject
			var boton_confirm = Button.new()
			boton_confirm.text = "Confirm"
			boton_confirm.custom_minimum_size = Vector2(150, 50)
			boton_confirm.pressed.connect(_finalizar)
			var boton_reject = Button.new()
			boton_reject.text = "Reject (Exit)"
			boton_reject.custom_minimum_size = Vector2(150, 50)
			boton_reject.pressed.connect(get_tree().quit)
			contenedor_botones_advertencia.add_child(boton_confirm)
			contenedor_botones_advertencia.add_child(boton_reject)

	add_child(contenedor_botones_advertencia)
	contenedor_botones_advertencia.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	contenedor_botones_advertencia.position.y -= 80

func _finalizar():
	# Le avisa al BootBase que ya terminó, y luego destruye esta pantalla completa de la RAM
	warning_completed.emit()
	queue_free()
