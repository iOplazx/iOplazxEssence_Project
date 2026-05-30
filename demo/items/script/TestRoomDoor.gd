class_name TestRoomDoor
extends EssenceInteractiveLocation

## Signal emitted when a hotspot requests a scene transition or state change.
signal navigation_requested(next_place: int, mode: int, is_only_mode: bool)

func _ready() -> void:
	# Llama al ready del padre para conectar los clicks automáticos
	super._ready()
	# Inicializa los efectos visuales de hover
	_setup_hover_effects()


## Automatically scans hotspots and hooks mouse hover behavior.
func _setup_hover_effects() -> void:
	if not fixed_hotspots: return
	
	for hotspot in fixed_hotspots.get_children():
		if hotspot is Area2D:
			# Hide visual elements inside the hotspot by default
			_set_hotspot_visual_visibility(hotspot, false)
			
			# Connect hover entry
			hotspot.mouse_entered.connect(func(target=hotspot):
				if environment_interactable:
					_set_hotspot_visual_visibility(target, true)
			)
			
			# Connect hover exit
			hotspot.mouse_exited.connect(func(target=hotspot):
				_set_hotspot_visual_visibility(target, false)
			)


## Overrides the base click behavior to execute specific room navigation events.
func _on_hotspot_clicked(event: InputEvent, node: Area2D) -> void:
	# Mantiene el print base de la consola si lo deseas
	super._on_hotspot_clicked(event, node)
	
	if not environment_interactable: return
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		# Mapeamos el nombre del nodo físico a una orden para el LevelManager
		match node.name:
			"Door1":
				# Regresar a la habitación inicial
				navigation_requested.emit(LevelManager.RoomID["INITIAL_ROOM"], 0, false)
			"Door2":
				# Ir a la habitación de 1 puerta
				navigation_requested.emit(LevelManager.RoomID["ROOM_1_DOOR"], 0, false)
			"Door3":
				# Ejemplo: Activar el sub-modo interno 2 de esta misma habitación
				navigation_requested.emit(LevelManager.RoomID["ROOM_3_DOORS"], 2, true)


# ==========================================
# PRIVATE METHODS (Helper Logic)
# ==========================================

func _set_hotspot_visual_visibility(hotspot: Area2D, is_visible: bool) -> void:
	# Busca cualquier Sprite2D o TextureRect dentro de la puerta para apagarlo/encenderlo
	for child in hotspot.get_children():
		if child is CanvasItem and not child is CollisionShape2D:
			child.visible = is_visible
