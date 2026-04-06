extends EssenceSaveManager

# ==============================================================================
# GAME SAVE MANAGER (AUTOLOAD)
# This script extends the core iOplazxEssence framework.
# Replace the default 'SaveManager' in Project -> Autoloads with this file.
# ==============================================================================

func _ready():
	# Always call the parent class _ready() so the framework initializes properly
	super._ready()
	print("Demo: GameSaveManager initialized, wrapping EssenceSaveManager.")

# ==============================================================================
# INTEGRATION HOOKS (GAME LOGIC OVERRIDES)
# ==============================================================================

func _on_before_save_hook(game_data: Dictionary, meta_data: Dictionary):
	# OVERRIDE: This hook is triggered exactly one millisecond before the 
	# temporary dictionaries are written to the physical .ess file.
	
	print("Demo: Before Save Hook triggered. Injecting live game data...")
	
	# --------------------------------------------------------------------------
	# 1. INJECT GAME DATA
	# Add your live game variables here. Because dictionaries are passed by reference,
	# anything you add here will be saved permanently.
	# --------------------------------------------------------------------------
	
	# Examples (Uncomment and adapt to your actual global singletons/variables):
	# game_data["player_hp"] = PlayerStats.current_hp
	# game_data["inventory"] = InventorySystem.get_all_items()
	# game_data["current_chapter"] = GameRuntime.chapter
	# game_data["has_met_kiwi"] = GameRuntime.met_kiwi
	
	# --------------------------------------------------------------------------
	# 2. INJECT METADATA
	# Metadata is what the UI (Load Menu) reads to display the save slot beautifully.
	# Add things like the current location name, playtime, or player level.
	# --------------------------------------------------------------------------
	
	# Examples:
	# meta_data["location"] = "Kumi's Castle" 
	# meta_data["playtime"] = GlobalTimer.get_total_playtime_string()
	# meta_data["level"] = PlayerStats.level
	
	pass
