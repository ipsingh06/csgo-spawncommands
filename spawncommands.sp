#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#pragma semicolon 1
#pragma newdecls required
#define PARAM_RESET "reset"

int g_iSpawnHealth[MAXPLAYERS+1];
bool g_bSpawnHealth[MAXPLAYERS+1];
StringMap g_mapSpawnHealth;

public Plugin myinfo =
{
    name = "Spawn Commands",
    author = "Xlurmy",
    description = "Set player properties on spawn. Based off Set Health by joac1144 / Zyanthius [DK]",
    version = "0.1",
    url = ""
};

public void OnPluginStart() {
    LoadTranslations("common.phrases");
    RegAdminCmd("sm_spawnhp", Command_SpawnHP, ADMFLAG_SLAY, "Set health on spawn.");
    RegAdminCmd("sm_spawnhealth", Command_SpawnHP, ADMFLAG_SLAY, "Set health on spawn.");

    HookEvent("player_spawn", vPlayerSpawn);

    g_mapSpawnHealth = new StringMap();
    Reset();
}

public void OnMapStart() {
    Reset();
}

void Reset() {
    // Reset commands
    for (int i = 0; i <= MAXPLAYERS; i++) {
        g_bSpawnHealth[i] = false;
    }
    g_mapSpawnHealth.Clear();
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
        ReplyToCommand(client, "[SM] Usage: sm_spawnhp <#userid|name> <HP value|reset>");
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

    return Command_Generic("spawnhp", client, target, iHP, reset, g_iSpawnHealth, g_bSpawnHealth, g_mapSpawnHealth);
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
    int value;

    // Spawn health
    if(GetSpawnValueForPlayer(player_id, g_iSpawnHealth, g_bSpawnHealth, g_mapSpawnHealth, value)) {
        SetEntityHealth(player_id, value);
    }
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
