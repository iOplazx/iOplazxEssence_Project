class_name TestMainGame
extends Control 

# ==
# TestMainGame.tscn
# ==
# TestMainGame (TestMainGame) [Script: TestMainGame]
# ├── ColorRect (ColorRect)      
# ├── BackgroundLayer (TextureRect)                     
# ├── GameplayDirector (EssenceGameplayDirector)   
# │   ├── EnviromentFilter (CanvasModulate)           
# │   ├── ActiveLocation (Node2D)    
# │   ├── CharacterStage (Node2D) 
# │   ├── ItemStage (Node2D)      
# │   └── HUD_Layer (CanvasLayer) 
# │       ├── TranslationManager (Node)   
# │       ├── EssenceDialogBox (EssenceDialogBox)              
# │       └── FadeOverlay (ColorRect)                           
# ├── TutorialPanelUI (EssenceTutorialPanel)    
# └── PanelControles (Panel)   
#     └── ...   
# ==

const ES_NAME_CLASS = "TestMainGame"

# ==========================================
# FLOW MANAGEMENT
# ==========================================
enum TestPhase { INTRO, GAMEPLAY }
var current_phase: TestPhase = TestPhase.INTRO

# ==========================================
# UI AND WORLD CONNECTIONS
# ==========================================
@export_category("UI Connections")
@export var background_layer: TextureRect
@export var btn_return: Button
@export var btn_save: Button
@export var btn_load: Button
@export var tutorial_panel: EssenceTutorialPanel 
@export var ui_principal: Control 

# We use % instead of $ for instant access, regardless of hierarchy.
@onready var director: EssenceGameplayDirector = %GameplayDirector
@onready var item_stage_container: Node2D = %GameplayDirector/ItemStage

const ROUTES_PATH = "res://_static/RouteConfig.tres"
var routes: EssenceRouteConfig

var _cached_interaction_menu: EssenceBaseInteractionMenu = null

# Global variable to track the current numeric room ID
var current_room_id: int = GameIDs.RoomID.INITIAL_ROOM
# Example dictionary to simulate your story's conditions (Flags)
var story_flags: Dictionary = {
	"is_phone_event_active": false,   # The condition in your phone example
	"is_first_time_here": true,
	
	# PERSISTENT WARDROBE SYSTEM
	# This holds the true state of the player's clothing across saves and room switches.
	"player_wardrobe": {
		IDsGIC.Items.HAT_1: false,
		IDsGIC.Items.SUNGLASS_1: false
	}
}

#####################################################
# SECTION declaration of characters and items tscn  #
#####################################################
var active_character: GenericInteractiveCharacter = null

## Array to massively clean all floating elements when changing rooms
var spawned_items_in_room: Array[Node2D] = []

## Array to keep track of active background and secondary actors for clean garbage collection.
var _spawned_actors_in_room: Array[Node2D] = []

var current_interactive_loc: EssenceInteractiveLocation = null

######################################
# SECTION (ALL SCENES IN THIS TSCN)  #
######################################

# ==========================================
# INITIALIZATION
# ==========================================
func _ready() -> void:
	director.clear_character_stage()
	director.clear_item_stage()
	
	# Connect the signal for when the tutorial closes
	if tutorial_panel:
		tutorial_panel.tutorial_finished.connect(_on_tutorial_finished)
		
	_load_configuration()
	_check_security_nodes()
	_config_buttons()
	
	# 2. We check whether we are coming from loading a game or from pressing "Back" in the menu.
	if is_instance_valid(SaveManager) and not SaveManager.loaded_game_data.is_empty():
		# We go straight into the restore system.
		_restaurar_partida_cargada()
	else:
		# If it is a 100% new game: start the clock from 0.0.
		var main_loop: SceneTree = Engine.get_main_loop() as SceneTree
		if is_instance_valid(main_loop) and main_loop.root.has_node("TimeManager"):
			var tm = main_loop.root.get_node("TimeManager")
			tm.stop_clock()   # Resets to 0.0
			tm.start_clock()  # Start accumulating delta
		
		# Get real data from the initial room and build the scene
		var initial_data = LevelManager.get_scenery_config(GameIDs.RoomID.INITIAL_ROOM, GameIDs.RoomID.INITIAL_ROOM, 0, true)
		_route_room_initialization(GameIDs.RoomID.INITIAL_ROOM, initial_data, true)
		
		var fade = director.open_curtain(0.4)
		if fade: await fade.finished
		
		_iniciar_secuencia_intro()
		
	EssenceLogger.system_info("[%s/_ready] Main scene initialized." % ES_NAME_CLASS)
	
## Load the .tres file into memory
func _load_configuration() -> void:
	if ResourceLoader.exists(ROUTES_PATH):
		routes = load(ROUTES_PATH) as EssenceRouteConfig
	else:
		EssenceReportUtils.critical(
			"Resource Error",
			"RouteConfig.tres was not found at path: %s in %s." % [ROUTES_PATH, ES_NAME_CLASS]
		)
		
# ==========================================
# FLOW LOGIC (TUTORIALS AND EVENTS)
# ==========================================

func _iniciar_secuencia_intro() -> void:
	current_phase = TestPhase.INTRO
	director.change_game_state(EssenceGameplayDirector.GameState.CUTSCENE)
	
	await get_tree().create_timer(0.3).timeout
	
	# Direct and clean invocation via the Director
	await director.show_modal_prompt(
		"Notice",
		"This is strictly a controls test and technical demo for the iOplazxEssence addon, not the actual game.",
		EssenceBaseModalPrompt.ButtonPreset.OK
	)
	
	# 2. STEP 2: Multi-page tutorial (if available)
	if tutorial_panel:
		var intro_messages: Array[String] = [
			"Welcome to the Essence Framework sandbox.",
			"Here we will test the rendering, saving systems, and interactive actors.",
			"Click 'Understood' to begin the test."
		]
		tutorial_panel.load_and_show_tutorial(intro_messages)
	else:
		director.change_game_state(EssenceGameplayDirector.GameState.EXPLORATION)
		
func _setup_initial_room_layout():
	director.clear_item_stage()

## Callback triggered when the intro tutorial panel is closed.
func _on_tutorial_finished() -> void:
	if current_phase == TestPhase.INTRO:
		#print("[%s] Tutorial Intro terminado. Esperando cierre de UI..." % ES_NAME_CLASS)
		current_phase = TestPhase.GAMEPLAY
		
		story_flags["is_first_time_here"] = false
		story_flags["room_mode_" + str(current_room_id)] = 1
		
		await get_tree().create_timer(0.6).timeout 
		
		# Clean transition to Mode 1 (Activates exploration, floating items, and interactions)
		set_room_interaction_mode(1)
		
		if director:
			director.change_game_state(EssenceGameplayDirector.GameState.EXPLORATION)
			
	elif current_phase == TestPhase.GAMEPLAY:
		print("[%s] Second tutorial completed successfully by the player." % ES_NAME_CLASS)
		story_flags["has_completed_touch_tutorial"] = true
			
# ==========================================
# S,ECURITY ARMORING
# ==========================================
func _check_security_nodes() -> void:
	var missing = []
	if not btn_return: missing.append("btn_return")
	if not btn_save: missing.append("btn_save")
	if not btn_load: missing.append("btn_load")
	if not tutorial_panel: missing.append("tutorial_panel")
	
	if missing.size() > 0:
		var msg = "Faltan nodos exportados en %s: %s" % [ES_NAME_CLASS, ", ".join(missing)]
		EssenceReportUtils.warning("UI Setup Warning", msg)

# ==========================================
# CONFIGURATION
# ==========================================
func _config_buttons() -> void:
	if btn_return: btn_return.pressed.connect(func(): _play_sfx(); _on_return_pressed())
	if btn_save: btn_save.pressed.connect(func(): _play_sfx(); _on_btn_save_pressed())
	if btn_load: btn_load.pressed.connect(func(): _play_sfx(); _on_btn_load_pressed())


func _play_sfx() -> void:
	if is_instance_valid(AudioManager) and AudioManager.has_method("play_ui_sfx"):
		AudioManager.play_ui_sfx()

# ==========================================
# SAVE/LOAD LOGIC
# ==========================================
func _preparar_datos_para_menu() -> void:
	EssenceLogger.system_info("[%s] Capturing screenshot and preparing menu state..." % ES_NAME_CLASS)
	
	await get_tree().process_frame
	await SaveManager.take_temp_screenshot()
	await get_tree().create_timer(0.1).timeout
	
	var current_playtime: float = EssenceTimeUtils.get_playtime_seconds()
	
	# ==========================================
	# INTERFACE / CACHE DICTIONARY (STANDARDIZED)
	# ==========================================
	var current_game_data: Dictionary = {
		GameSaveKeys.CURRENT_SCENE: "MainRoom",
		GameSaveKeys.CURRENT_PHASE: current_phase,
		GameSaveKeys.CURRENT_ROOM: current_room_id,
		GameSaveKeys.STORY_FLAGS: story_flags,
		GameSaveKeys.CHARACTER_CLOTHING_STATE: active_character.get_clothing_state() if is_instance_valid(active_character) else {},
		GameSaveKeys.PLAYTIME_SECONDS: current_playtime
	}
	
	# OBTENER EL NOMBRE REAL DESDE EL ESCENARIO VISUAL ACTIVO
	var current_loc: EssenceLocation = director.get_current_location() if is_instance_valid(director) else null
	var room_name: String = "Unknown Room"
	
	if is_instance_valid(current_loc) and not current_loc.location_name.is_empty():
		room_name = current_loc.location_name
	else:
		var room_key: String = GameIDs.RoomID.find_key(current_room_id)
		if not room_key.is_empty():
			room_name = room_key.capitalize().replace("_", " ")
	
	var current_meta_data: Dictionary = {
		"title": "Framework Test",
		"description": "Place: %s | Phase: %s" % [room_name, ("Intro" if current_phase == TestPhase.INTRO else "Gameplay")],
		GameSaveKeys.META_PLAYTIME: EssenceTimeUtils.format_seconds(current_playtime)
	}
	
	SaveManager.cache_current_state(current_game_data, current_meta_data)
	
func _restaurar_partida_cargada() -> void:
	#print("[%s] Restaurando datos cargados." % ES_NAME_CLASS)
	var datos = SaveManager.loaded_game_data
	
	# 1. Recover standardized state keys
	current_phase = int(datos.get(GameSaveKeys.CURRENT_PHASE, 0)) as TestPhase
	var room_saved_id: int = int(datos.get(GameSaveKeys.CURRENT_ROOM, GameIDs.RoomID.INITIAL_ROOM))
	
	if datos.has(GameSaveKeys.STORY_FLAGS):
		story_flags = datos.get(GameSaveKeys.STORY_FLAGS).duplicate()
	
	# The engine stabilizes. The player sees only black because we force Color.BLACK in `_ready` or in the Director.
	# Engine frame stabilization
	await get_tree().process_frame 
	
	if current_phase == TestPhase.GAMEPLAY:
		if tutorial_panel: tutorial_panel.visible = false 
		director.change_game_state(EssenceGameplayDirector.GameState.EXPLORATION)
		current_room_id = room_saved_id
		
		var room_data = LevelManager.get_scenery_config(room_saved_id, room_saved_id, 1, true)
		
		if not room_data["flag_error"]:
			# FIXED: Delegating routing and dynamically supporting the PARK scene lifecycle
			_route_room_initialization(room_saved_id, room_data, true)
		
		if is_instance_valid(active_character):
			var ropa_guardada = datos.get(GameSaveKeys.CHARACTER_CLOTHING_STATE, {})
			active_character.apply_clothing_state(ropa_guardada)
			
	else:
		# INTRO PHASE: Load clean initial scenario
		var initial_data = LevelManager.get_scenery_config(GameIDs.RoomID.INITIAL_ROOM, GameIDs.RoomID.INITIAL_ROOM, 0, true)
		_route_room_initialization(GameIDs.RoomID.INITIAL_ROOM, initial_data, true)
		_iniciar_secuencia_intro()
	
	# 2. RESTORE AND RESUME PLAYTIME CLOCK
	var restored_seconds: float = float(datos.get(GameSaveKeys.PLAYTIME_SECONDS, 0.0))
	var main_loop: SceneTree = Engine.get_main_loop() as SceneTree
	if is_instance_valid(main_loop) and main_loop.root.has_node("TimeManager"):
		var tm: Node = main_loop.root.get_node("TimeManager")
		if tm.has_method("set_playtime"):
			tm.set_playtime(restored_seconds)
		if tm.has_method("start_clock"):
			tm.start_clock()
		
	# We clear the cache immediately to leave the loader ready for the next time.
	# 3. Clear temporary cache for the next cycle
	SaveManager.loaded_game_data.clear()
	
	# We open the curtain automatically and flawlessly.
	# 4. Open visual curtain
	var fade_in = director.open_curtain(0.5)
	if fade_in: 
		await fade_in.finished
		
	EssenceLogger.system_info("[%s] Restoration complete. Playtime set to: %s" % [
		ES_NAME_CLASS, 
		EssenceTimeUtils.format_seconds(restored_seconds)
	])

## Helper interno para congelar el reloj de forma segura
func _pause_gameplay_clock() -> void:
	var main_loop: SceneTree = Engine.get_main_loop() as SceneTree
	if is_instance_valid(main_loop) and main_loop.root.has_node("TimeManager"):
		var tm = main_loop.root.get_node("TimeManager")
		if tm.has_method("pause_clock"):
			tm.pause_clock()

# ==========================================
# EVENTOS DE BOTONES
# ==========================================
func _on_btn_save_pressed() -> void:
	# Freeze the clock before capturing the state and switching screens.
	_pause_gameplay_clock()
	
	if ui_principal: ui_principal.visible = false
	await _preparar_datos_para_menu()
	if is_instance_valid(SceneManager):
		SceneManager.goto_save_game(SceneManager.TransitionType.INSTANT)

func _on_btn_load_pressed() -> void:
	# Freeze the clock
	_pause_gameplay_clock()
	
	await _preparar_datos_para_menu()
	if is_instance_valid(SceneManager):
		SceneManager.goto_load_game(SceneManager.TransitionType.INSTANT)

func _on_return_pressed() -> void:
	if is_instance_valid(SceneManager):
		SceneManager.goto_main_menu()

## Triggered when the user performs a physical left-click interaction over the active character.
func _on_character_interacted() -> void:
	# GUARD: If not in exploration mode (i.e., in a cutscene or dialogue), ignore clicks.
	if director.current_state != EssenceGameplayDirector.GameState.EXPLORATION:
		return
	if not is_instance_valid(active_character): 
		return
		
	# DEBOUNCE ANTI-SPAM PROTECTION: 
	# Rejects character interaction if the menu layer is active or playing a transition.
	if is_instance_valid(_cached_interaction_menu):
		if _cached_interaction_menu.visible or _cached_interaction_menu.is_animating:
			return
	
	# 1. VALIDATION LAYER
	if current_phase == TestPhase.GAMEPLAY and active_character.is_interactable:
		
		# 2. STATE CHECK (Initial transition to Mode 2 on the first click of the game)
		if not story_flags.get("has_touched_character", false):
			story_flags["has_touched_character"] = true
			story_flags["room_mode_" + str(current_room_id)] = 2
			
			var data = LevelManager.get_scenery_config(current_room_id, current_room_id, 2, true)
			if not data["flag_error"]:
				_apply_interaction_state(data["interaction_mode"])
				director.clear_item_stage()
				_build_stage_interactables(current_room_id, data["interaction_mode"])
		
		# 3. INTERACTION FLOW (The menu ALWAYS opens)
		# This ensures the player always sees the orange triangle animation.
		_open_interaction_menu()
		
		# 4. TUTORIAL LAYER (Conditional)
		# If the second tutorial has NOT been completed, we open the explanatory panel on top.
		if not story_flags.get("has_completed_touch_tutorial", false):
			_trigger_character_tutorial()

## Launches the specific wardrobe and saving system tutorial overlay.
func _trigger_character_tutorial() -> void:
	if tutorial_panel:
		var interaction_messages: Array[String] = [
			"Character Interaction Detected!",
			"Try removing some of my clothes using the Inspector, or via code.",
			"Then, save the game and load it to verify the Wardrobe System."
		]
		tutorial_panel.load_and_show_tutorial(interaction_messages)
		
## Prepares the options and deploys the menu by loading it dynamically if it does not exist in memory.
func _open_interaction_menu() -> void:
	# 1. PERFORMANCE OPTIMIZATION LAYER: If the menu hasn't been instantiated yet, load it at runtime
	if not is_instance_valid(_cached_interaction_menu):
		print("[%s] First-time interaction detected. Loading interface from disk..." % ES_NAME_CLASS)
		
		# Read the constant path exactly like we do with character templates
		var menu_route: String = EssencePaths.MENU_HEXAGONAL_INTERFACE
		var menu_resource: PackedScene = load(menu_route) as PackedScene
		
		if menu_resource:
			# Instantiate the node and dynamically append it to the HUD layer
			_cached_interaction_menu = menu_resource.instantiate() as EssenceBaseInteractionMenu
			$GameplayDirector/HUD_Layer.add_child(_cached_interaction_menu)
			
			# Connect its centralized notification signal to the Main script receiver
			_cached_interaction_menu.action_selected.connect(_on_menu_action_selected)
		else:
			EssenceReportUtils.critical(
				"Interface Error",
				"Failed to load the interaction menu resource in %s." % ES_NAME_CLASS
			)
			return

	# 2. DATA-DRIVEN ACTION INTERFACE CONFIGURATION
	var datos_acciones: Array = [
		[
			{"id": "talk", "descripcion": "Talk to the character", "icono": null},
			{"id": "examine", "descripcion": "Inspect clothing", "icono": null},
			{"id": "wardrobe", "descripcion": "Change outfit", "icono": EssencePaths.ICON_SHIRT},
			{"id": "stretch", "descripcion": "Stretch arms", "icono": null}
		],
		# PÁGINA 2
		[
			{"id": "atmosphere", "descripcion": "Toggle Atmosphere", "icono": null}
		]
	]
	
	# 3. MENU FLOW EXECUTION
	# The menu node now safely exists within the HUD layer; populate data and invoke its animation sequence.
	_cached_interaction_menu.configure_menu(datos_acciones)
	_cached_interaction_menu.open_menu(get_global_mouse_position())


## Callback receiver for the interaction menu selection signal. Processes the corresponding action logic.
func _on_menu_action_selected(action: String) -> void:
	#print("[%s] Processing menu action: %s" % [ES_NAME_CLASS, action])
	
	match action:
		"talk":
			print("-> Invocando diálogo desde el GameplayDirector...")
			
			if is_instance_valid(director):
				director.play_dialogue([
					{
						"speaker": active_character.display_name if "display_name" in active_character else "Protagonist",
						"text": "This is a test."
					},
					{
						"speaker": "Narrator",
						"text": "Yes, it's a test."
					}
				])
		"examine":
			print("-> Player is examining the character. Launching shirt minigame...")
			
			if is_instance_valid(director):
				# 1. Launch the minigame scene and wait for completion
				var minigame_path: String = DemoItemsRoute.TEST_SHIRT_MINIGAME_SCENE
				var result: Dictionary = await director.launch_minigame(minigame_path)
				
				# 2. If the player won the minigame, show the success modal prompt
				if result.get("victory", false):
					await director.show_modal_prompt(
						"Minigame Completed",
						"You successfully examined and selected all 3 shirts!",
						EssenceBaseModalPrompt.ButtonPreset.OK
					)
				else:
					print("Minigame was cancelled or failed.")
		"wardrobe":
			#print("-> Alternando visibilidad de accesorios (Gorra y Lentes)...")
			
			if is_instance_valid(active_character) and active_character is EssenceModularActor:
				var wardrobe_data: Dictionary = story_flags.get("player_wardrobe", {})
				
				# 1. Read the current state (if it does not exist in the dictionary, assume false)
				var is_currently_equipped: bool = bool(wardrobe_data.get(IDsGIC.Items.HAT_1, false))
				var target_state: bool = not is_currently_equipped
				
				# 2. We affect the on-screen character's live graphics.
				active_character.modify_clothing(IDsGIC.Items.HAT_1, target_state)
				active_character.modify_clothing(IDsGIC.Items.SUNGLASS_1, target_state)
				
				# 3. We store the new truth in story_flags for persistence and saving.
				wardrobe_data[IDsGIC.Items.HAT_1] = target_state
				wardrobe_data[IDsGIC.Items.SUNGLASS_1] = target_state
				story_flags["player_wardrobe"] = wardrobe_data
				
				#print("-> ¡Accesorios cambiados a: %s!" % target_state)
		"stretch":
			#print("-> [MODO CINEMÁTICA] Ejecutando pose temporal de estiramiento...")
			_ejecutar_animacion_pose_temporal()
		"atmosphere":
			# Alterna la visibilidad del degradado/atmósfera en el escenario visual activo
			if is_instance_valid(director):
				var current_loc = director.get_current_location()
				if is_instance_valid(current_loc):
					if current_loc.has_method("toggle_atmosphere"):
						current_loc.toggle_atmosphere()
					elif "atmosphere_fx" in current_loc and is_instance_valid(current_loc.atmosphere_fx):
						current_loc.atmosphere_fx.visible = not current_loc.atmosphere_fx.visible
			
	# Smoothly retract the interface once the requested action is resolved
	if is_instance_valid(_cached_interaction_menu):
		_cached_interaction_menu.close_menu()
		
## Executes the asynchronous pose-changing sequence with a full interface lock
func _ejecutar_animacion_pose_temporal() -> void:
	if not is_instance_valid(active_character) or not (active_character is EssenceModularActor):
		return
		
	# 1. ENTER CINEMATIC MODE
	# Disables interaction with hotspots, doors, and HUD buttons
	director.change_game_state(EssenceGameplayDirector.GameState.CUTSCENE)
	
	# 2. SWITCH TO ACTION POSE / RAISE ARMS
	# change_pose() handles only turning off the previous pose and synchronizing the equipped clothing
	active_character.change_pose(IDsGIC.Poses.ARMS_OUT)
	
	# 3. WAIT 2 SECONDS FOR ANIMATION/TIMER
	await get_tree().create_timer(2.0).timeout
	
	# 4. RETURN TO THE NORMAL POSE
	active_character.change_pose(IDsGIC.Poses.BASE_BODY)
	
	# 5. RESTORE CONTROL AND EXIT CINEMATIC MODE
	director.change_game_state(EssenceGameplayDirector.GameState.EXPLORATION)
	#print("-> [MODO EXPLORACIÓN] Secuencia finalizada. Interacción restaurada.")
	
## Central listener that processes all navigation signals coming from inside the active rooms.
## [param next_place]: The RoomID destination.
## [param mode]: The required interaction layout mode (defaults to 1 for exploration).
## [param is_only_mode]: True if we are just switching internal rules instead of reloading.
func _on_room_navigation_requested(next_place: int, mode: int = 1, is_only_mode: bool = false) -> void:
	var data = LevelManager.get_scenery_config(current_room_id, next_place, mode, is_only_mode)
	
	if data["flag_error"]:
		EssenceReportUtils.critical(
			"Navigation Error",
			"Illegal transition requested by room layout in %s." % ES_NAME_CLASS
		)
		return
		
	if is_only_mode:
		_apply_interaction_state(data["interaction_mode"])
		return
		
	if director:
		# We ask the director to close their black curtain immediately (within 0.25s)
		var curtain_tween = director.close_curtain(0.25)
		if curtain_tween:
			# We hide the game behind the black wall before moving a single pixel.
			await curtain_tween.finished 
			
	# TECHNICAL INTERCEPT: Handle the application scene-swap separately
	if data["id_room"] == GameIDs.RoomID.SAVE_SCENE:
		spawned_items_in_room.clear()
		if director: 
			director.unload_scenery()
		await get_tree().process_frame
		get_tree().change_scene_to_file(DemoItemsRoute.TESTSAVESCENE_SCENE)
		return

	# STANDARD ROOM FLOW
	_route_room_initialization(data["id_room"], data, true)
	
	if director:
		# We wait for a stabilization frame so the engine finishes rendering the map.
		await get_tree().process_frame
		
		# We gently open the curtain to reveal the new stage.
		var open_tween = director.open_curtain(0.4)
		if open_tween:
			await open_tween.finished
			
		director.change_game_state(EssenceGameplayDirector.GameState.EXPLORATION)

## Evaluates story conditions before enabling player control inside a room.
## [param room_id]: The active Room ID from GameIDs.RoomID.
## [param default_mode]: The fallback interaction mode if no story events trigger.
func _evaluate_room_narrative_entry(room_id: int, default_mode: int) -> void:
	
	# 1. INTERMEDIATE STORY FILTER
	# If an event or cutscene takes control, we interrupt the normal flow.
	if _check_room_interruptions(room_id):
		return 
		
	# 2. DYNAMIC MODE RESOLUTION (DATA-DRIVEN)
	# Construct a generic key based on the current room ID (e.g., "room_mode_1")
	var room_mode_key: String = "room_mode_" + str(room_id)
	
	# Fetch the saved mode for this room if it exists; otherwise, fall back to default_mode.
	var final_mode: int = story_flags.get(room_mode_key, default_mode)
	
	# 3. NORMAL EXPLORATION FLOW
	# Fetch the internal room configuration directly from the LevelManager using the resolved mode.
	var data = LevelManager.get_scenery_config(room_id, room_id, final_mode, true)
	if data["flag_error"]: 
		return
		
	_apply_interaction_state(data["interaction_mode"])
	
	# 4. AUTOMATED STAGE CONSTRUCTION
	# The system reads the StageItemManager manifesto, processes filters, 
	# and instantiates all floating buttons/interactables automatically.
	_build_stage_interactables(room_id, data["interaction_mode"])
	
	# 5. AUTOMATED SECONDARY ACTORS CONSTRUCTION
	# Automatically handles layout fillers like the park NPCs or dogs
	_build_stage_actors(room_id, data["interaction_mode"], false)
	
	# 6. EXCLUSIVE CHARACTER / ACTOR INITIALIZATION
	if room_id == GameIDs.RoomID.INITIAL_ROOM:
		if data["interaction_mode"] == 2 and not story_flags.get("has_completed_touch_tutorial", false):
			print("[%s] Unfinished second tutorial detected. Re-triggering overlay..." % ES_NAME_CLASS)
			_trigger_character_tutorial()
		
## CENTRAL AUTOMATION: Instantiates and positions all actors dynamically via the Gameplay Director.
## [param room_id]: The active Room ID from GameIDs.RoomID.
## [param current_layout_mode]: The active interaction variant of the room.
## [param is_instant]: If true, skips appearance animations (perfect for loading saves).
func _build_stage_actors(room_id: int, current_layout_mode: int, is_instant: bool = false) -> void:
	# 1. CLEANUP LAYER: Safely queue_free previous nodes to prevent memory leaks
	for actor in _spawned_actors_in_room:
		if is_instance_valid(actor):
			actor.queue_free()
	_spawned_actors_in_room.clear()
	
	# 2. MANIFEST QUERY
	var modes_dict: Dictionary = StageActorManager.ROOM_ACTOR_MANIFESTO.get(room_id, {})
	var actors_to_spawn: Array = modes_dict.get(current_layout_mode, [])
	
	if actors_to_spawn.is_empty():
		return
		
	# 3. AUTOMATED INSTANTIATION LOOP
	for actor_data in actors_to_spawn:
		var actor_id: int = actor_data.get(StageActorManager.KEY_ACTOR_ID, -1)
			
		if not _should_allow_actor_spawn(room_id, actor_id, current_layout_mode):
			continue
			
		var placement: Dictionary = StageActorManager.get_actor_placement(room_id, actor_id, current_layout_mode)
		if not placement.get(StageActorManager.KEY_IS_VISIBLE, false):
			continue
			
		# 4. IDENTIFICATION OF ASSET PATH (.TSCN)
		# RESOLUTION VIA CENTRAL ROUTE SOLVER
		var scene_path: String = GetRouteActors.get_actor_path(actor_id)
				
		if scene_path == "" or not ResourceLoader.exists(scene_path):
			EssenceReportUtils.critical(
				"Actor Setup Error",
				"No .tscn scene found for ActorID %d in %s." % [actor_id, ES_NAME_CLASS]
			)
			continue
			
		# 5. DYNAMIC MEMORY LOADING VIA DIRECTOR
		var actor_resource: PackedScene = load(scene_path) as PackedScene
		var actor_instance: EssenceActor = director.add_actor_to_stage(actor_resource) as EssenceActor
		
		if not is_instance_valid(actor_instance):
			EssenceReportUtils.critical(
				"Actor Instantiation Error",
				"Director returned a null node for ActorID %d in %s." % [actor_id, ES_NAME_CLASS]
			)
			continue
			
		# 6. PHYSICAL TRANSFORMATIONS
		actor_instance.position = placement.get(StageActorManager.KEY_POSITION, Vector2.ZERO)
		actor_instance.scale = placement.get(StageActorManager.KEY_SCALE, Vector2.ONE)
		actor_instance.rotation_degrees = placement.get(StageActorManager.KEY_ROTATION, 0.0)
		
		# 7. TYPE-SAFE SPECIALIZATION LAYER
		if actor_instance is EssenceModularActor:
			if actor_id == GameIDs.ActorID.PROTAGONIST:
				var wardrobe_data: Dictionary = story_flags.get("player_wardrobe", {})
				
				if wardrobe_data.is_empty():
					# Fallback configuration in case the dictionary turns out to be empty
					actor_instance.modify_clothing(IDsGIC.Items.HAT_1, false) 
					actor_instance.modify_clothing(IDsGIC.Items.SUNGLASS_1, false) 
				else:
					# Dynamic garment equipping/unequipping processing
					for garment_key in wardrobe_data.keys():
						var key_str: String = str(garment_key)
						
						# Valid for numeric Enums and serialized JSON IDs (ex: "40")
						if key_str.is_valid_int():
							var item_id: int = key_str.to_int()
							var is_equipped: bool = bool(wardrobe_data[garment_key])
							actor_instance.modify_clothing(item_id, is_equipped)
				
		if actor_instance is EssenceInteractiveActor:
			if actor_id == GameIDs.ActorID.PROTAGONIST:
				active_character = actor_instance
			
			actor_instance.clicked_on_character.connect(_on_character_interacted)
		
		# 8. DELEGATED EXECUTION LAYER
		var entry_mode: EssenceActor.TransitionType = EssenceActor.TransitionType.INSTANT if is_instant else EssenceActor.TransitionType.FADE
		actor_instance.enter_stage(entry_mode, 1.0)
		
		# 9. REGISTER TO LOCAL GARBAGE COLLECTOR
		_spawned_actors_in_room.append(actor_instance)
		
## Evaluates global story flags to determine if a background actor is temporarily forbidden.
func _should_allow_actor_spawn(room_id: int, _actor_id: int, _layout_mode: int) -> bool:
	# Example override: If a special story event empties the park, block all filler NPCs
	if room_id == GameIDs.RoomID.PARK:
		if story_flags.get("is_park_emptied_by_story", false):
			return false # Forbidden to spawn
			
	return true # Allowed by default if declared in the manifesto

## Checks for pending story events in the given room.
## Returns TRUE if an event intercepted the flow, FALSE if the room is clear.
func _check_room_interruptions(room_id: int) -> bool:
	# If we are already in the gameplay phase, NO initial events or old tutorials should slip through.
	if current_phase == TestPhase.GAMEPLAY:
		return false # There is no interruption; it continues freely.
		
	match room_id:
		GameIDs.RoomID.INITIAL_ROOM:
			if story_flags.get("is_first_time_here", false):
				#print("[Story] Interrupción: Primera vez en la habitación inicial. Esperando tutorial.")
				director.change_game_state(EssenceGameplayDirector.GameState.DIALOGUE)
				return true 
				
		GameIDs.RoomID.ROOM_3_DOORS:
			if story_flags.get("is_phone_event_active", false):
				print("[Story] Interrupción: ¡Alguien llama al telefono! Bloqueando exploracion.")
				director.change_game_state(EssenceGameplayDirector.GameState.DIALOGUE)
				story_flags["is_phone_event_active"] = false 
				return true 
				
	return false

## Helper method to translate matrix modes into director game states.
func _apply_interaction_state(matrix_mode: int) -> void:
	match matrix_mode:
		0:
			director.change_game_state(EssenceGameplayDirector.GameState.DIALOGUE)
		1, 2:
			director.change_game_state(EssenceGameplayDirector.GameState.EXPLORATION)
			
	# Synchronize hotspot physical collisions with the saved variable
	if is_instance_valid(current_interactive_loc):
		current_interactive_loc.environment_interactable = (matrix_mode != 0)
			
## Dynamically changes the current room mode and automatically updates items/actors.
func set_room_interaction_mode(target_mode: int) -> void:
	var data = LevelManager.get_scenery_config(current_room_id, current_room_id, target_mode, true)
	if data["flag_error"]:
		return
		
	# 1. Apply state to the Director (Locks/unlocks the interaction interface)
	_apply_interaction_state(data["interaction_mode"])
	
	# 2. Refresh floating items for this new mode
	director.clear_item_stage()
	spawned_items_in_room.clear()
	
	if target_mode != 0:
		_build_stage_interactables(current_room_id, target_mode)
	
	# 3. Refresh actors for the new mode
	_build_stage_actors(current_room_id, target_mode, false)
	
	EssenceLogger.system_info("[%s] Transición de modo completada -> Modo: %d" % [ES_NAME_CLASS, target_mode])
			
## CENTRAL AUTOMATION: Builds and validates all interactive elements declared in the room
## [param room_id]: The ID of the current scene (GameIDs.RoomID)
## [param current_layout_mode]: The current sub-mode or variant of the room (0, 1, 2, etc.)
func _build_stage_interactables(room_id: int, current_layout_mode: int) -> void:
	# 1. QUERY: Obtener la lista de ítems del manifiesto para esta sala
	var raw_items_list: Array = StageItemManager.ROOM_ITEM_MANIFESTO.get(room_id, [])
	
	if raw_items_list.is_empty():
		return # Sala pasiva o estática; nada que instanciar vía código.
		
	# 2. PROCESAMIENTO Y FILTRADO POR ELEMENTO
	for item_data in raw_items_list:
		var item_id: int = item_data["item_id"]
		var destination: int = item_data["destination"]
		
		var placement: Dictionary = StageItemManager.get_item_placement(item_data, current_layout_mode)
		
		# Validar visibilidad según el modo actual de la sala
		if not placement.get(StageItemManager.KEY_IS_VISIBLE, false):
			#print("[%s/Spawner] Ítem ID %d omitido: no es visible en el Modo %d." % [ES_NAME_CLASS, item_id, current_layout_mode])
			continue
			
		var spawn_position: Vector2 = placement.get(StageItemManager.KEY_POSITION, Vector2.ZERO)
		var spawn_scale: Vector2 = placement.get(StageItemManager.KEY_SCALE, Vector2.ONE)
		
		# Validar condiciones narrativas especiales (story_flags)
		if not _should_allow_item_spawn(room_id, item_id, current_layout_mode):
			print("[%s/Spawner] Ítem ID %d rechazado por condiciones narrativas (Modo: %d)." % [ES_NAME_CLASS, item_id, current_layout_mode])
			continue
			
		# 3. RESOLUCIÓN DE RUTA VÍA GetRouteItems
		var scene_path: String = GetRouteItems.get_item_path(item_id)
		
		if scene_path == "" or not ResourceLoader.exists(scene_path):
			EssenceReportUtils.critical(
				"Item Setup Error",
				"Escena .tscn no encontrada para el ItemID %d en la ruta: '%s' (%s)." % [item_id, scene_path, ES_NAME_CLASS]
			)
			continue
			
		# 4. INSTANCIACIÓN VÍA DIRECTOR
		var packed_item = load(scene_path) as PackedScene
		var item_instance = director.add_item_to_stage(packed_item)
		
		if not is_instance_valid(item_instance):
			EssenceReportUtils.critical(
				"Item Instantiation Error",
				"El Director devolvió un nodo nulo para el ItemID %d en %s." % [item_id, ES_NAME_CLASS]
			)
			continue
			
		# 5. TRANSFORMACIÓN FÍSICA
		item_instance.position = spawn_position
		item_instance.scale = spawn_scale
		
		# Guardar referencia para el reciclaje de nodos al cambiar de sala
		spawned_items_in_room.append(item_instance)
		
		# 6. CONFIGURAR ÁREA INTERACTIVA (Smart Input Binding)
		var target_area: Area2D = item_instance if item_instance is Area2D else null
		if not target_area:
			for child in item_instance.get_children():
				if child is Area2D:
					target_area = child
					break
					
		# 7. CONEXIÓN DE ACCIONES
		if target_area:
			if destination != -1:
				# Conexión a evento de navegación con destino
				var callable = _on_dynamic_door_clicked.bind(destination)
				if not target_area.input_event.is_connected(callable):
					target_area.input_event.connect(callable)
			else:
				# Elemento utilitario/interactivo sin cambio de escena
				pass
		else:
			EssenceReportUtils.warning(
				"Item Area Warning",
				"El Ítem %d no contiene un Area2D en %s. Se instanció únicamente como elemento visual." % [item_id, ES_NAME_CLASS]
			)
			
## INTERNAL VALIDATOR: Decides whether an item is eligible to enter based on the current rules
func _should_allow_item_spawn(_room_id: int, _item_id: int, current_mode: int) -> bool:
	# Rule filter example: If it's night mode (Mode 3), we could block non-bed items here
	if current_mode == 0:
		# NOTE: If you need to use them inside an 'if' statement later,
		# Just remove the underscore and you're done. For now, if you're only using current_mode,
		# The filter works just as well.
		pass
		
	# Example of the rule you suggested: If it is nighttime (let's assume Mode 3), we block everything except the bed.
	if current_mode == 3: # Dummy Night Filter for testing
		# If we are in the starting room at night and the item isn't the one we want, we block it.
		# if item_id != GameIDs.ItemID.BED_ITEM: return false
		pass
		
	# By default, unless a story rule or phase prohibits it, the object enters freely.
	return true
		
## Processes the click of any dynamic door and requests navigation to its bound destination.
func _on_dynamic_door_clicked(_viewport: Node, event: InputEvent, _shape_idx: int, next_room_id: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		#print("[Framework] Crossed door! Traveling to room ID: ", next_room_id)
		# GUARD: Do not allow room changes while a cutscene is active.
		if director.current_state != EssenceGameplayDirector.GameState.EXPLORATION:
			return
		# We query the LevelManager matrix using the destination that was linked to the door.
		var data = LevelManager.get_scenery_config(current_room_id, next_room_id, 0, false)
		
		if not data["flag_error"]:
			# When changing rooms, we clear our list of references and instruct the Director to clear the screen.
			spawned_items_in_room.clear()
			director.clear_item_stage() 
			
			# We redirect the result to the central callback you already built.
			_on_room_navigation_requested(next_room_id, 0, false)
			
## BASE GENERIC METHOD (The Framework's Build Engine)
## Automatically resolves and builds both scenery (.tscn) and interactive hotspots (.tscn) via resolvers.
func _build_room_base(data: Dictionary, skip_animations: bool = false) -> Node2D:
	current_room_id = data["id_room"]
	var target_mode: int = data.get("interaction_mode", 0)
	
	# 1. TOTAL CENTRALIZED CLEANUP
	director.clear_character_stage()
	active_character = null
	director.clear_item_stage()
	spawned_items_in_room.clear() 
	director.unload_scenery()
	
	# 2. AUTOMATED SCENERY PREFAB LOADING VIA GetRouteScenary
	var scenery_path: String = GetRouteScenary.get_scenery_path(current_room_id)
	
	if scenery_path != "" and ResourceLoader.exists(scenery_path):
		var packed_scenery = load(scenery_path) as PackedScene
		if packed_scenery:
			director.load_scenery(packed_scenery, current_room_id, target_mode)
		
	# 3. LOADING INTERACTIVE MASK / HOTSPOTS (.TSCN)
	current_interactive_loc = null # Limpiar referencia anterior
	var current_loc: Node2D = null
	
	var interactive_path: String = GetRouteInteractiveInScenary.get_interactive_path(current_room_id)
	if interactive_path != "" and ResourceLoader.exists(interactive_path):
		var interactive_scene = load(interactive_path) as PackedScene
		if interactive_scene:
			current_loc = director.load_interactive(interactive_scene)
			
			if current_loc is EssenceInteractiveLocation:
				current_interactive_loc = current_loc
				# Si no estamos en Modo 0 (Cinemática), encendemos las colisiones físicas
				current_interactive_loc.environment_interactable = (target_mode != 0)
				
			if current_loc and current_loc.has_signal("navigation_requested"):
				if not current_loc.navigation_requested.is_connected(_on_room_navigation_requested):
					current_loc.navigation_requested.connect(_on_room_navigation_requested)
					
	# 4. ACTOR INSTANTIATION (They are always instantiated so that they appear in the cinematic)
	_build_stage_actors(current_room_id, target_mode, skip_animations)
	
	# 5. FLOATING ITEMS (Only created if the mode allows interaction)
	if target_mode != 0:
		_build_stage_interactables(current_room_id, target_mode)
	
	return current_loc
	
## Route and execute the specific setup pipeline for a room layout based on its unique ID.
## [param room_id]: The target RoomID from GameIDs tracking enum.
## [param scenery_data]: The validated layout configuration dictionary from LevelManager.
## [param skip_animations]: True to force immediate state placement without transitions.
func _route_room_initialization(room_id: int, scenery_data: Dictionary, skip_animations: bool) -> void:
	match room_id:
		GameIDs.RoomID.INITIAL_ROOM:
			_on_ready_initialRoom(scenery_data, skip_animations)
		GameIDs.RoomID.ROOM_3_DOORS:
			_on_ready_room3doors(scenery_data, skip_animations)
		GameIDs.RoomID.ROOM_1_DOOR:
			_on_ready_room1door(scenery_data, skip_animations)
		GameIDs.RoomID.PARK:
			_on_ready_parkScene(scenery_data, skip_animations)
		_:
			EssenceReportUtils.critical(
				"Routing Error",
				"Failed to route initialization: Unknown RoomID %d in %s." % [room_id, ES_NAME_CLASS]
			)

#########################
# SECTION Initial Room  #
#########################
			
## Sets up the initial room layout. If skip_animations is true, it builds instantly.
func _on_ready_initialRoom(data: Dictionary, skip_animations: bool = false) -> void:
	_build_room_base(data, skip_animations)
	_evaluate_room_narrative_entry(data["id_room"], data.get("interaction_mode", 1))

#########################
# SECTION Room 3 Doors  #
#########################

## Sets up the 3 doors room. If skip_animations is true, it builds instantly.
func _on_ready_room3doors(data: Dictionary, skip_animations: bool = false) -> void:
	_build_room_base(data, skip_animations)
	_evaluate_room_narrative_entry(data["id_room"], data.get("interaction_mode", 1))

#########################
# SECTION Room 1 Door   #
#########################

## Sets up the 3 doors room. If skip_animations is true, it builds instantly.
func _on_ready_room1door(data: Dictionary, skip_animations: bool = false) -> void:
	_build_room_base(data, skip_animations)
	_evaluate_room_narrative_entry(data["id_room"], data.get("interaction_mode", 1))
	
##################
# SECTION PARK   #
##################
func _on_ready_parkScene(data: Dictionary, skip_animations: bool = false) -> void:
	_build_room_base(data, skip_animations)
	_evaluate_room_narrative_entry(data["id_room"], data.get("interaction_mode", 1))
	
# Inside your central Game Director / Main Game script when instantiating a room:
func _register_room_signals(room_instance: EssenceNavigationRoom) -> void:
	if not room_instance.navigation_requested.is_connected(_on_room_navigation_requested):
		room_instance.navigation_requested.connect(_on_room_navigation_requested)

##############
# Ejemplo
#############
func _on_ready_habitacion_secreta(data: Dictionary, skip_animations: bool = false) -> void:
	# SPECIFIC code BEFORE loading:
	print("¡Alerta! El jugador entró a una zona peligrosa. Modificando música...")
	#AudioManager.play_music("Musica_Tension")
	
	# We execute the common base load and capture the node it generates.
	var locacion_actual = _build_room_base(data, skip_animations)
	
	# SPECIFIC code AFTER loading (Modify things inside the room):
	if is_instance_valid(locacion_actual):
		# We are looking for a chest that exists only in this room, and we are altering it via code.
		var cofre = locacion_actual.get_node_or_null("CofreOculto")
		if cofre:
			print("x")
		#if cofre and GlobalSave.ya_abrio_cofre:
		#	cofre.queue_free() # We delete the chest if it has already been used.
			
	# We move past the standard narrative check
	_evaluate_room_narrative_entry(current_room_id, data["interaction_mode"])

# ==========================================
# DIAGNÓSTICO DE CLICS Y UI (TEMPORAL)
# ==========================================
#func _input(event: InputEvent) -> void:
#	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
#		# Le preguntamos directamente a Godot qué nodo Control de la UI está justo bajo el cursor
#		var hovered_control = get_viewport().gui_get_hovered_control()
#		
#		if hovered_control:
#			print("--------------------------------------------------")
#			print("[DIAGNÓSTICO UI] Clic capturado por el nodo: '", hovered_control.name, "'")
#			print("   - Clase del nodo: ", hovered_control.get_class())
#			print("   - Mouse Filter actual: ", hovered_control.mouse_filter, " (0=STOP, 1=PASS, 2=IGNORE)")
#		else:
#			print("--------------------------------------------------")
#			print("[DIAGNÓSTICO UI] Camino 100% libre. Ninguna UI tapa el cursor en esta posición.")
#
#
#func _unhandled_input(event: InputEvent) -> void:
#	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
#		print("[DIAGNÓSTICO 2D] ¡El clic sobrevivió a la UI y llegó al motor de físicas 2D!")
