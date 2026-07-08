--15.lua--婚礼迎宾 id=15
---------------------------------------
require "global"

Dialog = j.Dialog       --对话
Option =j.Option        --对话选项
SMessage = j.SMessage   --弹出提示
CloseInteract = j.CloseInteract --结束交互
MissionBanner = j.MissionBanner --新版任务面板接取模式
Dialog_End = j.Dialog_End       
SMessage_End = j.SMessage_End   

thisId = 15
NPCName = nil

------------------------------------------
--以下为脚本部分：
------------------------------------------
function NpcMain(pUser,missionId)
	if NPCName == nil then
		NPCName = j.GetNpcName(thisId)
	end
	local s
	local lv
	local ns
	local serverType = j.GetServerType()
	local serverId = pUser:GetServerId()
	
	if serverType == "qq" and  (serverId >= 31 and serverId <= 120) then
		pUser:DelPackageById(188,1)		
	end
	Dialog(pUser,NPCName,LANGUAGE_TRANSFORM_1686)
	-- Option(pUser,NPCName,"本功能目前开放为测试","1|增加友好度(请组队)|2|获取结婚道具|3|关闭")
	-- pUser:SetCallFun("DoCheat")
end

function DoCheat(pUser,sel)
	if sel==1 then
		local pmem=j.GetTeamMember1(pUser)
		if pmem==nil then
			Dialog(pUser,NPCName,LANGUAGE_TRANSFORM_1687)
			return
		end
		
		if pUser:SetHotVal(pmem:GetRoleId(),10000) then
			Dialog(pUser,NPCName,LANGUAGE_TRANSFORM_1688..pmem:GetName()..LANGUAGE_TRANSFORM_1689)
		else
			Dialog(pUser,NPCName,LANGUAGE_TRANSFORM_1690)
		end
	elseif sel==2 then
		pUser:AddBangDingPackage(1835)
	else	
		j.CloseInteract(pUser)
	end	
end


function GetState(pUser)
	local s 


	return 0
end

function AutoTransportUser(pUser,nextSceneId)
	local s
	if nextSceneId~=49 then
		return
	end
	j.TransportUser(pUser,49,1300,910,4)
end

function GetChatMsg(pUser)
	return NPC_HEAD_NONE
end

