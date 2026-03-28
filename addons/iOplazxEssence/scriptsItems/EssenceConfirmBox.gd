class_name EssenceConfirmBox extends ColorRect

# Emitimos true si dio "Sí", false si dio "No"
signal on_choice(accepted: bool)

@export_category("UI Connections")
@export var lbl_title: Label
@export var lbl_message: Label
@export var btn_yes: Button
@export var btn_no: Button

func _ready():
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

## Esta función la llamaremos desde otros scripts para configurar los textos
func setup(title: String, message: String, yes_text: String = "YES", no_text: String = "NO"):
	if lbl_title: lbl_title.text = tr(title)
	if lbl_message: lbl_message.text = tr(message)
	if btn_yes: btn_yes.text = tr(yes_text)
	if btn_no: btn_no.text = tr(no_text)
