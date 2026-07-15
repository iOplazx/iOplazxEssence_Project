## [EssenceBaseInteractionButton]
## Abstract parent class for all buttons in the interaction menu.
## Controls input cycle, mass click blocking, and standard hover effects.
class_name EssenceBaseInteractionButton
extends Control

## Official signal to notify the manager which action was selected.
signal action_chosen(action_name: String)

@export_category("Base Configuration")
## The unique string identifier for this button's action.
@export var action_name: String = "empty" 
## Default texture resource used for this slot's graphical icon.
@export var icon_texture: Texture2D 

var btn: TextureButton
var icon: TextureRect
var base_scale: Vector2 
var can_be_pressed: bool = true 

func _ready() -> void:
	# 1. Configure the geometric center for elastic animations 
	pivot_offset = size / 2.0
	
	# 2. Type-safe node lookup to decouple the node tree structure
	btn = get_node_or_null("Btn") as TextureButton
	icon = get_node_or_null("Icon") as TextureRect
	
	# 3. CRITICAL UI INTERACTION HARDENING:
	# Force the invisible TextureButton to expand and occupy 100% of the parent container's area.
	# This prevents the button from collapsing to a 0x0 size when it holds no custom textures.
	if btn:
		btn.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		btn.mouse_filter = Control.MOUSE_FILTER_STOP # Ensures the button consumes and stops the click event
		
		# Safe connection of internal Godot interaction signals
		btn.pressed.connect(_on_btn_pressed)
		btn.mouse_entered.connect(_on_hover_enter)
		btn.mouse_exited.connect(_on_hover_exit)
		
	# 4. SILENT GRAPHICAL PASS-THROUGH:
	# Force the Icon overlay to always ignore mouse inputs, letting interactions fall through to the button.
	if icon:
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if icon_texture:
			icon.texture = icon_texture
		
	call_deferred("_save_base_scale")


func _save_base_scale() -> void:
	base_scale = scale 


## ANTI-SPAM COOLDOWN: Prevents accidental multiple click exploitation.
func _on_btn_pressed() -> void:
	if not can_be_pressed: 
		return 
		
	can_be_pressed = false 
	action_chosen.emit(action_name) 
	
	# Automated unlock via native time yields
	get_tree().create_timer(0.3).timeout.connect(func(): can_be_pressed = true) 


## VIRTUAL VISUAL EFFECTS: Open for override in specialized child classes.
func _on_hover_enter() -> void:
	var tween = create_tween()
	tween.tween_property(self, "scale", base_scale * 1.1, 0.1).set_trans(Tween.TRANS_SINE) 


func _on_hover_exit() -> void:
	var tween = create_tween()
	tween.tween_property(self, "scale", base_scale, 0.1).set_trans(Tween.TRANS_SINE)
	
