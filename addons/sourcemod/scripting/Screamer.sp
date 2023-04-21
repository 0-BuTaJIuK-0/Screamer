#include <sdktools>
#include <sourcemod>
#include <csgo_colors>
#include <sdktools_sound>

#define ZVUK "Screamer/Skr.mp3"
//!Handle hScreamer[MAXPLAYERS+1];


public Plugin:myinfo = 
{
	name = "Screamer",
	author = "0-BuTaJIuK-0",
	description = "Allows you to send a screamer to players",
	version = "2.0",
	url = "https://github.com/0-BuTaJIuK-0/Screamer"
};

Handle TS[MAXPLAYERS+1];
Handle TS2[MAXPLAYERS+1];
float Stime[MAXPLAYERS+1];

bool g_repeat[MAXPLAYERS+1];

new Handle:g_FlagUseAdmin;

public void OnPluginStart()
{
	g_FlagUseAdmin = CreateConVar("sv_screamerflag", "b", "Administrators with which flag can use sending a screamer");
	RegConsoleCmd("sm_screamer", Skrimer);
	LoadTranslations("screamer.phrases");
}


//! sv_max_allowed_net_graph 0
//! SetEntProp(iClient, Prop_Data, "m_takedamage", 0);

public OnMapStart()
{
	if (!IsDecalPrecached("Screamer/Skr.vtf"))
	{
	PrecacheDecal("Screamer/Skr.vtf", true);
	AddFileToDownloadsTable("materials/Screamer/Skr.vmt");
	AddFileToDownloadsTable("materials/Screamer/Skr.vtf");
	}
	AddFileToDownloadsTable("sound/Screamer/Skr.mp3");
	PrecacheSound("Screamer/Skr.mp3");
	AddFileToDownloadsTable("sound/Screamer/Serd.mp3");
	PrecacheSound("Screamer/Serd.mp3");
}

public Action:Skrimer(int client, int args)
{
	decl String:buffer[8]
	GetConVarString(g_FlagUseAdmin, buffer, sizeof(buffer))
	if (GetUserFlagBits(client) & ReadFlagString(buffer))
	{
		Stime[client] = 1.5;
		mMenu(client);
		CGOPrintToChat(client, "%t%t", "Prefix", "Greeting");
	}
	else
	{
		CGOPrintToChat(client, "%t%t", "Prefix", "Access");
	}
}

public Action:mMenu(int client)
{
	Menu hMenu = new Menu(MenuHandler_mMenu, MenuAction_Select|MenuAction_Cancel);

	char szBuffer[64];
	FormatEx(szBuffer, sizeof(szBuffer), "%T", "Main Menu", client);
	hMenu.SetTitle(szBuffer);
	FormatEx(szBuffer, sizeof(szBuffer), "%T", "Menu select a player", client);
	hMenu.AddItem("item0", szBuffer);
	FormatEx(szBuffer, sizeof(szBuffer), "%T", "Menu time of action", client);
	hMenu.AddItem("item1", szBuffer);
	hMenu.Display(client, MENU_TIME_FOREVER);
}

public MenuHandler_mMenu(Menu hMenu, MenuAction action, int client, int item)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			if(item == 0)
			{
				ShowSkrimerMenu(client);
			}
			else if(item == 1)
			{
				TimerMenu(client);
			}
		}
        case MenuAction_End:
        {
            delete hMenu;
        }
	}
}

ShowSkrimerMenu(int client)
{
	char id[4], name[MAX_NAME_LENGTH];
	Menu MList = new Menu(Skrimer_List);
	char szBuffer[64];
	FormatEx(szBuffer, sizeof(szBuffer), "%T", "Menu title who", client);
	MList.SetTitle(szBuffer);
	for (int i = 1; i <= MaxClients; ++i)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
		{
			GetClientName(i, name, sizeof(name))
			IntToString(i, id, sizeof(id));
			MList.AddItem(id, name);
		}
	}
	if (!MList.ItemCount)
	{
		FormatEx(szBuffer, sizeof(szBuffer), "%T", "No players found", client);
		MList.AddItem("", szBuffer, ITEMDRAW_DISABLED);
	}
	MList.ExitBackButton = true;
	MList.ExitButton = false;
	MList.Display(client, MENU_TIME_FOREVER);
}

public Skrimer_List(Menu menu, MenuAction action, int client, int slot)
{
	switch (action)
	{
		case MenuAction_Cancel:
		{
			mMenu(client);
		}
		case MenuAction_Select:
		{
			char info[4];
			menu.GetItem(slot, info, sizeof(info));	
			int target = StringToInt(info);
			char targetName[MAX_NAME_LENGTH];
			GetClientName(target, targetName, MAX_NAME_LENGTH);
			if (target)
			{
				CGOPrintToChat(client, "%t%t", "Prefix", "A screamer has been sent", Stime[client], targetName);
				RequestFrame(HUDdisable, target);
				ClientCommand(target, "r_screenoverlay Screamer/Skr.vmt");
				EmitSoundToClient(target, "Screamer/Skr.mp3", _, _, 0);
				g_repeat[target] = true;
				TS[target] = CreateTimer(1.6, Timer_Repeat, target, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
				TS2[target] = CreateTimer(Stime[client], Timer_Kill, target, TIMER_FLAG_NO_MAPCHANGE);
			}
			ShowSkrimerMenu(client);
		}
	}
}

public Action:Timer_Kill(Handle timer, int target)
{
	g_repeat[target] = false;
	ClientCommand(target, "r_screenoverlay 0");
	EmitSoundToClient(target, "Screamer/Serd.mp3", _, _, 0);
	RequestFrame(HUDenbale, target);
	return Plugin_Stop;
}

public Action:Timer_Repeat(Handle time, int target)
{
	if(g_repeat[target])
	{
		EmitSoundToClient(target, "Screamer/Skr.mp3", _, _, 0);
	}
	else
	{
		return Plugin_Stop;
	}
}

public Action:TimerMenu(int client)
{
	Menu sMenu = new Menu(MenuHandler_TimerMenu, MenuAction_Select|MenuAction_Cancel);

	char szBuffer[64];
	FormatEx(szBuffer, sizeof(szBuffer), "%T", "For how long", client);
	sMenu.SetTitle(szBuffer);
	if (Stime[client] == 1.5)
	{
		sMenu.AddItem("item0", "1.5 (default)", ITEMDRAW_DISABLED);
	}
	else
	{
		sMenu.AddItem("item0", "1.5 (default)");
	}
	if (Stime[client] == 5.0)
	{
		sMenu.AddItem("item1", "5", ITEMDRAW_DISABLED);
	}
	else
	{
		sMenu.AddItem("item1", "5");
	}
	if (Stime[client] == 10.0)
	{
		sMenu.AddItem("item2", "10", ITEMDRAW_DISABLED);
	}
	else
	{
		sMenu.AddItem("item2", "10");
	}
	if (Stime[client] == 30.0)
	{
		sMenu.AddItem("item3", "30", ITEMDRAW_DISABLED);
	}
	else
	{
		sMenu.AddItem("item3", "30");
	}
	if (Stime[client] == 60.0)
	{
		sMenu.AddItem("item3", "60", ITEMDRAW_DISABLED);
	}
	else
	{
		sMenu.AddItem("item3", "60");
	}
	if (Stime[client] == 300.0)
	{
		sMenu.AddItem("item3", "300", ITEMDRAW_DISABLED);
	}
	else
	{
		sMenu.AddItem("item3", "300");
	}
	sMenu.ExitBackButton = true;
	sMenu.ExitButton = false;
	sMenu.Display(client, MENU_TIME_FOREVER);
}

public MenuHandler_TimerMenu(Menu sMenu, MenuAction action, int client, int item)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			if(item == 0)
			{
				Stime[client] = 1.5;
			}
			else if(item == 1)
			{
				Stime[client] = 5.0;
			}
			else if(item == 2)
			{
				Stime[client] = 10.0;
			}
			else if(item == 3)
			{
				Stime[client] = 30.0;
			}
			else if(item == 4)
			{
				Stime[client] = 60.0;
			}
			else if(item == 5)
			{
				Stime[client] = 300.0;
			}
			CGOPrintToChat(client, "%t%t", "Prefix", "The time of action is set", Stime[client]);
			TimerMenu(client);
		}
        case MenuAction_Cancel:
        {
            if(item == MenuCancel_ExitBack)
            {
                mMenu(client);
            }
        }
	}
}

public HUDdisable(int client)
{
	SetEntProp(client, Prop_Send, "m_iHideHUD", (1 << 2));  
}

public HUDenbale(int client)
{
	SetEntProp(client, Prop_Send, "m_iHideHUD", (1 << 13));  
}