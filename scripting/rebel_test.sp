
#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <rebel>

public Plugin myinfo = 
{
	name = "Rebel - Test Plugin",
	author = "Bara",
	description = "",
	version = "1.0.0",
	url = "github.com/Bara20/Rebel"
};

public void OnPluginStart()
{
	RegConsoleCmd("sm_iamrebel", Command_IamRebel);
	RegAdminCmd("sm_tsetrebel", Command_TSetRebel, ADMFLAG_GENERIC);
}

public Action Command_IamRebel(int client, int args)
{
	if(IsClientRebel(client))
		PrintToChat(client, "Yes!");
	else
		PrintToChat(client, "No!");
	
	return Plugin_Continue;
}

public Action Command_TSetRebel(int client, int args)
{
	if(args != 1)
		return Plugin_Handled;
	
	char sArg[4];
	GetCmdArg(1, sArg, sizeof(sArg));
	bool bStatus = view_as<bool>(StringToInt(sArg));
	
	SetClientRebel(client, 0, bStatus);
	
	return Plugin_Continue;
}

public Action OnClientRebel(int client, bool bStatus)
{
	// status should never true
	if(bStatus)
	{
		bStatus = false;
		return Plugin_Changed;
	}
	
	return Plugin_Continue;
}
