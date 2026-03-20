extends EssenceMenuController

# Precargamos la canción (asumiendo que sigues usando la "Caja Fuerte")
# Nota: Si el Boot ya la cargó en la RAM, no necesitas precargarla aquí, solo llamarla.

func _ready():
	# 1. Llamamos al _ready del "Cerebro" (EssenceMenuController) para que él conecte los botones que pusiste en el Inspector
	super._ready() 
	
	print("Demo: ¡Bienvenido al Menú Principal!")
	
	# 2. Sacamos la canción de la caja fuerte y la reproducimos
	var cancion_menu = AudioManager.get_cached_audio("menu_theme")
	if cancion_menu:
		AudioManager.play_music(cancion_menu, 2.0)

# ¡Y listo! Puedes borrar la función _cerrar_juego() porque el EssenceMenuController ya la tiene adentro.
