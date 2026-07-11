extends CanvasLayer

const ES_NAME_CLASS = "EssenceCrashScreen"

@export_category("Textos")
@export var lbl_header: Label
@export var lbl_title: Label
@export var lbl_description: Label

@export_category("Detalles Técnicos")
@export var btn_toggle_details: Button
@export var details_container: PanelContainer
@export var txt_details: TextEdit

@export_category("Botones de Acción")
@export var btn_back: Button
@export var btn_open_log: Button
@export var btn_open_folder: Button
@export var btn_ignore: Button
@export var btn_quit: Button

var _is_details_open: bool = false
var _current_log_path

func _ready():
	# 1. Blindaje silencioso (Sin llamar a EssenceError)
	_check_security_nodes()
	
	# Nos aseguramos de que este nodo corra aunque el juego esté pausado por el crash
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# 2. Conexiones seguras
	if btn_toggle_details: btn_toggle_details.pressed.connect(_on_toggle_details_pressed)
	if btn_back: btn_back.pressed.connect(_on_back_pressed)
	if btn_open_log: btn_open_log.pressed.connect(_on_open_log_pressed)
	if btn_open_folder: btn_open_folder.pressed.connect(_on_open_folder_pressed)
	if btn_ignore: btn_ignore.pressed.connect(_on_ignore_pressed)
	if btn_quit: btn_quit.pressed.connect(_on_quit_pressed)
	
	# 3. Estado inicial seguro
	if details_container: details_container.visible = false
	
	_update_ui_texts()

# ==========================================
# 0. BLINDAJE DE EMERGENCIA (Bucle-Free)
# ==========================================
func _check_security_nodes():
	var missing = []
	if not lbl_header: missing.append("lbl_header")
	if not lbl_title: missing.append("lbl_title")
	if not lbl_description: missing.append("lbl_description")
	if not btn_toggle_details: missing.append("btn_toggle_details")
	if not details_container: missing.append("details_container")
	if not txt_details: missing.append("txt_details")
	if not btn_back: missing.append("btn_back")
	if not btn_open_log: missing.append("btn_open_log")
	if not btn_open_folder: missing.append("btn_open_folder")
	if not btn_ignore: missing.append("btn_ignore")
	if not btn_quit: missing.append("btn_quit")
	
	if missing.size() > 0:
		# ¡OJO! Usamos push_error nativo de Godot para no causar bucles con nuestro propio sistema
		push_error("[%s] CRITICAL: Missing exported nodes: %s" % [ES_NAME_CLASS, ", ".join(missing)])

# ==========================================
# 1. CONFIGURACIÓN DE LA INTERFAZ
# ==========================================
func _update_ui_texts():
	if lbl_header: lbl_header.text = tr("CRASH_HEADER")
	if btn_toggle_details: btn_toggle_details.text = tr("CRASH_BTN_SHOW_DETAILS")
	
	if btn_back:
		btn_back.text = tr("CRASH_BTN_BACK")
		btn_back.tooltip_text = tr("CRASH_TOOLTIP_BACK")
	if btn_open_log:
		btn_open_log.text = tr("CRASH_BTN_OPEN_LOG")
		btn_open_log.tooltip_text = tr("CRASH_TOOLTIP_OPEN_LOG")
	if btn_open_folder:
		btn_open_folder.text = tr("CRASH_BTN_OPEN_FOLDER")
		btn_open_folder.tooltip_text = tr("CRASH_TOOLTIP_OPEN_FOLDER")
	if btn_ignore:
		btn_ignore.text = tr("CRASH_BTN_IGNORE")
		btn_ignore.tooltip_text = tr("CRASH_TOOLTIP_IGNORE")
	if btn_quit:
		btn_quit.text = tr("CRASH_BTN_QUIT")
		btn_quit.tooltip_text = tr("CRASH_TOOLTIP_QUIT")

# ==========================================
# INYECCIÓN DE DATOS
# ==========================================
func setup(data: Dictionary):
	if lbl_title: 
		lbl_title.text = data.get("title", tr("CRASH_DEFAULT_TITLE"))
		
	if lbl_description: 
		lbl_description.text = data.get("message", tr("CRASH_DEFAULT_DESC"))
		
	if txt_details:
		var stack = data.get("stack", [])
		var stack_text = tr("CRASH_STACK_HEADER") + "\n"
		
		if stack.is_empty():
			stack_text += tr("CRASH_STACK_EMPTY") + "\n"
		else:
			for i in range(stack.size()):
				var frame = stack[i]
				var file = frame.get("source", "N/A")
				var line = frame.get("line", 0)
				var func_name = frame.get("function", "N/A")
				# Mantenemos esto semi-técnico porque es para leer código
				stack_text += "[Lvl %d] %s -> %s() (Line %d)\n" % [i, file, func_name, line]
				
		txt_details.text = stack_text
		
	_current_log_path = data.get("log_path", "")
	
# ==========================================
# EVENTOS DE BOTONES
# ==========================================
func _on_toggle_details_pressed():
	_is_details_open = not _is_details_open
	
	# Parche: Verificar nodos antes de tocarlos
	if details_container:
		details_container.visible = _is_details_open
	if btn_toggle_details:
		btn_toggle_details.text = tr("CRASH_BTN_HIDE_DETAILS") if _is_details_open else tr("CRASH_BTN_SHOW_DETAILS")
	

func _on_back_pressed():
	get_tree().paused = false
	
	if is_instance_valid(SaveManager) and SaveManager.has_method("has_action_checkpoint"):
		if SaveManager.has_action_checkpoint():
			EssenceLogger.system_info("[%s/_on_back_pressed] Recovering via Action Checkpoint." % ES_NAME_CLASS)
			SaveManager.load_action_checkpoint()
			
		elif SaveManager.has_scene_checkpoint():
			EssenceLogger.system_info("[%s/_on_back_pressed] Recovering via Scene Checkpoint." % ES_NAME_CLASS)
			SaveManager.load_scene_checkpoint()
			
		else:
			EssenceLogger.system_info("[%s/_on_back_pressed] No checkpoints available. Reloading current scene." % ES_NAME_CLASS)
			get_tree().reload_current_scene() 
	else:
		# Plan C: Si el SaveManager está roto, dejamos evidencia en el log antes de reiniciar
		EssenceLogger.system_info("[%s/_on_back_pressed] WARNING: SaveManager invalid or missing. Forcing scene reload." % ES_NAME_CLASS)
		get_tree().reload_current_scene()
		
	queue_free()
	
func _on_open_log_pressed():
	if _current_log_path != "":
		OS.shell_open(ProjectSettings.globalize_path(_current_log_path))
	else:
		_on_open_folder_pressed() # Si no hay log específico, abre la carpeta

func _on_open_folder_pressed():
	# Abre la carpeta 'user://' del juego en el explorador de Windows/Linux
	var path = ProjectSettings.globalize_path("user://")
	OS.shell_open(path)

func _on_ignore_pressed():
	# Continúa bajo propio riesgo del usuario/dev
	get_tree().paused = false
	queue_free()

func _on_quit_pressed():
	# Salida segura
	get_tree().quit()
