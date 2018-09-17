# Spawn Commands

Spawn Commands plugin allows you to set player properties like health and speed. Unlike other plugins these are reapplied at spawn and stick with the player throughout the game. You can target specific players or an entire team using @t/@ct.

## Features

* Properties applied every spawn until reset
* Sticky targets: setting properties for targets like @ct will apply to players who join CT later on and stop applying to those who leave the CT team
* Properties applied to a specific player take precedence over properties applied to a generic target like @t/@ct
* Resets on map changes

## Commands

All commands follow the same format:
```
sm_spawn_health <target> <value>
```

A setting can be reset using the same command. The player will revert to the default values on the next spawn.
```
sm_spawn_health <target> reset
```

List of all supported commands:
* **sm_spawn_hp** - Set player health on spawn
* **sm_spawn_health** - Set player health on spawn
* **sm_spawn_speed** - Set player speed on spawn
* **sm_spawn_armor** - Set player armor on spawn
* **sm_spawn_cash** - Set player cash on spawn
* **sm_spawn_helmet** - Set player helmet on spawn
* **sm_spawn_primary_ammo_clip** - Set player's primary weapon clip ammo on spawn
* **sm_spawn_primary_ammo_reserve** - Set player's primary weapon reserve ammo on spawn
* **sm_spawn_secondary_ammo_clip** - Set player's secondary weapon clip ammo on spawn
* **sm_spawn_secondary_ammo_reserve** - Set player's secondary weapon reserve ammo on spawn
* **sm_spawn_grenade_ammo** - Set player's grenade ammo on spawn
* **sm_spawn_knife** - Set/strip player's knife on spawn

Example:
```
// Set all terrorist spawn health to 50
sm_spawn_health @t 50

// Reset the health setting applied to terrorists
sm_spawn_health @t reset
```

## Changelog
* v0.2 - Added primary, secondary and grenade ammo commands
* v0.1 - Initial release
