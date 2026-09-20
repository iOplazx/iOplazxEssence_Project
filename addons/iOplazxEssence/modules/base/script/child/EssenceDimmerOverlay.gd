## [EssenceDimmerOverlay]
## Componente modular para oscurecer la pantalla y bloquear clics traseros.
## Puede usarse como nodo independiente o dentro de escenas modales.
class_name EssenceDimmerOverlay
extends ColorRect

# ==
# EssenceDimmerOverlay (ColorRect) [Script: EssenceDimmerOverlay]
# ├── Layout: Full Rect (Preset 15)
# ├── Color: Color(0, 0, 0, 0.65)
# └── Mouse Filter: Stop

## Emitted if the user clicks on the dark area (useful for closing modals by clicking outside)
signal overlay_clicked

@export_category("Overlay Settings")
## Default duration for entrance/exit animations.
@export var default_fade_duration: float = 0.25
## Target color and opacity when the curtain is fully extended.
@export var target_color: Color = Color(0.0, 0.0, 0.0, 0.65)
## If true, the overlay will absorb clicks and prevent them from passing through to the background.
@export var block_mouse_input: bool = true


func _ready() -> void:
	# Force full-screen fit and mouse filtering
	anchors_preset = Control.PRESET_FULL_RECT
	color = target_color
	mouse_filter = Control.MOUSE_FILTER_STOP if block_mouse_input else Control.MOUSE_FILTER_IGNORE
	
	# Detect clicks on the background if the signal is required
	gui_input.connect(_on_gui_input)


## Shows the overlay with a fade-in effect (Fade In).
func fade_in(duration: float = -1.0) -> Tween:
	var anim_time: float = duration if duration >= 0.0 else default_fade_duration
	show()
	modulate.a = 0.0
	
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, anim_time)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)
		
	return tween


## Hides the overlay by fading it out (Fade Out).
func fade_out(duration: float = -1.0) -> Tween:
	var anim_time: float = duration if duration >= 0.0 else default_fade_duration
	
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, anim_time)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN)
		
	tween.finished.connect(hide)
	return tween


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		overlay_clicked.emit()
