class_name EssenceInputBox extends Control

const ES_NAME_CLASS = "EssenceInputBox"

signal on_submit(new_text: String)

@export_category("UI Connections")
@export var lbl_title: Label
@export var lbl_msg: Label
@export var input_text: LineEdit
@export var btn_confirm: Button
@export var btn_cancel: Button

func _ready():
	_check_security_nodes()
	
	# Conexiones seguras
	if btn_confirm:
		btn_confirm.pressed.connect(_on_confirm)
	if btn_cancel:
		btn_cancel.pressed.connect(_on_cancel)
	
	# Permite confirmar presionando "Enter"
	if input_text:
		input_text.text_submitted.connect(func(_text): _on_confirm())

# ==========================================
# SECURITY & BLINDING
# ==========================================
func _check_security_nodes():
	var missing = []
	if not lbl_title: missing.append("lbl_title")
	if not lbl_msg: missing.append("lbl_msg")
	if not input_text: missing.append("input_text")
	if not btn_confirm: missing.append("btn_confirm")
	if not btn_cancel: missing.append("btn_cancel")
	
	if missing.size() > 0:
		var msg = "Missing exported nodes in %s: %s" % [ES_NAME_CLASS, ", ".join(missing)]
		# Usamos un if seguro por si EssenceError no existe en este contexto
		if is_instance_valid(EssenceError) and EssenceError.has_method("report"):
			EssenceError.report("UI Setup Warning", msg, EssenceError.Severity.WARNING)
		else:
			push_error(msg)

# ==========================================
# CONFIGURATION
# ==========================================
func setup(title_key: String, msg_key: String, current_text: String):
	if lbl_title: lbl_title.text = tr(title_key)
	if lbl_msg: lbl_msg.text = tr(msg_key)
	
	if input_text:
		input_text.text = current_text
		
		# TRUCO SENIOR: call_deferred le dice a Godot:
		# "Espera a terminar de dibujar todo el frame, y LUEGO pon el foco aquí".
		# Esto evita el bug donde la caja de texto no te deja escribir al instante.
		input_text.call_deferred("grab_focus")
		input_text.call_deferred("select_all")

# ==========================================
# EVENTS
# ==========================================
func _on_confirm():
	if is_instance_valid(AudioManager) and AudioManager.has_method("play_ui_sfx"):
		AudioManager.play_ui_sfx()
		
	var final_text = ""
	if input_text:
		final_text = input_text.text.strip_edges() # strip_edges elimina espacios accidentales al inicio/fin
		
	on_submit.emit(final_text)
	queue_free() # Destruimos la UI para liberar RAM

func _on_cancel():
	if is_instance_valid(AudioManager) and AudioManager.has_method("play_ui_sfx"):
		AudioManager.play_ui_sfx()
		
	on_submit.emit("") # Mandar un string vacío significa "Cancelar"
	queue_free() # Destruimos la UI para liberar RAM
