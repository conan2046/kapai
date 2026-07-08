--199.lua--猜拳高手 id=199
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

thisId = 199
NPCName = nil

------------------------------------------
function NpcMain(pUser,missionId,index)
	if NPCName == nil then
		NPCName = j.GetNpcName(thisId)
	end
	Option(pUser,NPCName,LANGUAGE_TRANSFORM_153,LANGUAGE_TRANSFORM_154)
	pUser:SetCallFun("SelectOption")
end

function SelectOption(pUser,sel)
	if sel == 1 then
		if pUser:GetLevel() < 28 then
			Dialog(pUser,NPCName,LANGUAGE_TRANSFORM_155)
			return
		end
		if pUser:GetExtData8(38) >= 3 then
			Dialog(pUser,NPCName,LANGUAGE_TRANSFORM_156)
			return
		end
		if os.time() < pUser:GetExtData32(8) then
			local t = pUser:GetExtData32(8) - os.time()
			local min = math.floor(t/60)
			local second = t%60
			if min > 0 then
				Dialog(pUser,NPCName,LANGUAGE_TRANSFORM_157..min..LANGUAGE_TRANSFORM_158..second..LANGUAGE_TRANSFORM_159)
			else
				Dialog(pUser,NPCName,LANGUAGE_TRANSFORM_160..second..LANGUAGE_TRANSFORM_161)
			end
			return
		end
		j.SendYinDao2_Op(pUser,1001)	-- 打开猜拳界面
	end
end

function GetState(pUser)
	return 0
end

function GetChatMsg(pUser)
	return NPC_HEAD_NONE
end

