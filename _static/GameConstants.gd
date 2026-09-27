class_name GameConstants

# 1. VISUAL / HUMAN: Displayed in the UI, credits, badge, and patches.
const GAME_VERSION = "0.0.4"
# 2. ENGINE / BUILD: For stores (Android versionCode), telemetry, and scripts
const GAME_BUILD_NUMBER: int = 4
# 3. SAVE / STRUCTURE: For the migration factory (GameSaveMigrator)
const CURRENT_SAVE_VERSION = 4
const MIN_SUPPORTED_SAVE_VERSION: int = 1
# File constants
const EXTENSION_SAVE_FILE = ".ess"
const EXTENSION_IMAGE = ".webp"
