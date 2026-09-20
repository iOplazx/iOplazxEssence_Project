## [EssenceBaseMiniGame]
## Base class from which all the project's minigames will inherit.
class_name EssenceBaseMiniGame
extends Control

## Emit when the minigame ends.
## [param result_data]: Dictionary containing the final state (e.g., {"victory": true, "score": 100})
signal minigame_completed(result_data: Dictionary)

## Emit if the player leaves or closes the minigame without finishing it
signal minigame_cancelled

## The minigame ends by reporting a victory or defeat.
func finish_minigame(is_victory: bool, extra_data: Dictionary = {}) -> void:
	var result: Dictionary = {
		"victory": is_victory
	}
	# We mix in additional data if available (points, time, items earned, etc.)
	result.merge(extra_data, true)
	
	minigame_completed.emit(result)


## Cancels the execution of the minigame
func cancel_minigame() -> void:
	minigame_cancelled.emit()
