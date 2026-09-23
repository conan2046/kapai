-- 106 大师兄
---------------------------------------
require "global"

local Dialog = j.Dialog       --对话 
local DialogS_Start = j.DialogS_Start --剧情对话开始 
local DialogS_Doing = j.DialogS_Doing --剧情对话过程 
local DialogS_End = j.DialogS_End --剧情对话结束 
local SendSysInfo = j.SendSysInfo --Tips
local Option =j.Option        --对话选项
local SMessage = j.SMessage   --弹出提示
local CloseInteract = j.CloseInteract --结束交互
local Dialog_End = j.Dialog_End
local SMessage_End = j.SMessage_End

local masterId=55
local thisId=106
local NPCName=nil
local thisMen=5
------------------------------------------

function NpcMain(pUser, missionId)
	if NPCName == nil then
		NPCName = j.GetNpcName(thisId)
	end
    local userlv = pUser:GetLevel()
    if userlv >= j.GetCMissionAcceptLevel(MISSION_ID_DANYUAN) then
		if pUser:HaveCMission(MISSION_ID_DANYUAN) then
			if pUser:IsCMissionFinished(MISSION_ID_DANYUAN) then
				Option(pUser,NPCName, LANGUAGE_SSJ_0141, LANGUAGE_SSJ_0144)
				pUser:SetCallFun("DanYuanSelectOpt")
			else
				Dialog(pUser, NPCName, LANGUAGE_SSJ_0142)
			end
			return
		else
			if DodayCanDoDanYuanMission(pUser) then
				Option(pUser, NPCName, LANGUAGE_SSJ_0141, LANGUAGE_SSJ_0140)
				pUser:SetCallFun("DanYuanSelectOpt")
				return
			end
		end
    end
	
	Dialog(pUser, NPCName, LANGUAGE_TRANSFORM_17)
end

function DanYuanSelectOpt(pUser, sel)
    if sel == 1 then		-- 接任务
		j.UpdateNpcState(pUser,thisId, 2)
        AcceptDanYuan(pUser, sel)
	elseif sel == 2 then	-- 交任务			
		DanYuanMissionFinish(pUser, true)
	end
end

function GetState(pUser)
    local userlv = pUser:GetLevel()
    if userlv >= j.GetCMissionAcceptLevel(MISSION_ID_DANYUAN) then 
		if not pUser:HaveCMission(MISSION_ID_DANYUAN) then
			if DodayCanDoDanYuanMission(pUser) then
				return 1  -- 可接
			end
		else
			if pUser:IsCMissionFinished(MISSION_ID_DANYUAN) then
				return 3 -- 完成
			else
				return 2 -- 未完成
			end
		end
    end
	return 0 
end

