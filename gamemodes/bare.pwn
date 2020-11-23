#include <a_samp>
#include <crashdetect>
#include <sscanf2>
#include <izcmd>

main()
{
	print("\n----------------------------------");
	print("  Bare Script\n");
	print("----------------------------------\n");
}

static
	ps_PrivateVehicle[MAX_PLAYERS] = {INVALID_VEHICLE_ID, ...};

public OnPlayerConnect(playerid)
{
	GameTextForPlayer(playerid,"~w~SA-MP: ~r~Bare Script",5000,5);
	return 1;
}

public OnPlayerDisconnect(playerid, reason)
{
	if(IsValidVehicle(ps_PrivateVehicle[playerid]))
	{
		DestroyVehicle(ps_PrivateVehicle[playerid]);
	}
	ps_PrivateVehicle[playerid] = INVALID_VEHICLE_ID;
	return 1;
}

public OnPlayerSpawn(playerid)
{
	SetPlayerInterior(playerid,0);
	TogglePlayerClock(playerid,0);
	return 1;
}

public OnPlayerDeath(playerid, killerid, reason)
{
   	return 1;
}

SetupPlayerForClassSelection(playerid)
{
 	SetPlayerInterior(playerid,14);
	SetPlayerPos(playerid,258.4893,-41.4008,1002.0234);
	SetPlayerFacingAngle(playerid, 270.0);
	SetPlayerCameraPos(playerid,256.0815,-43.0475,1004.0234);
	SetPlayerCameraLookAt(playerid,258.4893,-41.4008,1002.0234);
}

public OnPlayerRequestClass(playerid, classid)
{
	SetupPlayerForClassSelection(playerid);
	return 1;
}

public OnGameModeInit()
{
	SetGameModeText("Bare Script");
	ShowPlayerMarkers(1);
	ShowNameTags(1);

	AddPlayerClass(265,1958.3783,1343.1572,15.3746,270.1425,0,0,0,0,-1,-1);

	return 1;
}

public OnPlayerClickMap(playerid, Float:fX, Float:fY, Float:fZ)
{
	SetPlayerPos(playerid, fX, fY, fZ);
	return 1;
}

public OnPlayerExitVehicle(playerid, vehicleid)
{
	switch(GetVehicleModel(vehicleid))
	{
		case 537, 538,  449:
		{
			SetCameraBehindPlayer(playerid);
		}
	}
	return 1;
}

CMD:jetpack(playerid)
{
	if(GetPlayerSpecialAction(playerid) == SPECIAL_ACTION_USEJETPACK)
	{
		SetPlayerSpecialAction(playerid, SPECIAL_ACTION_NONE);
	}
	else
	{
		SetPlayerSpecialAction(playerid, SPECIAL_ACTION_USEJETPACK);
	}
	return 1;
}

CMD:setskin(playerid, const params[])
{
	new
		skinid;

	if(sscanf(params, "i", skinid))
	{
		return SendClientMessage(playerid, -1, "USAGE: /setskin [skinid]");
	}

	if(skinid == 71 || !(0 <= skinid <= 311))
	{
		return SendClientMessage(playerid, -1, "Invalid skin index!");
	}

	SetPlayerSkin(playerid, skinid);
	return 1;
}

CMD:weapon(playerid, const params[])
{
	new
		weaponid,
		ammo;

	if(sscanf(params, "ik<weapon>", ammo, weaponid))
	{
		return SendClientMessage(playerid, -1, "USAGE: /weapon [ammo] [weapon]");
	}

	if(ammo <= 0)
	{
		return SendClientMessage(playerid, -1, "Invalid weapon ammo.");
	}

	switch(weaponid)
	{
		case -1, 0: return SendClientMessage(playerid, -1, "Invalid weapon.");
	}

	GivePlayerWeapon(playerid, weaponid, ammo);
	return 1;
}

CMD:vehicle(playerid, const params[])
{
	if(!strcmp(params, "destroy", true))
	{
		if(!IsValidVehicle(ps_PrivateVehicle[playerid]))
		{
			return SendClientMessage(playerid, -1, "You don't have a private vehicle.");
		}

		DestroyVehicle(ps_PrivateVehicle[playerid]);
		ps_PrivateVehicle[playerid] = INVALID_VEHICLE_ID;

		return SendClientMessage(playerid, -1, "You have destroyed your private vehicle!");
	}

	new
		model;

	if(sscanf(params, "k<vehicle>", model))
	{
		return SendClientMessage(playerid, -1, "USAGE: /vehicle [model] or 'destroy'");
	}

	if(model == -1)
	{
		return SendClientMessage(playerid, -1, "Invalid vehicle model.");
	}

	if(IsValidVehicle(ps_PrivateVehicle[playerid]))
	{
		DestroyVehicle(ps_PrivateVehicle[playerid]);
	}

	new
	Float:	x,
	Float:	y,
	Float:	z,
	Float:	angle;

	GetPlayerPos(playerid, x, y, z);
	GetPlayerFacingAngle(playerid, angle);

	switch(model)
	{
		case 537, 538, 449:
		{
			ps_PrivateVehicle[playerid] = AddStaticVehicle(model, x, y, z, angle, 1, 1);
		}
		default:
		{
			ps_PrivateVehicle[playerid] = CreateVehicle(model, x, y, z, angle, random(255), random(255), 0, 0);
		}
	}
	LinkVehicleToInterior(ps_PrivateVehicle[playerid], GetPlayerInterior(playerid));
	SetVehicleVirtualWorld(ps_PrivateVehicle[playerid], GetPlayerVirtualWorld(playerid));

	PutPlayerInVehicle(playerid, ps_PrivateVehicle[playerid], 0);

	SendClientMessage(playerid, -1, "You have successfully created a vehicle.");
	return 1;
}

CMD:gotocar(playerid, const params[])
{
	new
		vehicleid;

	if(sscanf(params, "i", vehicleid))
	{
		return SendClientMessage(playerid,  -1, "/gotocar [vehicleid]");
	}

	if(!IsValidVehicle(vehicleid))
	{
		return SendClientMessage(playerid, -1, "Invalid vehicle ID!");
	}	

	new
	Float:	x,
	Float:	y,
	Float:	z;

	GetVehiclePos(vehicleid, x, y, z);
	SetPlayerPos(playerid, x, y, z);

	return 1;
}

CMD:goto(playerid, const params[])
{
	new
		targetid;

	if(sscanf(params, "u", targetid))
	{
		return SendClientMessage(playerid, -1, "/goto [playerid/PartOfName]");
	}

	if(!IsPlayerConnected(targetid))
	{
		return SendClientMessage(playerid, -1, "Invalid player.");
	}

	new
	Float:	x,
	Float:	y,
	Float:	z;

	GetPlayerPos(targetid, x, y, z);
	if(GetPlayerState(playerid) == PLAYER_STATE_DRIVER)
	{
		new
			vehicleid = GetPlayerVehicleID(playerid);

		SetVehiclePos(vehicleid, x, y, z);
		SetVehicleVirtualWorld(vehicleid, GetPlayerVirtualWorld(targetid));
		LinkVehicleToInterior(vehicleid, GetPlayerInterior(targetid));
	}
	else
	{
		SetPlayerPos(playerid, x, y, z);
		SetPlayerInterior(playerid, GetPlayerInterior(targetid));
		SetPlayerVirtualWorld(playerid, GetPlayerVirtualWorld(targetid));
	}

	new
		string[144];
	GetPlayerName(targetid, string, sizeof(string));

	format(string, sizeof(string), "You have teleported to %s.", string);
	SendClientMessage(playerid, -1, string);

	return 1;
}