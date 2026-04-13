class_name EssenceSaveFactory

static func create_save_instance(config: EssenceMasterConfig) -> EssenceSaveData:
	# 1. ¿El desarrollador proporcionó su propio "hijo"?
	if config and config.custom_save_script:
		return config.custom_save_script.new()
	
	# 2. Si no hay configuración o la dejó vacía, usamos al Padre directamente.
	# ¡Cero rutas de archivos propensas a romperse!
	#print("iOplazxEssence: Usando EssenceSaveData base (No se detectó script personalizado).")
	EssenceLogger.system_info("EssenceSaveFactory: No custom save script detected. Using base EssenceSaveData.")
	return EssenceSaveData.new()
