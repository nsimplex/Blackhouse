# Blackhouse

Blackhouse is a mod for the game Don't Starve that introduces a set of mechanics for the Night Light. Its main feature is the mechanic of turning Flowers into Evil Flowers through the influence of a lit Night Light.

Blackhouse is free software, licensed under the terms of the GNU GPLv2.

## Description
The standard behaviour of a Night Light is preserved. In addition to that, when lit it will affect the entities close to it in the following manner:
* Flowers turn into Evil Flowers after 1 day of exposure.
* Bees turn into Killer Bees after 10% of a day (48 seconds) of exposure.
* Butterflies turn into Mosquitoes after a few seconds of exposure.
* Vegetables on the ground will turn into Durians after 25% of a day (2 minutes) of exposure.

All of these are configurable. Those are just their default values, which probably need some adjustment anyway.

A couple of threats were designed to thwart your farming goals:
* When a Flower turns into an Evil Flower, there is a 7.5% chance it will catch on fire.
* When you pick an Evil Flower created by a Night Light, every other Evil Flower nearby has a 10% chance of triggering the spawn of a Red Hound offscreen, which will charge after you (as in a hound attack). He will not drop any loot when killed, except for fire.

These probabilities are also configurable. Setting a threat to 0 probability will disable it. If you know some Lua and are looking to customize these further, each probability configuration can also be given as a function that acts on its trigger by returning the corresponding probability.

The area of effect of a lit Night Light is a circle with an 8 meter radius. It does not stack with the effect of other nearby Night Lights, and affects up to 16 (the closest 16) valid entities within in. The effect it has over entities is cumulative over time, is never decreased (not even when the Night Light is off, or the entity goes far away) and is preserved between saves, leading it to its inevitable corruption.

## Disclaimer
This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

## Installation
Put it in the right place and run `make`. A Unix environment with GNU Make and Perl is assumed for the building process.

## Configuration
Just edit the file rc.lua in the Blackhouse folder. Every option's effect is explained in the file.


Check the mod's discussion thread at http://forums.kleientertainment.com/showthread.php?21767
