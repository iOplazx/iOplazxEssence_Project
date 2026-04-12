class_name EssenceRowSlider extends MarginContainer

const ES_NAME_CLASS = "EssenceRowSlider"

@export_category("Base Configuration")
@export var icon_texture: Texture2D
@export var label_text: String = "SETTING_DEFAULT"
@export var show_mute_button: bool = false

@export_category("Slider Range")
@export var min_value: float = 0.0
@export var max_value: float = 1.0
@export var step: float = 0.01

@export_category("Visual Formatting")
@export var visual_multiplier: float = 100.0 
## 0 para enteros (ej. 50%), 1 para un decimal (ej. 1.5x), 2 para dos decimales, etc.
@export var decimal_places: int = 0 
@export var value_prefix: String = ""  # Ej: "x" para que diga "x1.5"
@export var value_suffix: String = "%" # Ej: "%" para que diga "50%"

@export_category("Internal Nodes")
@export var icon_rect: TextureRect
@export var lbl_name: Label
@export var slider: Slider
@export var lbl_value: Label
@export var btn_mute: BaseButton 

var _volumen_previo: float = 1.0 
var _cambio_automatico: bool = false 

func _ready():
	_check_security_nodes()
	
	if lbl_name:
		lbl_name.text = tr(label_text)
	
	if slider:
		slider.min_value = min_value
		slider.max_value = max_value
		slider.step = step
		slider.value_changed.connect(_on_slider_changed)
		
		# UX Senior: Reproducir sonido solo al soltar el slider, no mientras se arrastra (evita spam de audio)
		slider.drag_ended.connect(_on_slider_drag_ended)
	
	if icon_rect:
		if icon_texture:
			icon_rect.texture = icon_texture
			icon_rect.show()
		else:
			icon_rect.hide()
			
	if btn_mute:
		btn_mute.visible = show_mute_button
		btn_mute.toggled.connect(_on_mute_toggled)
		
	if slider:
		_update_value_label(slider.value)

# ==========================================
# BLINDAJE Y SEGURIDAD
# ==========================================
func _check_security_nodes():
	var missing = []
	if not icon_rect: missing.append("icon_rect")
	if not lbl_name: missing.append("lbl_name")
	if not slider: missing.append("slider")
	if not lbl_value: missing.append("lbl_value")
	if not btn_mute: missing.append("btn_mute")
	
	if missing.size() > 0:
		var msg = "Missing exported nodes in %s: %s" % [ES_NAME_CLASS, ", ".join(missing)]
		if is_instance_valid(EssenceError) and EssenceError.has_method("report"):
			EssenceError.report("UI Setup Warning", msg, EssenceError.Severity.WARNING)
		else:
			push_error(msg)

# ==========================================
# TRADUCCIÓN DINÁMICA
# ==========================================
func _notification(what):
	# Si el jugador cambia el idioma estando en el menú de opciones, el slider se traduce solo
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		if lbl_name:
			lbl_name.text = tr(label_text)

# ==========================================
# LÓGICA DE INTERFAZ
# ==========================================
func _on_slider_changed(val: float):
	_update_value_label(val)
	
	if btn_mute and slider:
		if val > slider.min_value and btn_mute.button_pressed and not _cambio_automatico:
			btn_mute.set_pressed_no_signal(false) 

func _on_slider_drag_ended(value_changed: bool):
	# Solo hace ruido si realmente moviste el valor, no si solo le hiciste clic
	if value_changed and is_instance_valid(AudioManager) and AudioManager.has_method("play_ui_sfx"):
		AudioManager.play_ui_sfx()

func _update_value_label(val: float):
	if not lbl_value: return
	
	var display_value = val * visual_multiplier
	# Magia de formateo ultra-optimizada en Godot
	var formatted_number = "%0.*f" % [decimal_places, display_value]
	
	lbl_value.text = value_prefix + formatted_number + value_suffix

func _on_mute_toggled(is_muted: bool):
	# Feedback de audio
	if not _cambio_automatico and is_instance_valid(AudioManager) and AudioManager.has_method("play_ui_sfx"):
		AudioManager.play_ui_sfx()
		
	_cambio_automatico = true 
	
	if slider:
		if is_muted:
			if slider.value > slider.min_value:
				_volumen_previo = slider.value
			else:
				_volumen_previo = (slider.max_value - slider.min_value) / 2.0 
				
			slider.value = slider.min_value
		else:
			slider.value = _volumen_previo
		
	_cambio_automatico = false
