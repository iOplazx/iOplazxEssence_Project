class_name EssenceRouteConfig extends Resource

@export_category("Rutas Base (Framework)")
@export_file("*.tscn") var main_menu_scene: String = ""
@export_file("*.tscn") var new_game_scene: String = ""
@export_file("*.tscn") var settings_scene: String = ""
@export_file("*.tscn") var credits_scene: String = ""

@export_category("Rutas Personalizadas (Usuario)")
## Escribe un nombre clave a la izquierda (ej: "casa", "nivel_1") y su ruta a la derecha.
@export var custom_routes: Dictionary = {}
