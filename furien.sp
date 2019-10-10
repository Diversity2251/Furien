#pragma semicolon 1
#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks> 

#define LoopAllClients(%1) for(int %1 = 1;%1 <= MaxClients;%1++)
#define LoopClients(%1) for(int %1 = 1;%1 <= MaxClients;%1++) if(IsValidClient(%1))
#define LoopAliveClients(%1) for(int %1 = 1;%1 <= MaxClients;%1++) if(IsValidClient(%1, true))

char g_sRadioCmds[][] = { "coverme", "takepoint", "holdpos", "regroup", "followme", "takingfire", "go", "fallback", "sticktog", "getinpos", "stormfront", "report", "roger", "enemyspot", "needbackup", "sectorclear",
"inposition", "reportingin", "getout", "negative","enemydown", "compliment", "thanks", "cheer" };
 
bool
        bg_MovedAfterSpawn[MAXPLAYERS+1] = {false,...},
        bg_ClientInv[MAXPLAYERS+1] = {false,...}; 

ConVar 
        cV_Gravity,
        cV_Speed;
float 
        cVf_Gravity,
        cVf_Speed;

public Plugin myinfo = {
  name = "Furien Mod",
  author = "Filiq_",
  version = "0.0.2",
  description = "Furien cs 1.6 style for cs:go",
  url = "https://github.com/Diversity2251/Furien"
};

public void OnPluginStart() {

    cV_Gravity = CreateConVar("furien_gravity", "0.25999", "Gravitatea * x la furien");
    cV_Speed = CreateConVar("furien_speed", "2.5", "Viteza * x la furien");

    cVf_Gravity = GetConVarFloat(cV_Gravity);
    cVf_Speed = GetConVarFloat(cV_Speed);

    HookConVarChange(cV_Gravity, OnConVarChanged);
    HookConVarChange(cV_Speed, OnConVarChanged);

    for(int i; i < sizeof(g_sRadioCmds); i++)
        AddCommandListener(Command_Block, g_sRadioCmds[i]); 

    AddCommandListener(Command_Block, "kill");
}

public void OnMapStart() {
    SetConVarString(FindConVar("mp_teamname_1"), "ANTI-FURIENS", true);
    SetConVarString(FindConVar("mp_teamname_2"), "FURIENS", true);

    SetConVarInt(FindConVar("mp_startmoney"), 800, true);
    SetConVarInt(FindConVar("sv_deadtalk"), 1, true);
    SetConVarInt(FindConVar("sv_alltalk"), 1, true);
    SetConVarInt(FindConVar("mp_buytime"), 0, true);
    SetConVarInt(FindConVar("sv_ignoregrenaderadio"), 1, true);
    SetConVarInt(FindConVar("sv_disable_immunity_alpha"), 1, true);
    SetConVarInt(FindConVar("sv_airaccelerate"), 20, true);
    SetConVarInt(FindConVar("mp_maxrounds"), 30, true); 
     
    SetConVarFloat(FindConVar("mp_roundtime"), 2.5, true);
    SetConVarFloat(FindConVar("mp_roundtime_defuse"), 2.5, true);
} 

public void OnClientPutInServer(int client) {
    if(IsValidClient(client)) {
        SDKHook(client, SDKHook_PreThink, ClientPreThink);
        SDKHook(client, SDKHook_PostThinkPost, ClientPostThink); 
    }
}

public void ClientPreThink(int client) {
	if(IsValidClient(client) && IsPlayerAlive(client) && GetClientTeam(client) == CS_TEAM_T) {
        SetEntityGravity(client, cVf_Gravity);
        SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", cVf_Speed);
	}
}

public void ClientPostThink(int client) {
	if(IsValidClient(client, true)) {
		SetEntProp(client, Prop_Send, "m_bInBuyZone", 0); 

		if(GetClientTeam(client) == CS_TEAM_T)
            SetEntProp(client, Prop_Send, "m_iAddonBits", 0);
		else if(GetClientTeam(client) == CS_TEAM_CT)
            SetEntProp(client, Prop_Send, "m_iAddonBits", 1);
	}
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2]) {
    if(IsValidClient(client, true)) { 
        char Weapon[32];
        int flag = GetEntityFlags(client); 
        GetClientWeapon(client, Weapon, 32);
        if(GetClientTeam(client) == CS_TEAM_T) {
            if(bg_MovedAfterSpawn[client] == false) {
                if(IsMoveButtonsPressed(buttons)) bg_MovedAfterSpawn[client] = true;
            }
            if(IsClientInAir(client, flag)) {
                // float vel[3];
                GetEntPropVector(client, Prop_Data, "m_vecVelocity", vel);
                
                if(vel[2] < -1.0) {
                    vel[2] += 1.9;
                    SetEntPropVector(client, Prop_Data, "m_VecVelocity", vel);
                    TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vel);
                }
                if(vel[2] > 200.0) {
                    vel[2] -=20.0;
                    SetEntPropVector(client, Prop_Data, "m_VecVelocity", vel);
                    TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vel);
                }
            } 
            if(IsClientNotMoving(buttons) && !IsClientInAir(client, flag) && bg_MovedAfterSpawn[client] == true && StrEqual(Weapon, "weapon_knife")) {
                if(bg_ClientInv[client] == false) {   
                    SetEntityRenderMode(client, RENDER_NONE);
                    SetEntityRenderColor(client, 255, 255, 255, 0);

                    bg_ClientInv[client] = true;

                    PrintCenterText(client, "Now you are invisibile");
                }
            } else {
                if(bg_ClientInv[client] == true) {
                    SetEntityRenderMode(client, RENDER_NORMAL);
                    SetEntityRenderColor(client, 255, 255, 255, 255); 

                    bg_ClientInv[client] = false;

                    PrintCenterText(client, "Now you are visibile");
                }
            }
        }
    }
} 

public Action Command_Block(int client, const char[] command,int  args) {
	return Plugin_Handled;
}

public void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue) { 

    if(convar == cV_Gravity)
        cVf_Gravity = GetConVarFloat(cV_Gravity); 
    else if(convar == cV_Speed)
        cVf_Speed = GetConVarFloat(cV_Speed);  
}

stock bool IsClientInAir(int client, int flags)
{
    return !(flags & FL_ONGROUND);
}
stock bool IsClientNotMoving(int buttons)
{
	return !IsMoveButtonsPressed(buttons);
}
stock bool IsMoveButtonsPressed(int buttons)
{
	return buttons & IN_FORWARD || buttons & IN_BACK || buttons & IN_MOVELEFT || buttons & IN_MOVERIGHT;
}

stock bool IsValidClient(int client, bool alive = false) {
    if(0 < client && client <= MaxClients && IsClientInGame(client) && IsFakeClient(client) == false && (alive == false || IsPlayerAlive(client)))
        return true; 
    return false;
}