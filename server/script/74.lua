--74.lua--准提道人 id=74
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

thisId = 74
NPCName = nil

------------------------------------------
function NpcMain(pUser,missionId)
	if NPCName == nil then
		NPCName = j.GetNpcName(thisId)
	end
	if pUser:HaveCMission(MISSION_ID_HUSONG) then
		Option(pUser,NPCName,LANGUAGE_TRANSFORM_282,LANGUAGE_TRANSFORM_283)
		pUser:SetCallFun("FinishHuSongTask")
	else
		Dialog(pUser,NPCName,LANGUAGE_TRANSFORM_285)
	end
end

function FinishHuSongTask(pUser, sel)
	if sel == 1 then
		local s = j.GetCMissionInts(pUser, MISSION_ID_HUSONG)
		if s ~= nil then
			local t = FormatMission(s)
			pUser:AddExpByItemWithTips(tonumber(t[2])-tonumber(t[3]))
			pUser:SetExtData8(81, pUser:GetExtData8(81)+1)
			pUser:DelCMission(MISSION_ID_HUSONG)
			j.UpdateUserInfo(pUser,15)
			pUser:ClearBitSet(156)
			pUser:ClearBitSet(157)
			j.SendSysInfo(pUser,LANGUAGE_TRANSFORM_286..t[5]..LANGUAGE_TRANSFORM_287)

			if pUser:GetExtData8(81) < 5 then
				j.ShowHuSongShenShouNextTaskPanel(pUser)
			else
				-- 11-1891-842-23
				j.SendYinDaoNPCPos(pUser, 11,1891 ,842, 23)
			end
			j.UpdateHuSongTaskState(pUser)
--			pUser:RecoveryAllHp()
			
			-- 上坐骑，上跟随宠
			j.SetGenSuiPetUp(pUser)
			j.SetQiPetUp(pUser)
			j.HD_DropExchangeItem(pUser,16)
			j.HD_DropHDItem(pUser,16)
			j.UpdateDCMissionComplate(pUser, MISSION_ID_DC_59, 1, MISSION_ID_HUSONG)
		else
			j.SendSysInfo(pUser,LANGUAGE_TRANSFORM_288)
		end
	end
end

function GetState(pUser)
    if pUser:IsCMissionFinished(MISSION_ID_HUSONG) then
        return 3 -- 完成
	end
	return 0  -- 此NPC默认没有任务状态
end

function GetChatMsg(pUser)
	if InOriginalScene(pUser) then
		return NPC_HEAD_HUSONG
	else
		return NPC_HEAD_NONE
	end
end


