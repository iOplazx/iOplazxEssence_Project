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

# --- AUTOLOADS DICTIONARY (Layered by Dependency) ---
const AUTOLOADS = {
	# LAYER 0: Foundations (No dependencies)
	"EssenceLogger": PATH_MANAGERS + "EssenceLogger.gd",
	"EssenceError": PATH_MANAGERS + "EssenceError.gd",
	
	# LAYER 1: Core Systems (Depend on Layer 0)
	"FileManager": PATH_MANAGERS + "EssenceFileManager.gd",
	"Preferences": PATH_MANAGERS + "EssencePreferences.gd",
	
	# LAYER 2: Complex Logic (Depend on Layer 1)
	"LanguageManager": PATH_MANAGERS + "EssenceLanguageManager.gd",
	"SaveManager": USER_SAVE_MANAGER,
	"AudioManager": PATH_MANAGERS + "EssenceAudioManager.gd",
	"DisplayManager": PATH_MANAGERS + "EssenceDisplayManager.gd",
	
	# LAYER 3: Master Controllers (Depend on Layer 2)
	"SceneManager": PATH_MANAGERS + "EssenceSceneManager.gd",
	
	# LAYER 4: Visual Overlays (.tscn)
	"GlobalLoading": PATH_UI + "overlays/EssenceLoadingScreen.tscn",
	"EssenceWarningUI": PATH_UI + "overlays/EssenceWarningOverlay.tscn"
}

func _enter_tree() -> void:
	# 1. Prepare User Workspace (Folders and Templates)
	_deploy_user_scaffolding()
	
	# 2. Secure Autoload Registration
	for autoload_name in AUTOLOADS:
		var path = AUTOLOADS[autoload_name]
		
		# Optimization: Only register if the file actually exists to avoid compiler hangs
		if FileAccess.file_exists(path):
			add_autoload_singleton(autoload_name, path)
		else:
			push_warning("iOplazxEssence: Could not find " + autoload_name + " at " + path)
	
	# 3. Apply Optimal Project Settings
	_setup_project_settings()
	
	print("iOplazxEssence: Framework v0.1.1 activated and deployed successfully.")

func _exit_tree() -> void:
	# Safe Cleanup: Only remove settings that actually exist
	for autoload_name in AUTOLOADS:
		if ProjectSettings.has_setting("autoload/" + autoload_name):
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

## Forces base project configurations (Resolution, Rendering, etc.)
func _setup_project_settings() -> void:
	# UI Optimization: Stretch mode is vital for the integrated GPU performance
	ProjectSettings.set_setting("display/window/size/viewport_width", 1280)
	ProjectSettings.set_setting("display/window/size/viewport_height", 720)
	ProjectSettings.set_setting("display/window/stretch/mode", "canvas_items")
	ProjectSettings.set_setting("display/window/stretch/aspect", "expand")
	
	# Hardware Optimization: Force GL Compatibility (Essential for Athlon Silver 3050U)
	ProjectSettings.set_setting("rendering/renderer/rendering_method", "gl_compatibility")
	ProjectSettings.set_setting("rendering/renderer/rendering_method.mobile", "gl_compatibility")
	
	# V-Sync: Disabled by default for maximum FPS on low-end hardware
	ProjectSettings.set_setting("display/window/vsync/vsync_mode", 0)
	
	# Save changes to project.godot
	ProjectSettings.save()