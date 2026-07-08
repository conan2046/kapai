--517.lua--闻仲 id=517
---------------------------------------
require "global"

Dialog = j.Dialog       --对话
Option =j.Option        --对话选项
SMessage = j.SMessage   --弹出提示
CloseInteract = j.CloseInteract --结束交互
MissionBanner = j.MissionBanner --新版任务面板接取模式
Dialog_End = j.Dialog_End       
SMessage_End = j.SMessage_End  

npcId = 517
NPCName = nil

------------------------------------------
--以下为脚本部分：
------------------------------------------
ZHOU_RICHANG_TURN = 7 

function NpcMain(pUser,missionId)
	if NPCName == nil then
		NPCName = j.GetNpcName(npcId)
	end
	local lv = pUser:GetLevel()
	
	if lv < j.GetCMissionAcceptLevel(MISSION_ID_ZHOUSHIMEN) then
		Dialog(pUser,NPCName,LANGUAGE_TRANSFORM_2032)
		return
	end

	if not pUser:HaveCMission(MISSION_ID_ZHOUSHIMEN) then
		local turn=pUser:GetExtData8(619)
		if turn >= ZHOU_RICHANG_TURN then
			Dialog(pUser,NPCName,LANGUAGE_ZQX_0028)
			return
		end

		Option(pUser,NPCName,LANGUAGE_ZQX_0020,LANGUAGE_ZQX_0021)
		pUser:SetCallFun("SelectOpt")
	else
		if pUser:IsCMissionFinished(MISSION_ID_ZHOUSHIMEN) then
			Option(pUser,NPCName,LANGUAGE_ZQX_0022,LANGUAGE_ZQX_0023)
			pUser:SetCallFun("SelectOpt")
		else
			Dialog(pUser,NPCName,LANGUAGE_ZQX_0024)
		end
	end
end

function SelectOpt(pUser,sel)
	if sel == 1 then	-- 接任务
		AcceptZhouShiMen(pUser)
	elseif sel == 2 then	-- 完成任务
		if pUser:IsCMissionFinished(MISSION_ID_ZHOUSHIMEN) then
			FinishZhouShiMen(pUser)
		else
			Dialog(pUser,NPCName,LANGUAGE_ZQX_0023)
		end
	end
end


