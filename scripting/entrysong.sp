#include <sourcemod>
#include <emitsoundany>
#include <sdktools>
#include <sdkhooks>
#include <menu-stocks>
#include <clientprefs>

#pragma semicolon 1;
#pragma newdecls required;

// ************************** Author & Description *************************** 

public Plugin myinfo = 
{
	name = "Entry Song",
	author = "xSLOW",
	description = "Set your own custom entry song",
	version = "1.0",
	url = "https://steamcommunity.com/profiles/76561193897443537"
};


// ************************** Variables *************************** 

char g_sEntrySongs[256][128];
char g_sSteamIds[256][32];

int g_iEntrySongsCounter;

bool g_bEntrySongsBool[MAXPLAYERS+1] = true;

Handle g_hEntrySongBool_Cookie = INVALID_HANDLE;


// ************************** ON PLUGIN START *************************** 

public void OnPluginStart()
{
    RegConsoleCmd("sm_entrysong", Command_EntrySong);
    RegConsoleCmd("sm_entrysongs", Command_EntrySong);
    g_hEntrySongBool_Cookie = RegClientCookie("Entry Song", "Turn it ON/OFF", CookieAccess_Private);
}


// ************************** ON MAP START *************************** 

public void OnMapStart()
{
    LoadConfigEntrySongs();
    EntrySongs_Cache();
}

// ************************** COMMAND_ENTRYSONG *************************** 

public Action Command_EntrySong(int client, int args) 
{
    if(IsClientValid(client))
        ShowMenu(client);
}

// ************************** OnClientPostAdmiCheck *************************** 

public void OnClientPostAdminCheck(int client)
{
    if(IsClientValid(client))
    {
        char pSTEAMID[32];
        GetClientAuthId(client, AuthId_Steam2, pSTEAMID, sizeof(pSTEAMID));
        for (int i = 0; i < g_iEntrySongsCounter; i++)
        {
            if(StrEqual(pSTEAMID, g_sSteamIds[i]))
            {
                char pSONG[128];
                Format(pSONG, sizeof(pSONG), "*/%s", g_sEntrySongs[i]);
                DataPack pack;
                CreateDataTimer(GetRandomFloat(3.0, 15.0), Timer_SendSong, pack);
                pack.WriteCell(client);
                pack.WriteString(pSONG);
            }
        }
        CreateTimer(5.0, Timer_OpenMenu, GetClientUserId(client));
    }
}

// ************************** Timer to open menu afer OnClientPostAdminCheck *************************** 

public Action Timer_OpenMenu(Handle timer, any userid)
{
    int client = GetClientOfUserId(userid);

    if(AreClientCookiesCached(client))
    {
        char cBuffer[8];
        GetClientCookie(client, g_hEntrySongBool_Cookie, cBuffer, sizeof(cBuffer));
        if(!StrEqual(cBuffer, "0") && !StrEqual(cBuffer, "1"))
        {
            ShowMenu(client);
        }
    }
}


// ************************** Timer_SendSong *************************** 

public Action Timer_SendSong(Handle timer, DataPack pack)
{
    char pSong[128];
    int client;
    pack.Reset();
    client = pack.ReadCell();
    pack.ReadString(pSong, sizeof(pSong));

    for(int iClient = 1; iClient <= MaxClients; iClient++)
    {
        if(IsClientValid(iClient) && g_bEntrySongsBool[iClient])
        {
            StopSound(iClient, SNDCHAN_STATIC, pSong);
            EmitSoundToClient(iClient, pSong, SOUND_FROM_PLAYER, SNDCHAN_STATIC, SNDLEVEL_NONE, _, 1.0);
            PrintToChat(iClient, " \x07*****************************");
            PrintToChat(iClient, " \x01Playing \x10%N\'s \x01song!", client);
            PrintToChat(iClient, " \x07*****************************");
            PrintToChat(iClient, " \x01* You can disable these songs by using \x10!entrysongs");
        }
    }
}

// ************************** LOAD CFG FILE *************************** 

public void LoadConfigEntrySongs()
{
    if(FileExists("addons/sourcemod/configs/EntrySong.cfg"))
    {
        KeyValues kv = new KeyValues("EntrySong");
        kv.ImportFromFile("addons/sourcemod/configs/EntrySong.cfg");    

        if (!kv.GotoFirstSubKey())
        {
            delete kv;
        }

        char SongPath[255], SteamID[32];
        g_iEntrySongsCounter = 0;

        do
	    {
            KvGetString(kv, "Song", SongPath, 255);
            kv.GetSectionName(SteamID, sizeof(SteamID));
            strcopy(g_sEntrySongs[g_iEntrySongsCounter], sizeof(g_sEntrySongs[]), SongPath);
            strcopy(g_sSteamIds[g_iEntrySongsCounter], sizeof(g_sSteamIds[]), SteamID);
            g_iEntrySongsCounter++;
	    } while (kv.GotoNextKey());
        delete kv;

    }
    else SetFailState("Config files not found. Check if config files are missing.");
}

// ************************** ADD FILES TO PRECACHE & DOWNLOADS TABLE  *************************** 

public void EntrySongs_Cache()
{
    for (int i = 0; i < g_iEntrySongsCounter; i++)
    {
        char FilePathToCheck[256];
        Format(FilePathToCheck, sizeof(FilePathToCheck), "sound/%s", g_sEntrySongs[i]);
        if(FileExists(FilePathToCheck))
        {
            char filepath[1024];
            Format(filepath, sizeof(filepath), "sound/%s", g_sEntrySongs[i]);
            AddFileToDownloadsTable(filepath);

            char soundpath[1024];
            Format(soundpath, sizeof(soundpath), "*/%s", g_sEntrySongs[i]);
            FakePrecacheSound(soundpath);
        } else LogError("Missing sound file: %s", FilePathToCheck);
    }
}

// ************************** CREATE THE MENU *************************** 

public void ShowMenu(int client)
{
    Menu EntrySongMenu = new Menu(ShowMenuHandler, MENU_ACTIONS_DEFAULT);
    EntrySongMenu.SetTitle("[Entry Songs] \nEnable entry songs? \nYou can type !entrysong later to ENABLE/DISABLE");
    EntrySongMenu.AddItem("Yes", "Yes");
    EntrySongMenu.AddItem("No", "No");

    EntrySongMenu.ExitButton = false;
    EntrySongMenu.Display(client, 15);
}

// ************************** MENU HANDLER *************************** 

public int ShowMenuHandler(Menu EntrySongMenu, MenuAction action, int param1, int param2)
{
    int client = param1;

    if(IsClientValid(client))
    {
        switch(action)
	    {
	    	case MenuAction_Select:
	    	{
	    		char info[128];
	    		EntrySongMenu.GetItem(param2, info, sizeof(info));
	    		if(StrEqual(info, "Yes"))
	    		{
                    PrintToChat(client, "* \x04[ON]\x01 - You can change your preference later by typing \x10!entrysongs");
                    if(AreClientCookiesCached(client))
                    {
                        SetClientCookie(client, g_hEntrySongBool_Cookie, "1");
                    }
                    else PrintToChatAll(" \x02Database NOT loaded. Settings not saved. Try again later.");
                    g_bEntrySongsBool[client] = true;
	    		}
	    		else if(StrEqual(info, "No"))
                {
                    PrintToChat(client, "* \x02[OFF]\x01 - You can change your preference later by typing \x10!entrysongs");
                    if(AreClientCookiesCached(client))
                    {
                        SetClientCookie(client, g_hEntrySongBool_Cookie, "0");
                    }
                    else PrintToChatAll(" \x02Database NOT loaded. Settings not saved. Try again later.");
                    g_bEntrySongsBool[client] = false;
                }
	    	}
    
	    	case MenuAction_Cancel:
            {
                PrintToChat(client, "* \x03[CANCELED]\x01 - You can change your preference later by typing \x10!entrysongs");
            }
	    }
    }
}

// ************************** OnClientsCookieCached *************************** 

public void OnClientCookiesCached(int client)
{
    if(IsClientValid(client))
    {
        char cBuffer[8];
        GetClientCookie(client, g_hEntrySongBool_Cookie, cBuffer, sizeof(cBuffer));

        if(StrEqual(cBuffer, "1", false))
        {
            g_bEntrySongsBool[client] = true;
        }
        else if(StrEqual(cBuffer, "0", false))
        {
            g_bEntrySongsBool[client] = false;
        }
    }
}


// ************************** SMALL STUFF *************************** 

// https://wiki.alliedmods.net/Csgo_quirks
stock void FakePrecacheSound(const char[] szPath)
{
	AddToStringTable(FindStringTable("soundprecache"), szPath);
}

stock bool IsClientValid(int client)
{
    return (0 < client <= MaxClients) && IsClientInGame(client) && !IsFakeClient(client);
}
