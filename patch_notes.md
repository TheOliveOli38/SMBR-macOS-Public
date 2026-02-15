# Super Mario Bros. Remastered - Update 1.1

# Breaking Changes (*FOR CUSTOM CHARACTER / RESOURCE PACK MAKERS*)
- Updated to Godot 4.6 Stable (This will break basically all GML mods, afaik, and theyll need to be manually updated. Sorry.)
- Starting Castles now have their own unique json files, Meaning that any unique castle sprites you had for end castles wont be applied to them, they work identically to the end castles, so you can just copy paste them if needed.
- Turn Blocks now have 2 unique animations, before they had none, and could only swap textures, (Idle, Turn)
- Peach + Toad have 3 animations (Idle (before the cutscene), Await (while the players walking to them), Talk (while the dialogues showing)), instead of (Idle, Emote) for Toad only.

# New Features / Additions
- New editor actions (Undo, Redo, Multi-Area Selections, Cut, Copy, Paste, Blueprints)
- Editor toolbar, allowing you to change stuff and perform new actions (Reset level)
- Object permanance (Collected objects, blocks, enemies will stay collected / dead / whatever, when the level is reloaded)
- Level Packs
- Player overhaul PR merged (https://github.com/JHDev2006/Super-Mario-Bros.-Remastered-Public/pull/710)
- JSON Localization System / Rewrite (Allowing for community translations via PR's)
- Search bar in Custom level menu (for both locally saved levels, and on the LSS Browser)
- Sort Custom Levels by Downloaded, Saved, or Both.
- Custom level loading rewrite (MUCH faster load times, and more stable fps)
- Classic Player Physics (theyre not perfect, but theyre DAMN close)
- Editor Guide overhaul (its an actual written guide now!)
- Several sprite updates / fixes
- Brand new JSON files / animations, for certain entities / objects.
- SFX's can now have JSON files (not used / made by default, just name the json file the same as the sfx file, and you should be able to figure it out from there)
- Rooms now have a "Enforce Screen Size" setting, which will force all players to use your current aspect ratio, when in that room, (doesnt matter if theyre in widescreen or 4:3 mode)
- Editor Tiles now have descriptions when hovering over them, hold SHIFT to read them.
- Version Checking, game will tell you if your on the latest version or not.
- Castles in Worlds 5, 6, 7 and 8 are now set to be at night, internally

## New Editor Parts
- Angry Sun / Happy Moon
- Homing Bullet Bill
- Bubble Note Blocks
- Snake Blocks
- Crates
- Superball Flower
- Bowser Jr.
- Signs
- Spike Tops
- Chain Chomps
- Ice Blocks
- Frozen Munchers, Coins, Bricks, Turn Blocks
- Fire Piranha Plants
- Static Piranha / Fire Plants (no pipe behaviour)
- 10, 30, 50 Coins
- Hidden Coins
- Wigglers
- Unique Start Castles
- Water Level Areas (turns the whole level to have underwater physics)
- Vines
- Grinders / Small Grinders
- One Way Panels / Small Panels
- Cameras
- Platform Rewrite (more customizable)
- Track Riding Platforms
- Vertically Looping Platforms
- Blue Rope Elevators (Will not fall)
- Gizmos (Fully connectable, programmable logic system)

# Fixes
- lots, dude theres so many, i genuinely cant keep track of them.