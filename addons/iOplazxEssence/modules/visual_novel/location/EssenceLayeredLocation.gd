class_name EssenceLayeredLocation
extends EssenceInteractiveLocation

const ES_LAYERED_CLASS = "EssenceLayeredLocation"

@export_category("Advanced Stage Layers")
## Far background layer (e.g. windows, distant sky)
@export var background_layer: CanvasItem

## Foreground overlay layer (e.g. tables or pillars in front of characters)
@export var foreground_layer: CanvasItem

## Environmental effects layer (e.g. fireflies, dust, local light particles)
@export var atmosphere_fx: Node2D

@export_category("Environment Variants")
## Maps room modes (1: Day, 2: Night, 3: Sunset) to background textures
@export var background_variants: Dictionary = {}


func _ready() -> void:
	super._ready()
	EssenceLogger.system_info("[%s] Layered scenario initialized for %s." % [ES_LAYERED_CLASS, location_id])


## Handles environmental variants (e.g. Day -> Night transitions)
func set_environment_mode(mode: int) -> void:
	if background_variants.has(mode):
		var target_texture: Texture2D = background_variants[mode] as Texture2D
		if background_layer and background_layer is TextureRect:
			(background_layer as TextureRect).texture = target_texture
			
	if is_instance_valid(atmosphere_fx):
		atmosphere_fx.visible = (mode == 2)
		
	print("[%s] Layered environment mode set to: %d" % [location_id, mode])
