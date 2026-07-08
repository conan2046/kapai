--241.lua 河洛守卫
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
SMessage_End = j.SMessage_End

thisId = 241

------------------------------------------
--以下为脚本部分：
------------------------------------------
function NpcMain(pUser,missionId,index)
	pUser:SetVal(1,index)

	Option(pUser,LANGUAGE_TRANSFORM_2015,LANGUAGE_TRANSFORM_2016..index..LANGUAGE_TRANSFORM_2017,LANGUAGE_TRANSFORM_2018)
	pUser:SetCallFun("UserChoose")
end

function UserChoose(pUser,sel)
	local index = pUser:GetVal(1)
	local floor = pUser:GetExtData8(136)
	if sel == 5 and index == floor+1 then
		-- 战斗
		j.ShiLianFight(pUser,floor,1)
--		pUser:SetCallFun("ShowWeiFightCall")
	end
end

function ShowWeiFightCall(pUser,state)
	local index = pUser:GetVal(1)
	if state == 0 then	-- 胜利
		j.DelDynamicNpcWithIndex(pUser,thisId,index)
		ShiLianAddBoxNpc(pUser)
		pUser:SetExtData8(136,index)
	end
end

function GetState(pUser)
	return 0
end

function GetChatMsg(pUser)
	return NPC_HEAD_NONE
end

