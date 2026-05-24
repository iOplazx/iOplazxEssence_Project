# ==============================================================================
# SCRIPT: EssenceInteractiveLocation.gd
# DESCRIPCIÓN: Hereda de EssenceLocation. Añade contenedores para objetos
# interactivos (Hotspots) y controla cuándo se pueden clickear.
# ==============================================================================
class_name EssenceInteractiveLocation
extends EssenceLocation

#@export_category("Contenedores Interactivos")
## Folder (Node2D) where the user will place the doors and fixed objects (Area2D)
@export var fixed_hotspots: Node2D    
## Folder (Node2D) reserved for instantiating dynamic/random objects
@export var dynamic_hotspots: Node2D  

# Variable mágica con un "setter". Cada vez que cambie, ejecuta la función automáticamente.
var environment_interactable: bool = false:
	set(value):
		environment_interactable = value
		_toggle_hotspots_interaction(value)

func _ready() -> void:
	# Llama al _ready del padre para registrar el fondo
	super._ready() 
	
	# Por defecto, bloqueamos el escenario al cargar (esperando órdenes del Director)
	environment_interactable = false
	_connect_fixed_hotspots()
	print("[EssenceInteractiveLocation] Nodos interactivos preparados para: %s" % location_id)

## Find the doors/objects and connect their click signals to the script
func _connect_fixed_hotspots() -> void:
	if not fixed_hotspots: return
	
	for object in fixed_hotspots.get_children():
		if object is Area2D and object.has_signal("input_event"):
			# Conectamos con una función Lambda para pasarle el nodo exacto que se tocó
			object.input_event.connect(func(_vp, event, _idx, obj=object):
				_on_hotspot_clicked(event, obj)
			)

## It captures the click of any object and notifies the system.
func _on_hotspot_clicked(event: InputEvent, node: Area2D) -> void:
	if not environment_interactable: return
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		print("[%s] El jugador interactuó con el Hotspot: %s" % [location_id, node.name])
		get_viewport().set_input_as_handled()
		# TODO: Enviar señal al Director para cambiar de cuarto o lanzar un diálogo.

## Turn door collisions on or off (Exploration Mode vs. Dialogue Mode)
func _toggle_hotspots_interaction(enabled: bool) -> void:
	if not fixed_hotspots: return
	
	for object in fixed_hotspots.get_children():
		if object is CollisionObject2D:
			object.input_pickable = enabled
			
