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

func _ready() -> void:
	# 1. Blindaje Inicial
	_check_security_nodes()
	
	# 2. Empezamos invisibles y desactivados para ahorrar recursos
	self.hide() 
	if warning_panel: warning_panel.visible = false
	if btn_trigger: btn_trigger.visible = false
	
	# 3. Conexiones Locales
	if btn_trigger: btn_trigger.pressed.connect(_on_trigger_pressed)
	if btn_close: btn_close.pressed.connect(_on_close_pressed)
	if btn_clear: btn_clear.pressed.connect(_clear_history)
	
	# 4. Conexión Externa Segura (Late Binding)
	_safe_connect_error_signal()
	
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
func _on_new_error(data: Dictionary) -> void:
	# Usamos el valor crudo 1 (WARNING) para evitar dependencias de clase
	var severity = data.get("severity", 0)
	
	if severity == 1: # 1 = WARNING
		_add_warning_to_list(data)
		_unread_count += 1
		
		# ¡Despertamos la UI!
		self.show() 
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

func _on_close_pressed() -> void:
	_play_sfx()
	if warning_panel: warning_panel.visible = false
	if btn_trigger: btn_trigger.visible = false 
	
	_safe_log("[%s] Interface hidden by user." % ES_NAME_CLASS)
	
	# Si no hay más botones visibles, podemos volver a ocultar el CanvasLayer completo
	self.hide()

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

func _play_sfx() -> void:
	_safe_audio_ui()
		
# ==============================================================================
# WRAPPERS DE SEGURIDAD (Desacoplamiento Total)
# ==============================================================================

func _safe_log(msg: String) -> void:
	var logger = get_tree().root.get_node_or_null("EssenceLogger")
	if is_instance_valid(logger) and logger.has_method("system_info"):
		logger.system_info(msg)
	else:
		print("Fallback Log: ", msg)

func _safe_audio_ui() -> void:
	var audio_mgr = get_tree().root.get_node_or_null("AudioManager")
	if is_instance_valid(audio_mgr) and audio_mgr.has_method("play_ui_sfx"):
		audio_mgr.play_ui_sfx()

func _safe_connect_error_signal() -> void:
	var err_node = get_tree().root.get_node_or_null("EssenceError")
	if is_instance_valid(err_node) and err_node.has_signal("on_error_reported"):
		if not err_node.on_error_reported.is_connected(_on_new_error):
			err_node.on_error_reported.connect(_on_new_error)
