## [EssenceInteractiveActor]
## An actor that can be interacted with via mouse clicks or touch.
## Inherits the wardrobe system and adds interaction capabilities.
## Requires a child Area2D connected to the '_on_interact_area_input_event' method.
extends EssenceModularActor
class_name EssenceInteractiveActor

# ==========================================
# SIGNALS
# ==========================================
## Emitted when the character is clicked or touched (Left Mouse Button / Tap).
signal clicked_on_character

# ==========================================
# CONFIGURATION
# ==========================================

## Determines if the character can currently be interacted with.
## If false, clicks will be ignored.
@export var is_interactable: bool = true

# ==========================================
# INPUT HANDLING
# ==========================================

## Connect this method to the 'input_event' signal of a child Area2D node.
## [param _viewport]: The viewport where the event occurred.
## [param event]: The input event (mouse click, touch, etc.).
## [param _shape_idx]: The index of the clicked collision shape.
func _on_interact_area_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if not is_interactable: 
		return
	
	# Detectamos el clic izquierdo (o toque en pantallas táctiles) al presionar
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		clicked_on_character.emit()
		
		# Consumimos el evento para que no se haga clic accidental en cosas detrás del personaje
		get_viewport().set_input_as_handled()
		
