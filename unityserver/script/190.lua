--190.lua--巡察使6
---------------------------------------
require "global"

Dialog = j.Dialog       --对话
Option =j.Option        --对话选项
SMessage = j.SMessage   --弹出提示
CloseInteract = j.CloseInteract --结束交互
Dialog_End = j.Dialog_End
SMessage_End = j.SMessage_End

NPCID = 190
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
		Option(pUser,name,LANGUAGE_TRANSFORM_1887..name..LANGUAGE_TRANSFORM_1889,LANGUAGE_TRANSFORM_1890)
	else
		Option(pUser,name,LANGUAGE_TRANSFORM_1891..name..LANGUAGE_TRANSFORM_1893,LANGUAGE_TRANSFORM_1894)
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
			Dialog(pUser,name,LANGUAGE_TRANSFORM_1895..LEVEL_LIMIT..LANGUAGE_TRANSFORM_1896)
			return
		end
		
		if pUser:GetTeam() == 0 then
			Dialog(pUser,name,LANGUAGE_TRANSFORM_1897)
			return
		end
		if pUser:GetTeam() ~= pUser:GetRoleId() then
			Dialog(pUser,name,LANGUAGE_TRANSFORM_1898)
			return
		end
		if j.GetTeamMemNum(pUser) < 2 then
			Dialog(pUser,name,LANGUAGE_TRANSFORM_1899)
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
			Dialog(pUser,name,LANGUAGE_TRANSFORM_1904)
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

