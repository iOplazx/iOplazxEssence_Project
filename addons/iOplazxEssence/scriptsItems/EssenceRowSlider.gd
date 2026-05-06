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

signal mute_toggled(is_muted: bool)

func _ready():
	_check_security_nodes()
	
	if lbl_name:
		lbl_name.text = tr(label_text)
	
	if slider:
		slider.min_value = min_value
		slider.max_value = max_value
		slider.step = step
		slider.value_changed.connect(_on_slider_changed)
		slider.drag_ended.connect(_on_slider_drag_ended)
	
	if icon_rect:
		if icon_texture:
			icon_rect.texture = icon_texture
			icon_rect.show()
		else:
			icon_rect.hide()
			
	if btn_mute:
		btn_mute.visible = show_mute_button
		# Conectamos el botón a nuestra nueva función
		btn_mute.toggled.connect(_on_btn_mute_toggled)
		
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
	
	# AUTO-UNMUTE: Si mueven el slider y estaba en mute, lo quitamos
	if btn_mute and slider:
		if btn_mute.button_pressed and not _cambio_automatico:
			_cambio_automatico = true 
			btn_mute.button_pressed = false # Desmarca la casilla visualmente
			mute_toggled.emit(false) # Le avisa al AudioManager que quite el mute
			_cambio_automatico = false

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

func _on_btn_mute_toggled(is_muted: bool):
	# Feedback de audio (solo si no es un cambio por código)
	if not _cambio_automatico and is_instance_valid(AudioManager) and AudioManager.has_method("play_ui_sfx"):
		AudioManager.play_ui_sfx()
		
	# YA NO bajamos el slider a 0.
	# Simplemente emitimos la señal para que el TabAudio haga el Mute nativo.
	if not _cambio_automatico:
		mute_toggled.emit(is_muted)
	
