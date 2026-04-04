class_name EssenceExportMenu extends Control

signal on_option_selected(option: String) # Avisará al controlador qué elegimos

@onready var btn_current = $Panel/VBox/BtnCurrent
@onready var btn_all = $Panel/VBox/BtnAll
@onready var btn_cancel = $Panel/VBox/BtnCancel

func _ready():
	# Conectamos los botones a la función de cierre
	btn_current.pressed.connect(func(): _seleccionar("CURRENT"))
	btn_all.pressed.connect(func(): _seleccionar("ALL"))
	btn_cancel.pressed.connect(func(): _seleccionar("CANCEL"))
	
	# Efecto visual sencillo al aparecer (opcional, pero se ve bien)
	modulate.a = 0
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.15)

func _seleccionar(opcion: String):
	AudioManager.play_ui_sfx()
	on_option_selected.emit(opcion)
	queue_free() # Nos destruimos para liberar RAM
