--14.lua--月老 id=14
---------------------------------------
require "global"

Dialog = j.Dialog       --对话
Option =j.Option        --对话选项
OptionConfirm = j.OptionConfirm
SMessage = j.SMessage   --弹出提示
CloseInteract = j.CloseInteract --结束交互
MissionBanner = j.MissionBanner --新版任务面板接取模式
Dialog_End = j.Dialog_End       
SMessage_End = j.SMessage_End   
ShowGuidance = j.ShowGuidance
DialogS_Start = j.DialogS_Start
DialogS_Doing = j.DialogS_Doing
DialogS_End = j.DialogS_End

thisId = 14
NPCName = nil

------------------------------------------
--以下为脚本部分：
------------------------------------------
function NpcMain(pUser,missionId)
	if NPCName == nil then
		NPCName = j.GetNpcName(thisId)
	end
	local s
	local ts = pUser:GetSaveVal(5)
	local nts=j.GetNextMainMissionId(ts)

	if HaveLetter(pUser,NPCName,thisId, missionId) then
		return
	end

--	local serverType = j.GetServerType()
--	if serverType == "hanban" or serverType == "offical" then
		Dialog(pUser,NPCName,LANGUAGE_TRANSFORM_59)
		return
--	else
--	Dialog(pUser,NPCName,LANGUAGE_TRANSFORM_59)
--	Option(pUser,NPCName,"婚姻的相关问题找我就对了，我可是月老！","1|结婚|2|离婚|3|夫妻恩爱度|4|离开")
--	pUser:SetCallFun("DoSelect")
--[[
		if j.IsShowWeddingOption(pUser) then
			Option(pUser,NPCName,LANGUAGE_TRANSFORM_60,LANGUAGE_SSJ_0055)
		else
			if pUser:isGetMarriaged() then
				if not pUser:HaveBitSet(582) then
					Option(pUser,NPCName,LANGUAGE_TRANSFORM_60,LANGUAGE_SSJ_0059)
				else
					Option(pUser,NPCName,LANGUAGE_TRANSFORM_60,LANGUAGE_SSJ_0057)
				end
			else
				Option(pUser,NPCName,LANGUAGE_TRANSFORM_60,LANGUAGE_SSJ_0060)
			end
		end
		pUser:SetCallFun("DoNewMarriageSelect")
--]]
--	end
end

function DoSelect(pUser,sel)
	local s
	local t

	if sel==1 then
		Option(pUser,NPCName,LANGUAGE_TRANSFORM_62,LANGUAGE_TRANSFORM_63)
		pUser:SetCallFun("Marry")
	elseif sel==2 then
		Option(pUser,NPCName,LANGUAGE_TRANSFORM_64,LANGUAGE_TRANSFORM_65)
		pUser:SetCallFun("Unmarry")
	elseif sel==3 then
		Option(pUser,NPCName,LANGUAGE_TRANSFORM_66,LANGUAGE_TRANSFORM_67)
		pUser:SetCallFun("LoveNumber")
	elseif sel==4 then
		j.CloseInteract(pUser)
	end
end

function Marry(pUser,sel)
	local nm
	local pmem
	local ret

	if sel==1 then
		ret=j.CheckMarry(pUser)
		if ret==1 then
			Dialog(pUser,NPCName,LANGUAGE_TRANSFORM_70)
			return
		elseif ret==2 then
			Dialog(pUser,NPCName,LANGUAGE_TRANSFORM_71)
			return
		elseif ret==3 then
			Dialog(pUser,NPCName,LANGUAGE_TRANSFORM_72)
			return
		elseif ret==4 then
			Dialog(pUser,NPCName,LANGUAGE_TRANSFORM_73)
			return
		elseif ret==5 then
			Dialog(pUser,NPCName,LANGUAGE_TRANSFORM_74)
			return
		elseif ret==6 then
			Dialog(pUser,NPCName,LANGUAGE_TRANSFORM_75)
			return
		end
		Option(pUser,NPCName,LANGUAGE_TRANSFORM_76,LANGUAGE_TRANSFORM_77)
		pUser:SetCallFun("Marry2")
	elseif sel==2 then
		Dialog(pUser,NPCName,LANGUAGE_TRANSFORM_78)
		pUser:SetCallFun("RuleInfo2")
	elseif sel==3 then
		j.CloseInteract(pUser)
	end
end

function Marry2(pUser,sel)
	local pmem

	if sel==1 then
		--是否有道具
		if pUser:GetItemNum(1835)==0 then
			Dialog(pUser,NPCName,LANGUAGE_TRANSFORM_79)
			return
		end
		pmem=j.GetTeamMember1(pUser)
		if pmem==nil then
			return
		end
		if pUser:EmptyPackage() < 1 or pmem:EmptyPackage() < 1 then
			Dialog(pUser,NPCName,LANGUAGE_TRANSFORM_80)
			return
		end	
		OptionConfirm(pmem,NPCName,LANGUAGE_TRANSFORM_81..pUser:GetName()..LANGUAGE_TRANSFORM_82,LANGUAGE_TRANSFORM_83)
		pUser:SetVal(0,0)
		pmem:SetCall(14,"Marry3")
		Dialog(pUser,NPCName,LANGUAGE_TRANSFORM_84..pmem:GetName()..LANGUAGE_TRANSFORM_85)
	elseif sel==2 then
		if pUser:GetItemNum(1836)==0 then
			Dialog(pUser,NPCName,LANGUAGE_TRANSFORM_86)
			return
		end
		pmem=j.GetTeamMember1(pUser)
		if pmem==nil then
			return
		end
		if pUser:EmptyPackage() < 1 or pmem:EmptyPackage() < 1 then
			Dialog(pUser,NPCName,LANGUAGE_TRANSFORM_87)
			return
		end	
		OptionConfirm(pmem,NPCName,LANGUAGE_TRANSFORM_88..pUser:GetName()..LANGUAGE_TRANSFORM_89,LANGUAGE_TRANSFORM_90)
		pUser:SetVal(0,1)
		pmem:SetCall(14,"Marry3")
		Dialog(pUser,NPCName,LANGUAGE_TRANSFORM_91..pmem:GetName()..LANGUAGE_TRANSFORM_92)
	else
		j.CloseInteract(pUser)
	end
end

function Marry3(pUser,sel)
	local pcap
	local type

	if sel==1 then
		pcap=j.GetTeamLeader(pUser)
		if pcap==nil then
			j.CloseInteract(pUser)
			return
		end
		type=pcap:GetVal(0)
		if type==0 then
			if pcap:GetItemNum(1835)==0 then
				return
			end
			pcap:DelPackageById(1835,1)
			Dialog(pUser,NPCName,LANGUAGE_TRANSFORM_93..pcap:GetName()..LANGUAGE_TRANSFORM_94)
			Dialog(pcap,NPCName,LANGUAGE_TRANSFORM_95..pUser:GetName()..LANGUAGE_TRANSFORM_96)
			j.DoMarry(pcap,1)
		else
			if pcap:GetItemNum(1836)==0 then
				return
			end
			pcap:DelPackageById(1836,1)
			Dialog(pUser,NPCName,LANGUAGE_TRANSFORM_97..pcap:GetName()..LANGUAGE_TRANSFORM_98)
			Dialog(pcap,NPCName,LANGUAGE_TRANSFORM_99..pUser:GetName()..LANGUAGE_TRANSFORM_100)
			j.DoMarry(pcap,2)
		end
	else
		pcap=j.GetTeamLeader(pUser)
		if pcap==nil then
			return
		end
		Dialog(pcap,NPCName,LANGUAGE_TRANSFORM_101)
		j.CloseInteract(pUser)
	end
end

function Unmarry(pUser,sel)
	local s

	if sel==1 then
		s=j.GetMarried(pUser)
		if s==nil then
			Dialog(pUser,NPCName,LANGUAGE_TRANSFORM_102)
			return
		end
		OptionConfirm(pUser,NPCName,LANGUAGE_TRANSFORM_103..s..LANGUAGE_TRANSFORM_104,LANGUAGE_TRANSFORM_105)
		pUser:SetCallFun("Unmarry2")
	elseif sel==2 then
		Dialog(pUser,NPCName,LANGUAGE_TRANSFORM_106)
	else
		j.CloseInteract(pUser)
	end
end

function Unmarry2(pUser,sel)
	local s

	if sel==1 then
		s=j.GetMarried(pUser)
		j.DoDivorce(pUser)
		SMessage(pUser,LANGUAGE_TRANSFORM_107..s..LANGUAGE_TRANSFORM_108)
	else
		j.CloseInteract(pUser)
	end
end

function RuleInfo2(pUser)
	Dialog(pUser,NPCName,LANGUAGE_TRANSFORM_109)
end

function LoveNumber(pUser,sel)
	if sel==1 then
		-- local num=pUser:GetData32(10)
		-- local marry=j.GetMarried(pUser)
		-- if marry==nil then
		-- 	Dialog(pUser,NPCName,"您还没有结婚，没有夫妻恩爱度。")
		-- 	return
		-- end
		Dialog(pUser,NPCName,LANGUAGE_TRANSFORM_110)
	elseif sel==2 then
		Dialog(pUser,NPCName,LANGUAGE_TRANSFORM_111)
		pUser:SetCallFun("LoveRule2")
	elseif sel==3 then
		j.CloseInteract(pUser)
	end
end

function LoveRule2(pUser)
	Dialog(pUser,NPCName,LANGUAGE_TRANSFORM_112)
end


function GetState(pUser)
	local s 
	local t
	local lv=pUser:GetLevel()
	local ts = pUser:GetSaveVal(5)
	local nts = j.GetNextMainMissionId(ts)
	
	if nts == 88 then
		s=pUser:GetMission(nts)
		if s~=nil then
			return 3
		end
	elseif nts == 89 then
		s=pUser:GetMission(nts)
		if s==nil then
			return 1
		end
	end
	return 0
end

function GetChatMsg(pUser)
	return NPC_HEAD_NONE
end




--新结婚功能

function DoNewMarriageSelect(pUser,sel)
	local s
	local t

	if sel==1 then
		GetMarriedReqCheck(pUser)
	elseif sel==2 then
		j.divorceReqCheck(pUser)
		return
	elseif sel == 3 then
		Dialog(pUser,NPCName,LANGUAGE_TRANSFORM_113)
	elseif sel == 4 then
		if j.GetTeamMemNum(pUser) == 3 then
			Dialog(pUser,NPCName,LANGUAGE_SSJ_0061)
			return
		end
		if pUser:GetTeam() > 0 and pUser:GetRoleId() == pUser:GetTeam() then
			local m1 = j.GetTeamMember1(pUser)
			if m1 ~= nil then
				if j.IsShowWeddingOption(m1) then
					j.CloseInteract(pUser)
					j.StartWedding(pUser,m1)
				else
					Dialog(pUser,NPCName,LANGUAGE_SSJ_0056)
				end
			else
				m1 = j.GetTeamMember2(pUser)
				if m1 ~= nil then
					if j.IsShowWeddingOption(m1) then
						j.CloseInteract(pUser)
						j.StartWedding(pUser,m1)
					else
						Dialog(pUser,NPCName,LANGUAGE_SSJ_0056)
					end
				else
					Dialog(pUser,NPCName,LANGUAGE_SSJ_0056)
				end
			end
		else
			Dialog(pUser,NPCName,LANGUAGE_SSJ_0056)
		end
	elseif sel == 5 then
		if not j.ShowWeddingOrderPanelByOldRoles(pUser) then
			j.CloseInteract(pUser)
		end		
	end
end



function GetMarriedReqCheck(pUser)
	local nm
	local pmem
	local ret
	
	local hour = j.GetHour()
	local min = j.GetMinute()
	if hour == 0 then
		Dialog(pUser,NPCName,LANGUAGE_SSJ_0062)
		return
	end

	ret = j.getMarriedReqCheck(pUser)
	if ret==1 then
		Dialog(pUser,NPCName,LANGUAGE_TRANSFORM_114)
		return
	elseif ret==2 then
		Dialog(pUser,NPCName,LANGUAGE_TRANSFORM_115)
		return
	elseif ret==3 then
		Dialog(pUser,NPCName,LANGUAGE_TRANSFORM_116)
		return
	elseif ret==4 then
		Dialog(pUser,NPCName,LANGUAGE_TRANSFORM_117)
		return
	end
	return
end



