--5.lua--酒楼老板
---------------------------------------
require "global"

Dialog = j.Dialog       --对话
DialogS_Start = j.DialogS_Start --剧情对话开始 
DialogS_Doing = j.DialogS_Doing --剧情对话过程 
DialogS_End = j.DialogS_End --剧情对话结束
Option =j.Option        --对话选项
SMessage = j.SMessage   --弹出提示
SendSysInfo = j.SendSysInfo --Tips
Dialog_End = j.Dialog_End
SMessage_End = j.SMessage_End
CloseInteract = j.CloseInteract --结束交互
MissionBanner = j.MissionBanner --新版任务面板接取模式

thisId = 5
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

	Dialog_End(pUser,LANGUAGE_TRANSFORM_1368,LANGUAGE_TRANSFORM_1369)
	
--[[
	local num = 0
	local opt = ""
	if num == 0 then
		if j.InHuoDongTime(80) then
			opt = LANGUAGE_ZDL_0001
			Option(pUser,NPCName,LANGUAGE_ZDL_0002,opt)
			pUser:SetCallFun("ChooseOption")
		else
			Dialog_End(pUser,LANGUAGE_TRANSFORM_1368,LANGUAGE_TRANSFORM_1369)
		end
	elseif num == 1 then
		t = FormatMission(opt)
		ChooseOption(pUser,tonumber(t[1]))
	else
		Option(pUser,LANGUAGE_TRANSFORM_1370,LANGUAGE_TRANSFORM_1371,opt)
		pUser:SetCallFun("ChooseOption")
	end
--]]
end

function ChooseOption(pUser,sel)
	if sel == 82 then
		j.ShowTaoHuaGengPanel(pUser)
	end
end

function GetState(pUser)
	return 0
end

function GetChatMsg(pUser)
	return NPC_HEAD_NONE
end
