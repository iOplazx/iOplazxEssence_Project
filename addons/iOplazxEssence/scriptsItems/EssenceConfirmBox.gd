class_name EssenceConfirmBox extends ColorRect

const ES_NAME_CLASS = "EssenceConfirmBox"

# Emitimos true si dio "Sí", false si dio "No"
signal on_choice(accepted: bool)

@export_category("UI Connections")
@export var lbl_title: Label
@export var lbl_message: Label
@export var btn_yes: Button
@export var btn_no: Button

func _ready():
	_check_security_nodes()
	
	# Conectamos los botones usando funciones lambda (anónimas) para ahorrar líneas
	if btn_yes:
		btn_yes.pressed.connect(func(): 
			AudioManager.play_ui_sfx()
			on_choice.emit(true)
			queue_free() # Se destruye a sí misma al terminar
		)
		
	if btn_no:
		btn_no.pressed.connect(func(): 
			AudioManager.play_ui_sfx()
			on_choice.emit(false)
			queue_free()
		)

# ==========================================
# BLINDAJE: VERIFICACIÓN DE NODOS
# ==========================================
func _check_security_nodes():
	var missing = []
	if not lbl_title: missing.append("lbl_title")
	if not lbl_message: missing.append("lbl_message")
	if not btn_yes: missing.append("btn_yes")
	if not btn_no: missing.append("btn_no")
	
	# Si falta algún nodo, lanzamos el Warning Overlay
	if missing.size() > 0:
		var msg = "Missing exported nodes in %s: %s" % [ES_NAME_CLASS, ", ".join(missing)]
		EssenceError.report("UI Setup Warning", msg, EssenceError.Severity.WARNING)

# ==========================================
# CONFIGURACIÓN EXTERNA
# ==========================================
## Esta función la llamaremos desde otros scripts para configurar los textos
func setup(title: String, message: String, yes_text: String = "MENU_YES", no_text: String = "MENU_NO"):
	if lbl_title: lbl_title.text = tr(title)
	if lbl_message: lbl_message.text = tr(message)
	if btn_yes: btn_yes.text = tr(yes_text)
	if btn_no: btn_no.text = tr(no_text)