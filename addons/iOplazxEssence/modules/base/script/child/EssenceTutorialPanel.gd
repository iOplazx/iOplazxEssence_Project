extends EssenceLateralPanel 
class_name EssenceTutorialPanel
# =======
# ESTRUCTURA DE LA ESCENA: EssenceTutorialPanelUI (Heredada)
# =======
# EssenceTutorialPanelUI (Control) [Heredado]
# └── CajonDeslizante (Control) [Heredado]
#     ├── ContenedorFondo (Panel) [Heredado]
#     │   └── MargenInterno (MarginContainer) [Heredado]
#     │       └── ContenedorContenido (VBoxContainer) [Heredado]
#     │           ├── (+) TituloTutorial (Label)          <- Ej: "Annie dice:"
#     │           ├── (+) Separador (HSeparator)         <- Opcional: línea estética
#     │           ├── (+) TextoExplicativo (RichTextLabel) <- El texto del tutorial
#     │           └── (+) ContenedorBotones (HBoxContainer) <- Para ponerlos en fila
#     │               ├── (+) BtnAnterior (Button)        <- Volver atrás
#     │               └── (+) BtnSiguiente (Button)       <- Avanzar
#     └── BtnAlternar (Button) [Heredado]
# =====
# ==========================================
# SEÑALES
# ==========================================
signal tutorial_finished
signal page_changed(page: int)

# ==========================================
# VARIABLES
# ==========================================
@export_group("Layout Customization")
@export_range(0.0, 0.5) var top_margin: float = 0.2:
	set(value):
		top_margin = value
		if is_node_ready(): _update_custom_layout()

@export_range(0.5, 1.0) var bottom_margin: float = 0.8:
	set(value):
		bottom_margin = value
		if is_node_ready(): _update_custom_layout()

@export_group("Content")
@export var tutorial_pages: Array[String] = []

# ==========================================
# VARIABLES Y NODOS
# ==========================================
var _current_page: int = 0
var _ocultar_al_terminar: bool = true

# UI References (Make sure you have the % in the scene)
@onready var rich_text_tutorial: RichTextLabel = %TextoExplicativo
@onready var btn_prev: Button = %BtnAnterior
@onready var btn_next: Button = %BtnSiguiente

# ==========================================
# INICIALIZACIÓN
# ==========================================
func _ready() -> void:
	super._ready() 
	
	# Apply custom vertical anchors on startup
	_update_custom_layout()
	
	# Delete test text from the editor
	if rich_text_tutorial: 
		rich_text_tutorial.text = ""
	
	# Connect the tutorial's own buttons
	if btn_prev: 
		btn_prev.pressed.connect(prev_page)
		btn_prev.focus_mode = Control.FOCUS_NONE
		
	if btn_next: 
		btn_next.pressed.connect(next_page)
		btn_next.focus_mode = Control.FOCUS_NONE
	
	_update_ui()

# ==========================================
#PUBLIC METHODS (Tutorial API)
# ==========================================
func load_and_show_tutorial(messages: Array[String], ocultar: bool = true) -> void:
	_ocultar_al_terminar = ocultar # We save the preference
	_setup_new_tutorial(messages)
	
	show() # We ensure the node is turned on in the engine.
	
	if not is_open:
		toggle() # Entrance animation

func load_tutorial_silently(messages: Array[String]) -> void:
	_setup_new_tutorial(messages)

func next_page() -> void:
	if _current_page < tutorial_pages.size() - 1:
		_current_page += 1
		_update_ui()
	else:
		# so that it is stored elegantly on the screen.
		if is_open:
			toggle() # This runs your tween to the minimized X position.
		
		# We wait for the timer and turn off the motor.
		if _ocultar_al_terminar:
			await get_tree().create_timer(anim_duration).timeout
			visible = false
		
		# We transmit the signal so that the main game continues.
		tutorial_finished.emit()

func prev_page() -> void:
	if _current_page > 0:
		_current_page -= 1
		_update_ui()

# ==========================================
# PRIVATE METHODS
# ==========================================
func _update_custom_layout() -> void:
	if cajon:
		cajon.anchor_top = top_margin
		cajon.anchor_bottom = bottom_margin
		
		cajon.offset_top = 0.0
		cajon.offset_bottom = 0.0

func _setup_new_tutorial(messages: Array[String]) -> void:
	tutorial_pages = messages
	_current_page = 0
	_update_ui()

func _update_ui() -> void:
	if tutorial_pages.is_empty(): 
		return
		
	# Update text
	if rich_text_tutorial: 
		rich_text_tutorial.text = tutorial_pages[_current_page]
		
	# Update button states
	if btn_prev:
		btn_prev.disabled = (_current_page == 0)
		btn_prev.text = tr("ESS_BUTTON_PREV_TUTORIAL")
	
	if btn_next:
		if _current_page == tutorial_pages.size() - 1:
			btn_next.text = tr("ESS_BUTTON_UNDERSTOOD")
		else:
			btn_next.text = tr("ESS_BUTTON_NEXT_TUTORIAL")

	page_changed.emit(_current_page)
