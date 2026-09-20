## [EssenceBaseInteractionButton]
## Abstract parent class for all buttons in the interaction menu.
## Controls input cycle, mass click blocking, and standard hover effects directly.
class_name EssenceBaseInteractionButton
extends Control

## Official signal to notify the manager which action was selected.
signal action_chosen(action_name: String)

@export_category("Base Configuration")
@export var action_name: String = "empty" 
@export var icon_texture: Texture2D 

var icon: TextureRect
var base_scale: Vector2 
var can_be_pressed: bool = true 


func _ready() -> void:
	# 1. Configure the geometric center for elastic animations 
	pivot_offset = size / 2.0
	
	# 2. Connect internal hover events directly to this root control node
	mouse_entered.connect(_on_hover_enter)
	mouse_exited.connect(_on_hover_exit)
	
	# 3. Hardware graphical pass-through safety
	icon = get_node_or_null("Icon") as TextureRect
	if icon:
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if icon_texture:
			icon.texture = icon_texture
			
	# 4. Force the old sub-button to stand down and not conflict with picking
	var old_btn = get_node_or_null("Btn") as Control
	if old_btn:
		old_btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
	call_deferred("_save_base_scale") 


func _save_base_scale() -> void:
	base_scale = scale 


## Direct UI Input interception for handling clicks reliably on the Control node itself.
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_handle_click_activation()


## Processes the core action dispatching with anti-spam cooldown measures.
func _handle_click_activation() -> void:
	if not can_be_pressed or action_name == "empty" or action_name == "": 
		return 
		
	can_be_pressed = false 
	action_chosen.emit(action_name) 
	
	# Automated unlock via native time yields
	get_tree().create_timer(0.3).timeout.connect(func(): can_be_pressed = true) 


## VIRTUAL VISUAL EFFECTS: Open for override in specialized child classes.
func _on_hover_enter() -> void:
	if action_name != "empty" and action_name != "":
		var tween = create_tween()
		tween.tween_property(self, "scale", base_scale * 1.1, 0.1).set_trans(Tween.TRANS_SINE) 


func _on_hover_exit() -> void:
	var tween = create_tween()
	tween.tween_property(self, "scale", base_scale, 0.1).set_trans(Tween.TRANS_SINE)
