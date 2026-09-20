class_name EssenceImportConflictBox extends CanvasLayer

const ES_NAME_CLASS = "EssenceImportConflictBox"

# This signal will send the dictionary to the controller
signal on_conflict_resolved(respuesta: Dictionary)

@export_category("UI References")
@export var label_msg: Label
@export var chk_apply_all: CheckBox
@export var btn_omit: Button
@export var btn_overwrite: Button
@export var btn_new: Button

func _ready():
	_check_security_nodes()
	
	# Secure connections: If a button is missing, it simply doesn't connect.
	if btn_omit: btn_omit.pressed.connect(func(): _responder("OMITIR"))
	if btn_overwrite: btn_overwrite.pressed.connect(func(): _responder("SOBRESCRIBIR"))
	if btn_new: btn_new.pressed.connect(func(): _responder("NUEVO"))
	
	# Secure dynamic localization
	if chk_apply_all: chk_apply_all.text = tr("UI_IMPORT_APPLY_ALL")
	if btn_omit: btn_omit.text = tr("UI_IMPORT_BTN_OMIT")
	if btn_overwrite: btn_overwrite.text = tr("UI_IMPORT_BTN_OVERWRITE")
	if btn_new: btn_new.text = tr("UI_IMPORT_BTN_NEW")

# ==========================================
# SECURITY ARMORING
# ==========================================
func _check_security_nodes():
	var missing = []
	if not label_msg: missing.append("label_msg")
	if not chk_apply_all: missing.append("chk_apply_all")
	if not btn_omit: missing.append("btn_omit")
	if not btn_overwrite: missing.append("btn_overwrite")
	if not btn_new: missing.append("btn_new")
	
	if missing.size() > 0:
		var msg = "Missing exported nodes in %s: %s" % [ES_NAME_CLASS, ", ".join(missing)]
		EssenceReportUtils.warning("UI Setup Error", msg)

# ==========================================
# DATA INJECTION
# ==========================================
func setup(slot_id: String):
	# We format the translated text safely.
	if label_msg: 
		label_msg.text = tr("UI_IMPORT_CONFLICT_MSG").format({"slot": slot_id})

# ==========================================
# RESPONSE AND DESTRUCTION
# ==========================================
func _responder(accion: String):
	# Sonido seguro
	if AudioManager and AudioManager.has_method("play_ui_sfx"):
		AudioManager.play_ui_sfx()
		
	# We prepare the data packet and trigger it. 
	# We use a ternary operator for the CheckBox in case the node is lost/deleted.
	var paquete = {
		"accion": accion,
		"aplicar_a_todos": chk_apply_all.button_pressed if chk_apply_all else false
	}
	
	on_conflict_resolved.emit(paquete)
	queue_free() # We destroy the window to clear the memory
