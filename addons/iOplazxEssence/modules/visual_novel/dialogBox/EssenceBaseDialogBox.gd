## [EssenceBaseDialogBox]
## Agnostic base class for dialog boxes.
## Handles line queues, typewriter effect, click-to-skip, and signals.
class_name EssenceBaseDialogBox
extends PanelContainer

# ==========================================
# FRAMEWORK SIGNALS
# ==========================================
signal dialogue_started
signal line_started(line_data: Dictionary)
signal line_completed
signal dialogue_finished

# ==========================================
# CONFIGURATION
# ==========================================
@export_category("Typewriter Settings")
## Development speed in seconds per character.
@export var character_reveal_delay: float = 0.025
## If true, it will automatically process strings with tr().
@export var enable_auto_translation: bool = true

# ==========================================
# INTERNAL STATE
# ==========================================
var _dialogue_queue: Array = []
var _current_line: Dictionary = {}
var _is_typing: bool = false
var _typewriter_tween: Tween


func _ready() -> void:
	hide()


# ==========================================
# PUBLIC API: Flow Control
# ==========================================

## Starts a dialogue sequence by passing an array of dictionaries.
## Example: [{"nombre": "Annie", "texto": "LINE_1"}, ...]
func start_dialogue(lines: Array) -> void:
	_dialogue_queue = lines.duplicate()
	show()
	dialogue_started.emit()
	advance_dialogue()


## Advance to the next line or complete the on-screen text if it is still being typed.
func advance_dialogue() -> void:
	# 1. If the text is being written on the screen, clicking completes it instantly.
	if _is_typing:
		_complete_typewriter_instant()
		return
		
	# 2. If the queue is empty, we close the interface.
	if _dialogue_queue.is_empty():
		_finish_dialogue()
		return
		
	# 3. We extract and process the following line
	_current_line = _dialogue_queue.pop_front()
	_process_current_line(_current_line)


# ==========================================
# VIRTUAL METHODS (To be overridden in subclasses)
# ==========================================

## Override in the subclass to assign the name to the corresponding Label.
func _set_speaker_name(_name_text: String, _line_data: Dictionary) -> void:
	pass

## Override in the subclass to return the RichTextLabel/Label node for the text.
func _get_text_label_node() -> Control:
	return null


# ==========================================
# INTERNAL LOGIC AND TYPEWRITER
# ==========================================

func _process_current_line(line_data: Dictionary) -> void:
	line_started.emit(line_data)
	
	# ===================================================================
	# FLEXIBLE SEARCH: Prioritizes English ("speaker"/"name", "text") 
	# and maintains a fallback to Spanish ("nombre", "texto") for compatibility.
	# ===================================================================
	var raw_speaker: String = line_data.get("speaker", line_data.get("name", line_data.get("nombre", "Narrator")))
	var raw_text: String = line_data.get("text", line_data.get("texto", "..."))
	
	var final_speaker: String = tr(raw_speaker) if enable_auto_translation else raw_speaker
	var final_text: String = tr(raw_text) if enable_auto_translation else raw_text
	
	# Pass the name to the UI
	_set_speaker_name(final_speaker, line_data)
	
	# Start typewriter effect
	var label_node = _get_text_label_node()
	if label_node:
		_start_typewriter_effect(label_node, final_text)
	else:
		line_completed.emit()


func _start_typewriter_effect(label_node: Control, text_to_display: String) -> void:
	if _typewriter_tween and _typewriter_tween.is_running():
		_typewriter_tween.kill()
		
	_is_typing = true
	
	if label_node is RichTextLabel:
		var rtl = label_node as RichTextLabel
		rtl.text = text_to_display
		rtl.visible_characters = 0
		
		var total_chars: int = rtl.get_parsed_text().length()
		var duration: float = total_chars * character_reveal_delay
		
		_typewriter_tween = create_tween()
		_typewriter_tween.tween_property(rtl, "visible_characters", total_chars, duration)
		_typewriter_tween.finished.connect(_on_typewriter_finished)
		
	elif label_node is Label:
		var lbl = label_node as Label
		lbl.text = text_to_display
		lbl.visible_ratio = 0.0
		
		var duration: float = text_to_display.length() * character_reveal_delay
		
		_typewriter_tween = create_tween()
		_typewriter_tween.tween_property(lbl, "visible_ratio", 1.0, duration)
		_typewriter_tween.finished.connect(_on_typewriter_finished)


func _complete_typewriter_instant() -> void:
	if _typewriter_tween and _typewriter_tween.is_running():
		_typewriter_tween.kill()
		
	var label_node = _get_text_label_node()
	if label_node is RichTextLabel:
		(label_node as RichTextLabel).visible_characters = -1
	elif label_node is Label:
		(label_node as Label).visible_ratio = 1.0
		
	_on_typewriter_finished()


func _on_typewriter_finished() -> void:
	_is_typing = false
	line_completed.emit()


func _finish_dialogue() -> void:
	hide()
	dialogue_finished.emit()
