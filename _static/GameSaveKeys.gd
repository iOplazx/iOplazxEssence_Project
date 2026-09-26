class_name GameSaveKeys
extends RefCounted

## [GameSaveKeys]
## Centralizes dictionary keys for metadata and persistent game save states,
## eliminating magic strings and human typos across user scripts.

# --- METADATA KEYS (Used in Load Screen Cards) ---
const META_LOCATION = "location"
const META_PLAYTIME = "playtime"
const META_PLAYER_LEVEL = "player_level"

# --- PERSISTENT GAME DATA KEYS ---
const CURRENT_SCENE = "current_scene"
const CURRENT_PHASE = "current_phase"
const CURRENT_ROOM = "current_room"
const CHARACTER_CLOTHING_STATE = "character_clothing_state"
const STORY_FLAGS = "story_flags"
const PLAYTIME_SECONDS = "playtime_seconds"
const DEMO_PROGRESS = "demo_progress"
const UNLOCKED_GALLERY = "unlocked_gallery"
