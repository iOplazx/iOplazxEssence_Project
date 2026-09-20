# ==============================================================================
# SCRIPT: EssenceLocation.gd
# DESCRIPCIÓN: Clase base para todos los escenarios del juego. Controla datos
# básicos como el fondo, la música y la identificación de la zona.
# ==============================================================================
class_name EssenceLocation
extends Node2D

const ES_NAME_CLASS = "EssenceLocation"

#@export_category("Datos del Escenario")
@export var location_id: String = "zona_generica"
@export var location_name: String = "Zona Desconocida"

@export_category("Referencias Visuales y Audio")
@export var stage_background: TextureRect
# @export var background_music: AudioStream # Descomentar si usas música por escenario

func _ready() -> void:
	if not stage_background:
		EssenceReportUtils.warning(
			"Location Setup Warning",
			"No Sprite2D background assigned for location '%s'." % location_id
		)
		
	EssenceLogger.system_info("[%s] Location loaded: %s (%s)" % [ES_NAME_CLASS, location_name, location_id])

## Changes the current background texture.
## Ideal for time transitions (e.g., Day -> Night) if no filters are used.
func change_background(new_texture: Texture2D) -> void:
	if stage_background and new_texture:
		stage_background.texture = new_texture
		print("[%s] Textura de fondo actualizada." % location_id)
