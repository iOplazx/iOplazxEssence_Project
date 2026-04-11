class_name EssenceLoader extends RefCounted

const ES_NAME_CLASS = "EssenceLoader"

## Carga imágenes propias del Framework
static func get_internImage(key: EssencePaths.KeyImage) -> Texture2D:
	if EssencePaths.INTERNAL_IMAGES.has(key):
		var path = EssencePaths.INTERNAL_IMAGES[key]
		if ResourceLoader.exists(path):
			return load(path) as Texture2D
	
	# Parcheo: Reporte estandarizado en vez de push_error
	EssenceError.report(
		"Internal Image Error", 
		"Internal image key not found or invalid: %s" % key,
		EssenceError.Severity.WARNING
	)
	return load(EssencePaths.INTERNAL_IMAGES[EssencePaths.KeyImage.ERROR_FALLBACK])

## Carga bytes puros desde el disco duro (Solo para archivos fuera del juego)
static func get_externImage(ruta: String, usar_imagen_error: bool = true) -> Texture2D:
	var clean_path = ruta.strip_edges()
	
	if clean_path == "" or clean_path == null:
		return _get_fallback(usar_imagen_error)
	
	# === EL SEGURO (MÁXIMA PRIORIDAD) ===
	# Si por error llega un res:// aquí, lo desviamos al cargador nativo.
	# Esto es lo que mata el Warning de Godot definitivamente.
	if clean_path.begins_with("res://"):
		return load(clean_path) as Texture2D

	# === BLOQUE EXTERNO REAL ===
	if FileAccess.file_exists(clean_path):
		var img = Image.new()
		# Aquí ya es 100% seguro: la ruta NO empieza con res://
		var err = img.load(clean_path) 
		
		if err == OK:
			return ImageTexture.create_from_image(img)
		else:
			EssenceError.report(
				"External Load Error", 
				"Failed to load image bytes from: %s" % clean_path, 
				EssenceError.Severity.WARNING
			)
	
	return _get_fallback(usar_imagen_error)
	
## Carga una textura decidiendo automáticamente si es interna (res://) o externa (disco)
static func smart_load_texture(path: String, use_fallback: bool = true) -> Texture2D:
	var clean_path = path.strip_edges()
	
	if clean_path == "" or clean_path == null:
		return _get_fallback(use_fallback)
	
	# === LÓGICA DE DECISIÓN ===
	
	# Si es interna, usamos el cargador de recursos nativo (Rápido y seguro para exportar)
	if clean_path.begins_with("res://"):
		if ResourceLoader.exists(clean_path):
			return load(clean_path) as Texture2D
		else:
			EssenceError.report("Resource Not Found", "Path: %s" % clean_path, EssenceError.Severity.WARNING)
			return _get_fallback(use_fallback)
	
	# Si llegamos aquí, forzosamente es externa (user:// o ruta absoluta)
	# Llamamos a get_externImage pero nos aseguramos de que no sea una ruta res://
	return get_externImage(clean_path, use_fallback)

# ==========================================
# UTILIDADES PRIVADAS
# ==========================================

# Extraemos la lógica del fallback a una función para no repetir código (Optimización DRY)
static func _get_fallback(usar_imagen_error: bool) -> Texture2D:
	if usar_imagen_error:
		return load(EssencePaths.INTERNAL_IMAGES[EssencePaths.KeyImage.ERROR_FALLBACK])
	return null
