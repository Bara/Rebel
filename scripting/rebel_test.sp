
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
}

public Action Command_IamRebel(int client, int args)
{
	if(IsClientRebel(client))
		PrintToChat(client, "Yes!");
	else
		PrintToChat(client, "No!");
}
