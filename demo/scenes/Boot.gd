extends BootBase

func inject_custom_tasks(loader: EssenceLoadingScreen):
	# Añadimos la tarea a la cola
	loader.add_task(Callable(self, "load_audio_assets"))

func load_audio_assets():
	print("Demo: Subiendo música a la memoria RAM...")
	# Metemos la canción en la caja fuerte del AudioManager con la llave "menu_theme"
	AudioManager.cache_audio("menu_theme", "res://demo/audio/better_days.mp3")
