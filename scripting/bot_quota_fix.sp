#include <sourcemod>
#include <sdktools>
#include <cstrike>
#pragma newdecls required

public Plugin myinfo =
{
	name = "Bot Quota Fix",
	author = "Ilusion9",
	description = "Bot quota fix.",
	version = "1.0",
	url = "https://github.com/Ilusion9/"
};

ConVar g_Cvar_BotsNum;
ConVar g_Cvar_BotsMode;
ConVar g_Cvar_BotQuota;
ConVar g_Cvar_BotQuotaMode;

int g_NumBotsOnServer;

public void OnPluginStart()
{
	g_Cvar_BotsNum = CreateConVar("sm_bots_num", "6", "Determines the total number of bots in the game.", FCVAR_NONE, true, 0.0);
	g_Cvar_BotsNum.AddChangeHook(ConVarChange_BotsNum);
	g_Cvar_BotsMode = CreateConVar("sm_bots_mode", "round", "Determines the type of quota. Allowed values: \"fix\", \"round\" and \"dm\".", FCVAR_NONE, true, 0.0);
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
	g_Cvar_BotQuotaMode.SetString("normal");
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
	char bots_mode[64];
	g_Cvar_BotsMode.GetString(bots_mode, sizeof(bots_mode));
	int num_bots = g_NumBotsOnServer;

	if (StrEqual(bots_mode, "fix", true))
	{
		num_bots = g_Cvar_BotsNum.IntValue;
	}
	else if (StrEqual(bots_mode, "dm", true))
	{
		if (g_Cvar_BotsNum.IntValue)
		{
			num_bots = g_Cvar_BotsNum.IntValue - GetNumOfPlayers();
			if (num_bots < 1)
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
	bool dm_mode = StrEqual(newValue, "dm", true);
	bool fix_mode = StrEqual(newValue, "fix", true);
	bool round_mode = StrEqual(newValue, "round", true);

	if (!dm_mode && !fix_mode && !round_mode)
	{
		g_Cvar_BotsMode.SetString("round");
		return;
	}
	
	int num_bots = g_NumBotsOnServer;	
	if (fix_mode)
	{
		num_bots = g_Cvar_BotsNum.IntValue;
	}
	else if (dm_mode)
	{
		if (g_Cvar_BotsNum.IntValue)
		{
			num_bots = g_Cvar_BotsNum.IntValue - GetNumOfPlayers();
			if (num_bots < 1)
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

public void Event_PlayerTeam(Event event, const char[] name, bool dontBroadcast) 
{
	if (event.GetBool("isbot") || !g_Cvar_BotsNum.IntValue)
	{
		return;
	}
	
	char bots_mode[64];
	g_Cvar_BotsMode.GetString(bots_mode, sizeof(bots_mode));
	
	int num_bots, num_players;
	int userId = event.GetInt("userid");
	int to_team = event.GetInt("team");
	int old_team = event.GetInt("oldteam");
	bool is_disconnecting = event.GetBool("disconnect");
	
	if (StrEqual(bots_mode, "dm", true))
	{
		if (is_disconnecting)
		{
			num_players = GetNumOfPlayers(userId);
		}
		else
		{
			if (to_team == CS_TEAM_SPECTATOR)
			{
				num_players = GetNumOfPlayers(userId);
			}
			else
			{
				num_players = GetNumOfPlayers();
				if (old_team < CS_TEAM_T)
				{
					num_players++;
				}
			}
		}
		
		num_bots = g_Cvar_BotsNum.IntValue - num_players;
		if (num_bots < 0 || !num_players)
		{
			num_bots = 0;
		}
		
		if (!num_bots)
		{
			g_NumBotsOnServer = 0;
			ServerCommand("bot_kick all");
		}
		
		if (num_bots != g_NumBotsOnServer)
		{
			g_NumBotsOnServer = num_bots;
			g_Cvar_BotQuota.SetInt(num_bots);
		}
	}
	else
	{
		if (is_disconnecting || to_team == CS_TEAM_SPECTATOR)
		{
			num_players = GetNumOfPlayers(userId);
			if (!num_players)
			{
				g_NumBotsOnServer = 0;
				ServerCommand("bot_kick all");
			}
		}
	}
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast) 
{
	if (!g_Cvar_BotsNum.IntValue)
	{
		return;
	}
	
	char bots_mode[64];
	g_Cvar_BotsMode.GetString(bots_mode, sizeof(bots_mode));
	
	if (StrEqual(bots_mode, "dm", true))
	{
		return;
	}
	
	int num_bots, num_players;
	if (StrEqual(bots_mode, "fix", true))
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
		
		if (!num_bots)
		{
			g_NumBotsOnServer = num_bots;
			ServerCommand("bot_kick all");
		}
	}
	
	if (num_bots != g_NumBotsOnServer)
	{
		g_NumBotsOnServer = num_bots;
		g_Cvar_BotQuota.SetInt(num_bots);
	}
}

int GetNumOfPlayers(int skip_userid = 0)
{
	int num_players = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i) && GetClientUserId(i) != skip_userid && GetClientTeam(i) > CS_TEAM_SPECTATOR)
		{
			num_players++;
		}
	}
	
	return num_players;
}
