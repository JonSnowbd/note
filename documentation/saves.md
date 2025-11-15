# Save Files

By extending `NoteSaveSession` you already have what you need to provide Note with your
save structure. Simply put the script in your Note Developer Settings under the save category
as `Session Type`.

## Save File Dev Settings

- Strategy is where you set Simple(instant non-changeable save profile) or Profile Selector(start
the game into a profile selection screen)
- Session Type is the script file you made that extends `NoteSaveSession`
- Sticky is a feature for profile selector, where after picking or creating a save, the user
is automatically logged into that save every startup until they manually go back to save selection
via `note.return_to_save_select()`
- Soft settings is not working yet, but will save general settings such as volumes, fullscreen,
window position/size, and restore them each time your game launches. It will be recommended
for extremely quick/small games that don't want to bother with a save file.
- Pulse Duration determines the interval at which your save file receives the 'heartbeat' type method
called `pulse(time: float)`
