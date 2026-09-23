--19.lua--师门任务 id=19
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

thisId = 19
NPCName = nil
local OPEN_LV = 29 --师门任务
SHI_MEN_NUM = 10 

------------------------------------------
--以下为脚本部分：
------------------------------------------
function NpcMain(pUser,missionId)
	if NPCName == nil then
		NPCName = j.GetNpcName(thisId)
	end
	local lv = pUser:GetLevel()

	if lv < OPEN_LV then
		Dialog(pUser,NPCName,LANGUAGE_TRANSFORM_2032)
		return
	end
	if not pUser:HaveCMission(MISSION_ID_SHIMEN) then
		local turn=pUser:GetSaveVal(2)
		if turn >= SHI_MEN_NUM then
			Dialog(pUser,NPCName,LANGUAGE_TRANSFORM_1988)
			return
		end

		Option(pUser,NPCName,LANGUAGE_SSJ_0118,LANGUAGE_SSJ_0119)
		pUser:SetCallFun("SelectOpt")
	else
		if pUser:IsCMissionFinished(MISSION_ID_SHIMEN) then
			Option(pUser,NPCName,LANGUAGE_SSJ_0120,LANGUAGE_SSJ_0121)
			pUser:SetCallFun("SelectOpt")
		else
			Dialog(pUser,NPCName,LANGUAGE_SSJ_0122)
		end
	end
end

function SelectOpt(pUser,sel)
	if sel == 1 then	-- 接任务
		AcceptShiMen(pUser)
	elseif sel == 2 then	-- 完成任务
		if pUser:IsCMissionFinished(MISSION_ID_SHIMEN) then
			FinishShiMen(pUser)
		else
			Dialog(pUser,NPCName,LANGUAGE_SSJ_0122)
		end
	end
end


function GetState(pUser)
	local userlv = pUser:GetLevel()
	if userlv < OPEN_LV then
		return 0
	end
    if not pUser:HaveCMission(MISSION_ID_SHIMEN) then
        return 1  -- 可接
	else
        if pUser:IsCMissionFinished(MISSION_ID_SHIMEN) then
            return 3 -- 完成
        else
            return 2 -- 未完成
		end
    end
	return 0 
end
