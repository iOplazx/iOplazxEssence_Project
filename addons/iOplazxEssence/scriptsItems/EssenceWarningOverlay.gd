extends CanvasLayer

const ES_NAME_CLASS = "EssenceWarningUI"

@export_category("UI Connections")
@export var btn_trigger: Button
@export var warning_panel: Control
@export var btn_close: Button
@export var warning_list: Control
@export var lbl_title: Label
@export var btn_clear: Button

var _unread_count: int = 0

func _ready():
	# 1. Blindaje Inicial
	_check_security_nodes()
	
	# 2. Empezamos con la pantalla limpia de forma segura
	if warning_panel: warning_panel.visible = false
	if btn_trigger: btn_trigger.visible = false
	
	# 3. Conexiones
	if btn_trigger: btn_trigger.pressed.connect(_on_trigger_pressed)
	if btn_close: btn_close.pressed.connect(_on_close_pressed)
	if btn_clear: btn_clear.pressed.connect(_clear_history)
	
	# 4. Escuchamos globalmente al sistema de errores
	if is_instance_valid(EssenceError) and EssenceError.has_signal("on_error_reported"):
		EssenceError.on_error_reported.connect(_on_new_error)

# ==========================================
# BLINDAJE DE SEGURIDAD
# ==========================================
func _check_security_nodes():
	var missing = []
	if not btn_trigger: missing.append("btn_trigger")
	if not warning_panel: missing.append("warning_panel")
	if not btn_close: missing.append("btn_close")
	if not warning_list: missing.append("warning_list")
	if not lbl_title: missing.append("lbl_title")
	if not btn_clear: missing.append("btn_clear")
	
	if missing.size() > 0:
		# Al ser parte del sistema de advertencias, si falla algo aquí usamos push_error
		# para no crear un bucle infinito reportándonos a nosotros mismos.
		push_error("[%s] CRITICAL: Missing exported nodes: %s" % [ES_NAME_CLASS, ", ".join(missing)])

# ==========================================
# FLUJO AUTOMÁTICO
# ==========================================
func _on_new_error(data: Dictionary):
	# Si es un Warning, despertamos al sistema
	if data.get("severity", 0) == EssenceError.Severity.WARNING:
		_add_warning_to_list(data)
		_unread_count += 1
		
		# ¡Aparición!
		if btn_trigger:
			btn_trigger.visible = true
			btn_trigger.modulate = Color(1.0, 0.8, 0.2) # Brillo amarillo

func _on_trigger_pressed():
	_play_sfx()
	if warning_panel: warning_panel.visible = true
	if btn_trigger: btn_trigger.modulate = Color(1.0, 1.0, 1.0, 0.5) # Se vuelve tenue
	
	_unread_count = 0
	
	if lbl_title and warning_list:
		# Usamos tr() para soporte de localización si el jugador está en otro idioma
		var title_base = tr("UI_WARNING_TITLE")
		if title_base == "UI_WARNING_TITLE": title_base = "SYSTEM WARNINGS" # Fallback temporal
		lbl_title.text = title_base + " (" + str(warning_list.get_child_count()) + ")"

func _on_close_pressed():
	_play_sfx()
	
	if warning_panel: warning_panel.visible = false
	if btn_trigger: btn_trigger.visible = false # El icono desaparece hasta el próximo warning
	
	# Usamos nuestro Logger oficial en lugar de print()
	EssenceLogger.system_info("[%s] Interface hidden by user." % ES_NAME_CLASS)

# ==========================================
# UTILIDADES
# ==========================================
func _add_warning_to_list(data: Dictionary):
	if not warning_list: return
	
	var time = Time.get_time_string_from_system()
	var title = data.get("title", "WARNING")
	var msg = data.get("message", "")
	
	var label = Label.new()
	label.text = "[%s] %s: %s" % [time, title, msg]
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9)) 
	
	warning_list.add_child(label)

func _clear_history():
	_play_sfx()
	
	if warning_list:
		for child in warning_list.get_children():
			child.queue_free()
			
	_on_close_pressed()

func _play_sfx():
	# Centralizamos la llamada al audio para no repetirla
	if is_instance_valid(AudioManager) and AudioManager.has_method("play_ui_sfx"):
		AudioManager.play_ui_sfx()
