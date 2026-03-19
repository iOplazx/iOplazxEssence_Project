extends Control

@onready var boton_iniciar = $VBoxContainer/btnInit 
@onready var boton_salir = $VBoxContainer/btnExit 

func _ready():
	print("¡Bienvenido al Menú Principal!")
	
	# 1. Sacamos la canción de la caja fuerte (Tarda 0.0001 segundos)
	var cancion_menu = AudioManager.get_cached_audio("menu_theme")
	
	# 2. La reproducimos con tu transición suave
	if cancion_menu:
		AudioManager.play_music(cancion_menu, 2.0)
	
	boton_salir.pressed.connect(_cerrar_juego)

func _cerrar_juego():
	print("Cerrando el juego de forma segura...")
	get_tree().quit()
