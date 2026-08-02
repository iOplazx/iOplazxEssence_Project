## [EssenceMiniGameStage]
## Modal stage with a dark dimmer background that hosts dynamic minigame scenes.
class_name EssenceMiniGameStage
extends Control

# EssenceMiniGameStage (Control) [Script: EssenceMiniGameStage]
# ├── DimmerOverlay (EssenceDimmerOverlay) 
# └── GameContainer (CenterContainer) 
#     └── (Aquí se instanciará dinámicamente tu minijuego .tscn)

signal stage_closed(result_data: Dictionary)

@export_category("UI References")
@onready var dimmer_overlay: EssenceDimmerOverlay = $DimmerOverlay
@onready var game_container: CenterContainer = $GameContainer

var _loaded_minigame: EssenceBaseMiniGame = null


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	hide()


## Loads and instantiates a minigame scene inside the stage container.
func launch_minigame_scene(minigame_scene: PackedScene, init_data: Dictionary = {}) -> Dictionary:
	if not is_instance_valid(game_container) or not minigame_scene:
		push_error("[%s] Invalid minigame scene or null container." % name)
		return {"victory": false, "cancelled": true}

	# 1. Clean up previously loaded minigames if any
	for child in game_container.get_children():
		child.queue_free()

	# 2. Instantiate the new minigame
	var instance = minigame_scene.instantiate()
	if not (instance is EssenceBaseMiniGame):
		push_error("[%s] The provided scene does not extend EssenceBaseMiniGame." % name)
		instance.queue_free()
		return {"victory": false, "cancelled": true}

	_loaded_minigame = instance as EssenceBaseMiniGame
	game_container.add_child(_loaded_minigame)

	# 3. Connect minigame completion/cancellation signals
	_loaded_minigame.minigame_completed.connect(_on_minigame_finished)
	_loaded_minigame.minigame_cancelled.connect(_on_minigame_cancelled)

	# 4. Display stage with entry animation
	show()
	await _animate_in()

	# 5. Wait asynchronously until the minigame completes or gets cancelled
	var result: Dictionary = await stage_closed

	# 6. Play exit animation and clean up node instances
	await _animate_out()
	
	if is_instance_valid(_loaded_minigame):
		_loaded_minigame.queue_free()
		_loaded_minigame = null
		
	hide()
	return result


## Triggers entry animation via the Dimmer Overlay and stage opacity
func _animate_in() -> void:
	modulate.a = 0.0
	if is_instance_valid(dimmer_overlay):
		dimmer_overlay.fade_in(0.25)
		
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.25)
	await tween.finished


## Triggers exit animation via the Dimmer Overlay and stage opacity
func _animate_out() -> void:
	if is_instance_valid(dimmer_overlay):
		dimmer_overlay.fade_out(0.25)
		
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.25)
	await tween.finished


func _on_minigame_finished(result_data: Dictionary) -> void:
	stage_closed.emit(result_data)


func _on_minigame_cancelled() -> void:
	stage_closed.emit({"victory": false, "cancelled": true})
