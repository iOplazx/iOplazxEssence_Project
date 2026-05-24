# ==============================================================================
# SCRIPT: EssenceLocation.gd
# DESCRIPCIÓN: Clase base para todos los escenarios del juego. Controla datos
# básicos como el fondo, la música y la identificación de la zona.
# ==============================================================================
class_name EssenceLocation
extends Node2D

#@export_category("Datos del Escenario")
@export var location_id: String = "zona_generica"
@export var location_name: String = "Zona Desconocida"

@export_category("Referencias Visuales y Audio")
@export var stage_background: Sprite2D
# @export var background_music: AudioStream # Descomentar si usas música por escenario

func _ready() -> void:
	if not stage_background:
		push_warning("[%s] Alerta: No se asignó un Sprite2D para el fondo." % location_id)
	print("[EssenceLocation] Escenario cargado: %s (%s)" % [location_name, location_id])

## Changes the current background texture.
## Ideal for time transitions (e.g., Day -> Night) if no filters are used.
func change_background(new_texture: Texture2D) -> void:
	if stage_background and new_texture:
		stage_background.texture = new_texture
		print("[%s] Textura de fondo actualizada." % location_id)
