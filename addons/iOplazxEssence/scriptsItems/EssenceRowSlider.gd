class_name EssenceRowSlider extends MarginContainer

@export_category("Configuración Base")
@export var icon_texture: Texture2D
@export var label_text: String = "Ajuste"
@export var show_mute_button: bool = false

@export_category("Rango del Slider Nativo")
@export var min_value: float = 0.0
@export var max_value: float = 1.0
@export var step: float = 0.01

@export_category("Formato de Texto Visual")
@export var visual_multiplier: float = 100.0 
## 0 para enteros (ej. 50%), 1 para un decimal (ej. 1.5x), 2 para dos decimales, etc.
@export var decimal_places: int = 0 
@export var value_prefix: String = ""  # Ej: "x" para que diga "x1.5"
@export var value_suffix: String = "%" # Ej: "%" para que diga "50%"

@onready var icon_rect = $HBoxContainer/IconRect
@onready var lbl_name = $HBoxContainer/lblName
@onready var slider = $HBoxContainer/Slider
@onready var lbl_value = $HBoxContainer/lblValue
@onready var btn_mute = $HBoxContainer/CheckButton 

var _volumen_previo: float = 1.0 
var _cambio_automatico: bool = false 

func _ready():
	lbl_name.text = label_text
	
	if slider:
		slider.min_value = min_value
		slider.max_value = max_value
		slider.step = step
	
	if icon_texture:
		icon_rect.texture = icon_texture
		icon_rect.show()
	else:
		icon_rect.hide()
		
	if show_mute_button:
		btn_mute.show()
	else:
		btn_mute.hide()
		
	slider.value_changed.connect(_on_slider_changed)
	btn_mute.toggled.connect(_on_mute_toggled)
	
	_update_value_label(slider.value)

func _on_slider_changed(val: float):
	_update_value_label(val)
	
	if val > slider.min_value and btn_mute.button_pressed and not _cambio_automatico:
		btn_mute.set_pressed_no_signal(false) 

func _update_value_label(val: float):
	var display_value = val * visual_multiplier
	
	# Magia de formateo ultra-optimizada en Godot:
	# Inyecta la cantidad de decimales exactos que elegiste en el Inspector
	var formatted_number = "%0.*f" % [decimal_places, display_value]
	
	lbl_value.text = value_prefix + formatted_number + value_suffix

func _on_mute_toggled(is_muted: bool):
	_cambio_automatico = true 
	
	if is_muted:
		if slider.value > slider.min_value:
			_volumen_previo = slider.value
		else:
			_volumen_previo = (slider.max_value - slider.min_value) / 2.0 
			
		slider.value = slider.min_value
	else:
		slider.value = _volumen_previo
		
	_cambio_automatico = false
