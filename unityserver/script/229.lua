--229.lua--任务大使 id=229
---------------------------------------
require "global"

Dialog = j.Dialog       --对话
Option =j.Option        --对话选项
SMessage = j.SMessage   --弹出提示
CloseInteract = j.CloseInteract --结束交互
MissionBanner = j.MissionBanner --新版任务面板接取模式
Dialog_End = j.Dialog_End
SMessage_End = j.SMessage_End

thisId = 229
NPCName = nil

function NpcMain(pUser,missionId)
	if NPCName == nil then
		NPCName = j.GetNpcName(thisId)
	end
	local s
	local t
	local op = ""
	local serverType = j.GetServerType()
	if missionId == 801 then
		s = pUser:GetMission(missionId)
		if s~=nil then
			t = FormatMission(s)
			if tonumber(t[1]) == 1 then
				MissionBanner(pUser,BANNER_TYPE_FINISH,missionId)
				pUser:SetCallFun("MissionBannerCallBack1")
				return
			end
		end
	elseif missionId == 802 then
		s = pUser:GetMission(missionId)
		if s~=nil then
			t = FormatMission(s)
			if tonumber(t[1]) == 1 then
				MissionBanner(pUser,BANNER_TYPE_FINISH,missionId)
				pUser:SetCallFun("MissionBannerCallBack1")
				return
			end
		end
	elseif missionId == 803 then
		s = pUser:GetMission(missionId)
		if s~=nil then
			t = FormatMission(s)
			if tonumber(t[1]) == 1 then
				MissionBanner(pUser,BANNER_TYPE_FINISH,missionId)
				pUser:SetCallFun("MissionBannerCallBack1")
				return
			end
		end
	elseif missionId == 804 then
		s = pUser:GetMission(missionId)
		if s~=nil then
			t = FormatMission(s)
			if tonumber(t[1]) == 1 then
				MissionBanner(pUser,BANNER_TYPE_FINISH,missionId)
				pUser:SetCallFun("MissionBannerCallBack1")
				return
			end
		end
	elseif missionId == 805 then
		s = pUser:GetMission(missionId)
		if s~=nil then
			t = FormatMission(s)
			if tonumber(t[1]) == 1 then
				MissionBanner(pUser,BANNER_TYPE_FINISH,missionId)
				pUser:SetCallFun("MissionBannerCallBack1")
				return
			end
		end
	elseif missionId == 806 then
		s = pUser:GetMission(missionId)
		if s==nil then
			op = op.."806|"..j.GetMissionName(806)
			Option(pUser,NPCName,LANGUAGE_SSJ_0017,op)
			pUser:SetCallFun("NpcMainSel")
--			MissionBanner(pUser,BANNER_TYPE_ACCETP,missionId)
--			pUser:SetCallFun("MissionBannerCallBack0") 
			return
		end
	end

	local missNum = 0
	if pUser:GetMission(801) ~= nil then
		missNum = missNum+1
		op = op.."801|"..j.GetMissionName(801).."|"
	end
	if pUser:GetMission(802) ~= nil then
		missNum = missNum+1
		op = op.."802|"..j.GetMissionName(802).."|"
	end
	if pUser:GetMission(803) ~= nil then
		missNum = missNum+1
		op = op.."803|"..j.GetMissionName(803).."|"
	end
	if pUser:GetMission(804) ~= nil then
		missNum = missNum+1
		if missNum == 4 then
			op = op.."10|"..LANGUAGE_SSJ_0039.."|"
		elseif missNum < 4 then
			op = op.."804|"..j.GetMissionName(804).."|"
		end
	end
	
--	if serverType ~= "qq_qudao_kf" then
		if pUser:GetMission(805) ~= nil then
			missNum = missNum+1
			if missNum == 4 then
				op = op.."10|"..LANGUAGE_SSJ_0039.."|"
			elseif missNum < 4 then
				op = op.."805|"..j.GetMissionName(805).."|"
			end
		end
		if pUser:GetMission(806) == nil then
			missNum = missNum+1
			if missNum == 4 then
				op = op.."10|"..LANGUAGE_SSJ_0039.."|"
			elseif missNum < 4 then
				op = op.."806|"..j.GetMissionName(806).."|"
			end
		end
--	end
	
	if op ~= "" then
		op = string.sub(op,1,-2)
		if #op ~= 0 then
			Option(pUser,NPCName,LANGUAGE_SSJ_0017,op)
			pUser:SetCallFun("NpcMainSel")
		else
			Dialog(pUser,NPCName,LANGUAGE_SSJ_0017)
		end
	else
		Dialog(pUser,NPCName,LANGUAGE_SSJ_0017)
	end
end

function NpcMainSel(pUser,sel)
	local s
	local t
	local missionId
	local serverType = j.GetServerType()
	
	if sel == 801 then
		missionId = 801
		s = pUser:GetMission(missionId)
		if s ~= nil then
			t = FormatMission(s)
			if tonumber(t[1]) == 1 then
				MissionBanner(pUser,BANNER_TYPE_FINISH,missionId)
				pUser:SetCallFun("MissionBannerCallBack1")
			else
				Dialog(pUser,NPCName,LANGUAGE_SSJ_0020)
			end
			return
		end
	elseif sel == 802 then
		missionId = 802
		s = pUser:GetMission(missionId)
		if s ~= nil then
			t = FormatMission(s)
			if tonumber(t[1]) == 1 then
				MissionBanner(pUser,BANNER_TYPE_FINISH,missionId)
				pUser:SetCallFun("MissionBannerCallBack1")
			else
				Dialog(pUser,NPCName,LANGUAGE_SSJ_0020)
			end
			return
		end
	elseif sel == 803 then
		missionId = 803
		s = pUser:GetMission(missionId)
		if s ~= nil then
			t = FormatMission(s)
			if tonumber(t[1]) == 1 then
				MissionBanner(pUser,BANNER_TYPE_FINISH,missionId)
				pUser:SetCallFun("MissionBannerCallBack1")
			else
				Dialog(pUser,NPCName,LANGUAGE_SSJ_0020)
			end
			return
		end
	elseif sel == 804 then
		missionId = 804
		s = pUser:GetMission(missionId)
		if s ~= nil then
			t = FormatMission(s)
			if tonumber(t[1]) == 1 then
				MissionBanner(pUser,BANNER_TYPE_FINISH,missionId)
				pUser:SetCallFun("MissionBannerCallBack1")
			else
				Dialog(pUser,NPCName,LANGUAGE_SSJ_0020)
			end
			return
		end
	elseif sel == 805 then
		missionId = 805
		s = pUser:GetMission(missionId)
		if s ~= nil then
			t = FormatMission(s)
			if tonumber(t[1]) == 1 then
				MissionBanner(pUser,BANNER_TYPE_FINISH,missionId)
				pUser:SetCallFun("MissionBannerCallBack1")
			else
				Dialog(pUser,NPCName,LANGUAGE_SSJ_0020)
			end
			return
		end
	elseif sel == 806 then
		missionId = 806
		s = pUser:GetMission(missionId)
		if s == nil then
			j.AddKuaFuZhuoGuiMiss(pUser)
--			MissionBanner(pUser,BANNER_TYPE_ACCETP,missionId)
--			pUser:SetCallFun("MissionBannerCallBack0")
		end
		return
	elseif sel == 10 then
		local op = ""
		local missNum = 0
		if pUser:GetMission(801) ~= nil then
			missNum = missNum+1
		end
		if pUser:GetMission(802) ~= nil then
			missNum = missNum+1
		end
		if pUser:GetMission(803) ~= nil then
			missNum = missNum+1
		end
		if pUser:GetMission(804) ~= nil then
			missNum = missNum+1
			if missNum >= 4 then
				op = op.."804|"..j.GetMissionName(804).."|"
			end
		end
		
--		if serverType ~= "qq_qudao_kf" then
			if pUser:GetMission(805) ~= nil then
				missNum = missNum+1
				if missNum >= 4 then
					op = op.."805|"..j.GetMissionName(805).."|"
				end
			end
			if pUser:GetMission(806) == nil then
				missNum = missNum+1
				if missNum >= 4 then
					op = op.."806|"..j.GetMissionName(806).."|"
				end
			end
--		end
		
		if op ~= "" then
			op = string.sub(op,1,-2)
			if #op ~= 0 then
				Option(pUser,NPCName,LANGUAGE_SSJ_0017,op)
				pUser:SetCallFun("NpcMainSel")
			else
				Dialog(pUser,NPCName,LANGUAGE_SSJ_0017)
			end
		else
			Dialog(pUser,NPCName,LANGUAGE_SSJ_0017)
		end
		return
	end
	CloseInteract(pUser)
end

function MissionBannerCallBack0(pUser,missionId)
	if missionId==806 then
		j.AddKuaFuZhuoGuiMiss(pUser)
		return
	end
end

function MissionBannerCallBack1(pUser,missionId)
	local award
	local dropItem = true
	local serverType = j.GetServerType()
--	if serverType == "qq_qudao_kf" then
--		dropItem = false
--	end
	if missionId == 801 then
		local item = {2595,2605,2615,2625,2635,2645,2655,2665,2675,2685,2695,2705,2715}
		pUser:SetBitSet(missionId)
		pUser:DelMission(missionId)
		
		pUser:AddExp(MISSION_EXP[missionId])
		pUser:AddQianNeng(MISSION_QIANNENG[missionId])
		pUser:AddMoney(MISSION_MONEY[missionId])
		
		local id = item[math.random(1,#item)]
		if dropItem then
			pUser:AddBangDingPackage(id,1)
			pUser:AddPackage(2798,2)
			pUser:AddXianYuanValue(10)
			j.SendSysInfo(pUser,"[c4]"..LANGUAGE_SSJ_0018..j.GetItemName(id).."*1,"..LANGUAGE_SSJ_0019.."*10,"..j.GetItemName(2798).."*2[c/]")
		end
		award=GetAward(pUser,missionId)
		j.SendSysInfoRD(pUser,award)
		j.UpdateNpcState(pUser,thisId,GetState(pUser))
		j.SaveDate(pUser,711,missionId,"")
	elseif missionId == 802 then
		local item = {2595,2605,2615,2625,2635,2645,2655,2665,2675,2685,2695,2705,2715}
		pUser:SetBitSet(missionId)
		pUser:DelMission(missionId)
		
		pUser:AddExp(MISSION_EXP[missionId])
		pUser:AddQianNeng(MISSION_QIANNENG[missionId])
		pUser:AddMoney(MISSION_MONEY[missionId])
		
		local id = item[math.random(1,#item)]
		if dropItem then
			pUser:AddBangDingPackage(id,1)
			pUser:AddXianYuanValue(10)
			pUser:AddPackage(2798,2)
			j.SendSysInfo(pUser,"[c4]"..LANGUAGE_SSJ_0018..j.GetItemName(id).."*1,"..LANGUAGE_SSJ_0019.."*10,"..j.GetItemName(2798).."*2[c/]")
		end
		award=GetAward(pUser,missionId)
		j.SendSysInfoRD(pUser,award)
		j.UpdateNpcState(pUser,thisId,GetState(pUser))
		j.SaveDate(pUser,711,missionId,"")
	elseif missionId == 803 then
		local item = {2595,2605,2615,2625,2635,2645,2655,2665,2675,2685,2695,2705,2715}
		pUser:SetBitSet(missionId)
		pUser:DelMission(missionId)
		
		pUser:AddExp(MISSION_EXP[missionId])
		pUser:AddQianNeng(MISSION_QIANNENG[missionId])
		pUser:AddMoney(MISSION_MONEY[missionId])
		
		local id = item[math.random(1,#item)]
		if dropItem then
			pUser:AddBangDingPackage(id,1)
			pUser:AddXianYuanValue(10)
			pUser:AddPackage(2798,2)
			j.SendSysInfo(pUser,"[c4]"..LANGUAGE_SSJ_0018..j.GetItemName(id).."*1,"..LANGUAGE_SSJ_0019.."*10,"..j.GetItemName(2798).."*2[c/]")
		end
		award=GetAward(pUser,missionId)
		j.SendSysInfoRD(pUser,award)
		j.UpdateNpcState(pUser,thisId,GetState(pUser))
		j.SaveDate(pUser,711,missionId,"")
	elseif missionId == 804 then
		local item = {2595,2605,2615,2625,2635,2645,2655,2665,2675,2685,2695,2705,2715}
		pUser:SetBitSet(missionId)
		pUser:DelMission(missionId)
		
		pUser:AddExp(MISSION_EXP[missionId])
		pUser:AddQianNeng(MISSION_QIANNENG[missionId])
		pUser:AddMoney(MISSION_MONEY[missionId])
		
		local id = item[math.random(1,#item)]
		if dropItem then
			pUser:AddBangDingPackage(id,1)
			pUser:AddXianYuanValue(10)
			pUser:AddPackage(2798,2)
			j.SendSysInfo(pUser,"[c4]"..LANGUAGE_SSJ_0018..j.GetItemName(id).."*1,"..LANGUAGE_SSJ_0019.."*10,"..j.GetItemName(2798).."*2[c/]")
		end
		award=GetAward(pUser,missionId)
		j.SendSysInfoRD(pUser,award)
		j.UpdateNpcState(pUser,thisId,GetState(pUser))
		j.SaveDate(pUser,711,missionId,"")
	elseif missionId == 805 then
		pUser:SetBitSet(missionId)
		pUser:DelMission(missionId)
		
		pUser:AddExp(MISSION_EXP[missionId])
		pUser:AddQianNeng(MISSION_QIANNENG[missionId])
		pUser:AddMoney(MISSION_MONEY[missionId])
		
		if dropItem then
			pUser:AddPackage(2798,6)
			j.SendSysInfo(pUser,"[c4]"..LANGUAGE_SSJ_0018..j.GetItemName(2798).."*6[c/]")
		end
		award=GetAward(pUser,missionId)
		j.SendSysInfoRD(pUser,award)
		j.UpdateNpcState(pUser,thisId,GetState(pUser))
		j.SaveDate(pUser,711,missionId,"")
	end
end

function GetState(pUser)
	local s
	local t
	local state = 0
	
	s = pUser:GetMission(801)
	if s ~= nil then
		t = FormatMission(s)
		if tonumber(t[1]) == 1 then
			return 3
		else
			state = UpdateState(state,2)
		end
	end
	
	s = pUser:GetMission(802)
	if s ~= nil then
		t = FormatMission(s)
		if tonumber(t[1]) == 1 then
			return 3
		else
			state = UpdateState(state,2)
		end
	end
	
	s = pUser:GetMission(803)
	if s ~= nil then
		t = FormatMission(s)
		if tonumber(t[1]) == 1 then
			return 3
		else
			state = UpdateState(state,2)
		end
	end
	
	s = pUser:GetMission(804)
	if s ~= nil then
		t = FormatMission(s)
		if tonumber(t[1]) == 1 then
			return 3
		else
			state = UpdateState(state,2)
		end
	end
	
	s = pUser:GetMission(805)
	if s ~= nil then
		t = FormatMission(s)
		if tonumber(t[1]) == 1 then
			return 3
		else
			state = UpdateState(state,2)
		end
	end
	return state
end

function GetChatMsg(pUser)
	return NPC_HEAD_NONE
end

