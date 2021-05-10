# End's Battle Brothers Modkit 

`Version: 0.1.0`\
[Github Repo](https://github.com)\
Author: Enduriel (endur1el@protonmail.com, Discord: Enduriel#2727)

### License
[Attribution-ShareAlike 4.0 International (CC BY-SA 4.0)](https://creativecommons.org/licenses/by-sa/4.0/legalcode)

## Features

The modkit lets you issue commands to streamline the Battle Brothers modding experience,
is has a number of features that I and (from what I've seen) others have independently
developed that help to:
* Update your mod from a working directory to the Battle Brothers/data folder with
 	options to compile and remove .nut files
* Export your mod to an export directory with the same options as with update
 	(meant for exporting a mod to an easily accessible directory after testing)
* Import other mods or game data folder into your working directory, decompiling all
 	nuts and deleting all cnuts
* Delete the mod you're currently working on from the game/data folder
* Open your Battle Brothers Log

## Contents

The modkit relies on [Adam Milazzo's Battle Brothers mod kit](http://www.adammil.net/blog/v133_Battle_Brothers_mod_kit.html), an outstanding set of tools
that allowed people to start modding in the first place, which also relies on [DamianXVI's nutcracker](https://github.com/darknesswind/NutCracker)
Specifically it comes packaged with 3 .exes inside of /adams_kit, additionally I also use TaroEld's massdecompile script
to compile .cnuts while preserving their structure inside of /scripts to allow usage of
more advanced/recent Modding Script Hooks functions. It also has a cli.yml file for CLI
configuration and a config.yml to store the directories described commands. I will try to keep my versions of the exes up to date but I can't
guarantee that so make sure to check for updates.

## Usage

This is a CLI application intended for windows (though thanks to Rust's rubostness
it should work cross-platform, mostly), and therefore requires you to run it via cmd on windows
in cmd run bbkit -h for help as to the different commands, but here is a list:\
Commands are called in the format: `bbkit [SUBCOMMAND] -[SUBCOMMAND_ARGS]`
* `subcommand [shorthand]` subcommand description
 * `argument [shorthand] {value_to_pass} (required?)` argument description

### List of Commands

* `config [c]` Get config
  * `-clear [-c]` Clear config
* `set_work_dir [wd]` Set working directory (folder containing all mods you work on)
  * `-directory [-d] {path} (required)` directory to save
* `set_export_dir [ed]` Set export directory (folder to export completed mods to)
 * `-directory [-d] {path} (required)` directory to save
* `set_mod_dir [md]` Set current mod directory (folder of the mod you are currently working on to shorten other commands, eg: `bbkit u` rather than `bbkit u -d path/to/current/mod`)
  * `-directory [-d] {path} (required)` directory to save
* `set_game_dir [gd]` Set game directory (game folder called "Battle Brothers", containing a /data directory)
  * `-directory [-d] {path} (required)` directory to save
* `update [u]` update the mod in Battle Brothers/data specified with `set_game_dir`
  * `-mod [-m] {path} (default = mod_dir)` mod folder to update
  * `-compile [-c]` compile .nut files to .cnut (Should only be used if replacing vanilla files or using a lot of vanilla code in mod)
  * `-remove_nuts [-r]` remove .nut files (ONLY DO THIS IF YOU ARE REDISTRIBUTING OVERHYPE CODE), does nothing if -c isn't also passed
* `export [e]` export the mod to an easily accessible folder
  * `-mod [-m] {path} (default = mod_dir)` mod to export
  * `-directory {path} (default = export_dir)` directory to export to
  * `-compile [-c]` compile .nut files to .cnut (Should only be used if replacing vanilla files or using a lot of vanilla code in mod)
  * `-remove_nuts [-r]` remove .nut files (ONLY DO THIS IF YOU ARE REDISTRIBUTING OVERHYPE CODE), does nothing if -c isn't also passed
* `import [i]` import a mod into your working directory (also works with .dat vanilla files)
  * `-mod [-m] {zip} (required)` mod to import
  * `-directory [-d] {path} (default = work_dir)` directory to import to
  * `-keep_cnuts -k` option to keep .cnut files
* `delete [d]` delete the mod specified in mod_dir from your data folder [NOT working directory] (useful if you want to test what happens if you're not running a mod)
* `log [l]` Opens Battle Brothers log

### Examples

`bbkit wd -d D:/Other/Modding/BBros` to set general battle brothers working directory to BBros\
`bbkit md -d D:/Other/Modding/BBros/mod_EIMO` to set current mod to mod_EIMO\
`bbkit gd -d "D:SteamLibrary/steamapps/common/Battle Brothers"` to set game directory to correct folder Make sure to use "" if you have spaces in the path (as you always will with game_directory)\
`bbkit ed -d D:/Other/Modding/BBros/Export` to set export directory to Export inside of BBros (can be anywhere)\
`bbkit u` to update mod_EIMO version inside of Battle Brothers/data to whatever is in D:/Other/Modding/BBros/mod_EIMO\
`bbkit d` to delete the mod_EIMO version inside of Battle Brothers/data\
`bbkit i -m path/to/mod.zip` to import mod.zip into BBros where it will become a directory mod\
`bbkit e -m D:/Other/Modding/BBros/mod -d D:/Other -c -r` to export BBros/mod to D:/Other, compile it's nuts into cnuts, and remove it's nuts. This should basically be only used by Legends, it is unlikely anyone else will use enough Overhype code for this

