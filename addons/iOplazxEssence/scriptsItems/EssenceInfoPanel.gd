class_name EssenceInfoPanel extends Control

@export_category("Nodos Internos")
@export var lbl_title: Label
@export var lbl_author: Label
@export var lbl_ai_warning: Label
@export var btn_close: Button
@export var window_panel: PanelContainer # El panel que vamos a animar

func _ready():
	# Conectamos el botón de cerrar
	if btn_close:
		btn_close.pressed.connect(_on_close_pressed)
		
	# Escondemos la advertencia de IA por defecto
	if lbl_ai_warning:
		lbl_ai_warning.hide()
		
	# Animación de entrada (Súper optimizada para tu Athlon)
	if window_panel:
		window_panel.scale = Vector2(0.8, 0.8) # Empieza un poco más chico
		modulate.a = 0.0 # Empieza invisible
		
		var tween = create_tween().set_parallel(true)
		tween.tween_property(self, "modulate:a", 1.0, 0.15)
		tween.tween_property(window_panel, "scale", Vector2(1.0, 1.0), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

# Función que recibirá los datos desde el SettingsController
func setup(data: Dictionary):
	if lbl_title:
		lbl_title.text = data.get("name", "Unknown Language")
		
	if lbl_author:
		lbl_author.text = tr("MENU_AUTHOR") + ": " + data.get("author", "Unknown")
		
	# Mostramos la advertencia solo si la traducción fue hecha con IA
	if lbl_ai_warning and data.get("is_ai", false):
		lbl_ai_warning.text = tr("MENU_AI_WARNING") # Ej: "Traducido por IA"
		lbl_ai_warning.show()

func _on_close_pressed():
	AudioManager.play_ui_sfx() # Reproducimos el sonido de clic
	
	# Animación de salida antes de destruirse
	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "modulate:a", 0.0, 0.1)
	if window_panel:
		tween.tween_property(window_panel, "scale", Vector2(0.9, 0.9), 0.1)
		
	# Cuando termine la animación, destruimos el nodo para liberar RAM
	tween.chain().tween_callback(queue_free)
