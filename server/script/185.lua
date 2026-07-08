--185.lua--巡察使1
---------------------------------------
require "global"

Dialog = j.Dialog       --对话
Option =j.Option        --对话选项
SMessage = j.SMessage   --弹出提示
CloseInteract = j.CloseInteract --结束交互
Dialog_End = j.Dialog_End
SMessage_End = j.SMessage_End

NPCID = 185
XCS_LEVEL_LIMIT = 38

------------------------------------------
--以下为脚本部分：
------------------------------------------
function NpcMain(pUser,missionId,index)
	pUser:SetVal(1,index)
	local name = j.GetDiaNameByIndex(pUser,NPCID,index)
	local lv = pUser:GetLevel()
	if name == nil then
		CloseInteract(pUser)
		return
	end
	if lv >= XCS_LEVEL_LIMIT then
		Option(pUser,name,LANGUAGE_TRANSFORM_541..name..LANGUAGE_TRANSFORM_543,LANGUAGE_TRANSFORM_544)
	else
		Option(pUser,name,LANGUAGE_TRANSFORM_545..name..LANGUAGE_TRANSFORM_547,LANGUAGE_TRANSFORM_548)
	end
	pUser:SetCallFun("MonsterCallBack")
end

function MonsterCallBack(pUser,sel)
	local index = pUser:GetVal(1)
	local name = j.GetDiaNameByIndex(pUser,NPCID,index)
	if name == nil then
		CloseInteract(pUser)
		return
	end
	local LEVEL_LIMIT = XCS_LEVEL_LIMIT
	if sel == 1 then
		if pUser:GetLevel() < LEVEL_LIMIT then
			Dialog(pUser,name,LANGUAGE_TRANSFORM_549..LEVEL_LIMIT..LANGUAGE_TRANSFORM_550)
			return
		end
		
		if pUser:GetTeam() == 0 then
			Dialog(pUser,name,LANGUAGE_TRANSFORM_551)
			return
		end
		if pUser:GetTeam() ~= pUser:GetRoleId() then
			Dialog(pUser,name,LANGUAGE_TRANSFORM_552)
			return
		end
		if j.GetTeamMemNum(pUser) < 2 then
			Dialog(pUser,name,LANGUAGE_TRANSFORM_553)
			return
		end
		
		for idx=2,5 do
			local mem = j.GetTeamMember(pUser,idx)
			if mem ~= nil and mem:GetTeam() > 0 then
				if mem:GetLevel() < LEVEL_LIMIT then
					Dialog(pUser,name,LANGUAGE_TRANSFORM_554..LEVEL_LIMIT..LANGUAGE_TRANSFORM_555)
					return
				end
			end
		end

		if pUser:IsXunChaShiKilled(NPCID,index) then
			Dialog(pUser,name,LANGUAGE_TRANSFORM_558)
			return
		end
		
		j.XunChaShiFight(pUser,NPCID,index)
		pUser:SetCall(0,"")
	elseif sel == 2 then
		CloseInteract(pUser)
	end
end


function GetState(pUser)
	return 0
end

function GetHeadTitle(pUser,index)
	local data = 0
	if pUser:IsXunChaShiKilled(NPCID,index) then
		data = data + NPC_HEAD_KILLED
	end
	return data
end

function GetChatMsg(pUser)
	return NPC_HEAD_XUNCHASHI
end

