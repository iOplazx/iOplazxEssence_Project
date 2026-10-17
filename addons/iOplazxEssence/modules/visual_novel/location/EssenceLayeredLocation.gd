class_name EssenceLayeredLocation
extends EssenceLocation

const ES_LAYERED_CLASS = "EssenceLayeredLocation"

@export_category("Stage Metadata")
## Unique identifier for the room/zone (e.g. "annie_room", "park_stage")
@export var location_id: String = "generic_zone"
## Display name for UI and Save System (e.g. "Annie's Bedroom")
@export var location_name: String = "Unknown Zone"

@export_category("Advanced Stage Layers")
@export var background_layer: CanvasItem
@export var foreground_layer: CanvasItem
@export var atmosphere_fx: Node2D

@export_category("Environment Variants")
@export var background_variants: Dictionary = {}


func _ready() -> void:
	#EssenceLogger.system_info("[%s] Layered scenario initialized: %s (%s)" % [ES_LAYERED_CLASS, location_name, location_id])
	_disable_mouse_blocking_recursive(self)

func _disable_mouse_blocking_recursive(node: Node) -> void:
	if node is Control:
		node.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
	for child in node.get_children():
		_disable_mouse_blocking_recursive(child)

func set_environment_mode(mode: int) -> void:
	if background_variants.has(mode):
		var target_texture: Texture2D = background_variants[mode] as Texture2D
		if background_layer and background_layer is TextureRect:
			(background_layer as TextureRect).texture = target_texture
			
	if is_instance_valid(atmosphere_fx):
		atmosphere_fx.visible = (mode == 2)
