<p align="center">
  <img src="/documentation/logo.png" />
</p>
<h1 align="center"> Note</h1>

Note is a simple shim. By loading the Note entry scene first, and defining
a settings file you get a buttload of QoL features and nodes at the cost
of slight freedom in the initialization of your app.

For trading off some installation time and learning how to structure a save file(it's
easy, I promise!) you get:

- A code-first UI system inspired by MVU and Elm UI architecture. Make UI's with one function
that defines all the props and reactions and let Note diff it against the current layout for
efficient refreshes.
- A built in per-project documentation journal
- Very flexible and customizable transition system that lets you trigger
a transition anywhere anytime, without needing to change your level, it can be used
to simply cover a teleport.
- Simple UI Focus mode meant to simplify adjusting a UI for use with Gamepad.
- A pseudo ECS based on integration with nodes.
- Automatic loading behaviours including loading screen and level changer, that all
work together to make your game seamless, and handle better practices for you, such as
asynchronous loading screens, and background pre-loading.
- A logic chain system for orchestrating game interactions.
- A collection of optional commonplace UI Elements ready to use out of the box, such as
control guides and tooltips.
- And an extremely easy way to modify your types to have custom editors.
Mever having to make a EditorInspectorPlugin again was really fun.
- Tons of standalone nodes and utility functions that cover basic needs

Take any of note's features at your own pace or as you need them, or don't, note gives many
advantages out of the box

![A picture of the in-editor journal that Note provides](/documentation/journal.png)

---

## Project Status

> [!CAUTION]
> Note tracks with **Godot 4.8 Dev** cycle, awaiting Traits before settling on Stable.
Traits will be used extensively for Note features and as such will be in flux prior to,
and during the Traits dev release.

I'm using Note right now to develop a game, and I'm adding new features and fixing bugs
as I go, and as such I don't recommend using it just yet unless you're cool with breaking
changes happening quite often as I distill Note into something even more ergonomic.

With that said, I will be doing my best to maintain documentation going forward so you're never
lost while using Note. It's also worth mentioning that after you make your save file and settings file,
Note gets out of your way real quick so you should not be blocked by Note breaking changes often.

---

## Install

> [!NOTE]
> If you are experienced with installing Godot plugins, you can skip to the end of this
category and read the last few steps! It's nothing new besides the use of a settings
file in your project settings.

> [!IMPORTANT]
> Its normal to see a lot of errors when you first add the addon, this is due
> to note using the `note` global inside its own code. They will all disappear when you
> enable the plugin and restart.

<details>

<summary>
In your Godot project use <code>git submodule add https://github.com/JonSnowbd/note addons/note</code>
(If this fails make sure your project is a git repo with <code>git init</code>) OR clone this repo and
place it in your <code>YOUR_PROJECT/addons/</code> folder.
</summary>

![Screenshot of your godot folder after the above commands](/documentation/post_install.png)

</details>

<details>

<summary>In your project settings enable Note</summary>

![Enabling note in your project settings](/documentation/enabling_note.png)

</details>

<details>

<summary>
And then create a Note Developer Settings file in your project. Note will automatically
find it and set the settings file to be the default one. If you want to change the settings
file that note uses, you can change or set it manually in <code>ProjectSettings/Addons/Note</code>
</summary>

![Creating your Note developer file](/documentation/creating_settings.png)

</details>

<details>

<summary>
Finally in your Project Settings set the main scene to Note's entry,
and your games main scene to the settings file initial scene. You're done!
</summary>

![Setting the entry scenes up.](/documentation/setting_entry_points.png)

</details>

## Your Integration Checklist

- [ ] Add the `note` folder to `YOUR_PROJECT/addons/`
- [ ] Enable `note` in Project Settings
- [ ] Create a `NoteDeveloperSettings` resource in your project for Note to automatically
detect(or set it manually in `ProjectSettings/Addons/Note`)
- [ ] Set your Entry Scene to `res://addons/note/ENTRY.tscn`
- [ ] Set your game's entry scene in your `NoteDeveloperSettings` file.
- [ ] **(Optional)** Create a custom Save Script and set it in your Developer Settings

## Credits

Note wouldnt be what it is without the open source/MIT projects it stands on:

- https://kenney.nl/assets/input-prompts
- https://kenney.nl/assets/ui-audio
- https://gl-transitions.com
- https://www.svgrepo.com/collection/denali-solid-interface-icons
- https://fonts.google.com/specimen/Outfit
- https://github.com/binogure-studio/godot-uuid/tree/master

(These are packaged up already, you do not need to install these dependencies!)

## License

Note uses the MIT License.
