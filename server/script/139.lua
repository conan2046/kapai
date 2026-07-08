--139.lua--师门叛徒
---------------------------------------
require "global"
Dialog = j.Dialog       --对话
Option =j.Option        --对话选项
SMessage = j.SMessage   --弹出提示

thisId = 139

function NpcMain(pUser,missionId)
	if not pUser:HaveCMission(MISSION_ID_SHIMEN) then
		Dialog(pUser,LANGUAGE_TRANSFORM_1870,LANGUAGE_TRANSFORM_1871)
		j.DelNpc(pUser,thisId)
		return
	end
	
	j.ShiMenFight(pUser)
	pUser:SetCallFun("BattleOver")
end

function BattleOver(pUser,state)
	if state==0 then
		BattleWin(pUser)
	elseif state==1 then
		j.CloseInteract(pUser)
	else
		j.CloseInteract(pUser)
	end
end

function BattleWin(pUser)
	if pUser:HaveCMission(MISSION_ID_SHIMEN) then
		pUser:UpdateCMissionState(MISSION_ID_SHIMEN,1)
		FinishShiMen(pUser, true)
		return
	end
end

function GetState(pUser)
	local s 
	local id
	local t
	local lv=pUser:GetLevel()
	
	return 0
end

function GetChatMsg(pUser)
	return NPC_HEAD_NONE
end
