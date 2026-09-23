--166.lua--盛镖头 id=166
---------------------------------------
require "global"

Dialog = j.Dialog       --对话
Option =j.Option        --对话选项
SMessage = j.SMessage   --弹出提示
SendSysInfo = j.SendSysInfo --Tips
CloseInteract = j.CloseInteract --结束交互
MissionBanner = j.MissionBanner --新版任务面板接取模式
OptionConfirm = j.OptionConfirm
Dialog_End = j.Dialog_End       
SMessage_End = j.SMessage_End   

thisId=166
NPCName = nil

------------------------------------------

function NpcMain(pUser,missionId)
	if NPCName == nil then
		NPCName = j.GetNpcName(thisId)
	end
	local lv =pUser:GetLevel()
	local s = pUser:GetMission(213)
	
	if s ~= nil then
		local t = FormatMission(s)
		if tonumber(t[1]) == 6 then
			j.ShowFinishYaYunBiaoChePanel(pUser)
--			Option(pUser,"盛镖头","我一刀斩到你桃花开！","3|完成押运镖车")
			pUser:SetCallFun("DoOption")
--		else
--			j.ShowYaYunBiaoChePanel(pUser)
		end
	else
		Dialog(pUser,LANGUAGE_TRANSFORM_1222,LANGUAGE_TRANSFORM_1223)
	end
end

function DoOption(pUser,sel)
	local s = pUser:GetMission(213)
	if s == nil then
		CloseInteract(pUser)
		return
	end
	local t = FormatMission(s)
	if tonumber(t[1]) ~= 6 then
		return
	end
	if sel == 3 then
		if tonumber(t[1]) ~= 6 then
			return
		end
	
		local exp,money = GetYaBiaoMissionExp(s)
		pUser:DelMission(213)
		j.UpdateNpcState(pUser,thisId,0)
		pUser:SendYaBiaoMissionState(0,0)
		j.SendSysInfo(pUser,LANGUAGE_TRANSFORM_1224)
		pUser:RecoveryAllHp()
		pUser:AddExpByItemWithTips(exp)
--		pUser:AddBaiHuaChip(3,1,1)
		
		pUser:AddMoney(money)
		j.SendSysInfo(pUser,LANGUAGE_TRANSFORM_1225..money.."[/c]")
		
		-- 上坐骑，上跟随宠
		j.SetGenSuiPetUp(pUser)
		j.SetQiPetUp(pUser)
		
		if pUser:GetExtData8(88) < 10 then
			j.ShowYaYunBiaoCheNextTaskPanel(pUser,exp,money)
		end
		pUser:CheckMissionHuoYueDu()
		
		j.HD_DropExchangeItem(pUser,4)
		j.HD_DropHDItem(pUser,4)
	end
end

function GetState(pUser)
	local s 
	local id
	local t
	local lv=pUser:GetLevel()

	s = pUser:GetMission(213)
	
	if s ~= nil then
		t = FormatMission(s)
		if tonumber(t[6]) == 6 then
			return 3
		else
			return 2	
		end
	end
	return 0
end

function NotifyRes(pUser,mid,num) 
	local s
	local n
	local t
	local max
	local item

	--- 0|0|id|max ；0|0|mid|Iid|max


end

function GetChatMsg(pUser)
	return NPC_HEAD_YUNBIAO
end
