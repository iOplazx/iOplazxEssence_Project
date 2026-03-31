class_name EssenceMasterConfig extends Resource

@export_category("Localization Toggles")
## Cargar los textos base del framework (Menús, Ajustes)
@export var load_framework_loc: bool = true
## Cargar los textos personalizados del proyecto
@export var load_project_loc: bool = true

@export_category("Framework Paths (Internal)")
@export_dir var path_static_loc: String = "res://addons/ioplazx_essence/core/static_loc/"

@export_category("Developer Paths (Game Data)")
@export_dir var path_persistent: String = "res://game_data/persistent/"
@export_dir var path_remote_template: String = "res://game_data/remote/"
@export_dir var path_global_template: String = "res://game_data/global/"

@export_category("Save System Customization")
## Drag your script that inherits from EssenceSaveData here (e.g., res://game_data/MySave.gd)
## If left empty, the framework will use the basic template.
@export var custom_save_script: GDScript
