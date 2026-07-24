class_name EssencePaths extends RefCounted

#Extension shortcut
const EXTENSION_PNG = ".png"
const EXTENSION_TSCN = ".tscn"
const EXTENSION_WAV = ".wav"

# ==========================================
# RUTAS BASE
# ==========================================
const BASE_ROUTE = "res://addons/iOplazxEssence/"
const BASE_RESOURCES = BASE_ROUTE + "resources/"

const PATH_IMAGES = BASE_RESOURCES + "images/"
const PATH_IMAGES_BACKGROUND = PATH_IMAGES + "background/"
const PATH_IMAGES_CHARACTER = PATH_IMAGES + "character/"
const PATH_IMAGES_OBJECTS = PATH_IMAGES + "objects/"
const PATH_IMAGES_ICON = PATH_IMAGES + "icon/"

const PATH_AUDIO = BASE_RESOURCES + "audio/"
const PATH_CORE = BASE_ROUTE + "core/"

const PATH_UI = BASE_ROUTE + "ui/"
const PATH_UI_CARDS = BASE_ROUTE + "ui/cards/"
const PATH_UI_OVERLAYS = BASE_ROUTE + "ui/overlays/"
const PATH_UI_SCREEN = BASE_ROUTE + "ui/screens/"
const PATH_UI_WIDGETS = BASE_ROUTE + "ui/widgets/"

# ==========================================
# RUTAS CARPETAS
# ==========================================
const CARPET_STATIC = "res://_static/"

# ==========================================
# ARCHIVOS ESPECIFICOS
# ==========================================
const PATH_TEST_SAVE_SCENE = PATH_UI + "test/TestSaveScene" + EXTENSION_TSCN

# ==========================================
# RUTAS LOGS
# ==========================================
const DIR_LOGS = "user://logs/"
const DIR_SYSTEM = "user://logs/system/"
const DIR_ERRORS = "user://logs/errors/"
const DIR_GAME = "user://logs/game/"

# ==========================================
# CONSTANTES DIRECTAS (Para usar con preload en Audio/Escenas)
# ==========================================
const AUDIO_UI_SPACE = PATH_AUDIO + "spaceUiSound" + EXTENSION_WAV
const AUDIO_UI_BUBBLE = PATH_AUDIO + "bubbleUiSound" + EXTENSION_WAV
# Puedes agregar aquí escenas también: const SCENE_WARNING = ...

# ==========================================
# DICCIONARIOS DE CARGA DINÁMICA (Para usar con load)
# ==========================================
enum KeyImage {
	GODOT,
	IOPLAZX,
	WARNING,
	EYE,
	PLUS18,
	ERROR_FALLBACK,
	ICON_PLAY,  
	ICON_PAUSE,
	ICON_INFO,
	ICON_INFO_MED,
	ICON_FILTER,
	ICON_FILTER_X,
	ICON_CONTROL,
	ICON_LAYOUT,
	ICON_CONTROL_W,
	ICON_LAYOUT_W,
	ICON_TOUCH
}

const INTERNAL_IMAGES = {
	KeyImage.GODOT: PATH_IMAGES_ICON + "icon_godot" + EXTENSION_PNG,
	KeyImage.IOPLAZX: PATH_IMAGES_ICON + "ioplazx_logo" + EXTENSION_PNG,
	KeyImage.WARNING: PATH_IMAGES_ICON + "iconWarning" + EXTENSION_PNG,
	KeyImage.EYE: PATH_IMAGES_ICON + "iconEye" + EXTENSION_PNG,
	KeyImage.PLUS18: PATH_IMAGES_ICON + "iconPlus18" + EXTENSION_PNG,
	KeyImage.ERROR_FALLBACK: PATH_IMAGES_ICON + "iconImageNoLoad" + EXTENSION_PNG,
	KeyImage.ICON_PLAY: PATH_IMAGES_ICON + "icon_play" + EXTENSION_PNG,
	KeyImage.ICON_PAUSE: PATH_IMAGES_ICON + "icon_pause" + EXTENSION_PNG,
	KeyImage.ICON_INFO: PATH_IMAGES_ICON + "icon_info" + EXTENSION_PNG,
	KeyImage.ICON_INFO_MED: PATH_IMAGES_ICON + "icon_info_med" + EXTENSION_PNG,
	KeyImage.ICON_FILTER: PATH_IMAGES_ICON + "icon_filter" + EXTENSION_PNG,
	KeyImage.ICON_FILTER_X: PATH_IMAGES_ICON + "icon_filter-x" + EXTENSION_PNG,
	KeyImage.ICON_CONTROL: PATH_IMAGES_ICON + "icon_control" + EXTENSION_PNG,
	KeyImage.ICON_LAYOUT: PATH_IMAGES_ICON + "icon_layout" + EXTENSION_PNG,
	KeyImage.ICON_CONTROL_W: PATH_IMAGES_ICON + "icon_control_w" + EXTENSION_PNG,
	KeyImage.ICON_LAYOUT_W: PATH_IMAGES_ICON + "icon_layout_w" + EXTENSION_PNG,
	KeyImage.ICON_TOUCH: PATH_IMAGES_ICON + "iconTouch" + EXTENSION_PNG
}

# ==========================================
# DEMO RESOURCES (ONLY USE FOR DEMO GAME)
# ==========================================
const MODULE_ROUTE = BASE_ROUTE + "modules/"
const MODULE_VISUALNOVEL_ROUTE = MODULE_ROUTE + "visual_novel/"
const MODULE_BASE_ROUTE = MODULE_ROUTE + "base/"
const MODULE_BASE_UI_ROUTE = MODULE_BASE_ROUTE + "ui/"
const PREFAB_UI_ROUTE = MODULE_VISUALNOVEL_ROUTE + "prefab/ui/"

const ICON_SHIRT = PATH_IMAGES_ICON + "iconShirtLittle" + EXTENSION_PNG

const BACKGROUND_ROOM_INITIAL = PATH_IMAGES_BACKGROUND + "background_room_ai_1" + EXTENSION_PNG
const BACKGROUND_ROOM_3DOORS = PATH_IMAGES_BACKGROUND + "background_room_ai_3" + EXTENSION_PNG
const BACKGROUND_ROOM_1DOOR = PATH_IMAGES_BACKGROUND + "background_room_ai_2" + EXTENSION_PNG
const BACKGROUND_PARK = PATH_IMAGES_BACKGROUND + "background_generate_park" + EXTENSION_PNG

const ITEM_GENERIC_INTERACTIVE_CHARACTER = PREFAB_UI_ROUTE + "GenericInteractiveCharacter" + EXTENSION_TSCN
const ITEM_GENERIC_MODULAR_CHARACTER = PREFAB_UI_ROUTE + "GenericModularCharacter" + EXTENSION_TSCN

const MENU_HEXAGONAL_INTERFACE = MODULE_BASE_UI_ROUTE + "EssenceHexagonMenu" + EXTENSION_TSCN

const ESSENCE_DIALOG_BOX_INTERFACE = PREFAB_UI_ROUTE + "EssenceDialogBox" + EXTENSION_TSCN
