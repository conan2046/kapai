--231.lua--跨服鬼 id=231
---------------------------------------
require "global"

Dialog = j.Dialog       --对话
Option =j.Option        --对话选项
SMessage = j.SMessage   --弹出提示
CloseInteract = j.CloseInteract --结束交互
MissionBanner = j.MissionBanner --新版任务面板接取模式
Dialog_End = j.Dialog_End
SMessage_End = j.SMessage_End

thisId = 231
NPCName = nil

function NpcMain(pUser,missionId)
	if NPCName == nil then
		NPCName = j.GetNpcName(thisId)
	end
	if j.InKuaFu() then
		j.KuaFuZhuoGuiFight(pUser)
		CloseInteract(pUser)
	end
end

function GetState(pUser)
	return 0
end

function GetChatMsg(pUser)
	return NPC_HEAD_NONE
end

