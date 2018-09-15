#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#pragma semicolon 1
#pragma newdecls required
#define PARAM_RESET "reset"

int g_iSpawnHealth[MAXPLAYERS+1];
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
    	g_iSpawnHealth[i] = 0;
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
    char target[32], sHP[32];
    GetCmdArg(1, target, sizeof(target));
    GetCmdArg(2, sHP, sizeof(sHP));
    char target_name[MAX_NAME_LENGTH];
    int target_list[MAXPLAYERS], target_count;
    bool tn_is_ml;
    bool reset = false;

    // Check args
    if (args != 2) {
        ReplyToCommand(client, "[SM] Usage: sm_spawnhp <#userid|name> <HP value>|reset");
        return Plugin_Handled;
    }

    // Check value
    int iHP = StringToInt(sHP);
    if(iHP < 1 || StrEqual(PARAM_RESET, sHP)) {
        reset = true;
    }

    if(IsStickyTarget(target)) {
        // Set for a sticky target
        if(reset) {
            g_mapSpawnHealth.Remove(target);
            LogAction(client, -1, "Admin %L reset spawnhp of %s", client, target);
        } else {
            g_mapSpawnHealth.SetValue(target, iHP, true);
            LogAction(client, -1, "Admin %L set spawnhp of %s to %d", client, target, iHP);
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
                    g_iSpawnHealth[target_id] = 0;
                    LogAction(client, -1, "Admin %L reset spawnhp of %L", client, target_id);
                } else {
                    g_iSpawnHealth[target_id] = iHP;
                    LogAction(client, target_id, "Admin %L set spawnhp of %L to %d", client, target_id, iHP);
                }
            }
        }
    }

    // Print action
    if (tn_is_ml) {
        if(reset) {
            ShowActivity2(client, "[SM] ", "Reset spawnhp on %t", target_name);
        } else {
            ShowActivity2(client, "[SM] ", "Set spawnhp of %d on %t", iHP, target_name);
        }
    } else {
        if(reset) {
            ShowActivity2(client, "[SM] ", "Reset spawnhp on %s", target_name);
        } else {
            ShowActivity2(client, "[SM] ", "Set spawnhp of %d on %s", iHP, target_name);
        }
    }

    return Plugin_Handled;
}

public void vPlayerSpawn(Event event, const char[] name, bool dontBroadcast) {
    int iPlayer = GetClientOfUserId(event.GetInt("userid"));

    // Check for specific target
    int iHP = g_iSpawnHealth[iPlayer];
    if (iHP > 0) {
        SetEntityHealth(iPlayer, iHP);
        return;
    }

    // Check for sticky target
    StringMapSnapshot mapSnapshot = g_mapSpawnHealth.Snapshot();
    for(int i=0; i<mapSnapshot.Length; i++) {
        char target[32];
        int value;
        mapSnapshot.GetKey(i, target, sizeof(target));
        g_mapSpawnHealth.GetValue(target, value);
        if(value > 0 && IsPlayerTargetted(iPlayer, target)) {
            SetEntityHealth(iPlayer, value);
            return;
        }
    }
}