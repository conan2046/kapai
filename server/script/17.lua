--17.lua--杂货店老板 id=17
---------------------------------------
require "global"

Dialog = j.Dialog       --对话
DialogS_Start = j.DialogS_Start --剧情对话开始 
DialogS_Doing = j.DialogS_Doing --剧情对话过程 
DialogS_End = j.DialogS_End --剧情对话结束 
Option =j.Option        --对话选项
SMessage = j.SMessage   --弹出提示
MissionBanner = j.MissionBanner --新版任务面板接取模式
CloseInteract = j.CloseInteract --结束交互
Dialog_End = j.Dialog_End
ShowGuidance = j.ShowGuidance

thisId =17
NPCName = nil

------------------------------------------
--以下为脚本部分：
------------------------------------------
function NpcMain(pUser,missionId)
	if NPCName == nil then
		NPCName = j.GetNpcName(thisId)
	end
	if HaveLetter(pUser,NPCName,thisId, missionId) then
		return
	end

	local num = 0
	local opt = ""
	if num == 0 then
		Dialog_End(pUser,LANGUAGE_TRANSFORM_704,LANGUAGE_TRANSFORM_705)
	elseif num == 1 then
		t = FormatMission(opt)
		ChooseOption(pUser,tonumber(t[1]))
	else
		Option(pUser,LANGUAGE_TRANSFORM_706,LANGUAGE_TRANSFORM_707,opt)
		pUser:SetCallFun("ChooseOption")
	end
end

function GetState(pUser)
	return 0
end

function GetChatMsg(pUser)
	return NPC_HEAD_NONE
end

