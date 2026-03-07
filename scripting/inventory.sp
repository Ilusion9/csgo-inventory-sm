#pragma newdecls required

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <cstrike>
#include <clientprefs>
#include <intmap>
#include <clearhandle>

public Plugin myinfo =
{
	name = "Inventory",
	author = "Ilusion",
	description = "Inventory preferences.",
	version = "1.0",
	url = "https://github.com/Ilusion9/"
};

enum TWeapon
{
	TWeapon_TEC9,
	TWeapon_DEAGLE,
	TWeapon_MP7,
	TWeapon_MAX_WEAPONS
}

enum CTWeapon
{
	CTWeapon_HKP2000,
	CTWeapon_FIVESEVEN,
	CTWeapon_DEAGLE,
	CTWeapon_MP7,
	CTWeapon_M4A1,
	CTWeapon_MAX_WEAPONS
}

Cookie g_Cookie_TInventory;
Cookie g_Cookie_CTInventory;

IntMap g_Map_Weapons;

CSWeaponID g_TInventory[MAXPLAYERS + 1][TWeapon_MAX_WEAPONS];
CSWeaponID g_CTInventory[MAXPLAYERS + 1][CTWeapon_MAX_WEAPONS];

public void OnPluginStart()
{
	g_Cookie_TInventory = new Cookie("inventory_t", "Inventory preferences for Terrorists.", CookieAccess_Private);
	g_Cookie_CTInventory = new Cookie("inventory_ct", "Inventory preferences for Counter-Terrorists.", CookieAccess_Private);
	
	g_Map_Weapons = new IntMap();
	
	HookEvent("round_prestart", Event_RoundPreStart);
	
	RegConsoleCmd("sm_inventory", Command_Invantory);
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i))
		{
			continue;
		}
		
		OnClientConnected(i);
		
		if (AreClientCookiesCached(i))
		{
			OnClientCookiesCached(i);
		}
	}
}

public void OnPluginEnd()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i))
		{
			continue;
		}
		
		SaveClientInventory(i);
	}
}

public void OnMapEnd()
{
	ClearTrie_Ex(view_as<StringMap>(g_Map_Weapons));
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if (!strncmp(classname, "weapon_", 7, true))
	{
		SDKHook(entity, SDKHook_SpawnPost, SDK_WeaponSpawn);
	}
}

public void OnClientConnected(int client)
{
	g_TInventory[client][TWeapon_TEC9] = CSWeapon_TEC9;
	g_TInventory[client][TWeapon_DEAGLE] = CSWeapon_DEAGLE;
	g_TInventory[client][TWeapon_MP7] = CSWeapon_MP7;
	
	g_CTInventory[client][CTWeapon_HKP2000] = CSWeapon_HKP2000;
	g_CTInventory[client][CTWeapon_FIVESEVEN] = CSWeapon_FIVESEVEN;
	g_CTInventory[client][CTWeapon_DEAGLE] = CSWeapon_DEAGLE;
	g_CTInventory[client][CTWeapon_MP7] = CSWeapon_MP7;
	g_CTInventory[client][CTWeapon_M4A1] = CSWeapon_M4A1;
}

public void OnClientCookiesCached(int client)
{
	LoadClientTerroristInventory(client);
	LoadClientCounterTerroristInventory(client);
}

public void OnClientDisconnect(int client)
{
	SaveClientInventory(client);
}

public void Event_RoundPreStart(Event event, const char[] name, bool dontBroadcast)
{
	ClearTrie_Ex(view_as<StringMap>(g_Map_Weapons));
}

public Action Command_Invantory(int client, int args)
{
	if (!client || !IsClientInGame(client))
	{
		return Plugin_Handled;
	}
	
	DisplayInventoryMenu(client);
	
	return Plugin_Handled;
}

public void SDK_WeaponSpawn(int entity)
{
	int entityRef = EntIndexToEntRef_Ex(entity);
	
	if (g_Map_Weapons.ContainsKey(entityRef))
	{
		return;
	}
	
	g_Map_Weapons.SetValue(entityRef, true);
	
	RequestFrame(Frame_WeaponSpawn, EntIndexToEntRef_Ex(entity));
}

public int Menu_Inventory(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_End)
	{
		delete menu;
	}
	else if (action == MenuAction_Select)
	{
		if (!IsClientInGame(param1))
		{
			return 0;
		}
		
		char arg[128];
		
		menu.GetItem(param2, arg, sizeof(arg));
		
		if (StrEqual(arg, "#t", true))
		{
			DisplayTerroristInventoryMenu(param1);
		}
		else if (StrEqual(arg, "#ct", true))
		{
			DisplayCounterTerroristInventoryMenu(param1);
		}
	}
	
	return 0;
}

public int Menu_TerroristInventory(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_End)
	{
		delete menu;
	}
	else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack)
		{
			DisplayInventoryMenu(param1);
		}
	}
	else if (action == MenuAction_Select)
	{
		if (!IsClientInGame(param1))
		{
			return 0;
		}
		
		char arg[128];
		
		menu.GetItem(param2, arg, sizeof(arg));
		
		if (StrEqual(arg, "#tec9", true))
		{
			if (g_TInventory[param1][TWeapon_TEC9] == CSWeapon_TEC9)
			{
				g_TInventory[param1][TWeapon_TEC9] = CSWeapon_CZ75A;
			}
			else
			{
				g_TInventory[param1][TWeapon_TEC9] = CSWeapon_TEC9;
			}
		}
		else if (StrEqual(arg, "#mp7", true))
		{
			if (g_TInventory[param1][TWeapon_MP7] == CSWeapon_MP7)
			{
				g_TInventory[param1][TWeapon_MP7] = CSWeapon_MP5NAVY;
			}
			else
			{
				g_TInventory[param1][TWeapon_MP7] = CSWeapon_MP7;
			}
		}
		else if (StrEqual(arg, "#deagle", true))
		{
			if (g_TInventory[param1][TWeapon_DEAGLE] == CSWeapon_DEAGLE)
			{
				g_TInventory[param1][TWeapon_DEAGLE] = CSWeapon_REVOLVER;
			}
			else
			{
				g_TInventory[param1][TWeapon_DEAGLE] = CSWeapon_DEAGLE;
			}
		}
		
		DisplayTerroristInventoryMenu(param1);
	}
	
	return 0;
}

public int Menu_CounterTerroristInventory(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_End)
	{
		delete menu;
	}
	else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack)
		{
			DisplayInventoryMenu(param1);
		}
	}
	else if (action == MenuAction_Select)
	{
		if (!IsClientInGame(param1))
		{
			return 0;
		}
		
		char arg[128];
		
		menu.GetItem(param2, arg, sizeof(arg));
		
		if (StrEqual(arg, "#hkp2000", true))
		{
			if (g_CTInventory[param1][CTWeapon_HKP2000] == CSWeapon_HKP2000)
			{
				g_CTInventory[param1][CTWeapon_HKP2000] = CSWeapon_USP_SILENCER;
			}
			else
			{
				g_CTInventory[param1][CTWeapon_HKP2000] = CSWeapon_HKP2000;
			}
		}
		else if (StrEqual(arg, "#fiveseven", true))
		{
			if (g_CTInventory[param1][CTWeapon_FIVESEVEN] == CSWeapon_FIVESEVEN)
			{
				g_CTInventory[param1][CTWeapon_FIVESEVEN] = CSWeapon_CZ75A;
			}
			else
			{
				g_CTInventory[param1][CTWeapon_FIVESEVEN] = CSWeapon_FIVESEVEN;
			}
		}
		else if (StrEqual(arg, "#deagle", true))
		{
			if (g_CTInventory[param1][CTWeapon_DEAGLE] == CSWeapon_DEAGLE)
			{
				g_CTInventory[param1][CTWeapon_DEAGLE] = CSWeapon_REVOLVER;
			}
			else
			{
				g_CTInventory[param1][CTWeapon_DEAGLE] = CSWeapon_DEAGLE;
			}
		}
		else if (StrEqual(arg, "#mp7", true))
		{
			if (g_CTInventory[param1][CTWeapon_MP7] == CSWeapon_MP7)
			{
				g_CTInventory[param1][CTWeapon_MP7] = CSWeapon_MP5NAVY;
			}
			else
			{
				g_CTInventory[param1][CTWeapon_MP7] = CSWeapon_MP7;
			}
		}
		else if (StrEqual(arg, "#m4a1", true))
		{
			if (g_CTInventory[param1][CTWeapon_M4A1] == CSWeapon_M4A1)
			{
				g_CTInventory[param1][CTWeapon_M4A1] = CSWeapon_M4A1_SILENCER;
			}
			else
			{
				g_CTInventory[param1][CTWeapon_M4A1] = CSWeapon_M4A1;
			}
		}
		
		DisplayCounterTerroristInventoryMenu(param1);
	}
	
	return 0;
}

void Frame_WeaponSpawn(any data)
{
	int entity = EntRefToEntIndex(view_as<int>(data));
	
	if (!IsValidEntity(entity))
	{
		return;
	}
	
	int currentOwner = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
	
	if (IsEntityClient(currentOwner) && IsClientInGame(currentOwner))
	{
		OnWeaponSpawn(entity, currentOwner, 0);
	}
	else
	{
		int previousOwner = GetEntPropEnt(entity, Prop_Send, "m_hPrevOwner");
			
		if (IsEntityClient(previousOwner) && IsClientInGame(previousOwner))
		{
			OnWeaponSpawn(entity, 0, previousOwner);
		}
	}
}

void OnWeaponSpawn(int entity, int currentOwner, int previousOwner) 
{
	int client = currentOwner ? currentOwner : previousOwner;
	
	CSWeaponID weaponId = CS_ItemDefIndexToID(GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex"));
	
	if (weaponId == CSWeapon_TEC9)
	{
		if (g_TInventory[client][TWeapon_TEC9] == CSWeapon_CZ75A)
		{
			if (client == currentOwner)
			{
				CS_DropWeapon(client, entity, false);
			}
			
			RemoveEntity(entity);
			
			GivePlayerItem(client, "weapon_cz75a");
		}
	}
	else if (weaponId == CSWeapon_DEAGLE)
	{
		int clientTeam = GetClientTeam(client);
		
		if (clientTeam == CS_TEAM_T)
		{
			if (g_TInventory[client][TWeapon_DEAGLE] == CSWeapon_REVOLVER)
			{
				if (client == currentOwner)
				{
					CS_DropWeapon(client, entity, false);
				}
				
				RemoveEntity(entity);
				
				GivePlayerItem(client, "weapon_revolver");
			}
		}
		else
		{
			if (g_CTInventory[client][CTWeapon_DEAGLE] == CSWeapon_REVOLVER)
			{
				if (client == currentOwner)
				{
					CS_DropWeapon(client, entity, false);
				}
				
				RemoveEntity(entity);
				
				GivePlayerItem(client, "weapon_revolver");
			}
		}
	}
	else if (weaponId == CSWeapon_HKP2000)
	{
		if (g_CTInventory[client][CTWeapon_HKP2000] == CSWeapon_USP_SILENCER)
		{
			if (client == currentOwner)
			{
				CS_DropWeapon(client, entity, false);
			}
			
			RemoveEntity(entity);
			
			GivePlayerItem(client, "weapon_usp_silencer");
		}
	}
	else if (weaponId == CSWeapon_FIVESEVEN)
	{
		if (g_CTInventory[client][CTWeapon_FIVESEVEN] == CSWeapon_CZ75A)
		{
			if (client == currentOwner)
			{
				CS_DropWeapon(client, entity, false);
			}
			
			RemoveEntity(entity);
			
			GivePlayerItem(client, "weapon_cz75a");
		}
	}
	else if (weaponId == CSWeapon_MP7)
	{
		int clientTeam = GetClientTeam(client);
		
		if (clientTeam == CS_TEAM_T)
		{
			if (g_TInventory[client][TWeapon_MP7] == CSWeapon_MP5NAVY)
			{
				if (client == currentOwner)
				{
					CS_DropWeapon(client, entity, false);
				}
				
				RemoveEntity(entity);
				
				GivePlayerItem(client, "weapon_mp5sd");
			}
		}
		else
		{
			if (g_CTInventory[client][CTWeapon_MP7] == CSWeapon_MP5NAVY)
			{
				if (client == currentOwner)
				{
					CS_DropWeapon(client, entity, false);
				}
				
				RemoveEntity(entity);
				
				GivePlayerItem(client, "weapon_mp5sd");
			}
		}
	}
	else if (weaponId == CSWeapon_M4A1)
	{
		if (g_CTInventory[client][CTWeapon_M4A1] == CSWeapon_M4A1_SILENCER)
		{
			if (client == currentOwner)
			{
				CS_DropWeapon(client, entity, false);
			}
			
			RemoveEntity(entity);
			
			GivePlayerItem(client, "weapon_m4a1_silencer");
		}
	}
}

void LoadClientTerroristInventory(int client)
{
	char buffer[256];
	
	g_Cookie_TInventory.Get(client, buffer, sizeof(buffer));
	
	if (!buffer[0])
	{
		return;
	}
	
	char parts[TWeapon_MAX_WEAPONS][256];
	
	ExplodeString(buffer, "|", parts, sizeof(parts), sizeof(parts[]));
	
	for (int i = 0; i < sizeof(parts); i++)
	{
		char buffers[2][128];
		
		ExplodeString(parts[i], ":", buffers, sizeof(buffers), sizeof(buffers[]));
		
		if (StrEqual(buffers[0], "tec9", true))
		{
			g_TInventory[client][TWeapon_TEC9] = view_as<CSWeaponID>(StringToInt(buffers[1]));
		}
		else if (StrEqual(buffers[0], "deagle", true))
		{
			g_TInventory[client][TWeapon_DEAGLE] = view_as<CSWeaponID>(StringToInt(buffers[1]));
		}
		else if (StrEqual(buffers[0], "mp7", true))
		{
			g_TInventory[client][TWeapon_MP7] = view_as<CSWeaponID>(StringToInt(buffers[1]));
		}
	}
}

void LoadClientCounterTerroristInventory(int client)
{
	char buffer[256];
	
	g_Cookie_CTInventory.Get(client, buffer, sizeof(buffer));
	
	if (!buffer[0])
	{
		return;
	}
	
	char parts[CTWeapon_MAX_WEAPONS][256];
	
	ExplodeString(buffer, "|", parts, sizeof(parts), sizeof(parts[]));
	
	for (int i = 0; i < sizeof(parts); i++)
	{
		char buffers[2][128];
		
		ExplodeString(parts[i], ":", buffers, sizeof(buffers), sizeof(buffers[]));
		
		if (StrEqual(buffers[0], "hkp2000", true))
		{
			g_CTInventory[client][CTWeapon_HKP2000] = view_as<CSWeaponID>(StringToInt(buffers[1]));
		}
		else if (StrEqual(buffers[0], "fiveseven", true))
		{
			g_CTInventory[client][CTWeapon_FIVESEVEN] = view_as<CSWeaponID>(StringToInt(buffers[1]));
		}
		else if (StrEqual(buffers[0], "deagle", true))
		{
			g_CTInventory[client][CTWeapon_DEAGLE] = view_as<CSWeaponID>(StringToInt(buffers[1]));
		}
		else if (StrEqual(buffers[0], "mp7", true))
		{
			g_CTInventory[client][CTWeapon_MP7] = view_as<CSWeaponID>(StringToInt(buffers[1]));
		}
		else if (StrEqual(buffers[0], "m4a1", true))
		{
			g_CTInventory[client][CTWeapon_M4A1] = view_as<CSWeaponID>(StringToInt(buffers[1]));
		}
	}
}

void SaveClientInventory(int client)
{
	SaveClientTerroristInventory(client)
	SaveClientCounterTerroristInventory(client)
}

void SaveClientTerroristInventory(int client)
{
	if (!g_Cookie_TInventory)
	{
		return;
	}
	
	char buffer[256];
	
	FormatEx(buffer, sizeof(buffer), "tec9:%d|deagle:%d|mp7:%d", 
		view_as<int>(g_TInventory[client][TWeapon_TEC9]), 
		view_as<int>(g_TInventory[client][TWeapon_DEAGLE]), 
		view_as<int>(g_CTInventory[client][CTWeapon_MP7]));
	
	g_Cookie_TInventory.Set(client, buffer);
}

void SaveClientCounterTerroristInventory(int client)
{
	if (!g_Cookie_CTInventory)
	{
		return;
	}
	
	char buffer[256];
	
	FormatEx(buffer, sizeof(buffer), "hkp2000:%d|fiveseven:%d|deagle:%d|mp7:%d|m4a1:%d", 
		view_as<int>(g_CTInventory[client][CTWeapon_HKP2000]), 
		view_as<int>(g_CTInventory[client][CTWeapon_FIVESEVEN]), 
		view_as<int>(g_CTInventory[client][CTWeapon_DEAGLE]), 
		view_as<int>(g_CTInventory[client][CTWeapon_MP7]), 
		view_as<int>(g_CTInventory[client][CTWeapon_M4A1]));
	
	g_Cookie_CTInventory.Set(client, buffer);
}

void DisplayInventoryMenu(int client)
{
	Menu menu = new Menu(Menu_Inventory);
	
	menu.SetTitle("Inventory");
	
	menu.AddItem("#t", "Terrorists");
	menu.AddItem("#ct", "Counter-Terrorists");
	
	menu.Display(client, MENU_TIME_FOREVER);
}

void DisplayTerroristInventoryMenu(int client)
{
	Menu menu = new Menu(Menu_TerroristInventory);
	
	menu.SetTitle("Inventory - Terrorists");
	
	if (g_TInventory[client][TWeapon_TEC9] == CSWeapon_TEC9)
	{
		menu.AddItem("#tec9", "Tec9 | CZ775A [Tec9]");
	}
	else
	{
		menu.AddItem("#tec9", "Tec9 | CZ775A [CZ775A]");
	}
	
	if (g_TInventory[client][TWeapon_DEAGLE] == CSWeapon_DEAGLE)
	{
		menu.AddItem("#deagle", "Deagle | Revolver [Deagle]");
	}
	else
	{
		menu.AddItem("#deagle", "Deagle | Revolver [Revolver]");
	}
	
	if (g_TInventory[client][TWeapon_MP7] == CSWeapon_MP7)
	{
		menu.AddItem("#mp7", "MP7 | MP5SD [MP7]");
	}
	else
	{
		menu.AddItem("#mp7", "MP7 | MP5SD [MP5SD]");
	}
	
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

void DisplayCounterTerroristInventoryMenu(int client)
{
	Menu menu = new Menu(Menu_CounterTerroristInventory);
	
	menu.SetTitle("Inventory - Counter-Terrorists");
	
	if (g_CTInventory[client][CTWeapon_HKP2000] == CSWeapon_HKP2000)
	{
		menu.AddItem("#hkp2000", "HKP2000 | USP-S [HKP2000]");
	}
	else
	{
		menu.AddItem("#hkp2000", "HKP2000 | USP-S [USP-S]");
	}
	
	if (g_CTInventory[client][CTWeapon_FIVESEVEN] == CSWeapon_FIVESEVEN)
	{
		menu.AddItem("#fiveseven", "Fiveseven | CZ775A [Fiveseven]");
	}
	else
	{
		menu.AddItem("#fiveseven", "Fiveseven | CZ775A [CZ775A]");
	}
	
	if (g_CTInventory[client][CTWeapon_DEAGLE] == CSWeapon_DEAGLE)
	{
		menu.AddItem("#deagle", "Deagle | Revolver [Deagle]");
	}
	else
	{
		menu.AddItem("#deagle", "Deagle | Revolver [Revolver]");
	}
	
	if (g_CTInventory[client][CTWeapon_MP7] == CSWeapon_MP7)
	{
		menu.AddItem("#mp7", "MP7 | MP5SD [MP7]");
	}
	else
	{
		menu.AddItem("#mp7", "MP7 | MP5SD [MP5SD]");
	}
	
	if (g_CTInventory[client][CTWeapon_M4A1] == CSWeapon_M4A1)
	{
		menu.AddItem("#m4a1", "M4A4 | M4A1-S [M4A4]");
	}
	else
	{
		menu.AddItem("#m4a1", "M4A4 | M4A1-S [M4A1-S]");
	}
	
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

bool IsEntityClient(int client)
{
	return (client > 0 && client <= MaxClients);
}

int EntIndexToEntRef_Ex(int entity)
{
	if (entity == -1)
	{
		return INVALID_ENT_REFERENCE;
	}
	
	if (entity < 0 || entity > 4096)
	{
		return entity;
	}
	
	return EntIndexToEntRef(entity);
}