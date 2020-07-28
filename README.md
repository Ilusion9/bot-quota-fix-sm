# Description
Bot quota fix for CS:GO.

# Alliedmods
https://forums.alliedmods.net/showthread.php?t=323988

# ConVars
```
sm_bots_num 6 - Determines the total number of bots in the game.
sm_bots_mode round - Determines the type of quota. Allowed values: "fix", "round" and "dm".
```

# Usage
## sm_bots_mode fix
- This type will always keep sm_bots_num bots in the server, even if the server is full. Setting sm_bots_num on 0 + sm_bots_mode on fix = nobots.

## sm_bots_mode round
- This type will always keep sm_bots_num bots in the server and will add/remove bots in the beginning of the round. Switching teams will not change the number of the bots (this is possible in warmup and will screw up the bot_quota convar. This plugin fixes this bug).
- This should be used on round type modes (casual, competitive etc).

## sm_bots_mode dm
- This type will always keep sm_bots_num bots in the server and will add/remove bots when players joins/change teams or when they leave the server. Switching teams will not change the number of the bots (this is possible in dm and will screw up the bot_quota convar. This plugin fixes this bug).
- This should be used on deathmatch modes (modes based on respawn: dm, ffa dm, gungame, awp with respawn etc.), even if you use game_mode and game_type as casual, comp etc.

## sm_bots_mode arena
- Keep 1 bot if someone is without an opponent in arena.

### I recommend these convars, because changing bot_quota too much will screw up the number of the players (on steam browser or gametracker):
```
host_name_store 1
host_info_show 2
host_players_show 2
```
