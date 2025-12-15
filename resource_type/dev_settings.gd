extends Resource
class_name NoteDeveloperSettings

enum NoteEntrySceneType {
	## If this is selected, there will be a sticky, default profile and no choice
	## will be provided to the user. Extremely simple, and fast start for games
	## where making save files does not make sense.
	SIMPLE,
	## If this is selected, the end user can create, delete, and select from
	## their created save files.
	PROFILE_SELECTOR,
}


## The initial scene that will be opened after a save is selected/created, or
## the scene that will be immediately presented to users with sticky saves, or
## the simple save strategy selected
@export_file("*.tscn", "*.scn") var initial_scene: String
## For the phase control system you should list them here. They will be summonable
## with their UID, their path, the base node name, or the class name of the script they inherit.
@export_file("*.tscn", "*.scn") var phases: Array[String]

@export_group("Saves", "save_")
## Select how the end user will experience the start of the game. This
## will change the startup scene that note uses to present the save file to
## the user.
@export var save_strategy: NoteEntrySceneType
## This script will be instantiated as the save type for every session.
@export var save_session_type: Script
## If true, and using a profile selector save strategy, the save created/selected
## will be 'stuck' and auto-loaded as if strategy was set to simple, highly recommended
## for games where save swapping is not a common occurance.
@export var save_sticky: bool = true
## If true, note will remember bus volumes, and fullscreen state and apply them
## on load, before even a save is selected. If you have sticky save's off, this
## is highly recommended, to prevent the user experience of loud sounds before 
## their settings are loaded.
@export var save_soft_settings: bool = false
## This is the time between "pulses" sent to the save session. It's intended to use this
## function for things such as tracking time until auto-save, or other book keeping related
## to your save session that you don't want every frame.
@export var save_pulse_duration: float = 1.0

@export_storage var developer_journal: NoteJournalResource


# TODO
#@export_group("Hoist Mods")
## Mods are disabled by default!! If enabled, every .pck in the mod folder, in the user path,
## will be opened, and then their content fed to the provided script. From there it is only needed
## that the introduction script read packed scenes, and scripts.
#@export var enable_mods: bool = false
#@export var mod_folder: String = "_note_mods"
#@export var mod_introduction_script: Script
