--225-- 225.lua --圣诞宝箱
require "global"
-------------------------
Dialog = j.Dialog       --对话
DialogS_Start = j.DialogS_Start --剧情对话开始
DialogS_Doing = j.DialogS_Doing --剧情对话过程
DialogS_End = j.DialogS_End --剧情对话结束
ShowGuidance = j.ShowGuidance --任务引导
Option =j.Option        --对话选项
SMessage = j.SMessage   --弹出提示
SMessage_End = j.SMessage_End
Dialog_End = j.Dialog_End
CloseInteract=j.CloseInteract
TransportUser=j.TransportUser
MissionBanner = j.MissionBanner --新版任务面板接取模式

NPCID = 225

function NpcMain(pUser,missionId,index)
	j.StartToFight(pUser,NPCID,index,1);
end


function CollectCall(pUser,index)
	j.StartToFight(pUser,NPCID,index,2);	
end


function GetNpcPos(state)
	return 0
end


function GetState(pUser)
	return 0
end

function GetChatMsg(pUser)
	return NPC_HEAD_NONE    
end
