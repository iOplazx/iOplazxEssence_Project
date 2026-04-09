extends CanvasLayer

@onready var btn_trigger = $MainControl/BtnWarningTrigger
@onready var warning_panel = $MainControl/WarningPanel
@onready var btn_close = $MainControl/WarningPanel/Layout/Header/BtnClose
@onready var warning_list = $MainControl/WarningPanel/Layout/Scroll/Margin/WarningList
@onready var lbl_title = $MainControl/WarningPanel/Layout/Header/lblTitle
@onready var btn_clear = $MainControl/WarningPanel/Layout/Footer/BtnClear

var _unread_count: int = 0

func _ready():
	# Paso 1: Empezamos con la pantalla totalmente limpia
	warning_panel.visible = false
	btn_trigger.visible = false
	
	# Conexiones
	btn_trigger.pressed.connect(_on_trigger_pressed)
	btn_close.pressed.connect(_on_close_pressed)
	btn_clear.pressed.connect(_clear_history)
	
	# Paso 2: Escuchamos globalmente al sistema de errores
	if EssenceError.has_signal("on_error_reported"):
		EssenceError.on_error_reported.connect(_on_new_error)

# ==========================================
# FLUJO AUTOMÁTICO
# ==========================================

func _on_new_error(data: Dictionary):
	# Si es un Warning, despertamos al sistema
	if data.get("severity", 0) == EssenceError.Severity.WARNING:
		_add_warning_to_list(data)
		_unread_count += 1
		
		# ¡Aparición! Solo se hace visible si hay algo que reportar
		btn_trigger.visible = true
		btn_trigger.modulate = Color(1.0, 0.8, 0.2) # Brillo amarillo

func _on_trigger_pressed():
	# Abrimos el panel y reseteamos el contador visual
	warning_panel.visible = true
	btn_trigger.modulate = Color(1.0, 1.0, 1.0, 0.5) # Se vuelve tenue al estar abierto
	_unread_count = 0
	lbl_title.text = "SYSTEM WARNINGS (" + str(warning_list.get_child_count()) + ")"

func _on_close_pressed():
	# Paso 3: Limpieza total de la UI para que no estorbe
	warning_panel.visible = false
	btn_trigger.visible = false # El icono desaparece hasta que llegue un NUEVO warning
	print("EssenceWarningUI: Interfaz ocultada por el usuario.")

# ==========================================
# UTILIDADES
# ==========================================

func _add_warning_to_list(data: Dictionary):
	var time = Time.get_time_string_from_system()
	var title = data.get("title", "WARNING")
	var msg = data.get("message", "")
	
	var label = Label.new()
	label.text = "[%s] %s: %s" % [time, title, msg]
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9)) # Texto legible
	
	warning_list.add_child(label)

func _clear_history():
	for child in warning_list.get_children():
		child.queue_free()
	_on_close_pressed()
