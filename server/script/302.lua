-- 302 挖宝使用
---------------------------------------
require "global"
Dialog = j.Dialog       --对话
Option =j.Option        --对话选项
SMessage = j.SMessage   --弹出提示

thisId = 302

function NpcMain(pUser,missionId)
	local itemid = pUser:GetCangBaotuId()
	if itemid == nil or itemid == 0 then
		if not pUser:HaveCMission(MISSION_ID_XUNBAO) then
			Dialog(pUser,LANGUAGE_SSJ_0131,LANGUAGE_SSJ_0132)
			j.DelNpc(pUser, thisId)
			return
		end
	end 
	
	j.WabaoFight(pUser)  -- TODO 
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
	FinishWaBao(pUser,thisId)
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
