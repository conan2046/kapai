--198.lua--问题大师 id=198
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

thisId = 198
NPCName = nil

------------------------------------------
function NpcMain(pUser,missionId,index)
	if NPCName == nil then
		NPCName = j.GetNpcName(thisId)
	end
	Option(pUser,NPCName,LANGUAGE_TRANSFORM_4610,LANGUAGE_TRANSFORM_4611)
	pUser:SetCallFun("SelectOption")
end

function SelectOption(pUser,sel)
	if sel == 1 then
		local lv = j.GetFuncOpenLevel(7)
		if pUser:GetLevel() < lv then
			Dialog(pUser,NPCName,LANGUAGE_SSJ_0173..lv..LANGUAGE_SSJ_0174)
			return
		end
		if pUser:GetExtData8(6) >= 2 and pUser:GetExtData8(35) >= 20 then
			Dialog(pUser,NPCName,LANGUAGE_TRANSFORM_4613)
			return
		end
		if pUser:GetExtData8(35) >= 20 and os.time() < pUser:GetExtData32(7) then
			local t = pUser:GetExtData32(7) - os.time()
			local min = math.floor(t/60)
			local second = t%60
			if min > 0 then
				Dialog(pUser,NPCName,LANGUAGE_TRANSFORM_4614..min..LANGUAGE_TRANSFORM_4615..second..LANGUAGE_TRANSFORM_4616)
			else
				Dialog(pUser,NPCName,LANGUAGE_TRANSFORM_4617..second..LANGUAGE_TRANSFORM_4618)
			end
			return
		end
		j.SendYinDao2_Op(pUser,1002)		-- 打开答题界面
	end
end

function GetState(pUser)
	return 0
end

function GetChatMsg(pUser)
	return NPC_HEAD_NONE
end

