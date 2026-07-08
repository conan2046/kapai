--237.lua--庆典仙官 id=237
---------------------------------------
require "global"

Dialog = j.Dialog       --对话
Option =j.Option        --对话选项
SMessage = j.SMessage   --弹出提示
CloseInteract = j.CloseInteract --结束交互
MissionBanner = j.MissionBanner --新版任务面板接取模式
Dialog_End = j.Dialog_End       
SMessage_End = j.SMessage_End   

thisId = 237
NPCName = nil
huodongType = 64 --夺宝抽抽抽
limitCount = 5

------------------------------------------
--以下为脚本部分：
------------------------------------------

function NpcMain(pUser,missionId)
	if NPCName == nil then
		NPCName = j.GetNpcName(thisId)
	end
	if j.HDHuanLeShengYanCall(pUser,NPCName) then
		pUser:SetCallFun("NpcMainSel")
	else
		CloseInteract(pUser)
	end
end

function NpcMainSel(pUser,sel)
	local serverType = j.GetServerType()
	local serverId = pUser:GetServerId()
	local lv = pUser:GetLevel()
		
	if sel == 1 then	-- 交材料
		local s = j.GetHuanLeShengYan_DuiHuanInfo()
		local t = FormatMission(s)
		local item1 = tonumber(t[1])
		local jifen1 = tonumber(t[2])
		local item2 = tonumber(t[3])
		local jifen2 = tonumber(t[4])
		Option(pUser,NPCName,LANGUAGE_SSJ_0072..j.GetItemName(item1)..LANGUAGE_SSJ_0074..pUser:GetItemNum(item1)..LANGUAGE_SSJ_0075.."  "..j.GetItemName(item2)..LANGUAGE_SSJ_0074..pUser:GetItemNum(item2)..LANGUAGE_SSJ_0075,LANGUAGE_SSJ_0073)
		pUser:SetCallFun("SelectOption11")
	elseif sel == 2 then	-- 欢乐盛宴
		Option(pUser,NPCName,LANGUAGE_SSJ_0080,LANGUAGE_SSJ_0081)
		pUser:SetCallFun("SelectOption21")
	elseif sel == 3 then	-- 积分排行
		Option(pUser,NPCName,LANGUAGE_SSJ_0084,LANGUAGE_SSJ_0085)
		pUser:SetCallFun("SelectOption31")
	elseif sel == 4 then	-- 活动规则
		Option(pUser,NPCName,LANGUAGE_SSJ_0082,LANGUAGE_SSJ_0083)
		pUser:SetCallFun("SelectOption41")
	elseif sel == 6 then	-- 保卫战
		local s = ""
		local h = j.GetHour()
		local m = j.GetMinute()
		if (h == 12 or h == 18) and m < 30 then
			if j.GetBaoWeiZhanBossCurHp() == 0 then
				s = LANGUAGE_SSJ_0091
			else
				s = LANGUAGE_SSJ_0090
			end
		else
			if h < 12 then
				s = LANGUAGE_SSJ_0094
			elseif j.GetBaoWeiZhanBossCurHp() == 0 then
				s = LANGUAGE_SSJ_0095
			else
				s = LANGUAGE_SSJ_0096
			end
		end
		Option(pUser,NPCName,LANGUAGE_SSJ_0086..s,LANGUAGE_SSJ_0087)
		pUser:SetCallFun("SelectOption61")
	end
end

function SelectOption11(pUser,sel)
	if sel == 1 then	-- 交材料
		local s = j.GetHuanLeShengYan_DuiHuanInfo()
		local t = FormatMission(s)
		local item1 = tonumber(t[1])
		local jifen1 = tonumber(t[2])
		local item2 = tonumber(t[3])
		local jifen2 = tonumber(t[4])
		local duihuanjf = pUser:GetItemNum(item1)*jifen1 + pUser:GetItemNum(item2)*jifen2
		Option(pUser,NPCName,LANGUAGE_SSJ_0076..duihuanjf..LANGUAGE_SSJ_0077,LANGUAGE_SSJ_0078)
		pUser:SetCallFun("SelectOption12")
	elseif sel == 2 then
		NpcMain(pUser,0)
	end
end

function SelectOption12(pUser,sel)
	if sel == 1 then
		local s = j.GetHuanLeShengYan_DuiHuanInfo()
		local t = FormatMission(s)
		local item1 = tonumber(t[1])
		local jifen1 = tonumber(t[2])
		local item2 = tonumber(t[3])
		local jifen2 = tonumber(t[4])
		local item1num = pUser:GetItemNum(item1)
		local item2num = pUser:GetItemNum(item2)
		local duihuanjf = item1num*jifen1 + item2num*jifen2
		pUser:DelPackageById(item1,item1num)
		pUser:DelPackageById(item2,item2num)
		pUser:SetExtData32(434,pUser:GetExtData32(434)+item1num)
		pUser:SetExtData32(435,pUser:GetExtData32(435)+item2num)
		pUser:SetExtData32(436,pUser:GetExtData32(436)+duihuanjf)
		j.UpdateHuanLeShengYan_PaiHangList(pUser,pUser:GetExtData32(436))
		j.AddHDHuanLeShengYanJiFen(pUser,duihuanjf)
		j.SendSysInfo(pUser,LANGUAGE_SSJ_0079)
		NpcMainSel(pUser,1)
	else
		NpcMainSel(pUser,1)
	end
end

function SelectOption21(pUser,sel)
	if sel == 1 then
		if j.HuanLeShengYan_LiBaoDesc(pUser,NPCName) then
			pUser:SetCallFun("SelectOption22")
		else
			CloseInteract(pUser)
		end
	elseif sel == 2 then	-- 礼包领取
		j.HuanLeShengYan_SendLiBao(pUser)
		NpcMainSel(pUser,2)
	elseif sel == 3 then	-- 返回
		NpcMain(pUser,0)
	end
end

function SelectOption22(pUser,sel)
	if sel == 1 then
		NpcMainSel(pUser,2)
	end
end

function SelectOption31(pUser,sel)
	if sel == 1 then	-- 积分排行
		j.ShowHuanLeShengYan_PaiHang(pUser)
	elseif sel == 2 then	-- 排行奖励
		j.ShowHuanLeShengYan_AwardList(pUser)
	elseif sel == 3 then	-- 返回
		NpcMain(pUser,0)
	end
end

function SelectOption41(pUser,sel)
	if sel == 1 then
		NpcMain(pUser,0)
	end
end

function SelectOption61(pUser,sel)
	if sel == 1 then	-- 击杀
		local h = j.GetHour()
		local m = j.GetMinute()
		if (h == 12 or h == 18) and m <= 30 then	-- 活动时间内
			if j.GetBaoWeiZhanBossCurHp() == 0 then	--已击杀
				Option(pUser,NPCName,LANGUAGE_SSJ_0093,LANGUAGE_SSJ_0089)
				pUser:SetCallFun("SelectOption62")
			else	-- 活动开始
				local curTime = os.time()
				local lastTime = pUser:GetExtData32(434)
				if lastTime > 0 and curTime >= lastTime and (curTime - lastTime < 5*60) then
					local time = 5*60 - (curTime - lastTime)
					local smin = math.floor(time/60)
					local ssec = time%60
					if smin > 0 then
						Option(pUser,NPCName,LANGUAGE_SSJ_0088..smin..LANGUAGE_SSJ_0106..ssec..LANGUAGE_SSJ_0107,LANGUAGE_SSJ_0089)
					else
						Option(pUser,NPCName,LANGUAGE_SSJ_0088..ssec..LANGUAGE_SSJ_0107,LANGUAGE_SSJ_0089)
					end
					pUser:SetCallFun("SelectOption62")
					return
				end
				j.BaoWeiZhanFight(pUser)
			end
		else	-- 未开始
			Option(pUser,NPCName,LANGUAGE_SSJ_0092,LANGUAGE_SSJ_0089)
			pUser:SetCallFun("SelectOption62")
		end
	elseif sel == 2 then
		NpcMain(pUser,0)
	end
end

function SelectOption62(pUser,sel)
	if sel == 1 then
		NpcMainSel(pUser,6)
	end
end

function MissionBannerCallBack0(pUser,missionId)
	--AddMison
	--Call剧情Dialog
	if missionId==1 then

	end
end

function MissionBannerCallBack1(pUser,missionId)
	--DelMison
	--AddAward
	if missionId==1 then


	end
end

function GetState(pUser)
	return 0
end

function GetChatMsg(pUser)
	return NPC_HEAD_NONE
end