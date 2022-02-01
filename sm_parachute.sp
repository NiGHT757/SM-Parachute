#include <sourcemod>
#include <sdktools>
#pragma newdecls required
#define PARACHUTE_VERSION 	"2.7"

int g_iVelocity = -1;

ConVar g_cvarFallspeed;
ConVar g_cvarLinear;
ConVar g_cvarDecrease;
int g_iFallSpeed;
int g_iLinear;
float g_fDecrease;

int cl_flags;
float speed[3];
bool isfallspeed;

bool inUse[MAXPLAYERS+1];

public Plugin myinfo =
{
	name = "SM Parachute",
	author = "SWAT_88, NiGHT",
	description = "To use your parachute press and hold your E(+use) button while falling.",
	version = PARACHUTE_VERSION,
	url = "http://www.sourcemod.net/"
};

public void OnPluginStart()
{
	g_cvarFallspeed = CreateConVar("sm_parachute_fallspeed","100");
	g_cvarLinear = CreateConVar("sm_parachute_linear","1");
	g_cvarDecrease = CreateConVar("sm_parachute_decrease","50");
	g_iVelocity = FindSendPropInfo("CBasePlayer", "m_vecVelocity[0]");

	g_cvarFallspeed.AddChangeHook(OnSettingsChanged);
	g_cvarLinear.AddChangeHook(OnSettingsChanged);
	g_cvarDecrease.AddChangeHook(OnSettingsChanged);

	HookEvent("player_death", PlayerDeath);
}

public void OnConfigsExecuted()
{
	g_iFallSpeed = g_cvarFallspeed.IntValue;
	g_iLinear = g_cvarLinear.IntValue;
	g_fDecrease = g_cvarDecrease.FloatValue;
}

public void OnSettingsChanged(ConVar cvar, const char[] oldval, const char[] newval)
{
	if(cvar == g_cvarFallspeed)
		g_iFallSpeed = g_cvarFallspeed.IntValue;
	else if(cvar == g_cvarLinear)
		g_iLinear = g_cvarLinear.IntValue;
	else if(cvar == g_cvarDecrease)
		g_fDecrease = g_cvarDecrease.FloatValue;
}

public void OnClientPutInServer(int client)
{
	inUse[client] = false;
}

public Action PlayerDeath(Event event, const char[] name, bool dontBroadcast){
	EndPara(GetClientOfUserId(event.GetInt("userid")));
	return Plugin_Continue;
}

void StartPara(int client)
{
	static float velocity[3];
	static float fallspeed;
	if (g_iVelocity == -1) return;
	fallspeed = g_iFallSpeed*(-1.0);
	GetEntDataVector(client, g_iVelocity, velocity);
	if(velocity[2] >= fallspeed){
		isfallspeed = true;
	}
	if(velocity[2] < 0.0) {
		if(isfallspeed && g_iLinear == 0){
		}
		else if((isfallspeed && g_iLinear == 1) || g_fDecrease == 0.0){
			velocity[2] = fallspeed;
		}
		else{
			velocity[2] = velocity[2] + g_fDecrease;
		}
		TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, velocity);
		SetEntDataVector(client, g_iVelocity, velocity);
		SetEntityGravity(client,0.1);
	}
}

void EndPara(int client)
{
	SetEntityGravity(client,1.0);
	inUse[client]=false;
}

void Check(int client){
		GetEntDataVector(client,g_iVelocity,speed);
		cl_flags = GetEntityFlags(client);
		if(speed[2] >= 0 || (cl_flags & FL_ONGROUND)) EndPara(client);
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	if(IsPlayerAlive(client))
	{
		if (buttons & IN_USE)
		{
			if (!inUse[client])
			{
				inUse[client] = true;
				isfallspeed = false;
				StartPara(client);
			}
			StartPara(client);
		}
		else
		{
			if (inUse[client])
			{
				inUse[client] = false;
				EndPara(client);
			}
		}
		Check(client);
	}
}