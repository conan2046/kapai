--3.lua--试炼大使 id=3
---------------------------------------
require "global"

Dialog = j.Dialog       --对话
Option =j.Option        --对话选项
SMessage = j.SMessage   --弹出提示
CloseInteract = j.CloseInteract --结束交互
ShowGuidance = j.ShowGuidance
Dialog_End = j.Dialog_End       

local bit=require "bit"

local MONTH_CARD = {}
local TITLE = {}

thisId = 3
NPCName = nil

------------------------------------------
--以下为脚本部分：
------------------------------------------
function NpcMain(pUser,missionId)
	if NPCName == nil then
		NPCName = j.GetNpcName(thisId)
	end
	local serverType = j.GetServerType()
	local serverId = pUser:GetServerId()
	local roleId = pUser:GetRoleId()
	local num = 0
	local opt = ""
	local monthCard = pUser:GetExtData8(70)

--[[	
	if serverType == "qq_ios" then
		if MONTH_CARD[roleId] ~= nil and MONTH_CARD[roleId].serverType == serverType and MONTH_CARD[roleId].serverId == serverId then
			opt = opt..LANGUAGE_TRANSFORM_402
			num = num + 1
		end
	end
	
	if TITLE[roleId] ~= nil and TITLE[roleId].serverType == serverType and TITLE[roleId].serverId == serverId then
		opt = opt..LANGUAGE_TRANSFORM_403
		num = num + 1
	end
--]]

	opt = string.sub(opt,1,-2)
	if num == 0 then
		Dialog_End(pUser,NPCName,LANGUAGE_TRANSFORM_404)
	else
		Option(pUser,NPCName,LANGUAGE_TRANSFORM_405,opt)
		pUser:SetCallFun("ChooseOption")
	end
end

function ChooseOption(pUser,sel)
	local s
	local t
	local lv = pUser:GetLevel()
	local serverType = j.GetServerType()
	local serverId = pUser:GetServerId()
	local roleId = pUser:GetRoleId()
	local monthCard = pUser:GetExtData8(70)
	local baijinTime = pUser:GetExtData32(86)
	local zuanshiTime = pUser:GetExtData32(88)
	local wangzheTime = pUser:GetExtData32(89)
	
	if serverType == "ali_ios" then
		serverType = "qq_ios"
	end

	if sel == 1 then
		local info = MONTH_CARD[roleId]
		local day = 30*3600*24
		local curTime = os.time()
		if info ~= nil then
			if info.serverType == serverType and info.serverId == serverId then
				local baijinCount = baijinTime > curTime and math.floor((baijinTime - curTime) / day) + 1 or 0
				local zuanshiCount = zuanshiTime > curTime and math.floor((zuanshiTime - curTime) / day) + 1 or 0
				local wangzheCount = wangzheTime > curTime and math.floor((wangzheTime - curTime) / day) + 1 or 0

				if not pUser:HaveBitSet(info.saveId) and (baijinCount < info.baijin or zuanshiCount < info.zuanshi or wangzheCount < info.wangzhe) then
					local str = ""
					if baijinCount < info.baijin then
						for i = 1, info.baijin - baijinCount do
							pUser:SetMonthCard(0)
						end
						str = LANGUAGE_TRANSFORM_406
					end
					
					if zuanshiCount < info.zuanshi then
						for i = 1, info.zuanshi - zuanshiCount do
							pUser:SetMonthCard(1)
						end
						str = LANGUAGE_TRANSFORM_407
					end
					
					if wangzheCount < info.wangzhe then
						for i = 1, info.wangzhe - wangzheCount do
							pUser:SetMonthCard(2)
						end
						str = LANGUAGE_TRANSFORM_408
					end
					str = string.sub(str,1,-3)
					pUser:SetBitSet(info.saveId)
					Dialog(pUser,NPCName,LANGUAGE_TRANSFORM_409..str..LANGUAGE_TRANSFORM_410)
				else
					Dialog(pUser,NPCName,LANGUAGE_TRANSFORM_411)
				end
			else
				Dialog(pUser,NPCName,LANGUAGE_TRANSFORM_412)
				return
			end
		else
			Dialog(pUser,NPCName,LANGUAGE_TRANSFORM_413)
			return
		end
	elseif sel == 2 then
		if monthCard <= 1 then
			Dialog(pUser,NPCName,LANGUAGE_TRANSFORM_414)
		else
			if not pUser:HaveBitSet(1186) then
				local num = 0
				if bit:_and(monthCard,2) > 0 then
					num = num + 1000
				end
				
				if bit:_and(monthCard,4) > 0 then
					num = num + 2000
				end
				pUser:AddTongBao(num,1)
				pUser:SetBitSet(1186)
				Dialog(pUser,NPCName,LANGUAGE_TRANSFORM_415..num..LANGUAGE_TRANSFORM_416)
			else
				Dialog(pUser,NPCName,LANGUAGE_TRANSFORM_417)
			end 
		end
	elseif sel == 3 then
		local info = TITLE[roleId]
		if info and info.titleId and next(info.titleId) then
			for k, v in pairs(info.titleId) do
				pUser:AddTitle(v)
			end
			Dialog(pUser,NPCName,LANGUAGE_TRANSFORM_418)
		end
	end
end

function GetState(pUser)
	return 0
end

function GetChatMsg(pUser)
	return NPC_HEAD_NONE
end

MONTH_CARD[999999999] = {serverType = "qq", serverId = 66, baijin = 0, zuanshi = 0, wangzhe = 1, saveId = 1185}

TITLE[999999999] = {serverType = "qq_qudao", serverId = 587, titleId = {58}}

