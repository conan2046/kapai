--255.lua--跨服心魔
---------------------------------------
require "global"
Dialog = j.Dialog       --对话
Option =j.Option        --对话选项
SMessage = j.SMessage   --弹出提示

thisId = 255

function NpcMain(pUser,missionId)
	if not pUser:HaveCMission(MISSION_ID_KUAFULILIAN) then
		Dialog(pUser,LANGUAGE_TRANSFORM_1870,LANGUAGE_TRANSFORM_1871)
		j.DelNpc(pUser,thisId)
		return
	end
	
	j.ShiLianXinMoFight(pUser)
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
	if pUser:HaveCMission(MISSION_ID_KUAFULILIAN) then
		pUser:UpdateCMissionState(MISSION_ID_KUAFULILIAN,1)
		j.DelNpc(pUser,thisId)
		pUser:SetExtData32(463, 0)
		FinishKuaFuShiLian(pUser, true)
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
