class_name EssenceInfoPanel extends Control

@export_category("Nodos Internos")
@export var lbl_title: Label
@export var lbl_author: Label
@export var lbl_version: Label
@export var lbl_description: Label
@export var lbl_ai_warning: Label
@export var btn_close: Button
@export var window_panel: PanelContainer

func _ready():
	if btn_close: btn_close.pressed.connect(_on_close_pressed)
	if lbl_ai_warning: lbl_ai_warning.hide()
	
	if window_panel:
		window_panel.scale = Vector2(0.8, 0.8)
		modulate.a = 0.0 
		var tween = create_tween().set_parallel(true)
		tween.tween_property(self, "modulate:a", 1.0, 0.15)
		tween.tween_property(window_panel, "scale", Vector2(1.0, 1.0), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func setup(data: Dictionary):
	if lbl_title: lbl_title.text = data.get("name", "Unknown Language")
	if lbl_author: lbl_author.text = tr("MENU_AUTHOR") + ": " + data.get("author", "Unknown")
	
	# Llenamos la versión
	if lbl_version:
		lbl_version.text = "v" + str(data.get("version", "1.0.0"))
		
	# Llenamos la descripción. Si viene vacía, escondemos el label para ahorrar espacio visual
	if lbl_description:
		var desc = data.get("description", "")
		lbl_description.text = desc
		lbl_description.visible = desc != ""
		
	if lbl_ai_warning and data.get("is_ai", false):
		lbl_ai_warning.text = tr("MENU_AI_WARNING")
		lbl_ai_warning.show()

func _on_close_pressed():
	AudioManager.play_ui_sfx()
	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "modulate:a", 0.0, 0.1)
	if window_panel: tween.tween_property(window_panel, "scale", Vector2(0.9, 0.9), 0.1)
	tween.chain().tween_callback(queue_free)
