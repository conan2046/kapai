--2.lua--活动大使 id=2
---------------------------------------
require "global"
require "30000"

Dialog = j.Dialog       --对话
Option =j.Option        --对话选项
SMessage = j.SMessage   --弹出提示
SendSysInfo = j.SendSysInfo --Tips
CloseInteract = j.CloseInteract --结束交互
MissionBanner = j.MissionBanner --新版任务面板接取模式
OptionConfirm = j.OptionConfirm
Dialog_End = j.Dialog_End       
SMessage_End = j.SMessage_End   

thisId = 2
NPCName = nil

------------------------------------------
--以下为脚本部分：
------------------------------------------
function NpcMain(pUser, missionId)
	if NPCName == nil then
		NPCName = j.GetNpcName(thisId)
	end
--	local serverType = j.GetServerType()
--	local serverId = pUser:GetServerId()

	local info = GetShaDiDuoBaoOption(pUser)
	if string.len(info) > 1 then
		Option(pUser,NPCName, LANGUAGE_TRANSFORM_325, info)
		pUser:SetCallFun("DoOption")
	else
--		j.UpdateNpcState(pUser, thisId, 0)
		Dialog(pUser,NPCName,LANGUAGE_TRANSFORM_326)
	end
end

function GetMissionsOptInfo(pUser)
	local s
	local lv
	local info=""
	local name
	local t

	lv=pUser:GetLevel()

	if lv>=30 then
		info = info..LANGUAGE_TRANSFORM_327
	end
	return info
end

function GetShaDiDuoBaoOption(pUser)
	local lv = pUser:GetLevel()
	local info = "" 
	if lv >= j.GetCMissionAcceptLevel(MISSION_ID_DUOBAO) then
		info = info..LANGUAGE_TRANSFORM_327
	end
	return info
	
end 

-- 神将数量|1金币2绑元|数量
PET_TASK = {
	"5|1500",
	"10|3000",
	"15|6000",
	"20|9000",
	"30|15000",
}

-- 神将数量|金币|1绑元2元宝|元宝数
JieBiao_TASK = {
	"3|200|1|5",
	"6|400|1|10",
	"9|600|1|15",
	"12|800|1|20",
	"18|1000|2|30",
}

function DoOption(pUser, sel)
	local s
	local t
	local serverType = j.GetServerType()
	if sel == 5 then
		-- 玩家选择杀敌夺宝
		if not DodayCanDoShaDiDuoBaoMission(pUser) then
			j.UpdateNpcState(pUser,thisId, 0)
			Dialog(pUser, NPCName,"你已经完成今天的杀敌取宝任务，请明天再来。")
			return
		end
		
		if pUser:HaveCMission(MISSION_ID_DUOBAO) then
			if not pUser:IsCMissionFinished(MISSION_ID_DUOBAO) then 
				j.UpdateNpcState(pUser,thisId, 2)
				Dialog(pUser,NPCName,"完成任务再来!")
				return
			else
				FinishShaDiDuoBao(pUser)
				if DodayCanDoShaDiDuoBaoMission(pUser) then
					AcceptShaDiDuoBao(pUser)
					j.UpdateNpcState(pUser,thisId, 2)
				else
					j.SendSysInfoFightEnd(pUser,LANGUAGE_ZQX_0019)
					j.ChangeClientGuaJiState(pUser, 2)
					-- j.SendYinDaoNPCPos(pUser,11,-1,-1,-1)
				end
				return
			end
		else
			AcceptShaDiDuoBao(pUser)
			if DodayCanDoShaDiDuoBaoMission(pUser) then
				j.UpdateNpcState(pUser,thisId, 2)
			else
				j.UpdateNpcState(pUser,thisId, 0)
			end
			return
		end
		

		--MissionBanner(pUser,BANNER_TYPE_ACCETP,MISSION_ID_DUOBAO)
		--pUser:SetCallFun("MissionBannerCallBack0")
	elseif sel==12 then		-- 押镖
		if not pUser:HaveBitSet(594) then
			Option(pUser,NPCName,LANGUAGE_SSJ_0069,LANGUAGE_SSJ_0070)
			pUser:SetCallFun("YaYunBiaoCheFunc")
		else
			YaYunBiaoChe(pUser,1)
		end
	elseif sel == 13 then
		if pUser:HaveBitSet(1019) then
			Dialog(pUser,NPCName,LANGUAGE_TRANSFORM_328)
			return
		end
		pUser:SetBitSet(1019)
		pUser:AddTongBao(25,1)
		pUser:AddBangDingPackage(1100,1)
		pUser:AddBangDingPackage(1100,1)
		pUser:AddBangDingPackage(1100,1)
		Dialog(pUser,NPCName,LANGUAGE_TRANSFORM_329..j.GetItemName(1100)..LANGUAGE_TRANSFORM_330)
	elseif sel == 14 then
		local day = j.GetDay()
		if j.GetMonth()+1 == 5 and day <= 25 then
			local bitset = 1008
			if day >= 16 then
				bitset = 1011 + day - 16
			end
			if pUser:HaveBitSet(bitset) then
				Dialog(pUser,NPCName,LANGUAGE_TRANSFORM_331)
			else
				pUser:SetBitSet(bitset)
				pUser:AddTongBao(2000,0)
				Dialog(pUser,NPCName,LANGUAGE_TRANSFORM_332)
			end
		else
			Dialog(pUser,NPCName,LANGUAGE_TRANSFORM_333..day..LANGUAGE_TRANSFORM_334)
		end
	elseif sel == 15 then
		Dialog(pUser,NPCName,LANGUAGE_TRANSFORM_335..(j.GetDay()+1)..LANGUAGE_TRANSFORM_336)
	elseif sel == 17 then
		if j.GetMonth() + 1 == 5 then
			Option(pUser,NPCName,LANGUAGE_TRANSFORM_337,"14|5."..j.GetDay()..LANGUAGE_TRANSFORM_338..(j.GetDay()+1)..LANGUAGE_TRANSFORM_339)
			pUser:SetCallFun("DoOption")
			return
		end
	elseif sel == 18 then
		if pUser:HaveBitSet(1023) then
			Dialog(pUser,NPCName,LANGUAGE_TRANSFORM_340)
		else
			pUser:SetBitSet(1023)
			pUser:AddTongBao(5000,0)
			Dialog(pUser,NPCName,LANGUAGE_TRANSFORM_341)
		end
	elseif sel == 1002 then --至尊豪礼
		if serverType == "qq" and pUser:GetExtData32(14) < 200 then
			Dialog(pUser,NPCName,"感谢您的关注，尽快提升到至尊5即可免费领取该福利！")
			return
		end
	
		if pUser:GetAccountRecordPhone() == 1 then
			Dialog(pUser,NPCName,"您已经填写过QQ号与手机号码，如果需要进行修改，可以添加至尊专属客服QQ：2507897687，尊享更多贴心服务！")
			return
		end	
	
		j.Input2Str(pUser,"2|请输入QQ号|请输入手机号码")
		pUser:SetCallFun("ZhiZhunLiBao")
	end
end

function YaYunBiaoCheFunc(pUser,sel)
	if sel == 1 then
		YaYunBiaoChe(pUser,1)
	elseif sel == 2 then
		CloseInteract(pUser)
	end
end

function ZhiZhunLiBao(pUser,qqNum,phoneNum)
	if(qqNum == nil) or (phoneNum == nil)then
		Dialog(pUser,NPCName,"请输入QQ号或手机号码")
		return
	end
	
	if tonumber(qqNum) == nil or tonumber(phoneNum) == nil then
		Dialog(pUser,NPCName,"请输入正确的QQ号和手机号码")
		return
	end
	
	if j.RecordPhoneInfo(pUser, NPCName, qqNum, phoneNum) then
		local award = {{awardType = 2901, num = 3},{awardType = 2898, num = 3},{awardType = 2386, num = 5},}
		local str = GetZhiZhunAward(pUser,award)
		local context = "恭喜您成功填写QQ号与手机号码，获得至尊专属福利："..str.."\n 添加至尊专属客服QQ：453346760，尊享更多贴心服务！"
		Dialog(pUser,NPCName,context)
	end
end

function GetZhiZhunAward(pUser, award)
	local str = ""
	local num = 0
	for k, v in pairs(award) do
		if num > 0 then
			str = str .. LANGUAGE_TRANSFORM_899
		end
		
		if v.awardType < 60000 then
			pUser:AddBangDingPackage(v.awardType, v.num)
			str = str .. j.GetItemName(v.awardType) .. "*" .. v.num
		elseif v.awardType == 60000 then
			pUser:AddMoney(v.num)
			str = str .. LANGUAGE_TRANSFORM_890 .. v.num
		elseif v.awardType == 60001 then
			pUser:AddTongBao(v.num, 1)
			str = str .. LANGUAGE_TRANSFORM_892 .. v.num
		elseif v.awardType == 60003 then
			pUser:AddTongBao(v.num, 0)
			str = str .. LANGUAGE_TRANSFORM_894 .. v.num
		elseif v.wardType == 60006 then
			pUser:AddExp(v.num)
			str = str .. LANGUAGE_TRANSFORM_896 .. v.num
		elseif v.awardType == 60007 then
			pUser:AddQianNeng(v.num)
			str = str .. LANGUAGE_TRANSFORM_898 .. v.num
		end
		num = num + 1
	end
	
	return str
end

function YaYunBiaoChe(pUser,sel)
	if sel == 1 then
		if pUser:GetLevel() < 25 then
			Dialog(pUser,NPCName,LANGUAGE_TRANSFORM_358)
			return
		end
		if pUser:HaveTeam() then
			Dialog(pUser,NPCName,LANGUAGE_TRANSFORM_359)
			return
		end
		if pUser:GetFightId() > 0 then
			Dialog(pUser,NPCName,LANGUAGE_TRANSFORM_360)
			return
		end
		
		s = pUser:GetMission(213)
		if s==nil then
			if pUser:HaveCMission(105) then
				Dialog(pUser,NPCName,LANGUAGE_TRANSFORM_361)
				return
			end
			if pUser:InTreasure() then
				Dialog(pUser,NPCName,LANGUAGE_TRANSFORM_362)
				return
			end
		
			if pUser:GetExtData8(88)<10 then
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
				
				local serverType = j.GetServerType()
				local completeIndex = 3			-- 完成npc的index(1-6)
				local index = pUser:GetExtData8(88)+1
				local addExp = math.floor(j.GetHuoDongExpWithType(pUser,18,0.1))
				local money = 1500
				addExp = addExp - addExp%1000
				--               1押镖阶段  2品质         3经验 4被抢经验 5第几轮      6完成npc序号      7金币  8被抢金币
				pUser:AddMission(213,"1|"..quality.."|"..addExp.."|0|"..index.."|"..completeIndex.."|"..money.."|0")
				pUser:SetExtData8(89,0)
				pUser:SendYaBiaoMissionState(1,quality)
				pUser:SetExtData8(88,index)
				local state = GetState(pUser)
				j.UpdateNpcState(pUser,thisId,state)
--				Dialog(pUser,NPCName,"成功接取押镖任务。")
				j.SaveDate(pUser, 25, 1,"")

				-- 下坐骑，下跟随宠
				j.SetGenSuiPetDown(pUser)
				j.SetQiPetDown(pUser)
				
				j.ShowYaYunBiaoChePanel(pUser,0,161)
				j.SendChangeYaYunBiaoCheSuccess(pUser,1)
				
				if quality == 4 or (quality == 3 and math.random(1,100) <= 20) then
					j.SysInfoToAllUser("[c"..ROLE_NAME_COLOR.."]"..pUser:GetName()..LANGUAGE_TRANSFORM_363..ITEM_NAME_COLOR.."]"..j.GetSceneName(pUser:GetSceneId())..LANGUAGE_TRANSFORM_364..GongGaoColor[quality][1].."]"..GongGaoColor[quality][2]..LANGUAGE_TRANSFORM_365)
				end
			else
				Dialog(pUser,NPCName,LANGUAGE_TRANSFORM_366)
			end
		else
			j.ShowYaYunBiaoChePanel(pUser,0,161)
		end
	elseif sel == 2 then
		Dialog(pUser,NPCName,LANGUAGE_TRANSFORM_367)
	end
end

function MissionBannerCallBack0(pUser, missionId)
	if missionId==86 then
		pUser:AddMission(86,"0")
		j.UpdateNpcState(pUser,thisId,0)
		j.SaveDate(pUser, 26, 1,"")
		
		local xiang = pUser:GetXiang()
		if xiang == 5 then
			j.SendYinDaoNPCPos(pUser,12,-1,-1,55)
		elseif xiang == 1 then
			j.SendYinDaoNPCPos(pUser,13,-1,-1,56)
		else
			j.SendYinDaoNPCPos(pUser,14,-1,-1,57)
		end
	elseif missionId==91 then
		pUser:AddMission(91,"0")
		return
	elseif missionId == MISSION_ID_DUOBAO then  -- 杀敌夺宝
		--AcceptShaDiDuoBao(pUser)
	end
end

function MissionBannerCallBack1(pUser,missionId)
	local award
	if missionId == 104 then
		local itemInfo = {{2355,1},{2355,2},{2355,3},{2355,4},{2355,5}}
		local s =pUser:GetMission(missionId)
		local t = FormatMission(s)
		local turn = tonumber(t[8])
		local exp = figureMission214Exp(pUser,turn)
		local otherAward = "3,"..itemInfo[turn][1]..",0,0,"..itemInfo[turn][2]..";|"
		award = GetAward(pUser,missionId,true,exp)..otherAward
		pUser:DelCMission(104)
		pUser:DelPackageById(833,-1)
		pUser:AddExp(exp)
		pUser:AddBangDingPackage(itemInfo[turn][1],itemInfo[turn][2])
		--pUser:AddMoney(1000)
		j.UpdateNpcState(pUser,thisId,1)
		j.SendSysInfoRD(pUser,LANGUAGE_SDDB_0002..LANGUAGE_SDDB_0003..award)
	end
end

function DialogTmpl(pUser)
	Dialog(pUser,NPCName,LANGUAGE_TRANSFORM_368)
end

function GetState(pUser)
	local userlv = pUser:GetLevel()
	if userlv < j.GetCMissionAcceptLevel(MISSION_ID_DUOBAO) then
		return 0
	end

    if not pUser:HaveCMission(MISSION_ID_DUOBAO) then
    	if DodayCanDoShaDiDuoBaoMission(pUser) then
            return 1  -- 可接
        end
	else
        if pUser:IsCMissionFinished(MISSION_ID_DUOBAO) then
            return 3 -- 完成
        else
            return 2 -- 未完成
		end
    end
	return 0 
end

-- ---------------------------------------------
-- 夺宝任务战斗结束后在c++调用
function NotifyRes(pUser,mid,num) 
	if pUser:HaveCMission(MISSION_ID_DUOBAO) then 
		VerifyShaDiDuoBaoMission(pUser,mid,num)
	end 
end

function AutoTransportUser(pUser,nextSceneId)
end

function GetChatMsg(pUser)
	return NPC_HEAD_NONE
end

function FinishShaDiDuoBao(pUser)
	j.UpdateNpcState(pUser, thisId, 1)
	pUser:DelCMission(MISSION_ID_DUOBAO)

	local turn = pUser:GetExtData16(39)+1
	pUser:SetExtData16(39,turn)
		
	local itemInfo = {{2355,1},{2355,2},{2355,3},{2355,4},{2355,5}}
	local exp = figureMission214Exp(pUser,turn)
	pUser:DelPackageById(833,-1)
	pUser:AddExp(exp, true, true)
	pUser:AddMaterial(itemInfo[turn][1],itemInfo[turn][2], true)
	j.UpdateNpcState(pUser,thisId,1)
	j.UpdateDCMissionComplate(pUser, MISSION_ID_DC_59, 1, MISSION_ID_DUOBAO)
	--j.SendSysInfo(pUser,LANGUAGE_SDDB_0003..j.GetItemName(itemInfo[turn][1]).."*"..itemInfo[turn][2])
	--j.SendSysInfo(pUser,LANGUAGE_SDDB_0003..LANGUAGE_TRANSFORM_140..exp)
end 

function GetShaDiDuoBaoExp(pUser)
	local lv = pUser:GetLevel()
	local curNeedExp=j.GetLvUpExp(lv)
	local exp = 0
	local exp0 = j.GetHuoDongExpWithType(pUser,19,1.0/5)
	exp = math.floor(exp0)
	return exp
end





function VerifyShaDiDuoBaoMission(pUser,mid,num)
	local s
	local n
	local t
	local rate
	local item
	s = j.GetCMissionInts(pUser, MISSION_ID_DUOBAO)
	if s~=nil then
		local memNum = j.GetTeamMemNum(pUser)
		t = FormatMission(s)
		local award = "3,2356,0,0,1;|"
		if tonumber(t[1])~=1 then
			rate = math.floor(tonumber(t[2]) + 10*(memNum-1))
			if rate > 100 then
				rate = 100
			end

			item = tonumber(t[5])
			if math.floor((mid-1)/4)==math.floor((tonumber(t[3])-1)/4) then
				local r = math.random(100)
				n = tonumber(t[7]) + 1
				t[7] = n
				
				if r < rate then
					if not pUser:AddBangDingPackage(item,1) then
						SendSysInfo(pUser,"[c1]背包已满，请及时清理。[/c]")
						return
					end
					j.SendSysInfoRD(pUser,award)
					t[6] = t[6] + 1
				else
					if n >= 5 then
						if not pUser:AddBangDingPackage(item,1) then
							SendSysInfo(pUser,"[c4]背包已满，请及时清理。[/c]")
							return
						end
						j.SendSysInfoRD(pUser,award)
						t[6] = t[6] + 1
						t[7] = 0
					end
				end

				
				if tonumber(t[6])>=tonumber(t[9]) then
					t[1] = 1 -- 任务完成条件的标记 
					pUser:DelPackageById(item, tonumber(t[9]))
					pUser:UpdateCMissionState(MISSION_ID_DUOBAO, 1 ) -- 任务完成
					j.UpdateNpcState(pUser, thisId, 3)
				end
				
				print("NotifyRes GetMission mission = "..table.concat(t, "|"))
				pUser:UpdateCMission(MISSION_ID_DUOBAO,table.concat(t, "|"),"")
				
				if t[1] == 1 then
					DoOption(pUser, 5)
				end
			end
		end
	end
end  

