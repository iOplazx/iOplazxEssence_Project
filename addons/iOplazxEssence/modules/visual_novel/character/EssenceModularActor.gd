## [EssenceModularActor]
## Handles modular visual parts like clothing, accessories, or visual variations.
## Automatically registers nodes added to the 'Wardrobe Nodes' array.
extends EssenceActor
class_name EssenceModularActor

# ==========================================
# CONFIGURACIÓN EXPUESTA AL EDITOR (En Inglés)
# ==========================================
## Array of nodes (Sprite2D, Node2D, etc.) that represent clothing or body parts.
## The exact name of the node in the Scene Tree will be used as its unique ID.
@export var wardrobe_nodes: Array[Node2D] = []

# ==========================================
# VARIABLES INTERNAS
# ==========================================
# Diccionario para acceso ultrarrápido a los nodos: {"bra": Node, "camisa": Node}
var _wardrobe_map: Dictionary = {}

# ==========================================
# INICIALIZACIÓN
# ==========================================
func _ready() -> void:
	super._ready() # Llamamos al _ready() de EssenceActor por si acaso
	_build_wardrobe_map()

func _build_wardrobe_map() -> void:
	# Recorremos el Array que el dev llenó en el inspector
	for node in wardrobe_nodes:
		if is_instance_valid(node):
			# Usamos el nombre exacto del nodo (ej: "Camisa") como llave
			_wardrobe_map[node.name] = node

# ==========================================
# MÉTODOS PÚBLICOS (API en Inglés)
# ==========================================

## Returns a dictionary with the visibility state (true/false) of all wardrobe nodes.
func get_clothing_state() -> Dictionary:
	var state: Dictionary = {}
	for garment_name in _wardrobe_map:
		var node = _wardrobe_map[garment_name]
		if is_instance_valid(node):
			state[garment_name] = node.visible
	return state

## Applies a saved visibility state to the wardrobe.
func load_clothing_state(state: Dictionary) -> void:
	for garment_name in state:
		if _wardrobe_map.has(garment_name):
			var node = _wardrobe_map[garment_name]
			if is_instance_valid(node):
				node.visible = state[garment_name]

## Toggles the visibility of a specific garment by its node name.
func toggle_garment(garment_name: String, is_visible: bool) -> void:
	if _wardrobe_map.has(garment_name):
		var node = _wardrobe_map[garment_name]
		if is_instance_valid(node):
			node.visible = is_visible
	else:
		# Aviso útil en consola si el dev intenta encender ropa que no existe
		push_warning("[%s] Garment not found in wardrobe: %s" % [display_name, garment_name])
	
	
