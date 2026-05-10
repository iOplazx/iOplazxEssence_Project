extends Control
class_name EssenceLateralPanel
# ========
# ESTRUCTURA DE LA ESCENA: EssenceSimpleLateralUI (Base)
# ========
# SimpleLateralPanelUI (Control) 
# └── CajonDeslizante (Control) 
#     ├── ContenedorFondo (Panel) 
#     │   └── MargenInterno (MarginContainer) 
#     │       └── ContenedorContenido (VBoxContainer) 
#     └── BtnAlternar (Button)

enum PanelSide { LEFT, RIGHT }

@export var side: PanelSide = PanelSide.LEFT :
	set(value):
		side = value
		_update_layout()
		
@export_range(0.0, 1.0) var button_y_pos: float = 0.5 :
	set(value):
		button_y_pos = value
		_update_layout()

@export var anim_duration: float = 0.3
@export var is_open: bool = false

@onready var cajon: Control = %CajonDeslizante
@onready var btn_alternar: Button = %BtnAlternar

var _tween: Tween

func _ready() -> void:
	btn_alternar.pressed.connect(toggle)
	_update_layout()
	_update_btn_icon()
	
	# Un pequeño delay para asegurar que Godot ya calculó el tamaño de la pantalla
	call_deferred("_force_position")

func toggle() -> void:
	is_open = !is_open
	_update_btn_icon()
	
	if _tween and _tween.is_valid():
		_tween.kill()
		
	var target = _get_target_x()
	print("[UI] Tween hacia position.x: ", target)
	
	_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.tween_property(cajon, "position:x", target, anim_duration)

func _update_layout() -> void:
	if not is_node_ready(): return
	
	# Configuración Horizontal del Cajón (Dejamos en paz el Top y Bottom)
	if side == PanelSide.LEFT:
		cajon.anchor_left = 0.0
		cajon.anchor_right = 0.0
		
		# Botón a la derecha del cajón
		btn_alternar.anchor_left = 1.0
		btn_alternar.anchor_right = 1.0
		btn_alternar.position.x = cajon.size.x
	else:
		cajon.anchor_left = 1.0
		cajon.anchor_right = 1.0
		
		# Botón a la izquierda del cajón
		btn_alternar.anchor_left = 0.0
		btn_alternar.anchor_right = 0.0
		btn_alternar.position.x = -btn_alternar.size.x

	# Configuración Vertical del Botón (Definida por el usuario)
	btn_alternar.anchor_top = button_y_pos
	btn_alternar.anchor_bottom = button_y_pos
	
	var mitad_altura = btn_alternar.size.y / 2.0
	btn_alternar.offset_top = -mitad_altura
	btn_alternar.offset_bottom = mitad_altura

func _get_target_x() -> float:
	# Usamos el ancho de la pantalla (viewport) por si el nodo raíz está mal configurado
	var ancho_pantalla = get_viewport_rect().size.x
	var ancho_cajon = cajon.size.x
	
	print("--- DEBUG PANEL ---")
	print("Lado: ", "IZQUIERDA" if side == PanelSide.LEFT else "DERECHA", " | Abierto: ", is_open)
	print("Ancho Pantalla: ", ancho_pantalla, " | Ancho Cajón: ", ancho_cajon)
	
	if side == PanelSide.LEFT:
		return 0.0 if is_open else -ancho_cajon
	else:
		return ancho_pantalla - ancho_cajon if is_open else ancho_pantalla

func _force_position() -> void:
	if not is_node_ready(): return
	cajon.position.x = _get_target_x()
	print("[UI] Posición forzada a: ", cajon.position.x)

func _update_btn_icon() -> void:
	if not is_node_ready(): return
	if side == PanelSide.LEFT:
		btn_alternar.text = "<" if is_open else ">"
	else:
		btn_alternar.text = ">" if is_open else "<"

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_force_position()
