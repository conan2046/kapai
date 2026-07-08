--250.lua--跨服历练 id=250
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

thisId = 250
NPCName = LANGUAGE_TRANSFORM_4849
------------------------------------------
--以下为脚本部分：
------------------------------------------
function NpcMain(pUser,missionId)
	local lv = pUser:GetLevel()
	if lv < j.GetFuncOpenLevel(38) then
		Dialog(pUser,NPCName,LANGUAGE_ZQX_0032)
		return
	end
	if not pUser:HaveCMission(MISSION_ID_KUAFULILIAN) then
		if pUser:GetExtData8(KUAFULILIAN_DATA8) >= KUAFULILIAN_MAX_CNT then
			Dialog(pUser,NPCName,LANGUAGE_ZQX_0033)
			return
		end

		Option(pUser, NPCName, LANGUAGE_ZQX_0032, LANGUAGE_ZQX_0034)
		pUser:SetCallFun("SelectOpt")
	else
		if pUser:IsCMissionFinished(MISSION_ID_KUAFULILIAN) then
			Option(pUser, NPCName, LANGUAGE_ZQX_0036, LANGUAGE_ZQX_0035)
			pUser:SetCallFun("SelectOpt")
		else
			Dialog(pUser,NPCName,LANGUAGE_ZQX_0037)
		end
	end
end

function SelectOpt(pUser,sel)
	if sel == 1 then	-- 接任务
		AcceptKuaFuShiLian(pUser)
	elseif sel == 2 then	-- 完成任务
		if pUser:IsCMissionFinished(MISSION_ID_KUAFULILIAN) then
			FinishKuaFuShiLian(pUser, false)
		else
			Dialog(pUser,NPCName,LANGUAGE_ZQX_0037)
		end
	end
end

function KuaFuShiLianFinish(pUser, inBattle)
	local battle = false
	if inBattle == 1 then
		battle = true
	end
	FinishKuaFuShiLian(pUser, battle)
end

function GetState(pUser)
	local userlv = pUser:GetLevel()
	if userlv < j.GetFuncOpenLevel(38) then
		return 0
	end

    if not pUser:HaveCMission(MISSION_ID_KUAFULILIAN) then
    	if pUser:GetExtData8(KUAFULILIAN_DATA8) < KUAFULILIAN_MAX_CNT then
	        return 1  -- 可接
        end
	else
        if pUser:IsCMissionFinished(MISSION_ID_KUAFULILIAN) then
            return 3 -- 完成
        else
            return 2 -- 未完成
		end
    end
	return 0 
end