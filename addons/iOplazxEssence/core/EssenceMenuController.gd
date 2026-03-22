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
		# Llamamos a la función unificada que gestiona panel + cascade
		_animar_entrada_ui_botones()
		
	_iniciar_foco_teclado()

func _conectar_botones():
	# Solo conectamos los botones que el usuario decidió usar (haciéndolo modular)
	if btn_new_game: 
		btn_new_game.pressed.connect(_on_new_game_pressed)
	if btn_continue: 
		btn_continue.pressed.connect(_on_continue_pressed)
	if btn_load: 
		btn_load.pressed.connect(_on_continue_pressed)
	if btn_settings: 
		btn_settings.pressed.connect(_on_settings_pressed)
	if btn_credits:
		btn_credits.pressed.connect(_on_credits_pressed)
	if btn_exit: 
		btn_exit.pressed.connect(_on_exit_pressed)


func _verificar_estado_partida():
	# TODO: Conectar esto con el EssenceSaveManager en el futuro.
	# Por ahora, simulamos que NO hay archivo de guardado.
	var has_save_file = false 
	
	if btn_continue:
		btn_continue.disabled = not has_save_file
	if btn_load:
		btn_load.disabled = not has_save_file
		
func _iniciar_foco_teclado():
	if first_focus_button:
		# Le damos el foco al botón. Si el botón entra con delay (cascada), 
		# no pasa nada, Godot lo recuerda.
		first_focus_button.grab_focus()

# ==========================================
# FUNCIONES DE ACCIÓN (Lógica del Framework)
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
	print("Cerrando motor desde el menú...")
	get_tree().quit()
	
# ==========================================
# EFECTOS VISUALES LIGEROS (TWEENS)
# ==========================================

func _animar_entrada_botones():
	var delay = 0.0
	var botones = [btn_new_game, btn_continue, btn_settings, btn_exit]
	
	for btn in botones:
		if btn:
			# Empezamos totalmente transparentes
			btn.modulate.a = 0.0 
			var tween = create_tween()
			# Aparecen en 0.4 segundos, pero cada botón se espera un poco más que el anterior
			tween.tween_property(btn, "modulate:a", 1.0, 0.4).set_delay(delay)
			delay += 0.15

# Función genérica para manejar el estado de las animaciones del título
func _iniciar_animaciones_titulo():
	# Primero, configuramos el estado inicial basado en la animación de entrada
	match entrance_anim_type:
		EntranceAnimation.NONE:
			title_container.modulate.a = 1.0
			_iniciar_animacion_idle() # Saltamos directo al idle
		EntranceAnimation.FADE_IN:
			title_container.modulate.a = 0.0
			_tween_entrance_fade()
		EntranceAnimation.SLIDE_FROM_TOP:
			title_container.modulate.a = 1.0
			# Mueve el pivote al centro para el slide si el layout no lo hace
			title_container.pivot_offset = title_container.size / 2.0
			var original_y = title_container.position.y
			title_container.position.y -= slide_distance
			_tween_entrance_slide(original_y)

# Animaciones de Entrada (Finite Tweens)
func _tween_entrance_fade():
	var tween = create_tween()
	# Un fade-in suave
	tween.tween_property(title_container, "modulate:a", 1.0, entrance_duration).set_trans(Tween.TRANS_SINE)
	# Al terminar la entrada, empezamos el idle
	tween.finished.connect(_iniciar_animacion_idle)

func _tween_entrance_slide(target_y: float):
	var tween = create_tween()
	# Un deslizamiento con "rebote" (TRANS_BACK) al final para que se vea más pro
	tween.tween_property(title_container, "position:y", target_y, entrance_duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	# Al terminar la entrada, empezamos el idle
	tween.finished.connect(_iniciar_animacion_idle)

# Animaciones Idle (Bucle)
func _iniciar_animacion_idle():
	match idle_anim_type:
		IdleAnimation.NONE:
			pass
		IdleAnimation.BREATHING:
			_tween_idle_breathing()

func _tween_idle_breathing():
	# Matamos cualquier tween idle previo para evitar duplicados si se recarga la escena
	if _idle_tween and _idle_tween.is_running():
		_idle_tween.kill()

	# Aseguramos pivote en el centro
	title_container.pivot_offset = title_container.size / 2.0
	
	# Creamos un Tween infinito
	_idle_tween = create_tween().set_loops()
	# Escala al 105% en la mitad del ciclo con curva suave
	_idle_tween.tween_property(title_container, "scale", Vector2(1.05, 1.05), idle_duration).set_trans(Tween.TRANS_SINE)
	# Regresa a la escala normal
	_idle_tween.tween_property(title_container, "scale", Vector2(1.0, 1.0), idle_duration).set_trans(Tween.TRANS_SINE)

func _animar_entrada_ui_botones():
	# Primero, animamos el panel si existe (Fade In suave)
	if buttons_panel:
		var panel_tween = create_tween()
		# Hacemos que el panel aparezca en 0.4s
		panel_tween.tween_property(buttons_panel, "modulate:a", 1.0, 0.4).set_trans(Tween.TRANS_SINE)
		
		# Esperamos a que el panel casi termine para empezar la cascada
		# Esto hace la transición más fluida
		_lanzar_cascada_botones(0.5) 
	else:
		# Si no hay panel, lanzamos la cascada de botones inmediatamente
		_lanzar_cascada_botones(0.0)

# Solo maneja la cascada de botones
func _lanzar_cascada_botones(start_delay: float):
	var cascade_delay = start_delay
	var button_duration = 0.4
	var button_stagger = 0.15
	var botones = [btn_new_game, btn_continue, btn_load, btn_settings, btn_credits, btn_exit]
	
	for btn in botones:
		if btn:
			# Ya está en opacidad 0 por _ready, solo hacemos tween de aparición
			var btn_tween = create_tween()
			btn_tween.tween_property(btn, "modulate:a", 1.0, button_duration).set_delay(cascade_delay).set_trans(Tween.TRANS_SINE)
			cascade_delay += button_stagger
