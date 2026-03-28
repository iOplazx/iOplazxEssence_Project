class_name EssenceCreditsController extends Control

@export_category("UI Connections")
@export var btn_back: Button
@export var scroll_container: ScrollContainer 
@export var lbl_game: Label
@export var lbl_thanks: Label
@export var lbl_framework: Label

@export_category("Game Credits")
@export var game_title: String = "My Game Demo"
@export_multiline var game_credits: String = "Lead Developer:\nYour Name Here\n\nMusic:\nAudio Better Days"

@export_category("Special Thanks")
## Add donors, testers, or asset providers here
@export var special_thanks: Array[String] = []

@export_category("Scroll Settings")
## Speed of the automatic scrolling (pixels per second).
@export var auto_scroll_speed: float = 30.0
## Multiplicador de velocidad si el jugador mantiene presionado el click/espacio
@export var speed_multiplier: float = 4.0 

var _exact_scroll: float = 0.0
var _is_scrolling: bool = true

func _ready():
	_connect_buttons()
	_build_all_sections()

# Escuchamos si cambian el idioma para reconstruir los textos
func _notification(what):
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		_build_all_sections()

func _process(delta: float):
	if not _is_scrolling or auto_scroll_speed <= 0.0 or not scroll_container:
		return
		
	var current_speed = auto_scroll_speed
	
	# Si el jugador mantiene click izquierdo, Enter o Espacio, los créditos van más rápido
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or Input.is_action_pressed("ui_accept"):
		current_speed *= speed_multiplier
		
	_exact_scroll += current_speed * delta
	
	if _exact_scroll >= 1.0:
		var pixels_to_scroll = int(_exact_scroll)
		var v_scrollbar = scroll_container.get_v_scroll_bar()
		
		# Verificamos si ya tocamos el fondo de la pantalla
		if scroll_container.scroll_vertical >= v_scrollbar.max_value - scroll_container.size.y:
			_is_scrolling = false
			set_process(false) # Apagamos el _process para no gastar recursos a lo tonto
		else:
			scroll_container.scroll_vertical += pixels_to_scroll
			_exact_scroll -= pixels_to_scroll

func _connect_buttons():
	if btn_back:
		btn_back.pressed.connect(SceneManager.go_back)

func _build_all_sections():
	_load_game_section()
	_load_special_thanks()
	_load_framework_section()

func _load_game_section():
	var game_version = "v???"
	var game_const_path = "res://_static/GameConstants.gd"
	if ResourceLoader.exists(game_const_path):
		var const_script = load(game_const_path)
		if "GAME_VERSION" in const_script:
			game_version = const_script.GAME_VERSION
			
	if lbl_game:
		lbl_game.text = "--- " + game_title + " (" + game_version + ") ---\n\n"
		lbl_game.text += game_credits + "\n\n"

func _load_special_thanks():
	if lbl_thanks:
		if special_thanks.is_empty():
			lbl_thanks.hide() 
		else:
			lbl_thanks.show() # Nos aseguramos de mostrarlo por si estaba oculto
			var thanks_text = "--- " + tr("CREDITS_THANKS_TITLE") + " ---\n\n"
			for person in special_thanks:
				thanks_text += "• " + person + "\n"
			lbl_thanks.text = thanks_text + "\n\n"

func _load_framework_section():
	if lbl_framework:
		var fw_text = "--- " + tr("CREDITS_FRAMEWORK_TITLE") + " ---\n\n"
		fw_text += tr("CREDITS_DEVELOPED_WITH") + ":\n"
		fw_text += EssenceConstants.ENGINE_NAME + "\n"
		fw_text += tr("CREDITS_VERSION") + ": " + EssenceConstants.ENGINE_VERSION + "\n"
		fw_text += tr("CREDITS_UPDATED") + ": " + EssenceConstants.UPDATE_DATE
		lbl_framework.text = fw_text
