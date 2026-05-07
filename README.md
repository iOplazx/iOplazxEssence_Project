# iOplazx Essence Framework - Alpha 

A high-performance, modular framework for **Godot Engine 4.x**, designed to streamline the development of narrative-driven games, visual novels, and complex UI systems.

## 🚀 Overview
The **iOplazx Essence Framework** (formerly part of the iOplazxEssence_Project) provides a robust architecture for handling the "essential" systems of any Godot project, allowing developers to focus on gameplay and storytelling rather than backend boilerplate.

## ✨ Key Features
* **Advanced Audio Management:** Built-in support for buses, linear-to-db conversion, and native mute toggles that persist across sessions.
* **Dynamic Localization System:** Support for external `.csv` and script-based translations, featuring a dynamic language browser and auto-restore capabilities.
* **Smart Resource Loading:** The `EssenceLoader` system handles both internal resources and external "raw" files (PNG, JSON, CFG) seamlessly, even in exported builds.
* **Modular UI Components:** Pre-built, theme-ready nodes like `EssenceRowSlider`, `EssenceConfirmBox`, and `EssenceLanguageCard`.
* **Flexible Preferences:** A centralized system for saving and loading user settings (Video, Audio, Language, Gameplay).

---
## 📥 Installation & Usage

Depending on your needs, you can use this repository in two ways:

1. **Framework Integration (Addon):** If you want to use the engine in your own game, simply download and copy the `addons/iOplazxEssence` folder into your project's `addons/` directory. Then, enable it in your Project Settings.

2. **Full Project & Demo:** If you want to test the framework in action, see the implementation examples, or play the project as a demo, clone or download the **entire repository** and open it with **Godot 4.x**. This is the best way to understand how the systems interact.
---

## 🛠️ Getting Started
### Installation
1. Clone this repository into your Godot 4.x project.
2. Ensure the `addons/iOplazxEssence` folder is correctly placed.


### Documentation
Detailed technical guides and implementation examples are located in the **`HowToUse/`** directory:
* `README_EN.md` - Technical documentation (English).
* `README_ES.md` - Documentación técnica (Español).

---

## ⚖️ License & Terms
This framework is released under the Apache License 2.0.

### Permitted Use:

**Commercial & Private Use**: You can use this framework to create and monetize your own games (Commercial or Free).

**Modification**: You can modify and extend the source code for your specific needs.

**Distribution**: You can distribute your games made with this framework without sharing your game's source code.

### Key Restrictions:

**Attribution:** Original copyright notices to **iOplazx** must remain in the core source files.  
**Standalone Reselling:** You cannot repackage the entire framework to sell it as a competing development tool.  
**Trademark:** Using the **iOplazx** logo for branding purposes requires permission (unless used for in-game credits/splash screens).

---

## 🧪 Development Status
This is an **Alpha** release. We are constantly optimizing the core nodes and expanding the API. If you find a bug or have a feature request, please open an issue in the repository.

---

**Developed with ❤️ by iOplazx Productions.**
*Just a programming enthusiast sharing tools with the community.*