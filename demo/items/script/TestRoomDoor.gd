class_name TestRoomDoor
extends EssenceInteractiveLocation

# ==
# TestRoomDoor.tscn
# ==
# TestRoomDoor (TestRoomDoor) [Script: TestRoomDoor]
# ├── StageBackground (TextureRect)    # imagen guia                 
# ├── FixedHotspots (Node2D)   
# │   ├── ExampleDoor (Area2D)   
# │       ├── Sprite2D (Sprite2D)           
# │       └── CollisionShape2D (CollisionShape2D)          
# │   ├── ExampleDoor2 (Area2D)   
# │       ├── Sprite2D (Sprite2D)           
# │       └── CollisionShape2D (CollisionShape2D)      
# │   ├── ExampleDoor3 (Area2D)   
# │       ├── Sprite2D (Sprite2D)           
# │       └── CollisionShape2D (CollisionShape2D)   
# └── DynamicHotspots (Node2d)  #Heredado de la escena anterior, no usado por ahora.                  
#     └── ... (no uso)
# ==

## Signal emitted 
signal navigation_requested(door_pressed: String)

func _ready() -> void:
	# Llama al ready del padre para conectar los clicks automáticos
	super._ready()
	# Inicializa los efectos visuales de hover
	_setup_hover_effects()

## Automatically scans hotspots and hooks mouse hover behavior.
## Automatically scans hotspots and hooks mouse hover behavior.
func _setup_hover_effects() -> void:
	if not fixed_hotspots: return
	
	for hotspot in fixed_hotspots.get_children():
		if hotspot is Area2D:
			# Ocultamos el sprite al inicio
			_set_hotspot_visual_visibility(hotspot, false)
			
			# 1. Creamos la función para la ENTRADA usando un tipado limpio
			var on_entered = func(target: Area2D):
				#print("[Hover] Mouse ENTRÓ a: %s | Interactuable = %s" % [target.name, environment_interactable])
				if environment_interactable:
					_set_hotspot_visual_visibility(target, true)
			
			# 2. Creamos la función para la SALIDA
			var on_exited = func(target: Area2D):
				#print("[Hover] Mouse SALIÓ de: %s" % target.name)
				_set_hotspot_visual_visibility(target, false)
			
			hotspot.mouse_entered.connect(on_entered.bind(hotspot))
			hotspot.mouse_exited.connect(on_exited.bind(hotspot))

## Overrides the base click behavior to execute specific room navigation events.
func _on_hotspot_clicked(event: InputEvent, node: Area2D) -> void:
	# Mantiene el print base de la consola si lo deseas
	super._on_hotspot_clicked(event, node)
	
	if not environment_interactable: return
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		# Mapeamos el nombre del nodo físico a una orden para el LevelManager
		navigation_requested.emit(node.name)


# ==========================================
# PRIVATE METHODS (Helper Logic)
# ==========================================

func _set_hotspot_visual_visibility(hotspot: Area2D, p_visible: bool) -> void:
	# Busca cualquier Sprite2D o TextureRect dentro de la puerta para apagarlo/encenderlo
	for child in hotspot.get_children():
		if child is CanvasItem and not child is CollisionShape2D:
			child.visible = p_visible
