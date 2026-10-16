class_name EssenceWipDoorItem
extends EssenceInteractableElement

## Overrides input event to keep visual feedback and add specific return logic.
func _on_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	# 1. First, call super to preserve automated hover/click animations (tint and scale)
	super._on_input_event(viewport, event, shape_idx)
	
	# 2. Add custom business logic when left click is released
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		_execute_wip_return()


## Executes the fallback navigation back to the origin room cached in LevelManager.
func _execute_wip_return() -> void:
	var return_room_id: int = LevelManager.last_room_before_wip
	print("[WIP Door] Returning to cached origin room ID: %d" % return_room_id)
	
	# Find main game container or delegate through scene tree / signal
	var main_game = get_tree().get_first_node_in_group("MainGame")
	if is_instance_valid(main_game) and main_game.has_method("change_room_sequence"):
		main_game.change_room_sequence(return_room_id)
	else:
		# Fallback if using direct director navigation signals
		var director = get_tree().get_first_node_in_group("GameplayDirector")
		if is_instance_valid(director):
			# Or route back via standard navigation signal
			pass
