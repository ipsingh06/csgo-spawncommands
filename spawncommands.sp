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

#define AMMO_CLIP        0
#define AMMO_RESERVE     1

methodmap SpawnProperty < StringMap {
    public SpawnProperty() {
        StringMap me = new StringMap();
        ArrayList player_values = new ArrayList(1, MAXPLAYERS+1);
        ArrayList player_enabled = new ArrayList(1, MAXPLAYERS+1);
        StringMap target_values = new StringMap();
        me.SetValue("pvalues", player_values, false);
        me.SetValue("penabled", player_enabled, false);
        me.SetValue("tvalues", target_values, false);
        return view_as<SpawnProperty>(me);
    }

    public int GetPlayerValue(int player_id) {
        ArrayList player_values;
        this.GetValue("pvalues", player_values);
        return player_values.Get(player_id);
    }

    public void SetPlayerValue(int player_id, int value) {
        ArrayList player_values;
        this.GetValue("pvalues", player_values);
        player_values.Set(player_id, value);
    }

    public bool GetPlayerEnabled(int player_id) {
        ArrayList player_enabled;
        this.GetValue("penabled", player_enabled);
        return player_enabled.Get(player_id);
    }

    public void SetPlayerEnabled(int player_id, bool enabled) {
        ArrayList player_enabled;
        this.GetValue("penabled", player_enabled);
        player_enabled.Set(player_id, enabled);
    }

    public int GetTargetValue(const char[] target) {
        StringMap target_values;
        this.GetValue("tvalues", target_values);
        int value;
        target_values.GetValue(target, value);
        return value;
    }

    public void SetTargetValue(const char[] target, int value) {
        StringMap target_values;
        this.GetValue("tvalues", target_values);
        target_values.SetValue(target, value, true);
    }

    public void RemoveTarget(const char[] target) {
        StringMap target_values;
        this.GetValue("tvalues", target_values);
        target_values.Remove(target);
    }

    public StringMapSnapshot GetTargets() {
        StringMap target_values;
        this.GetValue("tvalues", target_values);
        return target_values.Snapshot();
    }

    public void Reset() {
        ArrayList player_enabled;
        this.GetValue("penabled", player_enabled);
        for (int i = 0; i <= MAXPLAYERS; i++) {
            player_enabled.Set(i, false);
        }

        StringMap target_values;
        this.GetValue("tvalues", target_values);
        target_values.Clear();
    }
}

SpawnProperty g_spawnHealth;
SpawnProperty g_spawnSpeed;
SpawnProperty g_spawnArmor;
SpawnProperty g_spawnCash;
SpawnProperty g_spawnHelmet;
SpawnProperty g_spawnPrimaryAmmoClip;
SpawnProperty g_spawnPrimaryAmmoReserve;
SpawnProperty g_spawnSecondaryAmmoClip;
SpawnProperty g_spawnSecondaryAmmoReserve;
SpawnProperty g_spawnGrenadeAmmo;
SpawnProperty g_spawnKnife;

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
    RegAdminCmd("sm_spawn_primary_ammo_clip", Command_SpawnPrimaryAmmoClip, ADMFLAG_SLAY, "Set primary weapon's clip ammo on spawn.");
    RegAdminCmd("sm_spawn_primary_ammo_reserve", Command_SpawnPrimaryAmmoReserve, ADMFLAG_SLAY, "Set primary weapon reserve ammo on spawn.");
    RegAdminCmd("sm_spawn_secondary_ammo_clip", Command_SpawnSecondaryAmmoClip, ADMFLAG_SLAY, "Set secondary weapon's clip ammo on spawn.");
    RegAdminCmd("sm_spawn_secondary_ammo_reserve", Command_SpawnSecondaryAmmoReserve, ADMFLAG_SLAY, "Set secondary weapon reserve ammo on spawn.");
    RegAdminCmd("sm_spawn_grenade_ammo", Command_SpawnGrenadeAmmo, ADMFLAG_SLAY, "Set grenade ammo on spawn.");
    RegAdminCmd("sm_spawn_knife", Command_SpawnKnife, ADMFLAG_SLAY, "Set/strip knife on spawn.");

    HookEvent("player_spawn", vPlayerSpawn);

    g_spawnHealth = new SpawnProperty();
    g_spawnSpeed = new SpawnProperty();
    g_spawnArmor = new SpawnProperty();
    g_spawnCash = new SpawnProperty();
    g_spawnHelmet = new SpawnProperty();
    g_spawnPrimaryAmmoClip = new SpawnProperty();
    g_spawnPrimaryAmmoReserve = new SpawnProperty();
    g_spawnSecondaryAmmoClip = new SpawnProperty();
    g_spawnSecondaryAmmoReserve = new SpawnProperty();
    g_spawnGrenadeAmmo = new SpawnProperty();
    g_spawnKnife = new SpawnProperty();

    Reset();
}

public void OnMapStart() {
    Reset();
}

void Reset() {
    g_spawnHealth.Reset();
    g_spawnSpeed.Reset();
    g_spawnArmor.Reset();
    g_spawnCash.Reset();
    g_spawnHelmet.Reset();
    g_spawnPrimaryAmmoClip.Reset();
    g_spawnPrimaryAmmoReserve.Reset();
    g_spawnSecondaryAmmoClip.Reset();
    g_spawnSecondaryAmmoReserve.Reset();
    g_spawnGrenadeAmmo.Reset();
    g_spawnKnife.Reset();
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

    return Command_Generic("spawn hp", client, target, iHP, reset, g_spawnHealth);
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

    return Command_Generic("spawn speed", client, target, iSpeed, reset, g_spawnSpeed);
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

    return Command_Generic("spawn armor", client, target, iArmor, reset, g_spawnArmor);
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

    return Command_Generic("spawn cash", client, target, iCash, reset, g_spawnCash);
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

    return Command_Generic("spawn helmet", client, target, iHelmet, reset, g_spawnHelmet);
}

public Action Command_SpawnPrimaryAmmoClip(int client, int args) {
    // Check args
    if (args != 2) {
        ReplyToCommand(client, "[SM] Usage: sm_spawn_primary_ammo_clip <#userid|name> <ammo value|reset>");
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

    return Command_Generic("spawn primary ammo clip", client, target, iAmmo, reset, g_spawnPrimaryAmmoClip);
}

public Action Command_SpawnPrimaryAmmoReserve(int client, int args) {
    // Check args
    if (args != 2) {
        ReplyToCommand(client, "[SM] Usage: sm_spawn_primary_ammo_reserve <#userid|name> <ammo value|reset>");
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

    return Command_Generic("spawn primary ammo reserve", client, target, iAmmo, reset, g_spawnPrimaryAmmoReserve);
}

public Action Command_SpawnSecondaryAmmoClip(int client, int args) {
    // Check args
    if (args != 2) {
        ReplyToCommand(client, "[SM] Usage: sm_spawn_secondary_ammo_clip <#userid|name> <ammo value|reset>");
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

    return Command_Generic("spawn secondary ammo clip", client, target, iAmmo, reset, g_spawnSecondaryAmmoClip);
}

public Action Command_SpawnSecondaryAmmoReserve(int client, int args) {
    // Check args
    if (args != 2) {
        ReplyToCommand(client, "[SM] Usage: sm_spawn_secondary_ammo_reserve <#userid|name> <ammo value|reset>");
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

    return Command_Generic("spawn secondary ammo reserve", client, target, iAmmo, reset, g_spawnSecondaryAmmoReserve);
}

public Action Command_SpawnGrenadeAmmo(int client, int args) {
    // Check args
    if (args != 2) {
        ReplyToCommand(client, "[SM] Usage: sm_spawn_grenade_ammo <#userid|name> <ammo value|reset>");
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

    return Command_Generic("spawn grenade ammo", client, target, iAmmo, reset, g_spawnGrenadeAmmo);
}

public Action Command_SpawnKnife(int client, int args) {
    // Check args
    if (args != 2) {
        ReplyToCommand(client, "[SM] Usage: sm_spawn_knife <#userid|name> <0|1|reset>");
        return Plugin_Handled;
    }

    char target[32], sValue[32];
    GetCmdArg(1, target, sizeof(target));
    GetCmdArg(2, sValue, sizeof(sValue));

    bool reset = false;
    // Check value
    int iKnife = StringToInt(sValue);
    if(iKnife < 0 || iKnife > 1 || StrEqual(PARAM_RESET, sValue)) {
        reset = true;
    }

    return Command_Generic("spawn knife", client, target, iKnife, reset, g_spawnKnife);
}

public Action Command_Generic(
        const char[] command,
        int client,
        const char[] target,
        int value,
        bool reset,
        SpawnProperty spawn_property
) {
    char target_name[MAX_NAME_LENGTH];
    int target_list[MAXPLAYERS], target_count;
    bool tn_is_ml;

    if(IsStickyTarget(target)) {
        // Set for a sticky target
        if(reset) {
            spawn_property.RemoveTarget(target);
            LogAction(client, -1, "Admin %L reset %s of %s", client, command, target);
        } else {
            spawn_property.SetTargetValue(target, value);
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
                    spawn_property.SetPlayerEnabled(target_id, false);
                    LogAction(client, -1, "Admin %L reset %s of %L", client, command, target_id);
                } else {
                    spawn_property.SetPlayerEnabled(target_id, true);
                    spawn_property.SetPlayerValue(target_id, value);
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
    if(GetSpawnValueForPlayer(player_id, g_spawnHealth, value)) {
        SetEntityHealth(player_id, value);
        LogAction(0, player_id, "%L health set to %d", player_id, value);
    }

    // Spawn speed
    if(GetSpawnValueForPlayer(player_id, g_spawnSpeed, value)) {
        float fSpeed = value/100.0;
        SetEntPropFloat(player_id, Prop_Data, "m_flLaggedMovementValue", fSpeed);
        LogAction(0, player_id, "%L speed set to %f", player_id, fSpeed);
    }

    // Spawn armor
    if(GetSpawnValueForPlayer(player_id, g_spawnArmor, value)) {
        SetEntProp(player_id, Prop_Data, "m_ArmorValue", value);
        LogAction(0, player_id, "%L armor set to %d", player_id, value);
    }

    // Spawn cash
    if(GetSpawnValueForPlayer(player_id, g_spawnCash, value)) {
        SetEntProp(player_id, Prop_Send, "m_iAccount", value);
        LogAction(0, player_id, "%L cash set to %d", player_id, value);
    }

    // Spawn helmet
    if(GetSpawnValueForPlayer(player_id, g_spawnHelmet, value)) {
        SetEntProp(player_id, Prop_Send, "m_bHasHelmet", value);
        LogAction(0, player_id, "%L helmet set to %d", player_id, value);
    }

    // Spawn primary clip ammo
    if(GetSpawnValueForPlayer(player_id, g_spawnPrimaryAmmoClip, value)) {
        int weapon = GetPlayerWeaponSlot(player_id, CS_SLOT_PRIMARY);
        if (SetWeaponAmmo(player_id, weapon, AMMO_CLIP, value)) {
            LogAction(0, player_id, "%L primary clip ammo set to %d", player_id, value);
        }
    }

    // Spawn primary reserve ammo
    if(GetSpawnValueForPlayer(player_id, g_spawnPrimaryAmmoReserve, value)) {
        int weapon = GetPlayerWeaponSlot(player_id, CS_SLOT_PRIMARY);
        if (SetWeaponAmmo(player_id, weapon, AMMO_RESERVE, value)) {
            LogAction(0, player_id, "%L primary reserve ammo set to %d", player_id, value);
        }
    }

    // Spawn secondary clip ammo
    if(GetSpawnValueForPlayer(player_id, g_spawnSecondaryAmmoClip, value)) {
        int weapon = GetPlayerWeaponSlot(player_id, CS_SLOT_SECONDARY);
        if (SetWeaponAmmo(player_id, weapon, AMMO_CLIP, value)) {
            LogAction(0, player_id, "%L secondary clip ammo set to %d", player_id, value);
        }
    }

    // Spawn secondary reserve ammo
    if(GetSpawnValueForPlayer(player_id, g_spawnSecondaryAmmoReserve, value)) {
        int weapon = GetPlayerWeaponSlot(player_id, CS_SLOT_SECONDARY);
        if (SetWeaponAmmo(player_id, weapon, AMMO_RESERVE, value)) {
            LogAction(0, player_id, "%L secondary reserve ammo set to %d", player_id, value);
        }
    }

    // Spawn grenade ammo
    if(GetSpawnValueForPlayer(player_id, g_spawnGrenadeAmmo, value)) {
        int weapon = GetPlayerWeaponSlot(player_id, CS_SLOT_GRENADE);
        if (SetWeaponAmmo(player_id, weapon, AMMO_RESERVE, value)) {
            LogAction(0, player_id, "%L grenade ammo set to %d", player_id, value);
        }
    }

    // Spawn Knife
    if(GetSpawnValueForPlayer(player_id, g_spawnKnife, value)) {
        if(value == 0) {
            int weapon = GetPlayerWeaponSlot(player_id, CS_SLOT_KNIFE);
            if(IsValidEntity(weapon)) {
                RemovePlayerItem(player_id, weapon);
                AcceptEntityInput(weapon, "kill");
                LogAction(0, player_id, "%L knife removed", player_id);
            }
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
        SpawnProperty spawn_property,
        int& output_value
) {
    // Check for specific target
    if (spawn_property.GetPlayerEnabled(player_id)) {
        output_value = spawn_property.GetPlayerValue(player_id);
        return true;
    }

    // Check for sticky target
    StringMapSnapshot mapSnapshot = spawn_property.GetTargets();
    for(int i=0; i<mapSnapshot.Length; i++) {
        char target[32];
        mapSnapshot.GetKey(i, target, sizeof(target));
        int value = spawn_property.GetTargetValue(target);
        if(IsPlayerTargetted(player_id, target)) {
            output_value = value;
            return true;
        }
    }

    return false;
}

bool SetWeaponAmmo(int player_id, int weapon, int ammo_type, int ammo) {
    if (IsValidEntity(weapon)) {
        if(ammo_type == AMMO_CLIP) {
            SetEntProp(weapon, Prop_Send, "m_iClip1", ammo);
            SetEntProp(weapon, Prop_Send, "m_iClip2", ammo);
            return true;
        } else if(ammo_type == AMMO_RESERVE) {
            SetEntProp(weapon, Prop_Send, "m_iPrimaryReserveAmmoCount", ammo);
            int type = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType");
            if(type != -1) {
                SetEntProp(player_id, Prop_Send, "m_iAmmo", ammo, _, type);
            }
            return true;
        }
    }
    return false;
}
