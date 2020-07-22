#include <sourcemod>
#include <sdktools>
#include <cstrike>
#undef REQUIRE_PLUGIN
#include <multi1v1>
#pragma newdecls required

public Plugin myinfo =
{
	name = "Bot Quota Fix",
	author = "Ilusion9",
	description = "Bot quota fix.",
	version = "1.0",
	url = "https://github.com/Ilusion9/"
};

enum BotsMode
{
	BotsMode_Fix,
	BotsMode_Round,
	BotsMode_Deathmatch,
	BotsMode_Arena
};

ConVar g_Cvar_BotsNum;
ConVar g_Cvar_BotsMode;
ConVar g_Cvar_BotQuota;
ConVar g_Cvar_BotQuotaMode;

BotsMode g_BotsMode;
int g_NumBotsOnServer;

public void OnPluginStart()
{
	g_Cvar_BotsNum = CreateConVar("sm_bots_num", "6", "Determines the total number of bots in the game.", FCVAR_NONE, true, 0.0);
	g_Cvar_BotsNum.AddChangeHook(ConVarChange_BotsNum);
	g_Cvar_BotsMode = CreateConVar("sm_bots_mode", "round", "Determines the type of quota. Allowed values: \"fix\", \"round\", \"dm\" and \"arena\".", FCVAR_NONE, true, 0.0);
	g_Cvar_BotsMode.AddChangeHook(ConVarChange_BotsMode);

	g_Cvar_BotQuota = FindConVar("bot_quota");
	g_Cvar_BotQuota.AddChangeHook(ConVarChange_BotQuota);
	g_Cvar_BotQuotaMode = FindConVar("bot_quota_mode");
	g_Cvar_BotQuotaMode.AddChangeHook(ConVarChange_BotQuotaMode);

	HookEvent("player_team", Event_PlayerTeam);
	HookEvent("round_start", Event_RoundStart, EventHookMode_Pre);
}

public void OnMapEnd()
{
	g_NumBotsOnServer = 0;
}

public void OnConfigsExecuted()
{
	g_NumBotsOnServer = 0;
	g_Cvar_BotQuota.SetInt(0);
	g_Cvar_BotQuotaMode.SetString("normal");
	
	// Get bots mode
	char mode[128];
	g_Cvar_BotsMode.GetString(mode, sizeof(mode));
	
	if (StrEqual(mode, "dm", true))
	{
		g_BotsMode = BotsMode_Deathmatch;
	}
	else if (StrEqual(mode, "fix", true))
	{
		g_BotsMode = BotsMode_Fix;
	}
	else if (StrEqual(mode, "arena", true))
	{
		g_BotsMode = BotsMode_Arena;
	}
	else
	{
		g_BotsMode = BotsMode_Round;
	}
}

/* Change of valve cvars */
public void ConVarChange_BotQuota(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if (g_Cvar_BotQuota.IntValue != g_NumBotsOnServer)
	{
		g_Cvar_BotQuota.SetInt(g_NumBotsOnServer);
	}
}

public void ConVarChange_BotQuotaMode(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if (!StrEqual(newValue, "normal", true))
	{
		g_Cvar_BotQuotaMode.SetString("normal");
	}
}

/* Hook change of our convars */
public void ConVarChange_BotsNum(ConVar convar, const char[] oldValue, const char[] newValue)
{
	int num_players;
	int num_bots = g_NumBotsOnServer;
	
	if (g_BotsMode == BotsMode_Fix)
	{
		num_bots = g_Cvar_BotsNum.IntValue;
	}
	else if (g_BotsMode == BotsMode_Deathmatch)
	{
		if (g_Cvar_BotsNum.IntValue)
		{
			num_players = GetNumOfPlayers();
			num_bots = g_Cvar_BotsNum.IntValue - num_players;
			if (num_bots < 1 || !num_players)
			{
				num_bots = 0;
			}
		}
	}
	
	if (num_bots != g_NumBotsOnServer)
	{
		g_NumBotsOnServer = num_bots;
		g_Cvar_BotQuota.SetInt(num_bots);
	}
}

public void ConVarChange_BotsMode(ConVar convar, const char[] oldValue, const char[] newValue)
{
	// Get bots mode
	if (StrEqual(newValue, "dm", true))
	{
		g_BotsMode = BotsMode_Deathmatch;
	}
	else if (StrEqual(newValue, "fix", true))
	{
		g_BotsMode = BotsMode_Fix;
	}
	else if (StrEqual(newValue, "arena", true))
	{
		g_BotsMode = BotsMode_Arena;
	}
	else
	{
		g_BotsMode = BotsMode_Round;
	}
	
	// Change num bots on server
	int num_players;
	int num_bots = g_NumBotsOnServer;	
	
	if (g_BotsMode == BotsMode_Fix)
	{
		num_bots = g_Cvar_BotsNum.IntValue;
	}
	else if (g_BotsMode == BotsMode_Deathmatch)
	{
		if (g_Cvar_BotsNum.IntValue)
		{
			num_players = GetNumOfPlayers();
			num_bots = g_Cvar_BotsNum.IntValue - num_players;
			
			if (num_bots < 1 || !num_players)
			{
				num_bots = 0;
			}
		}
	}
	else if (g_BotsMode == BotsMode_Arena)
	{
		num_players = GetNumOfPlayers() + GetNumOfPlayersQueue();
		num_bots = num_players % 2;
	}
	
	if (num_bots != g_NumBotsOnServer)
	{
		g_NumBotsOnServer = num_bots;
		g_Cvar_BotQuota.SetInt(num_bots);
	}
}

public void Event_PlayerTeam(Event event, const char[] name, bool dontBroadcast) 
{
	if (event.GetBool("isbot") || !g_Cvar_BotsNum.IntValue)
	{
		return;
	}
	
	RequestFrame(Frame_PlayerTeam);
}

void Frame_PlayerTeam(any data)
{
	int num_bots = 0, num_players = 0;
	if (g_BotsMode == BotsMode_Deathmatch || IsWarmupPeriod() && g_BotsMode == BotsMode_Round)
	{
		num_players = GetNumOfPlayers();
		num_bots = g_Cvar_BotsNum.IntValue - num_players;
		
		if (num_bots < 0 || !num_players)
		{
			num_bots = 0;
		}
		
		if (num_bots != g_NumBotsOnServer)
		{
			g_NumBotsOnServer = num_bots;
			g_Cvar_BotQuota.SetInt(num_bots);
		}
	}
	else if (g_BotsMode == BotsMode_Arena)
	{
		num_players = GetNumOfPlayers() + GetNumOfPlayersQueue();
		num_bots = num_players % 2;
		
		if (num_bots != g_NumBotsOnServer)
		{
			g_NumBotsOnServer = num_bots;
			g_Cvar_BotQuota.SetInt(num_bots);
		}
	}
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast) 
{
	if (!g_Cvar_BotsNum.IntValue || g_BotsMode == BotsMode_Deathmatch || g_BotsMode == BotsMode_Arena)
	{
		return;
	}
	
	int num_bots = 0, num_players = 0;
	if (g_BotsMode == BotsMode_Fix)
	{
		num_bots = g_Cvar_BotsNum.IntValue;
	}
	else
	{
		num_players = GetNumOfPlayers();
		num_bots = g_Cvar_BotsNum.IntValue - num_players;
		
		if (num_bots < 0 || !num_players)
		{
			num_bots = 0;
		}
	}
	
	if (num_bots != g_NumBotsOnServer)
	{
		g_NumBotsOnServer = num_bots;
		g_Cvar_BotQuota.SetInt(num_bots);
	}
}

bool IsWarmupPeriod()
{
	return view_as<bool>(GameRules_GetProp("m_bWarmupPeriod"));
}

int GetNumOfPlayers()
{
	int num = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) > CS_TEAM_SPECTATOR)
		{
			num++;
		}
	}
	
	return num;
}

int GetNumOfPlayersQueue()
{
    int num = 0;
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == CS_TEAM_SPECTATOR && Multi1v1_IsInWaitingQueue(i))
        {
            num++;
        }
    }
    
    return num;
}
