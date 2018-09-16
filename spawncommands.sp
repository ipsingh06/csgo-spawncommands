#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#pragma semicolon 1
#pragma newdecls required

#define PARAM_RESET "reset"

#define CS_SLOT_PRIMARY     0   /**< Primary weapon slot. */
#define CS_SLOT_SECONDARY   1   /**< Secondary weapon slot. */
#define CS_SLOT_KNIFE       2   /**< Knife slot. */
#define CS_SLOT_GRENADE     3   /**< Grenade slot (will only return one grenade). */
#define CS_SLOT_C4          4   /**< C4 slot. */

int g_iSpawnHealth[MAXPLAYERS+1],
    g_iSpawnSpeed[MAXPLAYERS+1],
    g_iSpawnArmor[MAXPLAYERS+1],
    g_iSpawnCash[MAXPLAYERS+1],
    g_iSpawnHelmet[MAXPLAYERS+1],
    g_iSpawnWeaponAmmoClip[MAXPLAYERS+1],
    g_iSpawnWeaponAmmoReserve[MAXPLAYERS+1];

bool g_bSpawnHealth[MAXPLAYERS+1],
     g_bSpawnSpeed[MAXPLAYERS+1],
     g_bSpawnArmor[MAXPLAYERS+1],
     g_bSpawnCash[MAXPLAYERS+1],
     g_bSpawnHelmet[MAXPLAYERS+1],
     g_bSpawnWeaponAmmoClip[MAXPLAYERS+1],
     g_bSpawnWeaponAmmoReserve[MAXPLAYERS+1];

StringMap g_mapSpawnHealth,
          g_mapSpawnSpeed,
          g_mapSpawnArmor,
          g_mapSpawnCash,
          g_mapSpawnHelmet,
          g_mapSpawnWeaponAmmoClip,
          g_mapSpawnWeaponAmmoReserve;

public Plugin myinfo =
{
    name = "Spawn Commands",
    author = "Xlurmy",
    description = "Set player properties on spawn.",
    version = "0.1",
    url = ""
};

public void OnPluginStart() {
    LoadTranslations("common.phrases");
    RegAdminCmd("sm_spawn_hp", Command_SpawnHP, ADMFLAG_SLAY, "Set health on spawn.");
    RegAdminCmd("sm_spawn_health", Command_SpawnHP, ADMFLAG_SLAY, "Set health on spawn.");
    RegAdminCmd("sm_spawn_speed", Command_SpawnSpeed, ADMFLAG_SLAY, "Set speed on spawn.");
    RegAdminCmd("sm_spawn_armor", Command_SpawnArmor, ADMFLAG_SLAY, "Set speed on spawn.");
    RegAdminCmd("sm_spawn_cash", Command_SpawnCash, ADMFLAG_SLAY, "Set cash on spawn.");
    RegAdminCmd("sm_spawn_helmet", Command_SpawnHelmet, ADMFLAG_SLAY, "Set helmet on spawn.");
    RegAdminCmd("sm_spawn_weapon_ammo_clip", Command_SpawnWeaponAmmoClip, ADMFLAG_SLAY, "Set weapon clip ammo on spawn.");
    RegAdminCmd("sm_spawn_weapon_ammo_reserve", Command_SpawnWeaponAmmoReserve, ADMFLAG_SLAY, "Set weapon reserve ammo on spawn.");

    HookEvent("player_spawn", vPlayerSpawn);

    g_mapSpawnHealth = new StringMap();
    g_mapSpawnSpeed = new StringMap();
    g_mapSpawnArmor = new StringMap();
    g_mapSpawnCash = new StringMap();
    g_mapSpawnHelmet = new StringMap();
    g_mapSpawnWeaponAmmoClip = new StringMap();
    g_mapSpawnWeaponAmmoReserve = new StringMap();
    Reset();
}

public void OnMapStart() {
    Reset();
}

void Reset() {
    // Reset commands
    for (int i = 0; i <= MAXPLAYERS; i++) {
        g_bSpawnHealth[i] = false;
        g_bSpawnSpeed[i] = false;
        g_bSpawnArmor[i] = false;
        g_bSpawnCash[i] = false;
        g_bSpawnHelmet[i] = false;
        g_bSpawnWeaponAmmoClip[i] = false;
        g_bSpawnWeaponAmmoReserve[i] = false;
    }
    g_mapSpawnHealth.Clear();
    g_mapSpawnSpeed.Clear();
    g_mapSpawnArmor.Clear();
    g_mapSpawnCash.Clear();
    g_mapSpawnHelmet.Clear();
    g_mapSpawnWeaponAmmoClip.Clear();
    g_mapSpawnWeaponAmmoReserve.Clear();
}

bool IsPlayerTargetted(int player_id, const char[] target) {
    char target_name[MAX_NAME_LENGTH];
    int target_list[MAXPLAYERS], target_count;
    bool tn_is_ml;

    target_count = ProcessTargetString(target, 0, target_list, MAXPLAYERS, COMMAND_FILTER_ALIVE, target_name, sizeof(target_name), tn_is_ml);
    if(target_count > 0) {
        for (int i = 0; i <= target_count; i++) {
            if(target_list[i] == player_id) {
                return true;
            }
        }
    }
    return false;
}

bool IsStickyTarget(const char[] target) {
    char STICKY_TARGETS[7][] = { 
        "@ct", "@cts",
        "@t", "@ts",
        "@humans",
        "@bots",
        "@all"
    };

    for(int i=0; i<sizeof(STICKY_TARGETS); i++) {
        if(StrEqual(STICKY_TARGETS[i], target, false)) {
            return true;
        }
    }
    return false;
}

public Action Command_SpawnHP(int client, int args) {
    // Check args
    if (args != 2) {
        ReplyToCommand(client, "[SM] Usage: sm_spawn_hp <#userid|name> <HP value|reset>");
        return Plugin_Handled;
    }

    char target[32], sValue[32];
    GetCmdArg(1, target, sizeof(target));
    GetCmdArg(2, sValue, sizeof(sValue));

    bool reset = false;
    // Check value
    int iHP = StringToInt(sValue);
    if(iHP < 1 || StrEqual(PARAM_RESET, sValue)) {
        reset = true;
    }

    return Command_Generic("spawn hp", client, target, iHP, reset, g_iSpawnHealth, g_bSpawnHealth, g_mapSpawnHealth);
}

public Action Command_SpawnSpeed(int client, int args) {
    // Check args
    if (args != 2) {
        ReplyToCommand(client, "[SM] Usage: sm_spawn_speed <#userid|name> <speed value|reset>");
        return Plugin_Handled;
    }

    char target[32], sValue[32];
    GetCmdArg(1, target, sizeof(target));
    GetCmdArg(2, sValue, sizeof(sValue));

    bool reset = false;
    // Check value
    int iSpeed = StringToInt(sValue);
    if(iSpeed < 0 || iSpeed > 50000 || StrEqual(PARAM_RESET, sValue)) {
        reset = true;
    }

    return Command_Generic("spawn speed", client, target, iSpeed, reset, g_iSpawnSpeed, g_bSpawnSpeed, g_mapSpawnSpeed);
}

public Action Command_SpawnArmor(int client, int args) {
    // Check args
    if (args != 2) {
        ReplyToCommand(client, "[SM] Usage: sm_spawn_armor <#userid|name> <armor value|reset>");
        return Plugin_Handled;
    }

    char target[32], sValue[32];
    GetCmdArg(1, target, sizeof(target));
    GetCmdArg(2, sValue, sizeof(sValue));

    bool reset = false;
    // Check value
    int iArmor = StringToInt(sValue);
    if(iArmor < 0 || StrEqual(PARAM_RESET, sValue)) {
        reset = true;
    }

    return Command_Generic("spawn armor", client, target, iArmor, reset, g_iSpawnArmor, g_bSpawnArmor, g_mapSpawnArmor);
}

public Action Command_SpawnCash(int client, int args) {
    // Check args
    if (args != 2) {
        ReplyToCommand(client, "[SM] Usage: sm_spawn_cash <#userid|name> <cash value|reset>");
        return Plugin_Handled;
    }

    char target[32], sValue[32];
    GetCmdArg(1, target, sizeof(target));
    GetCmdArg(2, sValue, sizeof(sValue));

    bool reset = false;
    // Check value
    int iCash = StringToInt(sValue);
    if(iCash < 0 || StrEqual(PARAM_RESET, sValue)) {
        reset = true;
    }

    return Command_Generic("spawn cash", client, target, iCash, reset, g_iSpawnCash, g_bSpawnCash, g_mapSpawnCash);
}

public Action Command_SpawnHelmet(int client, int args) {
    // Check args
    if (args != 2) {
        ReplyToCommand(client, "[SM] Usage: sm_spawn_helmet <#userid|name> <0|1|reset>");
        return Plugin_Handled;
    }

    char target[32], sValue[32];
    GetCmdArg(1, target, sizeof(target));
    GetCmdArg(2, sValue, sizeof(sValue));

    bool reset = false;
    // Check value
    int iHelmet = StringToInt(sValue);
    if(iHelmet < 0 || iHelmet > 1 || StrEqual(PARAM_RESET, sValue)) {
        reset = true;
    }

    return Command_Generic("spawn helmet", client, target, iHelmet, reset, g_iSpawnHelmet, g_bSpawnHelmet, g_mapSpawnHelmet);
}

public Action Command_SpawnWeaponAmmoClip(int client, int args) {
    // Check args
    if (args != 2) {
        ReplyToCommand(client, "[SM] Usage: sm_spawn_weapon_ammo_clip <#userid|name> <ammo value|reset>");
        return Plugin_Handled;
    }

    char target[32], sValue[32];
    GetCmdArg(1, target, sizeof(target));
    GetCmdArg(2, sValue, sizeof(sValue));

    bool reset = false;
    // Check value
    int iAmmo = StringToInt(sValue);
    if(iAmmo < 0 || StrEqual(PARAM_RESET, sValue)) {
        reset = true;
    }

    return Command_Generic("spawn weapon ammo clip", client, target, iAmmo, reset,
        g_iSpawnWeaponAmmoClip, g_bSpawnWeaponAmmoClip, g_mapSpawnWeaponAmmoClip);
}

public Action Command_SpawnWeaponAmmoReserve(int client, int args) {
    // Check args
    if (args != 2) {
        ReplyToCommand(client, "[SM] Usage: sm_spawn_weapon_ammo_reserve <#userid|name> <ammo value|reset>");
        return Plugin_Handled;
    }

    char target[32], sValue[32];
    GetCmdArg(1, target, sizeof(target));
    GetCmdArg(2, sValue, sizeof(sValue));

    bool reset = false;
    // Check value
    int iAmmo = StringToInt(sValue);
    if(iAmmo < 0 || StrEqual(PARAM_RESET, sValue)) {
        reset = true;
    }

    return Command_Generic("spawn weapon ammo reserve", client, target, iAmmo, reset,
        g_iSpawnWeaponAmmoReserve, g_bSpawnWeaponAmmoReserve, g_mapSpawnWeaponAmmoReserve);
}

public Action Command_Generic(
        const char[] command,
        int client,
        const char[] target,
        int value,
        bool reset,
        int[] playerValues,
        bool[] playerEnabled,
        StringMap targetValues
) {
    char target_name[MAX_NAME_LENGTH];
    int target_list[MAXPLAYERS], target_count;
    bool tn_is_ml;

    if(IsStickyTarget(target)) {
        // Set for a sticky target
        if(reset) {
            targetValues.Remove(target);
            LogAction(client, -1, "Admin %L reset %s of %s", client, command, target);
        } else {
            targetValues.SetValue(target, value, true);
            LogAction(client, -1, "Admin %L set %s of %s to %d", client, command, target, value);
        }
        // Just for translation
        ProcessTargetString(target, client, target_list, MAXPLAYERS, COMMAND_FILTER_ALIVE, target_name, sizeof(target_name), tn_is_ml);
    } else {
        // Set for specific targets
        target_count = ProcessTargetString(target, client, target_list, MAXPLAYERS, COMMAND_FILTER_ALIVE, target_name, sizeof(target_name), tn_is_ml);
        if (target_count <= 0) {
            ReplyToTargetError(client, target_count);
            return Plugin_Handled;
        } else {
            for(int i=0; i<target_count; i++) {
                int target_id = target_list[i];
                if(reset) {
                    playerEnabled[target_id] = false;
                    LogAction(client, -1, "Admin %L reset %s of %L", client, command, target_id);
                } else {
                    playerEnabled[target_id] = true;
                    playerValues[target_id] = value;
                    LogAction(client, target_id, "Admin %L set %s of %L to %d", client, command, target_id, value);
                }
            }
        }
    }

    // Print action
    if (tn_is_ml) {
        if(reset) {
            ShowActivity2(client, "[SM] ", "Reset %s on %t", command, target_name);
        } else {
            ShowActivity2(client, "[SM] ", "Set %s of %d on %t", command, value, target_name);
        }
    } else {
        if(reset) {
            ShowActivity2(client, "[SM] ", "Reset %s on %s", command, target_name);
        } else {
            ShowActivity2(client, "[SM] ", "Set %s of %d on %s", command, value, target_name);
        }
    }

    return Plugin_Handled;
}

public void vPlayerSpawn(Event event, const char[] name, bool dontBroadcast) {
    int player_id = GetClientOfUserId(event.GetInt("userid"));
    // Need to delay a little bit before we can set some properties
    CreateTimer(0.1, OnPlayerSpawn, player_id, TIMER_FLAG_NO_MAPCHANGE);
}


public Action OnPlayerSpawn(Handle timer, int player_id) {
    int value;

    // Spawn health
    if(GetSpawnValueForPlayer(player_id, g_iSpawnHealth, g_bSpawnHealth, g_mapSpawnHealth, value)) {
        SetEntityHealth(player_id, value);
        LogAction(0, player_id, "%L health set to %d", player_id, value);
    }

    // Spawn speed
    if(GetSpawnValueForPlayer(player_id, g_iSpawnHealth, g_bSpawnSpeed, g_mapSpawnSpeed, value)) {
        float fSpeed = value/100.0;
        SetEntPropFloat(player_id, Prop_Data, "m_flLaggedMovementValue", fSpeed);
        LogAction(0, player_id, "%L Spawnspeed set to %f", player_id, fSpeed);
    }

    // Spawn armor
    if(GetSpawnValueForPlayer(player_id, g_iSpawnArmor, g_bSpawnArmor, g_mapSpawnArmor, value)) {
        SetEntProp(player_id, Prop_Data, "m_ArmorValue", value);
        LogAction(0, player_id, "%L Spawnarmor set to %d", player_id, value);
    }

    // Spawn cash
    if(GetSpawnValueForPlayer(player_id, g_iSpawnCash, g_bSpawnCash, g_mapSpawnCash, value)) {
        SetEntProp(player_id, Prop_Send, "m_iAccount", value);
        LogAction(0, player_id, "%L Spawncash set to %d", player_id, value);
    }

    // Spawn helmet
    if(GetSpawnValueForPlayer(player_id, g_iSpawnHelmet, g_bSpawnHelmet, g_mapSpawnHelmet, value)) {
        SetEntProp(player_id, Prop_Send, "m_bHasHelmet", value);
        LogAction(0, player_id, "%L Spawnhelmet set to %d", player_id, value);
    }

    // Spawn weapon clip ammo
    if(GetSpawnValueForPlayer(player_id, g_iSpawnWeaponAmmoClip, g_bSpawnWeaponAmmoClip, g_mapSpawnWeaponAmmoClip, value)) {
        int weapon = GetPlayerWeaponSlot(player_id, CS_SLOT_SECONDARY);
        if (IsValidEntity(weapon)) {
            SetEntProp(weapon, Prop_Send, "m_iClip1", value);
            SetEntProp(weapon, Prop_Send, "m_iClip2", value);
            LogAction(0, player_id, "%L weapon clip ammo set to %d", player_id, value);
        }
    }

    // Spawn weapon reserve ammo
    if(GetSpawnValueForPlayer(player_id, g_iSpawnWeaponAmmoReserve, g_bSpawnWeaponAmmoReserve, g_mapSpawnWeaponAmmoReserve, value)) {
        int weapon = GetPlayerWeaponSlot(player_id, CS_SLOT_SECONDARY);
        if (IsValidEntity(weapon)) {
            SetEntProp(weapon, Prop_Send, "m_iPrimaryReserveAmmoCount", value);
            int ammotype = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType");
            if(ammotype != -1) {
                SetEntProp(player_id, Prop_Send, "m_iAmmo", value, _, ammotype);
            }
            LogAction(0, player_id, "%L weapon reserve ammo set to %d", player_id, value);
        }
    }

    return Plugin_Stop;
}

/**
 * Get the spawn value to set for the player
 * Returns false if no value needs to be set
 */
bool GetSpawnValueForPlayer(
        int player_id,
        int[] playerValues,
        bool[] playerEnabled,
        StringMap targetValues,
        int& output_value
) {
    // Check for specific target
    if (playerEnabled[player_id]) {
        output_value = playerValues[player_id];
        return true;
    }

    // Check for sticky target
    StringMapSnapshot mapSnapshot = targetValues.Snapshot();
    for(int i=0; i<mapSnapshot.Length; i++) {
        char target[32];
        int value;
        mapSnapshot.GetKey(i, target, sizeof(target));
        targetValues.GetValue(target, value);
        if(IsPlayerTargetted(player_id, target)) {
            output_value = value;
            return true;
        }
    }

    return false;
}
