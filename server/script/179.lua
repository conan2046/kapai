--179.lua 未开启的宝箱
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

thisId = 179

------------------------------------------
--以下为脚本部分：
------------------------------------------
function NpcMain(pUser,missionId,index)
	local openBox = pUser:GetExtData8(137)
	local idx = math.floor(index/10)
	if idx == openBox then
		j.Collect(pUser,thisId,idx,4,2,LANGUAGE_SSJ_0116)
		pUser:SetCallFun("CollectCall")
	else
		CloseInteract(pUser)
	end
end

function DelBoxNpc(pUser)
	local boxIdx = pUser:GetExtData8(137)
	for i=1,5 do
		j.DelDynamicNpcWithIndex(pUser,thisId,boxIdx*10+i)
	end
end

function CollectCall(pUser,index)
	local floor = pUser:GetExtData8(137)
	local name = ""
	local pic = 62
	local lv = pUser:GetLevel()
	if index == floor then
		local scene = pUser:GetScene()
		local r
		-- 开宝箱
		if index <= 5 then
			r = math.random(1,5)
			if r == 1 then
				num = math.random(1,2)
				pUser:AddMaterial(610,num, false)
			elseif r == 2 then
				pUser:AddMaterial(60000,1500, false)
			elseif r == 3 then
				num = math.random(1,2)
				pUser:AddMaterial(610,num, false)
			elseif r == 4 then
				num = math.random(1,2)
				pUser:AddMaterial(610,num, false)
			elseif r == 5 then
				num = math.random(1,2)
				pUser:AddMaterial(610,num, false)
			end
		elseif index <= 10 then
			r = math.random(1,5)
			if r == 1 then
				pUser:AddMaterial(610,2, false)
			elseif r == 2 then
				pUser:AddMaterial(610,2, false)
			elseif r == 3 then
				pUser:AddMaterial(611,1, false)
			elseif r == 4 then
				num = math.random(2,3)
				pUser:AddMaterial(610,num, false)
			elseif r == 5 then
				pUser:AddMaterial(60000,2000, false)
			end
		else
			r = math.random(1,5)
			if r == 1 then
				num = math.random(2,3)
				pUser:AddMaterial(610,num, false)
			elseif r == 2 then
				pUser:AddMaterial(60000,2500, false)
			elseif r == 3 then
				num = math.random(2,3)
				pUser:AddMaterial(610,num, false)
			elseif r == 4 then
				num = math.random(2,3)
				pUser:AddMaterial(610,num, false)
			elseif r == 5 then
				pUser:AddMaterial(611,1, false)
			end
		end
		j.SaveDate(pUser, 36, 1,"")
		pUser:SetExtData8(588,pUser:GetExtData8(588)+1)
		
		DelBoxNpc(pUser)
		pUser:SetExtData8(137,index+1)
		if index+1 == 15 then
			pUser:SetExtData8(135,pUser:GetExtData8(135)+1)
			j.ShiLianNoticeToExit(pUser,10)
			j.SendSysInfo(pUser,LANGUAGE_TRANSFORM_1201)
		else	-- 全部刷新
		
			pUser:AddYingYongShiLianNpc()
		end
	end
end

function GetState(pUser)
	return 0
end

function GetChatMsg(pUser)
	return NPC_HEAD_NONE
end

