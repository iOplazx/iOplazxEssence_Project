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

## Carga imágenes del usuario (fuera del addon)
static func get_externImage(ruta: String, usar_imagen_error: bool = true) -> Texture2D:
	if ruta == "":
		return _get_fallback(usar_imagen_error)
	
	# === 1. RUTA INTERNA DEL MOTOR (res://) ===
	# Aquí usamos obligatoriamente load() nativo. Cero riesgo al exportar.
	if ruta.begins_with("res://"):
		if ResourceLoader.exists(ruta):
			return load(ruta) as Texture2D
		else:
			EssenceError.report(
				"Resource Not Found", 
				"Could not load internal image: %s" % ruta, 
				EssenceError.Severity.WARNING
			)
			return _get_fallback(usar_imagen_error)
			
	# === 2. RUTA EXTERNA REAL (user:// o C:/) ===
	# Aquí sí usamos Image.new().load() porque son archivos físicos fuera del juego
	if FileAccess.file_exists(ruta):
		var img = Image.new()
		var err = img.load(ruta) 
		
		if err == OK:
			return ImageTexture.create_from_image(img)
		else:
			EssenceError.report(
				"External Image Error", 
				"Failed to load raw image bytes from: %s. Code: %s" % [ruta, err], 
				EssenceError.Severity.WARNING
			)
			return _get_fallback(usar_imagen_error)
	
	# === 3. NO EXISTE LA RUTA EN NINGÚN LADO ===
	EssenceError.report(
		"Path Not Found", 
		"The image path does not exist: %s" % ruta, 
		EssenceError.Severity.WARNING
	)
	return _get_fallback(usar_imagen_error)

# ==========================================
# UTILIDADES PRIVADAS
# ==========================================

# Extraemos la lógica del fallback a una función para no repetir código (Optimización DRY)
static func _get_fallback(usar_imagen_error: bool) -> Texture2D:
	if usar_imagen_error:
		return load(EssencePaths.INTERNAL_IMAGES[EssencePaths.KeyImage.ERROR_FALLBACK])
	return null
