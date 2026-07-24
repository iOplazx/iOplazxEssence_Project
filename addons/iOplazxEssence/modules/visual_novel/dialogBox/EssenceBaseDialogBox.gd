## [EssenceBaseDialogBox]
## Clase base agnóstica para cajas de diálogo.
## Maneja colas de líneas, efecto máquina de escribir, omisión por clic y señales.
class_name EssenceBaseDialogBox
extends PanelContainer

# ==========================================
# SEÑALES DEL FRAMEWORK
# ==========================================
signal dialogue_started
signal line_started(line_data: Dictionary)
signal line_completed
signal dialogue_finished

# ==========================================
# CONFIGURACIÓN
# ==========================================
@export_category("Typewriter Settings")
## Velocidad de revelado en segundos por carácter.
@export var character_reveal_delay: float = 0.025
## Si es verdadero, procesará las cadenas con tr() automáticamente.
@export var enable_auto_translation: bool = true

# ==========================================
# ESTADO INTERNO
# ==========================================
var _dialogue_queue: Array = []
var _current_line: Dictionary = {}
var _is_typing: bool = false
var _typewriter_tween: Tween


func _ready() -> void:
	hide()


# ==========================================
# PUBLIC API: Control de Flujo
# ==========================================

## Inicia una secuencia de diálogo pasando un arreglo de diccionarios.
## Ejemplo: [{"nombre": "Annie", "texto": "LINE_1"}, ...]
func start_dialogue(lines: Array) -> void:
	_dialogue_queue = lines.duplicate()
	show()
	dialogue_started.emit()
	advance_dialogue()


## Avanza a la siguiente línea o completa el texto en pantalla si aún se está escribiendo.
func advance_dialogue() -> void:
	# 1. Si el texto se está escribiendo en pantalla, el clic lo completa de golpe
	if _is_typing:
		_complete_typewriter_instant()
		return
		
	# 2. Si la cola está vacía, cerramos la interfaz
	if _dialogue_queue.is_empty():
		_finish_dialogue()
		return
		
	# 3. Extraemos y procesamos la siguiente línea
	_current_line = _dialogue_queue.pop_front()
	_process_current_line(_current_line)


# ==========================================
# MÉTODOS VIRTUALES (Para sobreescribir en subclases)
# ==========================================

## Sobreescribir en la subclase para asignar el nombre al Label correspondiente.
func _set_speaker_name(_name_text: String, _line_data: Dictionary) -> void:
	pass


## Sobreescribir en la subclase para devolver el nodo RichTextLabel/Label del texto.
func _get_text_label_node() -> Control:
	return null


# ==========================================
# LÓGICA INTERNA Y TYPEWRITER
# ==========================================

func _process_current_line(line_data: Dictionary) -> void:
	line_started.emit(line_data)
	
	# ===================================================================
	# BÚSQUEDA FLEXIBLE: Prioriza inglés ("speaker"/"name", "text") 
	# y mantiene fallback a español ("nombre", "texto") por compatibilidad.
	# ===================================================================
	var raw_speaker: String = line_data.get("speaker", line_data.get("name", line_data.get("nombre", "Narrator")))
	var raw_text: String = line_data.get("text", line_data.get("texto", "..."))
	
	var final_speaker: String = tr(raw_speaker) if enable_auto_translation else raw_speaker
	var final_text: String = tr(raw_text) if enable_auto_translation else raw_text
	
	# Transmitir el nombre a la UI
	_set_speaker_name(final_speaker, line_data)
	
	# Iniciar efecto typewriter
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
