extends Control

signal on_submit(new_text: String)

@export var lbl_title: Label
@export var lbl_msg: Label
@export var input_text: LineEdit
@export var btn_confirm: Button
@export var btn_cancel: Button

func _ready():
	if btn_confirm:
		btn_confirm.pressed.connect(_on_confirm)
	if btn_cancel:
		btn_cancel.pressed.connect(_on_cancel)
	
	# Permite confirmar presionando "Enter"
	if input_text:
		input_text.text_submitted.connect(func(_text): _on_confirm())

func setup(title_key: String, msg_key: String, current_text: String):
	if lbl_title: lbl_title.text = tr(title_key)
	if lbl_msg: lbl_msg.text = tr(msg_key)
	
	if input_text:
		input_text.text = current_text
		input_text.grab_focus() # Pone el cursor ahí automáticamente
		input_text.select_all() # Selecciona todo para sobreescribir fácilmente

func _on_confirm():
	AudioManager.play_ui_sfx()
	var final_text = ""
	if input_text:
		final_text = input_text.text.strip_edges()
	on_submit.emit(final_text)

func _on_cancel():
	AudioManager.play_ui_sfx()
	on_submit.emit("") # Mandar un string vacío significa "Cancelar"
