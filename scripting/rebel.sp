/*

	ToDo:
		- Logging (config for file format (shortcuts - day, month, year))
		- Messages (tag, colors)
		- Translation
		Rebel on....
			- API
		Commands...
			for users...
				- (option to disable it & and a cvar for a command list) Rebel List (return list with all players - [X] = Rebel [ ] = No Rebel)
		API...
			- bool IsClientRebel(int client) - return status
			- bool SetClientRebel(int client, bool status) - return new status
			- bool OnClientRebel(int client, bool newStatus) - newStatus is new status - Action Forward (block change - change newStatus)

*/

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <cstrike>

bool g_bRebel[MAXPLAYERS + 1] =  { false, ... };

ConVar g_cEnable    = null;
ConVar g_cBots      = null;
ConVar g_cShoot     = null;
ConVar g_cHurt      = null;
ConVar g_cDeath     = null;

ConVar g_cPlayerCmd  = null;
ConVar g_cPlayerCmds = null;

ConVar g_cAdminCmd  = null;
ConVar g_cAdminCmds = null;

public Plugin myinfo = 
{
	name = "Rebel",
	author = "Bara",
	description = "",
	version = "1.0.0",
	url = "github.com/Bara20/Rebel"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("IsClientRebel", Native_IsClientRebel);
	CreateNative("SetClientRebel", Native_SetClientRebel);
	
	RegPluginLibrary("rebel");
	
	return APLRes_Success;
}

public void OnPluginStart()
{
	HookEvent("player_shoot", Event_PlayerShoot);
	HookEvent("player_hurt",  Event_PlayerHurt);
	HookEvent("player_death", Event_PlayerDeath);
	
	g_cEnable   = CreateConVar("rebel_enable",    "1", "Enable rebel plugin(s)?");
	g_cBots     = CreateConVar("rebel_bots",      "1", "Count bots to get rebel?");
	g_cShoot    = CreateConVar("rebel_shoot",     "1", "Get rebel after shooting?");
	g_cHurt     = CreateConVar("rebel_hurt",      "1", "Get rebel after hurt a player?");
	g_cDeath    = CreateConVar("rebel_death",     "1", "Get rebel after a kill?");
	
	g_cPlayerCmd  = CreateConVar("rebel_player_cmd",  "1", "Returns the state of a player");
	g_cPlayerCmds = CreateConVar("rebel_player_cmds", "rebel", "Commands for checking rebel state");
	
	g_cAdminCmd  = CreateConVar("rebel_admin_cmd", "1", "Enable admin cmd (set player rebel)");
	g_cAdminCmds = CreateConVar("rebel_admin_cmds", "setrebel,srebel", "Commands for set player rebel (max. 4 commands)");
}

public void OnClientPostAdminCheck(int client)
{
	if(IsRebel(client))
	{
		SetRebel(client, 0, false);
	}
}

public void OnClientDisconnect(int client)
{
	if(IsRebel(client))
	{
		SetRebel(client, 0, false);
	}
}

public void OnConfigsExecuted()
{
	int iCount = 0;
	char sCommands[128], sCommandsL[4][32], sCommand[32];
	
	if(g_cPlayerCmd.BoolValue)
	{
		g_cPlayerCmds.GetString(sCommands, sizeof(sCommands));
		iCount = ExplodeString(sCommands, ",", sCommandsL, sizeof(sCommandsL), sizeof(sCommandsL[]));
	
		for(int i = 0; i < iCount; i++)
		{
			Format(sCommand, sizeof(sCommand), "sm_%s", sCommandsL[i]);
			RegConsoleCmd(sCommand, Command_Rebel);
		}
	}
	
	if(g_cAdminCmd.BoolValue)
	{
		g_cAdminCmds.GetString(sCommands, sizeof(sCommands));
		iCount = ExplodeString(sCommands, ",", sCommandsL, sizeof(sCommandsL), sizeof(sCommandsL[]));
	
		for(int i = 0; i < iCount; i++)
		{
			Format(sCommand, sizeof(sCommand), "sm_%s", sCommandsL[i]);
			RegAdminCmd(sCommand, Command_SetRebel, ADMFLAG_BAN);
		}
	}
}

public Action Command_Rebel(int client, int args)
{
	if(!IsClientValid(client))
		return Plugin_Handled;
	
	if(g_bRebel[client])
		PrintToChat(client, "You are a rebel");
	else
		PrintToChat(client, "You aren't a rebel");
	
	return Plugin_Continue;
}

public Action Command_SetRebel(int client, int args)
{
	if(!IsClientValid(client))
		return Plugin_Handled;
	
	if (args < 2 || args > 3)
	{
		ReplyToCommand(client, "[SM] Usage: sm_setrebel <#userid|name> <status>");
		return Plugin_Handled;
	}
	
	char arg1[32];
	GetCmdArg(1, arg1, sizeof(arg1));
	
	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS];
	int target_count;
	bool tn_is_ml;
	
	if ((target_count = ProcessTargetString(arg1, client, target_list, MAXPLAYERS, COMMAND_FILTER_CONNECTED, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	for (int i = 0; i < target_count; i++)
	{
		int target = target_list[i];
		
		if (!IsClientValid(target))
			return Plugin_Handled;
		
		if(!IsPlayerAlive(target))
			return Plugin_Handled;
		
		if(GetClientTeam(target) != CS_TEAM_T)
			return Plugin_Handled;
		
		if(g_bRebel[target])
			SetRebel(target, 0, false);
		else
			SetRebel(target, 0, true);
		
	}
	
	return Plugin_Continue;
}

public Action Event_PlayerShoot(Event event, const char[] name, bool dontBroadcast)
{
	if(!g_cShoot.BoolValue)
		return Plugin_Continue;
	
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	if(IsClientValid(client))
	{
		if(!IsRebel(client) && GetClientTeam(client) == CS_TEAM_T)
		{
			// Rebel on Shot
			SetRebel(client, 0, true);
		}
	}
	
	return Plugin_Continue;
}

public Action Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
	if(!g_cHurt.BoolValue)
		return Plugin_Continue;
	
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	int victim   = GetClientOfUserId(event.GetInt("userid"));
	
	if(IsClientValid(attacker) && IsClientValid(victim))
	{
		if(!IsRebel(attacker) && GetClientTeam(attacker) == CS_TEAM_T)
		{
			// Rebel on Hurt
			SetRebel(attacker, victim, true);
		}
	}
	
	return Plugin_Continue;
}

public Action Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	if(!g_cDeath.BoolValue)
		return Plugin_Continue;
	
	int victim = GetClientOfUserId(event.GetInt("userid"));
	
	if(IsClientValid(victim))
	{
		if(IsRebel(victim))
		{
			// Reset Rebel on Death
			SetRebel(victim, 0, false);
		}
		
		int attacker = GetClientOfUserId(event.GetInt("attacker"));
		
		if(IsClientValid(attacker))
		{
			if(!IsRebel(attacker) && GetClientTeam(attacker) == CS_TEAM_T)
			{
				// Rebel on Kill
				SetRebel(attacker, victim, true);
			}
		}
	}
	
	return Plugin_Continue;
}

public int Native_IsClientRebel(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	
	return IsRebel(client);
}

public int Native_SetClientRebel(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	int victim = GetNativeCell(2);
	bool bStatus = view_as<bool>(GetNativeCell(3));
	
	if(g_bRebel[client] != bStatus)
		return SetRebel(client, victim, bStatus);
	
	return bStatus;
}

bool SetRebel(int client, int victim, bool status)
{
	// Call Forward	
	
	// if victim = 0 -> reason without victim
	// avoid warning (never used)
	victim = victim+0;
	
	// set new status (ignore the old value, since we check it before we set a new status)
	g_bRebel[client] = status;
	
	// send message
	
	// return new status
	return g_bRebel[client];
}

bool IsRebel(int client)
{
	// Check if rebel enable
	if(g_cEnable.BoolValue)
	{
		return g_bRebel[client];
	}
	return false;
}

bool IsClientValid(int client)
{
	// Check if rebel enable
	if(g_cEnable.BoolValue)
	{
		if (client > 0 && client <= MaxClients)
		{
			if(!g_cBots.BoolValue && IsFakeClient(client))
			{
				return false;
			}
			
			return IsClientInGame(client);
		}
	}
	return false;
}
