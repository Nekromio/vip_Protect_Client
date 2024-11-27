#pragma semicolon 1
#pragma newdecls required

#include <smlib>
#include <colors_ws>
#include <vip_core>

Database
	hDatabase;

ConVar
	cvMySQl;

char
	sFile[PLATFORM_MAX_PATH],
	sSqlInfo[MAXPLAYERS+1][512],
	sPass[MAXPLAYERS+1][PLATFORM_MAX_PATH];

public Plugin myinfo =   
{ 
	name = "Protect Client", 
    author = "Nek.'a 2x2 | ggwp.site | github.com/Nekromio", 
    description = "Protect Client", 
    version = "1.0.1", 
    url = "https://ggwp.site/" 
};

public void OnPluginStart()
{
	LoadTranslations("vip_protet_client.phrases");
	
	cvMySQl = CreateConVar("sm_protect_mysql", "1", "1 использовать MySQL базу, 0 - использовать SqLite локальную базу", _, true, 0.0, true, 1.0);
	
	BuildPath(Path_SM, sFile, sizeof(sFile), "logs/protet_client.log");
	
	RegConsoleCmd("sm_newpass", Command_Protect);
	RegConsoleCmd("sm_new", Command_Protect);

	AutoExecConfig(true, "protect_client");
	
	RequestFrame(DatabaseConnect);
}

public void VIP_OnClientLoaded(int client, bool bIsVIP)
{
	if(!bIsVIP)
		return;

	CheckConntect(client);
}

stock void CheckConntect(int client)
{
	char sQuery[512], sSteam[32], ip[32];
	GetClientAuthId(client, AuthId_Steam2, sSteam, sizeof(sSteam), true);
	GetClientIP(client, ip, sizeof(ip));

	LogToFile(sFile, "Зашёл ViP игрок [%N][%s][%s]", client, sSteam, ip);
	FormatEx(sQuery, sizeof(sQuery), "SELECT `password` FROM `protect_client` WHERE `steam_id` = '%s';", sSteam);	// Формируем запрос
	hDatabase.Query(SQL_Callback_SelectClient, sQuery, GetClientUserId(client));
}

public Action Command_Protect(int client, any args)
{
	if(!client)
		return Plugin_Continue;
	
	if(VIP_IsClientVIP(client) || GetUserFlagBits(client))
	{
		char sArg[PLATFORM_MAX_PATH];
		GetCmdArgString(sArg, sizeof(sArg));
		
		if(args != 1)
		{
			CPrint(client, "Tag", "%t", "Tag", "Improper use");
			LogToFile(sFile, "%t", "TagLog", "Log Improper use", client);
			return Plugin_Continue;
		}
		GetCmdArg(1, sPass[client], sizeof(sPass[]));
		char sSteam[32], sQuery[512];
		GetClientAuthId(client, AuthId_Steam2, sSteam, sizeof(sSteam));
		
		FormatEx(sQuery, sizeof(sQuery), "SELECT `password` FROM `protect_client` WHERE `steam_id` = '%s';", sSteam);
		hDatabase.Query(SQL_Callback_VerificationExistence, sQuery, GetClientUserId(client)); 
	}
	return Plugin_Handled;
}

public void SQL_Callback_VerificationExistence(Database hDatabaseLocal, DBResultSet hResults, const char[] sError, any iUserID)
{
	if(sError[0])
	{
		LogError("SQL_Callback_VerificationExistence: %s", sError);
		return;
	}
	
	int client = GetClientOfUserId(iUserID);
	if(client)
	{
		if(hResults.FetchRow())
		{
			CPrint(client, "Tag", "Already installed");
			LogToFile(sFile, "%t", "TagLog", "Log Already installed", client);
			return;
		}
		else
		{
			char sPassMd5[256], sSteam[32], sQuery[512];
			GetClientAuthId(client, AuthId_Steam2, sSteam, sizeof(sSteam));
			LogToFile(sFile, "%t", "TagLog", "Log Set a password", client, sPass[client]);
			
			CPrint(client, "Tag", "%t", "Tag", "You have registered", sPass[client]);
			CPrint(client, "Tag", "%t", "Tag", "At the entrance");
			CPrint(client, "Tag", "%t", "Tag", "Set a password", sPass[client]);
			
			Crypt_MD5(sPass[client], sPassMd5, sizeof(sPassMd5));

			Format(sQuery, sizeof(sQuery), "INSERT INTO protect_client (steam_id, password) VALUES('%s', '%s');", sSteam, sPassMd5);
			hDatabase.Query(SQL_Callback_SetPassword, sQuery);
		}
	}
}

public void SQL_Callback_SetPassword(Database hDatabaseLocal, DBResultSet hResults, const char[] sError, any iUserID)
{
	if(sError[0])
	{
		LogError("SQL_Callback_SetPassword: %s", sError);
		return;
	}
}

public void DatabaseConnect(any data)
{
	if(cvMySQl.BoolValue)
		Database.Connect(ConnectCallBack, "protect_client");
	else
		Database.Connect(ConnectCallBack, "protect_client_lite");
}

void ConnectCallBack(Database hDB, const char[] szError, any data)
{
	if (hDB == null || szError[0])
	{
		SetFailState("Ошибка подключения к базе: %s", szError);
		return;
	}
	
	char sQuery[1024];

	hDatabase = hDB;		//
	SQL_LockDatabase(hDatabase);
	if(!cvMySQl.BoolValue) 
		FormatEx(sQuery, sizeof(sQuery), "CREATE TABLE IF NOT EXISTS `protect_client` (\
		`id` INTEGER PRIMARY KEY,\
		`steam_id` VARCHAR(32),\
		`password` VARCHAR(512))");
	else
	{
		FormatEx(sQuery, sizeof(sQuery), "CREATE TABLE IF NOT EXISTS `protect_client` (\
		`id` INT(11) UNSIGNED NOT NULL AUTO_INCREMENT ,\
		`steam_id` VARCHAR(32) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ,\
		`password` VARCHAR(512) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ,\
		UNIQUE `id` (`id`)) ENGINE = MyISAM CHARSET=utf8 COLLATE utf8_general_ci;");
	}

	hDatabase.Query(SQL_Callback_Connect, sQuery);
	SQL_UnlockDatabase(hDatabase);
	hDatabase.SetCharset("utf8");
}

void SQL_Callback_Connect(Database hDatabaseLocal, DBResultSet results, const char[] sError, any iUserID)
{
	if(sError[0])
	{
		LogError("SQL_Callback_SelectClient: %s", sError);
		return;
	}
}

void SQL_Callback_SelectClient(Database hDatabaseLocal, DBResultSet hResults, const char[] sError, any iUserID)
{
	if(sError[0])
	{
		LogError("SQL_Callback_SelectClient: %s", sError);
		return;
	}
	
	int client = GetClientOfUserId(iUserID);
	if(client)
	{
		if(hResults.FetchRow())
		{
			hResults.FetchString(0, sSqlInfo[client], sizeof(sSqlInfo[]));
			CheckClient(client, true);
		}
	}
}

void CheckClient(int client, bool auth)
{
	if(auth)
	{
		char sBuffer[2][256];
		GetClientInfo(client, "_protect", sBuffer[0], sizeof(sBuffer[]));
		
		if(sBuffer[0][0])
		{
			Crypt_MD5(sBuffer[0], sBuffer[1], sizeof(sBuffer[]));
			
			if(!strcmp(sBuffer[1], sSqlInfo[client]))
			{
				LogToFile(sFile, "%t", "TagLog", "With a password", client, sBuffer[0], sBuffer[1]);
			}
			else
			{
				
				LogToFile(sFile, "%t", "TagLog", "With an incorrect password", client, sBuffer[0], sBuffer[1]);
				KickClient(client, "%t", "TagLog", "Kick failed authorization", sBuffer[0]);
			}
		}
		else
		{
			LogToFile(sFile, "%t", "TagLog", "Login attempt", client);
			KickClient(client, "%t", "TagLog", "Kick login attempt");
		}
	}
	else
		LogToFile(sFile, "Игроку [%N] пароль не установлен, он заходит без авторизации !", client);
}