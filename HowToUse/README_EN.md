# Quick Start Guide: iOplazx Essence Framework

Welcome to the professional setup manual. Follow these steps to correctly integrate the framework into your Godot 4.x project.

## Installation and Initial Setup

**Import the Addon:** Copy the `addons/iOplazxEssence` folder into your project's `res://` directory.
**Enable the Plugin:** Go to `Project > Project Settings > Plugins` and enable **iOplazxEssence**.
**Configure Autoloads (Singletons):** Go to `Project > Project Settings > Autoload`. You must add the following systems. **It is highly recommended to follow this exact order** to ensure dependencies load correctly:
   1.  `EssenceLogger`
   2.  `EssenceError`
   3.  `FileManager`
   4.  `Preferences`
   5.  `LanguageManager`
   6.  `SaveManager`
   7.  `AudioManager`
   8.  `DisplayManager`
   9.  `SceneManager`
   10. `GlobalLoading`
   11. `EssenceWarningUI`

**Data Structure:** Create a folder named `game_data` in your `res://` root. Inside it, create three subfolders: `persistent/`, `remote/`, and `global/`.
**Static Configuration:** Copy the files from `addons/iOplazxEssence/templates` into a new folder in your root named `res://_static/`.
**Class Adjustment:** Open `res://_static/GameConstants.gd`. In the `class_name` line, remove the `_IESS` suffix so it reads: `class_name GameConstants`.

## Routes and Menus Configuration

**Route Configuration (RouteConfig):** Double-click `res://_static/RouteConfig.tres`. Here you can define which scenes the framework will use for startup and the main menu.
   **SAFETY TIP:** *To customize your menu, copy the `iOplazxEssence/ui/screens/MainMenu.tscn` scene (and its script) to a folder outside of `addons/` (e.g., `res://scenes/`). This prevents losing your visual progress when updating the addon. Then, assign this new path in the `RouteConfig.tres` inspector.*

**Menu Controller:** In your customized menu scene, select the root node. In the inspector, you will see the `EssenceMenuController`. Link your buttons (Play, Settings, Exit, etc.) by dragging them into the controller's slots.

**Initial Audio:** In your startup script (`Boot.gd`), define your menu music using: `AudioManager.cache_audio("menu_theme", "res://your_path/music.ogg")`.

**Master Config:** Open `res://_static/EssenceMasterConfig.tres`. In the **Save System Customization** section, drag your custom save script (e.g., `MyGameSave.gd`) into the **Custom Save Script** field.

**Main Scene and Splash:** Set `Boot.tscn` as the Main Scene (`Project > Project Settings > Application > Run`). Then, under `Application > Boot Splash`, uncheck **Show Image** (the addon manages its own loading and warning screens).

---

## Export Settings (Mandatory!)

To ensure translations and flags work correctly in the final executable:

**Export Filters:** In the **Export > Resources** tab, add the following to "Filters to export non-resource files/directories": 
   `game_data/*, addons/iOplazxEssence/static_loc/*`
**Raw Image Import:** For `.png` files (like flags) inside `game_data` (like flags):
   * Select the files in the FileSystem dock.
   * In the **Import** tab, change "Import As" to **Keep File (No Import)**.
   * Click **Reimport**.
