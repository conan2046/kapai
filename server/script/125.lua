--125.lua--鲜花 id=125
---------------------------------------
require "global"

Dialog = j.Dialog       --对话
Option =j.Option        --对话选项
SMessage = j.SMessage   --弹出提示
CloseInteract = j.CloseInteract --结束交互
MissionBanner = j.MissionBanner --新版任务面板接取模式
Dialog_End = j.Dialog_End       
SMessage_End = j.SMessage_End   
ShowGuidance = j.ShowGuidance --任务引导 

------------------------------------------
--以下为脚本部分：
------------------------------------------

thisId = 125

function NpcMain(pUser, missionId, index)
	if pUser:HaveCMission(MISSION_ID_DANYUAN) then
		local mission = j.GetCMissionInts(pUser, MISSION_ID_DANYUAN)
		if not mission or mission == "" then 
			return
		end 

		local t = FormatMission(mission)
		if tonumber(t[1]) == 2 and tonumber(t[3]) == thisId then
			j.Collect(pUser, thisId, index,1,1,LANGUAGE_SSJ_0115)
			pUser:SetCallFun("CollectOver103")
			return
		end
	end
	Dialog(pUser,LANGUAGE_TRANSFORM_248,LANGUAGE_TRANSFORM_249)
end

-- ---------------------------------------
-- 丹园的采集任务
function CollectOver103(pUser,npcIdx)
	local mission = j.GetCMissionInts(pUser, MISSION_ID_DANYUAN)
	if not mission or mission == "" then 
		return
	end 

	local t = FormatMission(mission)
	if tonumber(t[1]) == 2 and tonumber(t[3]) == thisId then
		t[5] = tonumber(t[5]) + 1
		pUser:DelCollect(thisId,npcIdx,tonumber(t[2]))
		if tonumber(t[5]) >= tonumber(t[4]) then	-- 完成
			-- 1 完成 0 可接 2领奖
			pUser:UpdateCMission(MISSION_ID_DANYUAN, table.concat(t,"|"), "")
			pUser:UpdateCMissionState(MISSION_ID_DANYUAN, 1 ) -- 任务完成
			-- j.SendYinDaoNPCPos(pUser,11,-1,-1,106)
			--OnDanYuanCollectFinish(pUser)
			DanYuanMissionFinish(pUser, false)
		else
			pUser:UpdateCMission(MISSION_ID_DANYUAN, table.concat(t,"|"), "")
			j.SendYinDaoNPCPos(pUser,tonumber(t[2]),-1,-1,thisId)
		end
	end
end

function GetState(pUser)
	local s 


	return 0
end

function GetChatMsg(pUser)
	return NPC_HEAD_NONE
end
