class_name EssenceLoader extends RefCounted

const ES_NAME_CLASS = "EssenceLoader"

# ==========================================
# CARGADORES PRINCIPALES
# ==========================================

## Carga imágenes propias del Framework de forma segura
static func get_internImage(key: int) -> Texture2D:
	if EssencePaths.INTERNAL_IMAGES.has(key):
		var path = EssencePaths.INTERNAL_IMAGES[key]
		if ResourceLoader.exists(path):
			var loaded_tex = load(path) as Texture2D
			# Validamos que realmente sea una textura y no otro tipo de archivo
			if loaded_tex:
				return loaded_tex
	
	# Si llega aquí, o la llave no existe, o el archivo se borró, o no es una imagen.
	EssenceError.report(
		"Internal Image Missing", 
		"No se pudo cargar la imagen interna (Key: %s). Se usará Fallback." % key,
		EssenceError.Severity.WARNING
	)
	return _get_fallback(true)

## Carga bytes puros desde el disco duro (Modding / Externos)
static func get_externImage(ruta: String, usar_imagen_error: bool = true) -> Texture2D:
	var clean_path = ruta.strip_edges()
	
	# Usamos is_empty() en lugar de == "" por limpieza y rendimiento en Godot 4
	if clean_path.is_empty():
		return _get_fallback(usar_imagen_error)
	
	# === EL SEGURO (MÁXIMA PRIORIDAD) ===
	if clean_path.begins_with("res://"):
		var loaded_tex = load(clean_path) as Texture2D
		if loaded_tex: return loaded_tex
		return _get_fallback(usar_imagen_error)

	# === BLOQUE EXTERNO REAL ===
	if FileAccess.file_exists(clean_path):
		var img = Image.new()
		var err = img.load(clean_path) 
		
		if err == OK:
			return ImageTexture.create_from_image(img)
		else:
			EssenceError.report(
				"External Load Error", 
				"No se pudieron leer los bytes de la imagen en: %s" % clean_path, 
				EssenceError.Severity.WARNING
			)
			
	return _get_fallback(usar_imagen_error)
	
## Cargador inteligente que decide qué motor de carga usar
static func smart_load_texture(path: String, use_fallback: bool = true) -> Texture2D:
	var clean_path = path.strip_edges()
	
	if clean_path.is_empty():
		return _get_fallback(use_fallback)
	
	if clean_path.begins_with("res://"):
		if ResourceLoader.exists(clean_path):
			var loaded_tex = load(clean_path) as Texture2D
			if loaded_tex: return loaded_tex
			
		EssenceError.report("Resource Invalid", "La ruta nativa falló o no es una textura: %s" % clean_path, EssenceError.Severity.WARNING)
		return _get_fallback(use_fallback)
	
	return get_externImage(clean_path, use_fallback)

# ==========================================
# UTILIDADES PRIVADAS
# ==========================================

## Genera el reemplazo si algo falla. 
## ¡INCLUYE UN SEGURO DE VIDA GENERADO EN RAM!
static func _get_fallback(usar_imagen_error: bool) -> Texture2D:
	if not usar_imagen_error:
		return null
		
	# Intentamos cargar tu imagen de error oficial
	var fallback_path = EssencePaths.INTERNAL_IMAGES.get(EssencePaths.KeyImage.ERROR_FALLBACK, "")
	if not fallback_path.is_empty() and ResourceLoader.exists(fallback_path):
		var tex = load(fallback_path) as Texture2D
		if tex: return tex
		
	# TRUCO AAA (Seguro de Vida):
	# Si por alguna razón el desarrollador borró la imagen ERROR_FALLBACK.png de las carpetas,
	# Godot creará un cuadrado magenta (Placeholder) directamente en la memoria RAM 
	# para evitar que el juego explote por falta de textura.
	var emergency_placeholder = PlaceholderTexture2D.new()
	emergency_placeholder.size = Vector2(64, 64)
	
	EssenceLogger.system_error("[%s] CRITICAL: La imagen ERROR_FALLBACK no existe. Creando placeholder en RAM." % ES_NAME_CLASS)
	
	return emergency_placeholder