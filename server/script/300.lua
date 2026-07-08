-- 护宝小妖  300 护宝任务使用
---------------------------------------
require "global"
Dialog = j.Dialog       --对话
Option =j.Option        --对话选项
SMessage = j.SMessage   --弹出提示

thisId = 300

function NpcMain(pUser, missionId)
	if not pUser:HaveCMission(MISSION_ID_XUNBAO) then
		Dialog(pUser,LANGUAGE_SSJ_0131,LANGUAGE_SSJ_0132)
		j.DelNpc(pUser, thisId)
		return
	end

	j.WabaoFight(pUser)
	pUser:SetCallFun("BattleOver")
end

function BattleOver(pUser,state)
	if state==0 then
		WbMissionFightCallBack(pUser, thisId)
	elseif state==1 then
		j.CloseInteract(pUser)
	else
		j.CloseInteract(pUser)
	end
end

function GetState(pUser)

	return 0 
end

function GetChatMsg(pUser)
	return NPC_HEAD_NONE
end
