# ==============================================================================
# SCRIPT: GetRouteActors.gd
# DESCRIPTION: Central resolver mapping GameIDs.ActorID to DemoItemsRoute and EssencePaths constants.
# ==============================================================================

class_name GetRouteActors
extends RefCounted

## Manifest mapping ActorIDs to DemoItemsRoute/EssencePaths scene path constants
const ACTOR_MANIFEST: Dictionary = {
	GameIDs.ActorID.PROTAGONIST:       EssencePaths.ITEM_GENERIC_INTERACTIVE_CHARACTER,
	GameIDs.ActorID.SECONDARY:         EssencePaths.ITEM_GENERIC_MODULAR_CHARACTER,
	GameIDs.ActorID.PARK_PERSON_SIT_1: DemoItemsRoute.ACTOR_PARK_PERSON_SIT_1_SCENE,
	GameIDs.ActorID.PARK_PERSON_SIT_2: DemoItemsRoute.ACTOR_PARK_PERSON_SIT_2_SCENE,
	GameIDs.ActorID.PARK_PERSON_SIT_3: DemoItemsRoute.ACTOR_PARK_PERSON_SIT_3_SCENE,
	GameIDs.ActorID.PARK_DOG_1:        DemoItemsRoute.ACTOR_PARK_DOG_RUN_SCENE
}


## Resolves and returns the .tscn scene path bound to a specific ActorID
static func get_actor_path(actor_id: int) -> String:
	return ACTOR_MANIFEST.get(actor_id, "")
