#if defined _rebel_included
 #endinput
#endif
#define _rebel_included

stock bool IsRebelLoaded()
{
	return LibraryExists("rebel");
}

native bool IsClientRebel(int client);
native bool SetClientRebel(int client, int victim = 0, bool status);

public SharedPlugin __pl_rebel =
{
	name = "Rebel",
	file = "rebel.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN

public __pl_rebel_SetNTVOptional()
{
	MarkNativeAsOptional("IsClientRebel");
}
#endif
