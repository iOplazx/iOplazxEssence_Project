@tool
extends EditorPlugin

const ES_NAME_CLASS = "EssencePlugin"

# --- SOURCE PATHS (Inside the Addon) ---
const PATH_MANAGERS = "res://addons/iOplazxEssence/managers/"
const PATH_UI = "res://addons/iOplazxEssence/ui/"
const PATH_TEMPLATES = "res://addons/iOplazxEssence/templates/"

# --- DESTINATION PATHS (User Workspace) ---
const USER_STATIC = "res://_static/"
const USER_SAVE_MANAGER = USER_STATIC + "GameSaveManager.gd"

# --- AUTOLOADS DICTIONARY ---
# Defines the Singletons required by the framework and their paths.
const AUTOLOADS = {
	"EssenceLogger": PATH_MANAGERS + "EssenceLogger.gd",
	"EssenceError": PATH_MANAGERS + "EssenceError.gd",
	"Preferences": PATH_MANAGERS + "Preferences.gd",
	"AudioManager": PATH_MANAGERS + "AudioManager.gd",
	"SceneManager": PATH_MANAGERS + "SceneManager.gd",
	"DisplayManager": PATH_MANAGERS + "DisplayManager.gd",
	"LanguageManager": PATH_MANAGERS + "LanguageManager.gd",
	"FileManager": PATH_MANAGERS + "FileManager.gd",
	
	# Important: We point the SaveManager to the User Workspace, not the addon folder.
	# This prevents user logic from being overwritten during framework updates.
	"SaveManager": USER_SAVE_MANAGER,
	
	"GlobalLoading": PATH_UI + "overlays/EssenceLoadingScreen.tscn",
	"EssenceWarningUI": PATH_UI + "overlays/EssenceWarningScreen.tscn"
}

func _enter_tree() -> void:
	# 1. Setup User Workspace (Folders and Templates)
	_deploy_user_scaffolding()
	
	# 2. Automatic Autoload Registration
	for autoload_name in AUTOLOADS:
		add_autoload_singleton(autoload_name, AUTOLOADS[autoload_name])
	
	# 3. Apply Optimal Project Settings
	_setup_project_settings()
	
	# Note: We use standard 'print' instead of EssenceLogger because 
	# this script runs in the Editor context (@tool), not the game runtime.
	print("iOplazxEssence: Framework v0.1.1 activated and deployed successfully.")

func _exit_tree() -> void:
	# Cleanup Autoloads when the plugin is disabled
	for autoload_name in AUTOLOADS:
		remove_autoload_singleton(autoload_name)
		
	print("iOplazxEssence: Framework deactivated.")

## Creates necessary folders and copies base template files if they don't exist.
func _deploy_user_scaffolding() -> void:
	# Create the _static directory if it's missing
	if not DirAccess.dir_exists_absolute(USER_STATIC):
		var err = DirAccess.make_dir_absolute(USER_STATIC)
		if err != OK:
			push_error("iOplazxEssence: Failed to create _static folder. Error code: " + str(err))
		
	# Deploy the SaveManager template if the user doesn't have one yet
	if not FileAccess.file_exists(USER_SAVE_MANAGER):
		var template_path = PATH_TEMPLATES + "GameSaveManager.gd"
		
		if FileAccess.file_exists(template_path):
			var err = DirAccess.copy_absolute(template_path, USER_SAVE_MANAGER)
			if err == OK:
				print("iOplazxEssence: Deployed GameSaveManager.gd template to _static/")
			else:
				push_error("iOplazxEssence: Failed to copy GameSaveManager template. Error code: " + str(err))
		else:
			push_warning("iOplazxEssence: Template not found at " + template_path)

## Forces base project configurations (Resolution, Rendering, etc.)
func _setup_project_settings() -> void:
	# Display configuration
	ProjectSettings.set_setting("display/window/size/viewport_width", 1280)
	ProjectSettings.set_setting("display/window/size/viewport_height", 720)
	ProjectSettings.set_setting("display/window/stretch/mode", "canvas_items")
	
	# Force GL Compatibility mode (Crucial for integrated graphics performance)
	ProjectSettings.set_setting("rendering/renderer/rendering_method", "gl_compatibility")
	ProjectSettings.set_setting("rendering/renderer/rendering_method.mobile", "gl_compatibility")
	
	# Save changes to the user's project.godot file
	ProjectSettings.save()