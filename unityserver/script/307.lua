-- 挖宝道人 脚本
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

local npcId = 307
local NPCName = nil

------------------------------------------
--以下为脚本部分：
------------------------------------------
function NpcMain(pUser, missionId)
	if NPCName == nil then
		NPCName = j.GetNpcName(npcId)
	end
	local lv = pUser:GetLevel()
	if lv < j.GetCMissionAcceptLevel(MISSION_ID_XUNBAO) then
		Dialog(pUser, NPCName, LANGUAGE_SSJ_0125)
		return
	end

	if pUser:HaveCMission(MISSION_ID_XUNBAO) then
		Dialog(pUser, NPCName, LANGUAGE_SSJ_0130)
	else
		if pUser:GetExtData32(444) >= _DailyWBMax  then
			Dialog(pUser, NPCName, LANGUAGE_SSJ_0133)
			pUser:NotifyUserShowCangBaoTuPanel()
			return
		end
		Option(pUser, NPCName, LANGUAGE_SSJ_0126, LANGUAGE_SSJ_0127)
		pUser:SetCallFun("SelectOpt")
	end
end

function SelectOpt(pUser, sel)
	if sel == 1 then
		AcceptWaBao(pUser, sel)
		j.UpdateNpcState(pUser, npcId, 2)
	end
--[[
	elseif sel == 2 then
		if pUser:IsCMissionFinished(MISSION_ID_XUNBAO) then
			FinishWaBao(pUser)
		else
			Dialog(pUser, NPCName, LANGUAGE_SSJ_0122)
		end
	end
--]]
end


function GetState(pUser)
	if not pUser:HaveCMission(MISSION_ID_XUNBAO) then
		if pUser:GetLevel() >= j.GetCMissionAcceptLevel(MISSION_ID_XUNBAO) then
			if pUser:GetExtData32(444) < _DailyWBMax then
				return 1  -- 可接
			end
		end
	end
	return 0
end

function ClearData(pUser)
	pUser:DelCMission(MISSION_ID_XUNBAO) 
	pUser:SetExtData32(444,0)
	pUser:SetExtData32(445,0)
	pUser:SetCangBaotuId(0)
	pUser:SetExtData32(445 , 0)
end 







