class_name EssenceRowSlider extends MarginContainer

@export var icon_texture: Texture2D
@export var label_text: String = "Ajuste"
@export var show_mute_button: bool = false # NUEVO: Control para mostrar/ocultar el switch

@onready var icon_rect = $HBoxContainer/IconRect
@onready var lbl_name = $HBoxContainer/lblName
@onready var slider = $HBoxContainer/Slider
@onready var lbl_value = $HBoxContainer/lblValue
@onready var btn_mute = $HBoxContainer/CheckButton 

var _volumen_previo: float = 1.0 
var _cambio_automatico: bool = false 

func _ready():
	lbl_name.text = label_text
	
	# Control del Icono
	if icon_texture:
		icon_rect.texture = icon_texture
		icon_rect.show()
	else:
		icon_rect.hide()
		
	# NUEVO: Control del Botón Mute
	if show_mute_button:
		btn_mute.show()
	else:
		btn_mute.hide()
		
	# Conexiones
	slider.value_changed.connect(_on_slider_changed)
	btn_mute.toggled.connect(_on_mute_toggled)
	
	_update_value_label(slider.value)

func _on_slider_changed(val: float):
	_update_value_label(val)
	
	if val > 0.0 and btn_mute.button_pressed and not _cambio_automatico:
		btn_mute.set_pressed_no_signal(false) 

func _update_value_label(val: float):
	lbl_value.text = str(int(val * 100)) + "%"

func _on_mute_toggled(is_muted: bool):
	_cambio_automatico = true 
	
	if is_muted:
		if slider.value > 0:
			_volumen_previo = slider.value
		else:
			_volumen_previo = 0.5 
			
		slider.value = 0.0
	else:
		slider.value = _volumen_previo
		
	_cambio_automatico = false
