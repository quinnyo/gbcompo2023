# Gigant Golf

## You Gigant. You golf, too.

Gigant has been watching the humans for a long time.

When the humans first arrived, Gigant hid and watched them from behind a forest.
Gigant was embarrassed about this and found it too awkward to do introductions on subsequent encounters.
Gigant remained hidden.

Now there are humans everywhere. The water is stinky and the fish are all gone.
The humans must be eating something though! Hungry, Gigant resolved to meet the humans.

Help Gigant learn to live with the humans by playing their weird game of 'Golf'.

## Sure, but what is this?

Gigant Golf is a Game Boy (DMG) game, made for [GB Compo 2023](https://itch.io/jam/gbcompo23).

It's kind of like Rampage + a Golf Sim (choose one, they are literally all identical).
It was made in a hurry by someone with no experience writing Game Boy games in assembly,
so some of the Rampage parts are missing, and also some of the Golf Sim parts are missing.

You can drop a big rock on some little houses though.

You can get a binary [on itch.io](https://quinevere.itch.io/gigant-golf).

* This game features <0> sound effects
* Warning: all collisions are simulated... poorly.
* Made for [GB Compo 2023](https://itch.io/jam/gbcompo23)
* Written in assembly (RGBASM)
* Maps built in [Tiled](https://mapeditor.org)


## License
* This project is free software. The code is licensed under GPLv3.
* Non-code assets are provided under the terms of the Creative Commons Attribution-ShareAlike license (CC BY-SA).


## Building
The Makefile is a mess. The tool scripts are a mess. You should probably do a clean build every time.

Prerequisites:
* [RGBDS](https://rgbds.gbdev.io/)
* [pytiled_parser](https://github.com/pythonarcade/pytiled_parser/): required to build the maps

By default, a python venv at `tools/pyenv` is expected to exist. This environment is to have `pytiled_parser` installed.
Otherwise, the python interpreter can be overridden with one that does have the prerequisites.

Then, building the ROM should be as simple as `make`.
The built ROM should be at `target/bin/gigantgolf.gb`.
