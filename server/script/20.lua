--20.lua--钱庄老板
---------------------------------------
require "global"

Dialog = j.Dialog       --对话 
DialogS_Start = j.DialogS_Start --剧情对话开始 
DialogS_Doing = j.DialogS_Doing --剧情对话过程 
DialogS_End = j.DialogS_End --剧情对话结束 
ShowGuidance = j.ShowGuidance --任务引导
Option =j.Option        --对话选项
SMessage = j.SMessage   --弹出提示
CloseInteract = j.CloseInteract --结束交互
MissionBanner = j.MissionBanner --新版任务面板接取模式
Dialog_End = j.Dialog_End

thisId = 20
NPCName = nil

------------------------------------------
--以下为脚本部分：
------------------------------------------
function NpcMain(pUser,missionId)
	if NPCName == nil then
		NPCName = j.GetNpcName(thisId)
	end

end

function GetState(pUser)
	return 0
end

function GetChatMsg(pUser)
	return NPC_HEAD_NONE
end
