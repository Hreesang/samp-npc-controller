//
#define FILTERSCRIPT

//
#include <a_samp>
#include <crashdetect>
#include <sscanf2>
#include <streamer>
#include <FCNPC>
#include <izcmd>
#include <formatex>

//
#define COLOR_TOMATO                    0xFF6347FF
#define COLOR_WHITE                     0xFFFFFFFF
#define C_TOMATO                        "{FF6347}"
#define C_WHITE                         "{FFFFFF}"

//
static 
    bool:gNPCFromFS[MAX_PLAYERS];

stock hk_FCNPC_Create(const name[])
{
    new
        npcid = FCNPC_Create(name);

    if(FCNPC_IsValid(npcid))
    {
        gNPCFromFS[npcid] = true;
    }

    return npcid;
}

#if defined _ALS_FCNPC_Create
    #undef FCNPC_Create
#else
    #define _ALS_FCNPC_Create
#endif
#define FCNPC_Create hk_FCNPC_Create

//
public OnFilterScriptExit()
{
    for(new i = 0; i < MAX_PLAYERS; i++)
    {
        if(FCNPC_IsValid(i) && gNPCFromFS[i])
        {
            FCNPC_Destroy(i);
            gNPCFromFS[i] = false;
        }
    }
    return 1;
}

public OnFilterScriptInit()
{
    print("\n");
    print(" |=============================|");
    print(" |                             |");
    print(" |    NPC Controller 1.0.0     |");
    print(" |         by Hreesang         |");
    print(" |   /anim, /(rec)ord, /npc    |");
    print(" |                             |");
    print(" |=============================|");
    print("\n");
    return 1;
}

//
stock IsValidSkin(skinid)
{
    if(!(0 <= skinid <= 311) || skinid == 74)
    {
        return false;
    }
    return true;
}

//
new
    gLoadedNPCs = 0,

    gNPC_CurPlaybackFile[MAX_PLAYERS][32],
    bool:gPlayerRecording[MAX_PLAYERS] = {false, ...},
    bool:gNPCLoadingRecord[MAX_PLAYERS] = {false, ...},
    bool:gNPCStartingPlayback[MAX_PLAYERS] = {false, ...},
    bool:gNPCStartingPlaybackLoop[MAX_PLAYERS] = {false, ...},

    bool:gPlayerNPCLabelShown[MAX_PLAYERS] = {false, ...},
    Text3D:gPlayerNPCLabel[MAX_PLAYERS][MAX_PLAYERS] = {{Text3D:INVALID_STREAMER_ID, ...}, ...};

//
public OnPlayerConnect(playerid)
{
    gPlayerRecording[playerid] =
    gPlayerNPCLabelShown[playerid] = false;
    return 1;
}

public OnPlayerDisconnect(playerid, reason)
{
    if(gPlayerRecording[playerid])
    {
        StopRecordingPlayerData(playerid);
    }

    if(gNPCLoadingRecord[playerid] || gNPCStartingPlayback[playerid])
    {
        FCNPC_StopPlayingPlayback(playerid);
    }
    
    gNPCLoadingRecord[playerid] = false;
    gNPC_CurPlaybackFile[playerid][0] = EOS;
    for(new i = 0; i < MAX_PLAYERS; i++)
    {
        if(IsValidDynamic3DTextLabel(gPlayerNPCLabel[playerid][i]))
        {
            DestroyDynamic3DTextLabel(gPlayerNPCLabel[playerid][i]);
            gPlayerNPCLabel[playerid][i] = Text3D:INVALID_STREAMER_ID;    
        }

        if(IsValidDynamic3DTextLabel(gPlayerNPCLabel[i][playerid]))
        {
            DestroyDynamic3DTextLabel(gPlayerNPCLabel[i][playerid]);
            gPlayerNPCLabel[i][playerid] = Text3D:INVALID_STREAMER_ID;
        }
    }
        
    gNPCStartingPlayback[playerid] = false;
    gNPCStartingPlaybackLoop[playerid] = false;
    return 1;
}

//
public FCNPC_OnFinishPlayback(npcid)
{
    if(gNPCLoadingRecord[npcid])
    {
        gNPCLoadingRecord[npcid] = false;
        FCNPC_Destroy(npcid);
    }

    if(gNPCStartingPlayback[npcid])
    {
        if(gNPCStartingPlaybackLoop[npcid])
        {
            FCNPC_StartPlayingPlayback(npcid, gNPC_CurPlaybackFile[npcid]);
        }
        else
        {
            gNPCStartingPlayback[npcid] = false;
            FCNPC_StopPlayingPlayback(npcid);
            for(new i = GetPlayerPoolSize(); i >= 0; i --)
            {
                UpdatePlayerNPCLabel(i);
            }
        }
    }
    return 1;
}

//
CMD:rec(playerid, params[])
{
    return cmd_record(playerid, params);
}

CMD:record(playerid, option[])
{
    new
        params[128];
    sscanf(option, "s[32]s[128]", option, params);

    if(isnull(option))
    {
        SendClientMessage(playerid, COLOR_TOMATO, "USAGE: /(rec)ord [option]");
        SendClientMessage(playerid, COLOR_TOMATO, "OPTION: "C_WHITE"start, stop, load");
        return 1;
    }

    if(!strcmp(option, "start", true))
    {
        if(gPlayerRecording[playerid] == true)
        {
            SendClientMessage(playerid, COLOR_TOMATO, "You are currently recording.");
            return 1;
        }

        if(isnull(params))
        {
            SendClientMessage(playerid, COLOR_TOMATO, "USAGE: /(rec)ord start [filename]");
            return 1;
        }

        if(strlen(params) >= 32)
        {
            SendClientMessage(playerid, COLOR_TOMATO, "Recording playback name must be below 32 characters.");
            return 1;
        }

        if(strfind("/", params) != -1)
        {
            SendClientMessage(playerid, COLOR_TOMATO, "You can't add '/' to the filename.");
            return 1;
        }

        gPlayerRecording[playerid] = true;

        if(GetPlayerState(playerid) == PLAYER_STATE_DRIVER)
        {
            StartRecordingPlayerData(playerid, PLAYER_RECORDING_TYPE_DRIVER, params);
            SendClientMessage(playerid, COLOR_TOMATO, "[ ! ] "C_WHITE"Recording playback has been started: "C_TOMATO"PLAYER_RECORDING_TYPE_DRIVER");
        }
        else if(GetPlayerState(playerid) == PLAYER_STATE_ONFOOT)
        {
            StartRecordingPlayerData(playerid, PLAYER_RECORDING_TYPE_ONFOOT, params);
            SendClientMessage(playerid, COLOR_TOMATO, "[ ! ] "C_WHITE"Recording playback has been started: "C_TOMATO"PLAYER_RECORDING_TYPE_ONFOOT");
        }
        else
        {
            StartRecordingPlayerData(playerid, PLAYER_RECORDING_TYPE_NONE, params);
            SendClientMessage(playerid, COLOR_TOMATO, "[ ! ] "C_WHITE"Recording playback has been started: "C_TOMATO"PLAYER_RECORDING_TYPE_NONE");
        }

        new
            file_name_str[144];
        format(file_name_str, sizeof(file_name_str), "[ ! ] "C_WHITE"File name: %s", params);
        SendClientMessage(playerid, COLOR_TOMATO, file_name_str);
    }
    else if(!strcmp(option, "stop", true))
    {
        if(gPlayerRecording[playerid] == false)
        {
            SendClientMessage(playerid, COLOR_TOMATO, "You are not recording.");
            return 1;
        }

        StopRecordingPlayerData(playerid);
        gPlayerRecording[playerid] = false;

        SendClientMessage(playerid, COLOR_TOMATO, "[ ! ] "C_WHITE"Recording playback has been "C_TOMATO"stopped.");
    }
    else if(!strcmp(option, "load", true))
    {
        new
            file_name[32],
            vehicleid;

        if(sscanf(params, "s[32]I(-1)", file_name, vehicleid))
        {
            SendClientMessage(playerid, COLOR_TOMATO, "USAGE: /(rec)ord load [filename] [opt: vehicleid]");
            return 1;
        }

        if(strlen(file_name) >= 32)
        {
            SendClientMessage(playerid, COLOR_TOMATO, "Recording playback name must be below 32 characters.");
            return 1;
        }

        if(strfind(file_name, "/") != -1)
        {
            SendClientMessage(playerid, COLOR_TOMATO, "You can't add '/' to the filename.");
            return 1;
        }

        if(vehicleid != -1 && !IsValidVehicle(vehicleid))
        {
            SendClientMessage(playerid, COLOR_TOMATO, "That is an invalid vehicle!");
            return 1;
        }

        new
            file_full_name[128];
        
        format(file_full_name, sizeof(file_full_name), "%s.rec", file_name);
        if(!fexist(file_full_name))
        {
            SendClientMessage(playerid, COLOR_TOMATO, "You can't select an invalid recording file.");
            return 1;
        }

        new
            npc_name[MAX_PLAYER_NAME],
            npcid;

        format(npc_name, sizeof(npc_name), "NPC_%i", gLoadedNPCs);
        npcid = FCNPC_Create(npc_name);
        gLoadedNPCs ++;

        FCNPC_Spawn(npcid, GetPlayerSkin(playerid), 0.0, 0.0, 0.0);
        FCNPC_SetInvulnerable(npcid, true);
        if(vehicleid != -1)
        {
            FCNPC_PutInVehicle(npcid, vehicleid, 0);
        }
        
        FCNPC_SetPlayingPlaybackPath(npcid, "scriptfiles/");
        FCNPC_StartPlayingPlayback(npcid, file_name);
        format(gNPC_CurPlaybackFile[npcid], sizeof(gNPC_CurPlaybackFile[]), file_name);
        for(new i = GetPlayerPoolSize(); i >= 0; i --)
        {
            UpdatePlayerNPCLabel(i);
        }

        gNPCLoadingRecord[npcid] = true;

        format(file_full_name, sizeof(file_full_name), "[ ! ] "C_WHITE"NPC "C_TOMATO"%s"C_WHITE" is loading recording file "C_TOMATO"%s.rec", npc_name, file_name);
        SendClientMessage(playerid, COLOR_TOMATO, file_full_name);
    }
    else
    {
        SendClientMessage(playerid, COLOR_TOMATO, "Invalid parameters!");
    }
    return 1;
}

//
UpdatePlayerNPCLabel(playerid)
{
    if(
            !IsPlayerConnected(playerid)
        ||  !gPlayerNPCLabelShown[playerid])
    {
        return;
    }

    new
        string[128];

    for(new i = GetPlayerPoolSize(); i >= 0; i --)
    {
        if(IsValidDynamic3DTextLabel(gPlayerNPCLabel[playerid][i]))
        {
            DestroyDynamic3DTextLabel(gPlayerNPCLabel[playerid][i]);
            gPlayerNPCLabel[playerid][i] = Text3D:INVALID_STREAMER_ID;
        }

        if(!FCNPC_IsValid(i))
        {
            continue;
        }

        if(!isnull(gNPC_CurPlaybackFile[i]))
        {
            format(string, sizeof(string), "NPCID %i\nPlayback: %s.rec", i, gNPC_CurPlaybackFile[i]);
        }
        else
        {
            format(string, sizeof(string), "NPCID %i", i);
        }
        
        gPlayerNPCLabel[playerid][i] = CreateDynamic3DTextLabel(
            string, 
            COLOR_TOMATO, 
            0.0, 
            0.0, 
            0.0, 
            75.0, 
            i, 
            .playerid = playerid
        );
    }
}

//
CMD:npc(playerid, params[])
{
    new
        option[32];
    sscanf(params, "s[32]s[144]", option, params);

    if(isnull(option))
    {
        SendClientMessage(playerid, COLOR_TOMATO, "USAGE: /npc [option]");
        SendClientMessage(playerid, COLOR_TOMATO, "OPTION: "C_WHITE"dl, create, destroy, skin, anim,");
        SendClientMessage(playerid, COLOR_TOMATO, "OPTION: "C_WHITE"get, clearanim, weapon, startpb,");
        SendClientMessage(playerid, COLOR_TOMATO, "OPTION: "C_WHITE"stoppb, pausepb, resumepb");
        return 1;
    }

    if(!strcmp(option, "dl", true))
    {
        if(gPlayerNPCLabelShown[playerid])
        {
            gPlayerNPCLabelShown[playerid] = false;
            SendClientMessage(playerid, COLOR_TOMATO, "[ ! ] "C_WHITE"NPC dl has been disabled.");

            for(new i = GetPlayerPoolSize(); i >= 0; i--)
            {
                if(!FCNPC_IsValid(i))
                {
                    continue;
                }

                if(IsValidDynamic3DTextLabel(gPlayerNPCLabel[playerid][i]))
                {
                    DestroyDynamic3DTextLabel(gPlayerNPCLabel[playerid][i]);
                }
                gPlayerNPCLabel[playerid][i] = Text3D:INVALID_STREAMER_ID;
            }
        }
        else
        {
            gPlayerNPCLabelShown[playerid] = true;
            SendClientMessage(playerid, COLOR_TOMATO, "[ ! ] "C_WHITE"NPC dl has been enabled.");

            UpdatePlayerNPCLabel(playerid);
        }
    }
    else if(!strcmp(option, "create", true))
    {
        new
            skinid;

        if(sscanf(params, "i", skinid))
        {
            SendClientMessage(playerid, COLOR_TOMATO, "USAGE: /npc create [skin id]");
            return 1;
        }

        if(!IsValidSkin(skinid))
        {
            return SendClientMessage(playerid, COLOR_TOMATO, "That's an invalid skin index.");
        }

        new
            npc_name[MAX_PLAYER_NAME],
            npcid;

        format(npc_name, sizeof(npc_name), "NPC_%i", gLoadedNPCs);
        npcid = FCNPC_Create(npc_name);

        if(!FCNPC_IsValid(npcid))
        {
            SendClientMessage(playerid, COLOR_TOMATO, "There is an error led to NPC failed to create.");
            return 1;
        }
        gLoadedNPCs ++;
        FCNPC_SetInvulnerable(npcid, true);

        new
            Float:x,
            Float:y,
            Float:z,
            string[144];

        GetPlayerPos(playerid, x, y, z);
        FCNPC_Spawn(npcid, skinid, x, y, z);
        FCNPC_SetInterior(npcid, GetPlayerInterior(playerid));
        FCNPC_SetVirtualWorld(npcid, GetPlayerVirtualWorld(playerid));
        for(new i = GetPlayerPoolSize(); i >= 0; i --)
        {
            UpdatePlayerNPCLabel(i);
        }

        format(string, sizeof(string), "[ ! ] "C_WHITE"NPC ID %i (%s) has been created.", npcid, npc_name);
        SendClientMessage(playerid, COLOR_TOMATO, string);
    }
    else if(!strcmp(option, "destroy", true))
    {
        new
            npcid;

        if(sscanf(params, "i", npcid))
        {
            return SendClientMessage(playerid, COLOR_TOMATO, "USAGE: /npc destroy [npcid]");
        }

        if(!FCNPC_IsValid(npcid))
        {
            return SendClientMessage(playerid, COLOR_TOMATO,  "That's an invalid NPC index.");
        }

        if(gNPCLoadingRecord[npcid])
        {
            return SendClientMessage(playerid, COLOR_TOMATO, "You can't select NPC loaded from '/record'.");
        }

        FCNPC_Destroy(npcid);

        new
            string[144];
        format(string, sizeof(string), "[ ! ] "C_WHITE"NPC ID %i has been destroyed.", npcid);
        SendClientMessage(playerid,  COLOR_TOMATO, string);
    }
    else if(!strcmp(option, "startpb", true))
    {
        new
            npcid,
            file_name[32],
            loop[4],
            vehicleid;

        if(sscanf(params, "is[32]s[4]I(-1)", npcid, file_name, loop, vehicleid))
        {
            return SendClientMessage(playerid, COLOR_TOMATO, "USAGE: /npc startpb [npcid] [file_name] [loop: yes/no] [opt: vehicleid]");
        }

        if(!FCNPC_IsValid(npcid))
        {
            return SendClientMessage(playerid, COLOR_TOMATO,  "That's an invalid NPC index.");
        }

        if(gNPCLoadingRecord[npcid])
        {
            return SendClientMessage(playerid, COLOR_TOMATO, "You can't select NPC loaded from '/record'.");
        }

        if(strlen(file_name) >= 32)
        {
            SendClientMessage(playerid, COLOR_TOMATO, "Recording playback name must be below 32 characters.");
            return 1;
        }

        if(strfind(file_name, "/") != -1)
        {
            SendClientMessage(playerid, COLOR_TOMATO, "You can't add '/' to the filename.");
            return 1;
        }

        new
            bool:is_loop;

        if(!strcmp(loop, "yes", true))
        {
            is_loop = true;
        }
        else if(!strcmp(loop, "no", true))
        {
            is_loop = false;
        }
        else
        {
            return SendClientMessage(playerid, COLOR_TOMATO, "You can only put the loop to 'yes' or 'no'.");
        }

        if(vehicleid != -1 && !IsValidVehicle(vehicleid))
        {
            SendClientMessage(playerid, COLOR_TOMATO, "That is an invalid vehicle!");
            return 1;
        }

        if(vehicleid != -1)
        {
            FCNPC_PutInVehicle(npcid, vehicleid, 0);
        }
        FCNPC_SetPlayingPlaybackPath(npcid, "scriptfiles/");
        FCNPC_StartPlayingPlayback(npcid, file_name);
        format(gNPC_CurPlaybackFile[npcid], sizeof(gNPC_CurPlaybackFile[]), file_name);
        for(new i = GetPlayerPoolSize(); i >= 0; i --)
        {
            UpdatePlayerNPCLabel(i);
        }
        gNPCStartingPlayback[npcid] = true;
        gNPCStartingPlaybackLoop[npcid] = is_loop;

        new
            string[144];
        format(string, sizeof(string), "[ ! ] %s.rec "C_WHITE"has been applied to NPC ID %i. Loop: "C_TOMATO"%s", file_name, npcid, is_loop ? "Yes" : "No");
        SendClientMessage(playerid, COLOR_TOMATO, string);
    }
    else if(!strcmp(option, "stoppb", true))
    {
        new
            npcid;

        if(sscanf(params, "i", npcid))
        {
            return SendClientMessage(playerid, COLOR_TOMATO, "USAGE: /npc stoppb [npcid]");
        }

        if(!FCNPC_IsValid(npcid))
        {
            return SendClientMessage(playerid, COLOR_TOMATO,  "That's an invalid NPC index.");
        }

        if(gNPCLoadingRecord[npcid])
        {
            return SendClientMessage(playerid, COLOR_TOMATO, "You can't select NPC loaded from '/record'.");
        }

        if(!gNPCStartingPlayback[npcid])
        {
            return SendClientMessage(playerid, COLOR_TOMATO, "That NPC was not starting any playback.");
        }

        new
            string[144];
        format(string, sizeof(string), "[ ! ] "C_WHITE"NPC ID %i has been stopped from playing "C_TOMATO"%s.rec", npcid, gNPC_CurPlaybackFile[npcid]);
        SendClientMessage(playerid, COLOR_TOMATO, string);

        FCNPC_PausePlayingPlayback(npcid);
        FCNPC_StopPlayingPlayback(npcid);
        gNPCStartingPlayback[npcid] = false;
        gNPC_CurPlaybackFile[npcid][0] = EOS;

        for(new i = GetPlayerPoolSize(); i >= 0; i --)
        {
            UpdatePlayerNPCLabel(i);
        }
    }
    else if(!strcmp(option, "pausepb", true))
    {
        new
            npcid;

        if(sscanf(params, "i", npcid))
        {
            return SendClientMessage(playerid, COLOR_TOMATO, "USAGE: /npc pausepb [npcid]");
        }

        if(!FCNPC_IsValid(npcid))
        {
            return SendClientMessage(playerid, COLOR_TOMATO,  "That's an invalid NPC index.");
        }

        if(gNPCLoadingRecord[npcid])
        {
            return SendClientMessage(playerid, COLOR_TOMATO, "You can't select NPC loaded from '/record'.");
        }

        if(!gNPCStartingPlayback[npcid])
        {
            return SendClientMessage(playerid, COLOR_TOMATO, "That NPC was not starting any playback.");
        }

        FCNPC_PausePlayingPlayback(npcid);

        new
            string[144];
        format(string, sizeof(string), "[ ! ] "C_WHITE"NPC ID %i has been paused from playing "C_TOMATO"%s.rec", npcid, gNPC_CurPlaybackFile[npcid]);
        SendClientMessage(playerid, COLOR_TOMATO, string);
    }
    else if(!strcmp(option, "resumepb", true))
    {
        new
            npcid;

        if(sscanf(params, "i", npcid))
        {
            return SendClientMessage(playerid, COLOR_TOMATO, "USAGE: /npc resumepb [npcid]");
        }

        if(!FCNPC_IsValid(npcid))
        {
            return SendClientMessage(playerid, COLOR_TOMATO,  "That's an invalid NPC index.");
        }

        if(gNPCLoadingRecord[npcid])
        {
            return SendClientMessage(playerid, COLOR_TOMATO, "You can't select NPC loaded from '/record'.");
        }

        if(!gNPCStartingPlayback[npcid])
        {
            return SendClientMessage(playerid, COLOR_TOMATO, "That NPC was not starting any playback.");
        }

        FCNPC_ResumePlayingPlayback(npcid);

        new
            string[144];
        format(string, sizeof(string), "[ ! ] "C_WHITE"NPC ID %i has been resumed playing "C_TOMATO"%s.rec", npcid, gNPC_CurPlaybackFile[npcid]);
        SendClientMessage(playerid, COLOR_TOMATO, string);
    }
    else if(!strcmp(option, "anim", true))
    {
        new
            npcid,
            animlib[32],
            animname[32],
            Float:fDelta,
            loop,
            lockx, 
            locky,
            freeze,
            time;

        if(sscanf(params, "is[32]s[32]fiiiii", npcid, animlib, animname, fDelta, loop, lockx, locky, freeze, time))
        {
            return SendClientMessage(playerid, COLOR_TOMATO, "USAGE: /npc anim [npcid] [animlib] [animname] [fDelta (4.0)] [loop] [lockx] [locky] [freeze] [time]");
        }

        if(!FCNPC_IsValid(npcid))
        {
            return SendClientMessage(playerid, COLOR_TOMATO,  "That's an invalid NPC index.");
        }

        if(gNPCLoadingRecord[npcid])
        {
            return SendClientMessage(playerid, COLOR_TOMATO, "You can't select NPC loaded from '/record'.");
        }

        FCNPC_ApplyAnimation(
            npcid, 
            animlib, 
            animname, 
            fDelta, 
            loop, 
            lockx, 
            locky, 
            freeze, 
            time);

        new
            string[144];
        format(string, sizeof(string), "[ ! ] "C_WHITE"Animation (%s, %s, %.1f, %i, %i, %i, %i, %i) applied to NPC ID %i.", animlib, animname, fDelta, loop, lockx, locky, freeze, time, npcid);
        SendClientMessage(playerid, COLOR_TOMATO, string);
    }
    else if(!strcmp(option, "clearanim", true))
    {
        new
            npcid;

        if(sscanf(params, "i", npcid))
        {
            return SendClientMessage(playerid, COLOR_TOMATO, "USAGE: /npc clearanim [npcid]");
        }

        if(!FCNPC_IsValid(npcid))
        {
            return SendClientMessage(playerid, COLOR_TOMATO,  "That's an invalid NPC index.");
        }

        if(gNPCLoadingRecord[npcid])
        {
            return SendClientMessage(playerid, COLOR_TOMATO, "You can't select NPC loaded from '/record'.");
        }

        FCNPC_ApplyAnimation(npcid, "CARRY", "crry_prtial", 4.0, 0, 1, 1, 0, 0);

        new
            string[144];

        format(string, sizeof(string), "[ ! ] "C_WHITE"Animation cleared for NPC ID %i.", npcid);
        SendClientMessage(playerid, COLOR_TOMATO, string);
    }
    else if(!strcmp(option, "skin", true))
    {
        new
            npcid,
            skinid;

        if(sscanf(params, "ii", npcid, skinid))
        {
            return SendClientMessage(playerid, COLOR_TOMATO, "USAGE: /npc skin [npcid] [skinid]");
        }

        if(!FCNPC_IsValid(npcid))
        {
            return SendClientMessage(playerid, COLOR_TOMATO,  "That's an invalid NPC index.");
        }

        if(gNPCLoadingRecord[npcid])
        {
            return SendClientMessage(playerid, COLOR_TOMATO, "You can't select NPC loaded from '/record'.");
        }

        if(!IsValidSkin(skinid))
        {
            return SendClientMessage(playerid, COLOR_TOMATO, "You can't select an invalid skin index.");
        }

        FCNPC_SetSkin(npcid, skinid);

        new
            string[144];

        format(string, sizeof(string), "[ ! ] "C_WHITE"NPC ID %i skin has been changed to ID %i.", npcid, skinid);
        SendClientMessage(playerid, COLOR_TOMATO, string);
    }
    else if(!strcmp(option, "weapon", true))
    {
        new
            npcid,
            weaponid;

        if(sscanf(params, "ik<weapon>", npcid, weaponid))
        {
            return SendClientMessage(playerid, COLOR_TOMATO, "USAGE: /npc weapon [npcid] [weaponid/weapon name]");
        }

        if(!FCNPC_IsValid(npcid))
        {
            return SendClientMessage(playerid, COLOR_TOMATO,  "That's an invalid NPC index.");
        }

        if(gNPCLoadingRecord[npcid])
        {
            return SendClientMessage(playerid, COLOR_TOMATO, "You can't select NPC loaded from '/record'.");
        }

        if(weaponid == -1)
        {
            return SendClientMessage(playerid, COLOR_TOMATO, "You can't select an invalid weapon index.");
        }

        FCNPC_SetWeapon(npcid, weaponid);

        new
            string[144];

        format(string, sizeof(string), "[ ! ] "C_WHITE"NPC ID %i weapon has been set to %W.", npcid, weaponid);
        SendClientMessage(playerid, COLOR_TOMATO, string);
    }
    else if(!strcmp(option, "get", true))
    {
        new
            npcid;

        if(sscanf(params, "i", npcid))
        {
            return SendClientMessage(playerid, COLOR_TOMATO, "USAGE: /npc get [npcid]");
        }

        if(!FCNPC_IsValid(npcid))
        {
            return SendClientMessage(playerid, COLOR_TOMATO,  "That's an invalid NPC index.");
        }

        if(gNPCLoadingRecord[npcid])
        {
            return SendClientMessage(playerid, COLOR_TOMATO, "You can't select NPC loaded from '/record'.");
        }

        new
            Float:x,
            Float:y,
            Float:z;

        GetPlayerPos(playerid, x, y, z);
        FCNPC_SetPosition(npcid, x, y, z);
        FCNPC_SetInterior(npcid, GetPlayerInterior(playerid));
        FCNPC_SetVirtualWorld(npcid, GetPlayerVirtualWorld(playerid));

        new
            string[144];

        format(string, sizeof(string), "[ ! ] "C_TOMATO"You have teleported NPC ID %i to you.", npcid);
        SendClientMessage(playerid, COLOR_TOMATO, string);
    }
    else
    {
        SendClientMessage(playerid, COLOR_TOMATO, "Invalid parameters!");
    }
    return 1;
}

//
CMD:anim(playerid, const params[])
{
    new
        animlib[32],
        animname[32],
        Float:fDelta,
        loop,
        lockx,
        locky,
        freeze,
        time;

    if(sscanf(params, "s[32]s[32]fiiiii", animlib, animname, fDelta, loop, lockx, locky, freeze, time))
    {
        return SendClientMessage(playerid, COLOR_TOMATO, "USAGE: /anim [library] [name] [delta (4.0)] [loop] [lockx] [locky] [freeze] [time]");
    }

    ApplyAnimation(
        playerid, 
        animlib, 
        animname, 
        fDelta, 
        loop, 
        lockx, 
        locky, 
        freeze, 
        time, 
        1);

    new
        string[144];

    format(string, sizeof(string), "You have applied an animation: "C_TOMATO"%s, %s, %.1f, %i, %i, %i, %i, %i",
        animlib,
        animname,
        fDelta,
        loop,
        lockx,
        locky,
        freeze,
        time);
    SendClientMessage(playerid, COLOR_WHITE, string);

    return 1;
}