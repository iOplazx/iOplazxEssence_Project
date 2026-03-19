extends Control

# Asegúrate de que los nombres coincidan con los nodos que creaste
@onready var boton_iniciar = $VBoxContainer/btnInit 
@onready var boton_salir = $VBoxContainer/btnExit 

func _ready():
	print("¡Bienvenido al Menú Principal!")
	
	# Conectamos el botón de salir directamente a la función de cerrar el motor
	boton_salir.pressed.connect(_cerrar_juego)

func _cerrar_juego():
	print("Cerrando el juego de forma segura...")
	get_tree().quit()
