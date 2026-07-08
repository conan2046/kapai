--161.lua--蔡镖头 id=161
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

thisId=161
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
		if tonumber(t[1]) == 1 then
			if tonumber(t[6]) == 1 then
				j.ShowFinishYaYunBiaoChePanel(pUser)
--				Option(pUser,"蔡镖头","我的妈呀，这是要发啊！","3|完成押运镖车")
			else
				j.ShowYaYunBiaoChePanel(pUser,0,162)
--				Option(pUser,"蔡镖头","我的妈呀，这是要发啊！","1|我要换车|2|不换车")
			end
			pUser:SetCallFun("DoOption")
--		else
--			j.ShowYaYunBiaoChePanel(pUser,0,)
		end
	else
		Dialog(pUser,NPCName,LANGUAGE_TRANSFORM_1004)
	end
end

function DoOption(pUser,sel)
	local s = pUser:GetMission(213)
	if s == nil then
		return
	end
	local t = FormatMission(s)
	if tonumber(t[1]) ~= 1 then
		return
	end	
	
	if sel == 1 then
--		if tonumber(t[2]) == 4 then
--			j.ShowYaYunBiaoChe_CheckChange(pUser,"您当前车品质已经最高，换车有可能造成损失，您是否需要继续换车？")
--			return
--		end
		if tonumber(t[6]) == 1 then
			return
		end
		
		t[1] = 2
		
		local quality = 0
		local r = math.random(1,100)
		if r <= 15 then
			quality = 0
		elseif r <= 41 then
			quality = 1
		elseif r <= 81 then
			quality = 2
		elseif r <= 96 then
			quality = 3
		else
			quality = 4
		end
		t[2] = quality
		
		local q = tonumber(t[2])
		if q == 4 or (q == 3 and math.random(1,100) <= 20) then
			j.SysInfoToAllUser("[c"..ROLE_NAME_COLOR.."]"..pUser:GetName()..LANGUAGE_TRANSFORM_1005..ITEM_NAME_COLOR.."]"..j.GetSceneName(pUser:GetSceneId())..LANGUAGE_TRANSFORM_1006..GongGaoColor[q][1].."]"..GongGaoColor[q][2]..LANGUAGE_TRANSFORM_1007)
		end
		pUser:UpdateMission(213,table.concat(t, "|"))
		pUser:SendYaBiaoMissionState(1,q)
		
		s = pUser:GetMission(213)
		local exp,money,item_id,item_num  = GetYaBiaoMissionExp(s)
		if q >= 1 then
			j.SendSysInfo(pUser,LANGUAGE_TRANSFORM_1008..GongGaoColor[q][2]..LANGUAGE_TRANSFORM_1009)
		else
			j.SendSysInfo(pUser,LANGUAGE_TRANSFORM_1010)
		end
		
		local worldExpPer = GetWorldExpPercent(pUser)
		if worldExpPer > 0 then
			j.SendSysInfo(pUser,LANGUAGE_TRANSFORM_1011..exp..LANGUAGE_TRANSFORM_1012..worldExpPer..LANGUAGE_TRANSFORM_1013..money..LANGUAGE_CHY_301..j.GetItemName(item_id).."*"..item_num.."[/c]")
		else
			j.SendSysInfo(pUser,LANGUAGE_TRANSFORM_1015..exp..LANGUAGE_TRANSFORM_1016..money..LANGUAGE_CHY_301..j.GetItemName(item_id).."*"..item_num.."[/c]")
		end

		
		
		j.SendChangeYaYunBiaoCheSuccess(pUser,t[1])

--		j.ShowYaYunBiaoChePanel(pUser,1)
	elseif sel == 2 then
		if tonumber(t[6]) == 1 then
			return
		end
	
		t[1] = 2
		pUser:UpdateMission(213,table.concat(t, "|"))
		j.SendChangeYaYunBiaoCheSuccess(pUser,t[1])
--		j.ShowYaYunBiaoChePanel(pUser,0)
	elseif sel == 3 then
		if tonumber(t[6]) ~= 1 then
			return
		end
		
		local exp,money,item_id,item_num = GetYaBiaoMissionExp(s)
		pUser:DelMission(213)
		j.UpdateNpcState(pUser,thisId,0)
		pUser:SendYaBiaoMissionState(0,0)
		j.SendSysInfo(pUser,LANGUAGE_TRANSFORM_1018)
		pUser:RecoveryAllHp()
		pUser:AddExpByItemWithTips(exp)
--		pUser:AddBaiHuaChip(3,1,1)
		
		pUser:AddMoney(money)
		j.SendSysInfo(pUser,LANGUAGE_TRANSFORM_1019..money.."[/c]")
		
		pUser:AddPackage(item_id,item_num);
		j.SendSysInfo(pUser,LANGUAGE_TRANSFORM_1022..j.GetItemName(item_id).."*"..item_num.."[/c]")
		-- 上坐骑，上跟随宠
		j.SetGenSuiPetUp(pUser)
		j.SetQiPetUp(pUser)
		
		if pUser:GetExtData8(88) < 10 then
			j.ShowYaYunBiaoCheNextTaskPanel(pUser,exp,money,item_id,item_num)
		end
		pUser:CheckMissionHuoYueDu()
		
		j.HD_DropExchangeItem(pUser,4)
		j.HD_DropHDItem(pUser,4)
	end
end

function AutoTransportUser(pUser,nextSceneId)
end

function GetState(pUser)
	local s 
	local id
	local t
	local lv=pUser:GetLevel()

--[[
	s=pUser:GetMission(91)
	if s==nil then
		if lv>=32 and (not pUser:HaveBitSet(91)) then
			return 1
		end
	else
		if tonumber(s)==2 then
			return 3
		else
			return 2
		end
	end
--]]

	s = pUser:GetMission(213)
	if s ~= nil then
		t = FormatMission(s)
		if tonumber(t[6]) == 1 then
			return 3
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
