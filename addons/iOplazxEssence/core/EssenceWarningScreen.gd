class_name EssenceWarningScreen extends Control

signal warning_completed 

var config: EssenceConfig
var contenedor_principal: VBoxContainer 
var advertencia_label: Label
var icono_advertencia: TextureRect
var contenedor_botones_advertencia: HBoxContainer

# NUEVO: Variable para guardar el botón que tendrá el foco inicial
var primer_boton: Button = null 

func mostrar_advertencia(cfg: EssenceConfig):
	config = cfg
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	self.modulate.a = 0.0 
	
	if not config.show_warning_screen:
		_finalizar()
		return

	contenedor_principal = VBoxContainer.new()
	contenedor_principal.alignment = BoxContainer.ALIGNMENT_CENTER
	contenedor_principal.add_theme_constant_override("separation", 30) 
	
	if config.show_warning_icon:
		_crear_icono_advertencia()
		
	_crear_texto_advertencia()
	
	if config.button_type > 0:
		_crear_botones_advertencia()

	# 3. Centrar el bloque maestro en la pantalla
	add_child(contenedor_principal)
	contenedor_principal.set_anchors_and_offsets_preset(Control.PRESET_CENTER)

	if primer_boton:
		primer_boton.grab_focus()

	# 4. Animar el bloque completo
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 1.0)

	if config.button_type == 0:
		tween.tween_interval(3.0)
		tween.tween_property(self, "modulate:a", 0.0, 1.0)
		tween.finished.connect(_finalizar)

# --- FUNCIONES DE CONSTRUCCIÓN VISUAL ---

func _crear_icono_advertencia():
	icono_advertencia = TextureRect.new()
	icono_advertencia.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icono_advertencia.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icono_advertencia.custom_minimum_size = Vector2(80, 80) 
	
	match config.warning_icon_type:
		0: icono_advertencia.texture = EssenceLoader.get_internImage(EssencePaths.KeyImage.WARNING)
		1: icono_advertencia.texture = EssenceLoader.get_internImage(EssencePaths.KeyImage.EYE)
		2: icono_advertencia.texture = EssenceLoader.get_internImage(EssencePaths.KeyImage.PLUS18)
		3: icono_advertencia.texture = EssenceLoader.get_externImage(config.custom_warning_icon_path, true)
	
	contenedor_principal.add_child(icono_advertencia)

func _crear_texto_advertencia():
	advertencia_label = Label.new()
	advertencia_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	advertencia_label.add_theme_font_size_override("font_size", 24)
	
	if config.use_custom_text:
		advertencia_label.text = config.custom_warning_text
	else:
		advertencia_label.text = "WARNING: This game contains flashing lights and mature themes.\nPlayer discretion is advised."
	
	contenedor_principal.add_child(advertencia_label)

func _crear_botones_advertencia():
	contenedor_botones_advertencia = HBoxContainer.new()
	contenedor_botones_advertencia.alignment = BoxContainer.ALIGNMENT_CENTER
	contenedor_botones_advertencia.add_theme_constant_override("separation", 20) 
	
	var margen_superior = MarginContainer.new()
	margen_superior.add_theme_constant_override("margin_top", 15)
	
	match config.button_type:
		1: # OK
			var boton_ok = Button.new()
			boton_ok.text = "OK"
			boton_ok.custom_minimum_size = Vector2(150, 50)
			boton_ok.pressed.connect(_finalizar) 
			contenedor_botones_advertencia.add_child(boton_ok)
			primer_boton = boton_ok 
		2: # Yes / No
			var boton_yes = Button.new()
			boton_yes.text = "Yes"
			boton_yes.custom_minimum_size = Vector2(120, 50)
			boton_yes.pressed.connect(_finalizar)
			var boton_no = Button.new()
			boton_no.text = "No"
			boton_no.custom_minimum_size = Vector2(120, 50)
			boton_no.pressed.connect(get_tree().quit) 
			contenedor_botones_advertencia.add_child(boton_yes)
			contenedor_botones_advertencia.add_child(boton_no)
			primer_boton = boton_yes 
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
			primer_boton = boton_confirm 

	margen_superior.add_child(contenedor_botones_advertencia)
	contenedor_principal.add_child(margen_superior)

func _finalizar():
	warning_completed.emit()
	queue_free()
