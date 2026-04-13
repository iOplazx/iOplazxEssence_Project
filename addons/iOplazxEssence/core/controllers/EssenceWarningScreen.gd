class_name EssenceWarningScreen extends Control

const ES_NAME_CLASS = "EssenceWarningScreen"

signal warning_completed 

var config: EssenceConfig
var contenedor_principal: VBoxContainer 
var advertencia_label: Label
var icono_advertencia: TextureRect
var contenedor_botones_advertencia: HBoxContainer

# Variable para guardar el botón que tendrá el foco inicial
var primer_boton: Button = null 

func mostrar_advertencia(cfg: EssenceConfig) -> void:
	config = cfg
	
	# Blindaje: Si no hay config, saltamos la pantalla para evitar crasheos
	if not is_instance_valid(config):
		EssenceLogger.system_info("[%s] Missing EssenceConfig. Skipping warning screen." % ES_NAME_CLASS)
		_finalizar()
		return
		
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	self.modulate.a = 0.0 
	
	if not config.show_warning_screen:
		EssenceLogger.system_info("[%s] Warning screen disabled by config." % ES_NAME_CLASS)
		_finalizar()
		return

	# 1. Construcción de la UI dinámica
	contenedor_principal = VBoxContainer.new()
	contenedor_principal.alignment = BoxContainer.ALIGNMENT_CENTER
	contenedor_principal.add_theme_constant_override("separation", 30) 
	
	if config.show_warning_icon:
		_crear_icono_advertencia()
		
	_crear_texto_advertencia()
	
	if config.button_type > 0:
		_crear_botones_advertencia()

	# 2. Centrar el bloque maestro en la pantalla
	add_child(contenedor_principal)
	contenedor_principal.set_anchors_and_offsets_preset(Control.PRESET_CENTER)

	if primer_boton:
		primer_boton.grab_focus()

	# 3. Animar la entrada
	var tween = create_tween()
	tween.bind_node(self)
	tween.tween_property(self, "modulate:a", 1.0, 1.0)

	# 4. Comportamiento automático (Si no hay botones)
	if config.button_type == 0:
		tween.tween_interval(3.0)
		tween.tween_property(self, "modulate:a", 0.0, 1.0)
		tween.finished.connect(_finalizar)

# --- FUNCIONES DE CONSTRUCCIÓN VISUAL ---

func _crear_icono_advertencia() -> void:
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

func _crear_texto_advertencia() -> void:
	advertencia_label = Label.new()
	advertencia_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	advertencia_label.add_theme_font_size_override("font_size", 24)
	
	if config.use_custom_text:
		advertencia_label.text = config.custom_warning_text
	else:
		# Envolvemos en tr() para soportar localización futura
		advertencia_label.text = tr("WARNING_DEFAULT_TEXT") 
		if advertencia_label.text == "WARNING_DEFAULT_TEXT": # Fallback si no hay CSV
			advertencia_label.text = "WARNING: This game contains flashing lights and mature themes.\nPlayer discretion is advised."
	
	contenedor_principal.add_child(advertencia_label)

func _crear_botones_advertencia() -> void:
	contenedor_botones_advertencia = HBoxContainer.new()
	contenedor_botones_advertencia.alignment = BoxContainer.ALIGNMENT_CENTER
	contenedor_botones_advertencia.add_theme_constant_override("separation", 20) 
	
	var margen_superior = MarginContainer.new()
	margen_superior.add_theme_constant_override("margin_top", 15)
	
	match config.button_type:
		1: # OK
			var boton_ok = Button.new()
			boton_ok.text = tr("MENU_OK") if tr("MENU_OK") != "MENU_OK" else "OK"
			boton_ok.custom_minimum_size = Vector2(150, 50)
			boton_ok.pressed.connect(func(): _cerrar_con_animacion(true)) 
			contenedor_botones_advertencia.add_child(boton_ok)
			primer_boton = boton_ok 
		2: # Yes / No
			var boton_yes = Button.new()
			boton_yes.text = tr("MENU_YES") if tr("MENU_YES") != "MENU_YES" else "Yes"
			boton_yes.custom_minimum_size = Vector2(120, 50)
			boton_yes.pressed.connect(func(): _cerrar_con_animacion(true))
			
			var boton_no = Button.new()
			boton_no.text = tr("MENU_NO") if tr("MENU_NO") != "MENU_NO" else "No"
			boton_no.custom_minimum_size = Vector2(120, 50)
			boton_no.pressed.connect(func(): _cerrar_con_animacion(false)) 
			
			contenedor_botones_advertencia.add_child(boton_yes)
			contenedor_botones_advertencia.add_child(boton_no)
			primer_boton = boton_yes 
		3: # Confirm / Reject
			var boton_confirm = Button.new()
			boton_confirm.text = tr("MENU_CONFIRM") if tr("MENU_CONFIRM") != "MENU_CONFIRM" else "Confirm"
			boton_confirm.custom_minimum_size = Vector2(150, 50)
			boton_confirm.pressed.connect(func(): _cerrar_con_animacion(true))
			
			var boton_reject = Button.new()
			boton_reject.text = tr("MENU_REJECT") if tr("MENU_REJECT") != "MENU_REJECT" else "Reject (Exit)"
			boton_reject.custom_minimum_size = Vector2(150, 50)
			boton_reject.pressed.connect(func(): _cerrar_con_animacion(false))
			
			contenedor_botones_advertencia.add_child(boton_confirm)
			contenedor_botones_advertencia.add_child(boton_reject)
			primer_boton = boton_confirm 

	margen_superior.add_child(contenedor_botones_advertencia)
	contenedor_principal.add_child(margen_superior)

# --- LÓGICA DE SALIDA Y ANIMACIÓN ---

## Oculta los botones, reproduce sonido, hace un fade-out y ejecuta la acción
func _cerrar_con_animacion(aceptado: bool) -> void:
	if is_instance_valid(AudioManager):
		AudioManager.play_ui_sfx()
		
	# Escondemos los botones inmediatamente para evitar un doble clic accidental
	if is_instance_valid(contenedor_botones_advertencia):
		contenedor_botones_advertencia.hide()
		
	var tween = create_tween()
	tween.bind_node(self)
	tween.tween_property(self, "modulate:a", 0.0, 0.4) # Fade out rápido de 0.4s
	
	tween.finished.connect(func():
		if aceptado:
			EssenceLogger.system_info("[%s] Player accepted warning." % ES_NAME_CLASS)
			_finalizar()
		else:
			EssenceLogger.system_info("[%s] Player rejected warning. Terminating engine." % ES_NAME_CLASS)
			get_tree().quit()
	)

func _finalizar() -> void:
	warning_completed.emit()
	queue_free()