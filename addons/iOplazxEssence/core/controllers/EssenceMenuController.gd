class_name EssenceMenuController extends Control

# Enums para los tipos de animación (Crea casillas seleccionables en el Inspector)
enum EntranceAnimation { NONE, FADE_IN, SLIDE_FROM_TOP }
enum IdleAnimation { NONE, BREATHING }

@export_category("Conexión de Botones (UI)")
@export var btn_new_game: Button
@export var btn_continue: Button
@export var btn_load: Button
@export var btn_settings: Button
@export var btn_credits: Button
@export var btn_exit: Button

@export_subgroup("Configuración de Navegación")
## El botón que estará seleccionado por defecto para el teclado/mando
@export var first_focus_button: Control

@export_category("Efectos Visuales (Juice)")
@export_subgroup("Configuración de Botones") 
## Activa una aparición coordinada de los botones al iniciar
@export var animate_buttons_entrance: bool = true
## (Opcional) El panel que contiene los botones. Si se asigna, aparecerá antes que los botones.
@export var buttons_panel: Control 

@export_subgroup("Configuración del Título")
## Asigna el nodo del Título aquí (TextureRect, Label, etc.)
@export var title_container: Control 
## Tipo de animación de entrada para el título
@export var entrance_anim_type: EntranceAnimation = EntranceAnimation.FADE_IN
## Duración de la animación de entrada (segundos)
@export var entrance_duration: float = 0.5
## Distancia para la animación de 'Slide From Top'
@export var slide_distance: float = 100.0
## Tipo de animación idle (bucle) para el título
@export var idle_anim_type: IdleAnimation = IdleAnimation.BREATHING
## Duración de un ciclo de la animación idle (segundos)
@export var idle_duration: float = 1.5

# Variable interna para gestionar el tween idle
var _idle_tween: Tween

func _ready():
	print("EssenceMenuController: Inicializando menú principal...")
	_conectar_botones()
	_verificar_estado_partida()
	
	if animate_buttons_entrance:
		if buttons_panel:
			buttons_panel.modulate.a = 0.0
		var botones = [btn_new_game, btn_continue, btn_load, btn_settings, btn_credits, btn_exit]
		for btn in botones:
			if btn:
				btn.modulate.a = 0.0
	
	if title_container:
		_iniciar_animaciones_titulo()

	if animate_buttons_entrance:
		_animar_entrada_ui_botones()
		
	_setup_ui_sounds()
	_iniciar_foco_teclado()

func _conectar_botones():
	if btn_new_game: btn_new_game.pressed.connect(_on_new_game_pressed)
	if btn_continue: btn_continue.pressed.connect(_on_continue_pressed)
	if btn_load: btn_load.pressed.connect(_on_load_pressed) 
	if btn_settings: btn_settings.pressed.connect(_on_settings_pressed)
	if btn_credits: btn_credits.pressed.connect(_on_credits_pressed)
	if btn_exit: btn_exit.pressed.connect(_on_exit_pressed)

func _verificar_estado_partida():
	# TODO: Conectar esto con el EssenceSaveManager en el futuro.
	var has_save_file = false 
	
	if btn_continue:
		btn_continue.disabled = not has_save_file
	#if btn_load:
	#	btn_load.disabled = not has_save_file
		
func _iniciar_foco_teclado():
	if first_focus_button:
		first_focus_button.grab_focus()
		
# ==========================================
# LÓGICA DE AUDIO DE INTERFAZ (OPTIMIZADA)
# ==========================================
func _setup_ui_sounds():
	var group_buttons = [btn_new_game, btn_continue, btn_load, btn_settings, btn_credits, btn_exit]
	
	for btn in group_buttons:
		if btn:
			btn.mouse_entered.connect(_play_hover_ui)
			btn.focus_entered.connect(_play_hover_ui)
			btn.pressed.connect(_play_click_ui)

func _play_hover_ui():
	var pitch = randf_range(0.95, 1.05)
	# Le pasamos null al principio para que el AudioManager decida el tema,
	# y luego le pasamos nuestro pitch dinámico.
	AudioManager.play_ui_sfx(null, pitch)

func _play_click_ui():
	# Llamamos a la función global. El AudioManager sabrá qué tema usar basándose
	# en los ajustes guardados por el jugador.
	AudioManager.play_ui_sfx()

# ==========================================
# FUNCIONES DE ACCIÓN
# ==========================================

func _on_new_game_pressed():
	SceneManager.goto_new_game()

func _on_continue_pressed():
	SceneManager.goto_continue_game()
	
func _on_load_pressed():
	print("Opening Load Game screen...")
	SceneManager.goto_load_game()

func _on_settings_pressed():
	SceneManager.goto_settings()
	
func _on_credits_pressed():
	SceneManager.goto_credits()

func _on_exit_pressed():
	AudioManager.play_ui_sfx()
	SceneManager.request_quit() # Que llame al diálogo normal
	
# ==========================================
# EFECTOS VISUALES (Usando nuestra biblioteca global)
# ==========================================

func _iniciar_animaciones_titulo():
	var tween_entrada: Tween
	
	match entrance_anim_type:
		EntranceAnimation.NONE:
			title_container.modulate.a = 1.0
			_iniciar_animacion_idle() 
		EntranceAnimation.FADE_IN:
			tween_entrada = EssenceUIAnimator.fade_in(title_container, entrance_duration)
		EntranceAnimation.SLIDE_FROM_TOP:
			tween_entrada = EssenceUIAnimator.slide_from_top(title_container, slide_distance, entrance_duration)
			
	# Si hubo animación de entrada, conectamos el idle al terminar
	if tween_entrada:
		tween_entrada.finished.connect(_iniciar_animacion_idle)

func _iniciar_animacion_idle():
	if idle_anim_type == IdleAnimation.BREATHING:
		# Guardamos la referencia por si necesitamos matarla al cambiar de menú
		_idle_tween = EssenceUIAnimator.breathing(title_container, idle_duration)

func _animar_entrada_ui_botones():
	var cascade_start = 0.0
	
	if buttons_panel:
		EssenceUIAnimator.fade_in(buttons_panel, 0.4)
		cascade_start = 0.5 # Le damos tiempo al panel para aparecer
		
	var botones = [btn_new_game, btn_continue, btn_load, btn_settings, btn_credits, btn_exit]
	EssenceUIAnimator.cascade_fade_in(botones, 0.4, 0.15, cascade_start)
