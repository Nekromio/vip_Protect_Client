# vip_Protect_Client
Protect Client

The plugin allows users (ViP и Admin) to set a password for their Steam_id

Плагин позволяет пользователям устанавливать на свой Steam_id пароль

Set password: sm_new 1111
When logging in to the console: setinfo _protect 1111
Profit

Requirements:
1. https://hlmod.ru/resources/colors-inc-cveta-csgo-css-css-v34.2358/
2. https://hlmod.ru/resources/vip-core.245/
3. https://github.com/bcserv/smlib

MySQL and SQLite support

/addons/sourcemod/configs/databases.cfg

"protect_client"
	{ 
		"driver" "mysql" 
		"host" "ip" 
		"database" "database" 
		"user" "user" 
		"pass" "pass" 
		//"timeout" "0" 
		"port" "3306" 
	}
  
  Config: /cfg/sourcemod/protect_client.cfg

Logs: /addons/sourcemod/logs/protet_client.log
