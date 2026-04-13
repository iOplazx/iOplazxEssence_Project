extends BootBase

## We inject custom tasks into the framework's loading screen
func inject_custom_tasks(loader: EssenceLoadingScreen) -> void:
	
	# We use a Lambda function (native to Godot 4) for a quick and clean injection
	loader.add_task(func():
		# 1. We demonstrate how to change the visual text of the loading screen
		loader.set_status_text("Loading demo audio assets...")
		
		# 2. We leave a record in the professional log
		EssenceLogger.system_info("[DemoBoot] Caching music into RAM...")
		
		# 3. We cache the song into the AudioManager's safe (preloading it for later use in the Main Menu)
		AudioManager.cache_audio("menu_theme", "res://demo/audio/better_days.ogg")
	)
