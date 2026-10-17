class_name EssenceGenericActionItem
extends EssenceInteractableElement

## A generic signal that the addon emits, regardless of who might be listening
signal action_triggered

func _on_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	super._on_input_event(viewport, event, shape_idx)
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		_trigger_action()

func _trigger_action() -> void:
	# We transmit the signal so that any external node (the demo or game) can hear it
	action_triggered.emit()
	
	# Or we call a virtual method that subclasses can override
	_on_custom_action()

## Virtual method: Subclasses (in games) will implement the logic here
func _on_custom_action() -> void:
	pass
