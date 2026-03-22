class_name EssenceCreditsController extends Control

@export_category("Conexiones UI")
@export var btn_back: Button
@export var lbl_game: Label
@export var lbl_thanks: Label
@export var lbl_framework: Label

@export_category("Créditos del Juego")
@export var game_title: String = "Mi Juego Demo"
@export_multiline var game_credits: String = "Desarrollador Principal:\nTu Nombre Aquí\n\nMúsica:\nAudio Better Days"

@export_category("Agradecimientos")
## Añade aquí a donadores, testers o proveedores de recursos
@export var special_thanks: Array[String] = []

func _ready():
	_conectar_botones()
	_cargar_seccion_juego()
	_cargar_agradecimientos()
	_cargar_seccion_framework()

func _conectar_botones():
	if btn_back:
		# ¡Usamos a nuestro Taxista!
		btn_back.pressed.connect(SceneManager.go_back)

func _cargar_seccion_juego():
	var game_version = "v???"
	# Cargamos dinámicamente las constantes del static por si el usuario movió el archivo
	var game_const_path = "res://_static/GameConstants.gd"
	if ResourceLoader.exists(game_const_path):
		var const_script = load(game_const_path)
		if "GAME_VERSION" in const_script:
			game_version = const_script.GAME_VERSION
			
	if lbl_game:
		lbl_game.text = "--- " + game_title + " (" + game_version + ") ---\n\n"
		lbl_game.text += game_credits + "\n\n"

func _cargar_agradecimientos():
	if lbl_thanks:
		if special_thanks.is_empty():
			lbl_thanks.hide() # Si no hay nadie, ocultamos la sección
		else:
			var thanks_text = "--- Agradecimientos Especiales ---\n\n"
			for person in special_thanks:
				thanks_text += "• " + person + "\n"
			lbl_thanks.text = thanks_text + "\n\n"

func _cargar_seccion_framework():
	if lbl_framework:
		var fw_text = "--- Framework ---\n\n"
		fw_text += "Desarrollado sobre:\n"
		fw_text += EssenceConstants.ENGINE_NAME + "\n"
		fw_text += "Versión: " + EssenceConstants.ENGINE_VERSION + "\n"
		fw_text += "Actualización: " + EssenceConstants.UPDATE_DATE
		lbl_framework.text = fw_text
