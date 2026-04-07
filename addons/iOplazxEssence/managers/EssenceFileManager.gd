extends Node

var config: EssenceMasterConfig
var path_remote_actual: String = ""
var path_global_actual: String = "user://"

func _ready():
	_load_config()
	_determine_system_paths()
	
func _load_config():
	# 1. Ruta personalizada del desarrollador (Prioridad Máxima)
	var custom_path = "res://_static/EssenceMasterConfig.tres"
	# 2. Ruta de plantilla del framework (Respaldo/Fallback)
	var default_path = "res://addons/iOplazxEssence/templates/EssenceMasterConfig.tres"
	
	if ResourceLoader.exists(custom_path):
		config = load(custom_path) as EssenceMasterConfig
		print("Essence: Cargando configuración personalizada desde _static.")
		
	elif ResourceLoader.exists(default_path):
		config = load(default_path) as EssenceMasterConfig
		print("Essence: Cargando configuración por defecto del addon.")
		
	else:
		push_error("Essence CRITICAL: No se encontró EssenceMasterConfig.tres en ninguna ruta válida.")


func _determine_system_paths():
	# Si estamos probando en el editor, simulamos la ruta externa para no ensuciar tu PC
	if OS.has_feature("editor"):
		path_remote_actual = ProjectSettings.globalize_path("res://_remote_debug")
	else:
		# Si el juego ya está exportado, sacamos la ruta de la carpeta donde está el .exe
		path_remote_actual = OS.get_executable_path().get_base_dir()

# ==========================================
# INICIALIZACIÓN (Llamar desde el BootBase)
# ==========================================

func initialize_file_system():
	if not config: return
	
	print("Essence: Inicializando Sistema de Archivos...")
	
	# 1. Crear y clonar la carpeta REMOTE (Junto al .exe)
	if config.path_remote_template != "":
		_clone_directory(config.path_remote_template, path_remote_actual)
		
		# --- AUTO-CREAR .gdignore en modo editor ---
		if OS.has_feature("editor"):
			var ignore_path = path_remote_actual + "/.gdignore"
			if not FileAccess.file_exists(ignore_path):
				var file = FileAccess.open(ignore_path, FileAccess.WRITE)
				file.store_string("")
		
	# 2. Crear y clonar la carpeta GLOBAL (AppData)
	if config.path_global_template != "":
		# Godot ya entiende "user://" nativamente
		var user_real_path = ProjectSettings.globalize_path("user://")
		_clone_directory(config.path_global_template, user_real_path)
		
	print("Essence: Sistema de Archivos Listo.")

# ==========================================
# MOTOR DE CLONACIÓN RECURSIVA
# ==========================================

func _clone_directory(source_dir: String, target_dir: String):
	var dir = DirAccess.open(source_dir)
	if not dir:
		# Si el dev no creó la carpeta de plantilla en res://, no hacemos nada
		return 

	# Si la carpeta destino no existe en la PC del jugador, la creamos
	if not DirAccess.dir_exists_absolute(target_dir):
		DirAccess.make_dir_recursive_absolute(target_dir)

	dir.list_dir_begin()
	var file_name = dir.get_next()

	while file_name != "":
		if dir.current_is_dir():
			if file_name != "." and file_name != "..":
				# Es una sub-carpeta, hacemos recursividad
				_clone_directory(source_dir + "/" + file_name, target_dir + "/" + file_name)
		else:
			# Es un archivo. Copiamos SOLO SI NO EXISTE. 
			# Así no le borramos al jugador los archivos que ya tradujo/modificó.
			var src_file = source_dir + "/" + file_name
			var dst_file = target_dir + "/" + file_name
			
			if not FileAccess.file_exists(dst_file):
				# Ignoramos los archivos de importación propios del motor
				if not src_file.ends_with(".import"): 
					DirAccess.copy_absolute(src_file, dst_file)
					
		file_name = dir.get_next()
