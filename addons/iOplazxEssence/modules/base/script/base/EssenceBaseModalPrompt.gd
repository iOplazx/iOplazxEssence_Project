## [EssenceBaseModalPrompt]
## Base class for modal windows, alerts, and confirmation prompts.
## Blocks background interaction and provides async responses via await.
class_name EssenceBaseModalPrompt
extends Control

signal action_selected(action_id: String)

enum ButtonPreset {
	OK,
	YES_NO,
	YES_NO_CANCEL,
	CUSTOM
}

@export_category("Animation Settings")
@export var fade_duration: float = 0.25

var _selected_action: String = ""


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	hide()


## Displays a modal prompt and returns the chosen action via await.
func show_prompt(title: String, body: String, preset: ButtonPreset = ButtonPreset.OK, custom_buttons: Array = []) -> String:
	_selected_action = ""
	
	_set_title_text(tr(title))
	_set_body_text(tr(body))
	_build_buttons(preset, custom_buttons)
	
	show()
	await _animate_in()
	
	await action_selected
	
	await _animate_out()
	hide()
	
	return _selected_action


## Virtual method for entry animation (can be overridden by subclasses)
func _animate_in() -> void:
	modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, fade_duration)
	await tween.finished


## Virtual method for exit animation (can be overridden by subclasses)
func _animate_out() -> void:
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, fade_duration)
	await tween.finished


func _set_title_text(_text: String) -> void:
	pass


func _set_body_text(_text: String) -> void:
	pass


func _get_button_container() -> Container:
	return null


func _build_buttons(preset: ButtonPreset, custom_buttons: Array) -> void:
	var container = _get_button_container()
	if not is_instance_valid(container):
		return
		
	for child in container.get_children():
		child.queue_free()
		
	var button_configs: Array = []
	
	match preset:
		ButtonPreset.OK:
			button_configs = [{"id": "ok", "label": tr("OK")}]
		ButtonPreset.YES_NO:
			button_configs = [
				{"id": "yes", "label": tr("YES")},
				{"id": "no", "label": tr("NO")}
			]
		ButtonPreset.YES_NO_CANCEL:
			button_configs = [
				{"id": "yes", "label": tr("YES")},
				{"id": "no", "label": tr("NO")},
				{"id": "cancel", "label": tr("CANCEL")}
			]
		ButtonPreset.CUSTOM:
			button_configs = custom_buttons
			
	for config in button_configs:
		var btn = Button.new()
		btn.text = config.get("label", "Button")
		btn.custom_minimum_size = Vector2(90, 40)
		
		var action_id: String = config.get("id", "ok")
		btn.pressed.connect(_on_button_clicked.bind(action_id))
		
		container.add_child(btn)


func _on_button_clicked(action_id: String) -> void:
	_selected_action = action_id
	action_selected.emit(action_id)
