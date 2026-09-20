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
	
	# Secure connections
	if btn_confirm:
		btn_confirm.pressed.connect(_on_confirm)
	if btn_cancel:
		btn_cancel.pressed.connect(_on_cancel)
	
	# Allows confirmation by pressing "Enter"
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
		EssenceReportUtils.warning("UI Setup Warning", msg)

# ==========================================
# CONFIGURATION
# ==========================================
func setup(title_key: String, msg_key: String, current_text: String):
	if lbl_title: lbl_title.text = tr(title_key)
	if lbl_msg: lbl_msg.text = tr(msg_key)
	
	if input_text:
		input_text.text = current_text
		
		# call_deferred tells Godot:
		# "Wait until the entire frame has finished rendering, and THEN set the focus here." 
		# This prevents the bug where the text box doesn't let you type immediately.
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
		final_text = input_text.text.strip_edges() # strip_edges removes accidental spaces at the beginning/end
		
	on_submit.emit(final_text)
	queue_free() # We destroy the UI to free up RAM

func _on_cancel():
	if is_instance_valid(AudioManager) and AudioManager.has_method("play_ui_sfx"):
		AudioManager.play_ui_sfx()
		
	on_submit.emit("") # Sending an empty string means "Cancel"
	queue_free() # We destroy the UI to free up RAM
