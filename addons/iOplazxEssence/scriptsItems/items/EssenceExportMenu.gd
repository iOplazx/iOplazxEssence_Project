class_name EssenceExportMenu extends Control

const ES_NAME_CLASS = "EssenceExportMenu"
signal on_option_selected(option: String)

@export var btn_current : Button
@export var btn_all : Button
@export var btn_cancel : Button

func _ready():
	# Mantenemos un blindaje mínimo silencioso por si el usuario borra un nodo por accidente
	if btn_current: btn_current.pressed.connect(func(): _seleccionar("CURRENT"))
	if btn_all: btn_all.pressed.connect(func(): _seleccionar("ALL"))
	if btn_cancel: btn_cancel.pressed.connect(func(): _seleccionar("CANCEL"))
	
	modulate.a = 0
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.15)

func _seleccionar(opcion: String):
	if AudioManager and AudioManager.has_method("play_ui_sfx"):
		AudioManager.play_ui_sfx()
		
	on_option_selected.emit(opcion)
	queue_free()
