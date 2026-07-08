--10.lua--帮战接引人 id=10
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

thisId = 10
NPCName = nil

------------------------------------------
--以下为脚本部分：
------------------------------------------
function NpcMain(pUser,missionId)
	if NPCName == nil then
		NPCName = j.GetNpcName(thisId)
	end
	Option(pUser,LANGUAGE_TRANSFORM_2,LANGUAGE_TRANSFORM_3,LANGUAGE_TRANSFORM_4)
	pUser:SetCallFun("SelectOption")
end

function SelectOption(pUser,sel)
	if sel == 1 then
		local serverType = j.GetServerType()
		if serverType == "taiwan" then
			j.SendSysInfo(pUser,LANGUAGE_SSJ_0001)
			return
		end

		if pUser:GetTeam() > 0 and pUser:GetTeam() ~= pUser:GetRoleId() then
			j.SendSysInfo(pUser,LANGUAGE_TRANSFORM_5)
			return
		end
		if pUser:GetBangPai() == 0 then
			j.SendSysInfo(pUser,LANGUAGE_TRANSFORM_6)
			return
		end
		if not j.IsOpenBangPaiFight() then
			j.SendSysInfo(pUser,LANGUAGE_TRANSFORM_7)
			return
		end
		
		local wday = j.GetWeekDay()
		local hour = j.GetHour()
		local minute = j.GetMinute()
		-- 每周三、周六 19:55-20:30可进
		if (wday == 3 or wday == 6) and ((hour == 19 and minute >= 55) or (hour == 20 and minute <= 30)) then
			if pUser:GetLevel() < 40 then
				j.SendSysInfo(pUser,LANGUAGE_TRANSFORM_8)
				return
			end
			if os.time() - j.GetEnterBangPaiTime(pUser) < 24*3600 then
				j.SendSysInfo(pUser,LANGUAGE_TRANSFORM_9)
				return
			end
			if not j.CanEnterBangPaiFightScene(pUser) then
				j.SendSysInfo(pUser,LANGUAGE_TRANSFORM_10)
				return
			end
			
			if pUser:GetTeam() > 0 then
				local member1 = j.GetTeamMember1(pUser)
				local member2 = j.GetTeamMember2(pUser)
				if member1 ~= nil then
					if member1:GetLevel() < 40 then
						j.SendSysInfo(pUser,"[c1]"..member1:GetName()..LANGUAGE_TRANSFORM_11)
						return
					end
					if os.time() - j.GetEnterBangPaiTime(member1) < 24*3600 then
						j.SendSysInfo(pUser,"[c1]"..member1:GetName()..LANGUAGE_TRANSFORM_12)
						return
					end
				end
				
				if member2 ~= nil then
					if member2:GetLevel() < 40 then
						j.SendSysInfo(pUser,"[c1]"..member2:GetName()..LANGUAGE_TRANSFORM_13)
						return
					end
					
					if os.time() - j.GetEnterBangPaiTime(member2) < 24*3600 then
						j.SendSysInfo(pUser,"[c1]"..member2:GetName()..LANGUAGE_TRANSFORM_14)
						return
					end
				end
			end
			
			j.EnterBPFightReadyScene(pUser)
		else
			-- j.SendSysInfo(pUser,"[c1]每周三、周六 19：55-20：30可进入[c/]")
			j.SendSysInfo(pUser,LANGUAGE_TRANSFORM_15)
		end
	elseif sel == 2 then
		CloseInteract(pUser)
	end
end

function GetState(pUser)
	return 0
end

function GetChatMsg(pUser)
	return NPC_HEAD_NONE
end
