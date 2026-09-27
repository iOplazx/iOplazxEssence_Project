## [EssenceTimeManager]
## Core framework manager responsible for tracking active gameplay time.
## Accumulates delta time in seconds, supports pausing/resuming during scene loads or pause menus,
## and integrates cleanly with EssenceSaveManager and EssenceTimeUtils.
class_name EssenceTimeManager
extends Node
const ES_NAME_CLASS = "EssenceTimeManager"

## Emitted whenever the internal clock state transitions (e.g., from RUNNING to PAUSED).
signal clock_state_changed(new_state: ClockState)

## Emitted when playtime is explicitly updated or loaded from save data.
signal playtime_updated(total_seconds: float)

## Operational states for the gameplay clock.
enum ClockState {
	STOPPED,  ## Clock is inactive and reset (e.g., in Main Menu)
	RUNNING,  ## Active gameplay, accumulating delta time
	PAUSED    ## Frozen time (e.g., in pause menu, dialogues, or global scene transitions)
}

## Active clock operational state.
var current_state: ClockState = ClockState.STOPPED

## Total accumulated gameplay time in seconds.
var _total_playtime: float = 0.0


func _ready() -> void:
	# PROCESS_MODE_ALWAYS guarantees the manager processes process(delta) 
	# regardless of SceneTree pause state, letting us control state explicitly.
	process_mode = Node.PROCESS_MODE_ALWAYS
	EssenceLogger.system_info("[%s] Manager initialized successfully." % ES_NAME_CLASS)


func _process(delta: float) -> void:
	if current_state == ClockState.RUNNING:
		_total_playtime += delta


# ==============================================================================
# PUBLIC CLOCK CONTROL API
# ==============================================================================

## Starts accumulating time or resumes if paused.
func start_clock() -> void:
	if current_state == ClockState.RUNNING:
		return
		
	current_state = ClockState.RUNNING
	clock_state_changed.emit(current_state)
	EssenceLogger.system_info("[%s] Gameplay clock STARTED at %.2f seconds." % [ES_NAME_CLASS, _total_playtime])


## Freezes time accumulation without resetting the stored value.
func pause_clock() -> void:
	if current_state != ClockState.RUNNING:
		return
		
	current_state = ClockState.PAUSED
	clock_state_changed.emit(current_state)
	EssenceLogger.system_info("[%s] Gameplay clock PAUSED at %.2f seconds." % [ES_NAME_CLASS, _total_playtime])


## Resumes time accumulation if currently paused.
func resume_clock() -> void:
	if current_state == ClockState.PAUSED:
		start_clock()


## Stops accumulation and resets playtime to 0.0 (e.g., returning to Main Menu).
func stop_clock() -> void:
	_total_playtime = 0.0
	current_state = ClockState.STOPPED
	clock_state_changed.emit(current_state)
	playtime_updated.emit(_total_playtime)
	EssenceLogger.system_info("[%s] Gameplay clock STOPPED and reset." % ES_NAME_CLASS)


## Explicitly sets the accumulated playtime (e.g., when loading a save file).
func set_playtime(seconds: float) -> void:
	_total_playtime = maxf(0.0, seconds)
	playtime_updated.emit(_total_playtime)
	EssenceLogger.system_info("[%s] Playtime restored to %.2f seconds." % [ES_NAME_CLASS, _total_playtime])


## Returns the raw accumulated playtime in seconds.
func get_total_playtime() -> float:
	return _total_playtime


## Returns a formatted string representing the current playtime (e.g., "01:23:45").
func get_formatted_time(include_seconds: bool = true) -> String:
	return EssenceTimeUtils.format_seconds(_total_playtime, include_seconds)

## Returns whether the clock is actively accumulating time.
func is_running() -> bool:
	return current_state == ClockState.RUNNING
	
func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_FOCUS_OUT:
			# Pause clock when window loses focus
			if current_state == ClockState.RUNNING:
				pause_clock()
		NOTIFICATION_APPLICATION_FOCUS_IN:
			# Resume clock when window regains focus
			if current_state == ClockState.PAUSED:
				resume_clock()
