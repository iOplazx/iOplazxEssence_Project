## [EssenceDemoInteractionButton]
## Specialization of the button for the demo testing environment.
class_name EssenceDemoInteractionButton
extends EssenceBaseInteractionButton

# ==
# DemoInteractionButton.tscn
# ==
# DemoInteractionButton (Control) [Script: DemoInteractionButton]
# └── Btn (TextureButton)
# ├── Icon (TextureRect)
# └── HoverArrow (Sprite2D)
# ==

@onready var hover_arrow: Sprite2D = $HoverArrow


func _ready() -> void:
	super._ready() # Initializes textures and base events via parent class[cite: 7]
	
	# The arrow starts completely invisible and transparent
	if hover_arrow:
		hover_arrow.visible = false
		hover_arrow.modulate.a = 0.0


## Override behavior when the mouse enters the button boundary[cite: 7]
func _on_hover_enter() -> void:
	# 1. Maintain the parent's elastic scaling properties[cite: 7]
	super._on_hover_enter()
	
	# 2. Activate and smoothly fade in the white visual arrow
	if hover_arrow:
		hover_arrow.visible = true
		var tween = create_tween()
		tween.tween_property(hover_arrow, "modulate:a", 1.0, 0.1).set_trans(Tween.TRANS_SINE)


## Override behavior when the mouse leaves the button boundary[cite: 7]
func _on_hover_exit() -> void:
	# 1. Return the size scale to the parent's original baseline[cite: 7]
	super._on_hover_exit()
	
	# 2. Fade out the white visual arrow smoothly
	if hover_arrow:
		var tween = create_tween()
		tween.tween_property(hover_arrow, "modulate:a", 0.0, 0.1).set_trans(Tween.TRANS_SINE)
		tween.tween_callback(func(): hover_arrow.visible = false)
		
