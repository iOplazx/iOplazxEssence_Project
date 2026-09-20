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
## 0 for integers (e.g., 50%), 1 for one decimal place (e.g., 1.5x), 2 for two decimal places, etc.
@export var decimal_places: int = 0 
@export var value_prefix: String = ""  # Ex: "x" to read "x1.5"
@export var value_suffix: String = "%" # E.g., "%" so it says "50%"

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
		# We connect the button to our new function
		btn_mute.toggled.connect(_on_btn_mute_toggled)
		
	if slider:
		_update_value_label(slider.value)

# ==========================================
# ARMORING AND SECURITY
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
		EssenceReportUtils.warning("UI Setup Warning", msg)

# ==========================================
# TRADUCCIÓN DINÁMICA
# ==========================================
func _notification(what):
	# If the player changes the language while in the options menu, the slider translates automatically.
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		if lbl_name:
			lbl_name.text = tr(label_text)

# ==========================================
# INTERFACE LOGIC
# ==========================================
func _on_slider_changed(val: float):
	_update_value_label(val)
	
	# AUTO-UNMUTE: If the slider is moved and the audio was muted, we unmute it.
	if btn_mute and slider:
		if btn_mute.button_pressed and not _cambio_automatico:
			_cambio_automatico = true 
			btn_mute.button_pressed = false # Visually uncheck the box
			mute_toggled.emit(false) # Notifies the AudioManager to unmute
			_cambio_automatico = false

func _on_slider_drag_ended(value_changed: bool):
	# It only makes noise if you actually changed the value, not if you just clicked on it.
	if value_changed and is_instance_valid(AudioManager) and AudioManager.has_method("play_ui_sfx"):
		AudioManager.play_ui_sfx()

func _update_value_label(val: float):
	if not lbl_value: return
	
	var display_value = val * visual_multiplier
	# Ultra-optimized formatting magic in Godot
	var formatted_number = "%0.*f" % [decimal_places, display_value]
	
	lbl_value.text = value_prefix + formatted_number + value_suffix

func _on_btn_mute_toggled(is_muted: bool):
	# Audio feedback (only if not a code-based change)
	if not _cambio_automatico and is_instance_valid(AudioManager) and AudioManager.has_method("play_ui_sfx"):
		AudioManager.play_ui_sfx()
		
	# We no longer lower the slider to 0.
	# We simply send the signal so that TabAudio performs the native mute.
	if not _cambio_automatico:
		mute_toggled.emit(is_muted)
	
