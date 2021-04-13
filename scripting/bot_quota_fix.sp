#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <cstrike>

public Plugin myinfo =
{
	name = "Bot Quota Fix",
	author = "Ilusion9",
	description = "Bot quota fix.",
	version = "1.1",
	url = "https://github.com/Ilusion9/"
};

enum BotQuotaInfo
{
	BotQuota_Casual,
	BotQuota_Even,
	BotQuota_Fill,
	BotQuota_Normal
};

ConVar g_Cvar_BotsCount;
ConVar g_Cvar_BotsMode;

ConVar g_Cvar_BotQuota;
ConVar g_Cvar_BotQuotaMode;

int g_NumCurrentBots;
BotQuotaInfo g_CurrentBotsMode;

public void OnPluginStart()
{
	g_Cvar_BotsCount = CreateConVar("sm_bot_quota", "4", "Determines the total number of bots in the game.", FCVAR_NONE, true, 0.0);
	g_Cvar_BotsCount.AddChangeHook(ConVarChange_BotsCount);
	
	g_Cvar_BotsMode = CreateConVar("sm_bot_quota_mode", "casual", "Determines the type of quota. Allowed values: normal, casual, fill and even.", FCVAR_NONE, true, 0.0);
	g_Cvar_BotsMode.AddChangeHook(ConVarChange_BotsMode);

	g_Cvar_BotQuota = FindConVar("bot_quota");
	g_Cvar_BotQuota.AddChangeHook(ConVarChange_BotQuota);
	
	g_Cvar_BotQuotaMode = FindConVar("bot_quota_mode");
	g_Cvar_BotQuotaMode.AddChangeHook(ConVarChange_BotQuotaMode);

	HookEvent("player_team", Event_PlayerTeam);
	HookEvent("round_start", Event_RoundStart_Pre, EventHookMode_Pre);
}

public void OnMapEnd()
{
	g_NumCurrentBots = 0;
}

public void OnConfigsExecuted()
{
	char mode[256];
	g_Cvar_BotsMode.GetString(mode, sizeof(mode));
	
	if (StrEqual(mode, "even", false))
	{
		g_CurrentBotsMode = BotQuota_Even;
	}
	else if (StrEqual(mode, "fill", false))
	{
		g_CurrentBotsMode = BotQuota_Fill;
	}
	else if (StrEqual(mode, "normal", false))
	{
		g_CurrentBotsMode = BotQuota_Normal;
	}
	else
	{
		g_CurrentBotsMode = BotQuota_Casual;
	}
	
	g_Cvar_BotQuota.SetInt(0);
	g_Cvar_BotQuotaMode.SetString("normal");
}

/* Change of valve cvars */
public void ConVarChange_BotQuota(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if (g_Cvar_BotQuota.IntValue != g_NumCurrentBots)
	{
		g_Cvar_BotQuota.SetInt(g_NumCurrentBots);
	}
}

public void ConVarChange_BotQuotaMode(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if (!StrEqual(newValue, "normal", false))
	{
		g_Cvar_BotQuotaMode.SetString("normal");
	}
}

/* Hook change of our convars */
public void ConVarChange_BotsCount(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if (g_CurrentBotsMode == BotQuota_Normal || g_CurrentBotsMode == BotQuota_Fill)
	{
		FixBotQuota();
	}
}

public void ConVarChange_BotsMode(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if (StrEqual(newValue, "even", true))
	{
		g_CurrentBotsMode = BotQuota_Even;
	}
	else if (StrEqual(newValue, "fill", true))
	{
		g_CurrentBotsMode = BotQuota_Fill;
	}
	else if (StrEqual(newValue, "normal", true))
	{
		g_CurrentBotsMode = BotQuota_Normal;
	}
	else
	{
		g_CurrentBotsMode = BotQuota_Casual;
	}
	
	if (g_CurrentBotsMode == BotQuota_Normal || g_CurrentBotsMode == BotQuota_Fill)
	{
		FixBotQuota();
	}
}

public void Event_PlayerTeam(Event event, const char[] name, bool dontBroadcast) 
{
	if (event.GetBool("isbot") || !g_Cvar_BotsCount.IntValue)
	{
		return;
	}
	
	if (g_CurrentBotsMode == BotQuota_Fill || g_CurrentBotsMode == BotQuota_Casual && IsWarmupPeriod())
	{
		RequestFrame(FixBotQuota);
	}
}

public void Event_RoundStart_Pre(Event event, const char[] name, bool dontBroadcast) 
{
	if (!g_Cvar_BotsCount.IntValue)
	{
		return;
	}
	
	if (g_CurrentBotsMode == BotQuota_Casual || g_CurrentBotsMode == BotQuota_Even)
	{
		FixBotQuota();
	}
}

void FixBotQuota()
{
	int numBots = 0;
	int numPlayers = GetNumOfPlayers();
	
	switch (g_CurrentBotsMode)
	{
		case BotQuota_Even:
		{
			numBots = numPlayers % 2;
		}
		
		case BotQuota_Normal:
		{
			numBots = g_Cvar_BotsCount.IntValue;
		}
		
		default:
		{
			numBots = g_Cvar_BotsCount.IntValue - numPlayers;
			if (numBots < 0 || !numPlayers)
			{
				numBots = 0;
			}
		}
	}
	
	if (numBots != g_NumCurrentBots)
	{
		g_NumCurrentBots = numBots;
		g_Cvar_BotQuota.SetInt(numBots);
	}
}

bool IsWarmupPeriod()
{
	return view_as<bool>(GameRules_GetProp("m_bWarmupPeriod"));
}

int GetNumOfPlayers()
{
	int numPlayers = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) > CS_TEAM_SPECTATOR)
		{
			numPlayers++;
		}
	}
	
	return numPlayers;
}
