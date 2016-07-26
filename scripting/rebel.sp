/*

	ToDo:
		- (DONE) Bots (with cvar (enable/disable))
		- Logging (config for file format (shortcuts - day, month, year))
		- Messages (tag, colors)
		Rebel on....
			- (DONE) Fire (with cvar)
			- (DONE) Hit (with cvar)
			- (DONE) Kill (with cvar)
			- API
		Commands...
			for users...
				- (option to disable it & and a cvar for a command list) Rebel List (return list with all players - [X] = Rebel [ ] = No Rebel)
				- (option to disable it & and a cvar for a command list) Rebel (return if player or not)
			for admins...
				- (option to disable it & and a cvar for a command list) set client rebel
		API...
			- bool IsClientRebel(int client) - return status
			- bool SetClientRebel(int client, bool status) - return new status
			- bool OnClientRebel(int client, bool newStatus) - newStatus is new status - Action Forward (block change - change newStatus)

*/

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>

bool g_bRebel[MAXPLAYERS + 1] =  { false, ... };

ConVar g_cEnable = null;
ConVar g_cBots = null;
ConVar g_cShoot = null;
ConVar g_cHurt = null;
ConVar g_cDeath = null;

public Plugin myinfo = 
{
	name = "Rebel",
	author = "Bara",
	description = "",
	version = "1.0.0",
	url = "github.com/Bara20/Rebel"
};

public void OnPluginStart()
{
	HookEvent("player_shoot", Event_PlayerShoot);
	HookEvent("player_hurt", Event_PlayerHurt);
	HookEvent("player_death", Event_PlayerDeath);
	
	g_cEnable = CreateConVar("rebel_enable", "1", "Enable rebel plugin(s)?");
	g_cBots = CreateConVar("rebel_bots", "1", "Count bots to get rebel?");
	g_cShoot = CreateConVar("rebel_shoot", "1", "Get rebel after shooting?");
	g_cHurt = CreateConVar("rebel_hurt", "1", "Get rebel after hurt a player?");
	g_cDeath = CreateConVar("rebel_death", "1", "Get rebel after a kill?");
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

public Action Event_PlayerShoot(Event event, const char[] name, bool dontBroadcast)
{
	if(!g_cShoot.BoolValue)
		return Plugin_Continue;
	
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	if(IsClientValid(client))
	{
		if(!IsRebel(client))
		{
			// Rebel on Shot
			SetRebel(client, 0, true);
		}
	}
	
	return Plugin_Continue;
}

public Action  Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
	if(!g_cHurt.BoolValue)
		return Plugin_Continue;
	
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	int victim = GetClientOfUserId(event.GetInt("userid"));
	
	if(IsClientValid(attacker) && IsClientValid(victim))
	{
		if(!IsRebel(attacker))
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
			if(!IsRebel(attacker))
			{
				// Rebel on Kill
				SetRebel(attacker, victim, true);
			}
		}
	}
	
	return Plugin_Continue;
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
