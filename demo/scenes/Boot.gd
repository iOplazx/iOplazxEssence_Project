extends BootBase

func inject_custom_tasks(loader: EssenceLoadingScreen):
	# Tus tareas específicas de este juego
	loader.add_task(Callable(self, "load_player_data"))
	loader.add_task(Callable(self, "connect_to_server"))

func load_player_data():
	print("Demo: Cargando los datos del jugador desde el disco...")

func connect_to_server():
	print("Demo: Conectando al servidor multijugador...")
