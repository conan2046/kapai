--9.lua--药店老板
---------------------------------------
require "global"

Dialog = j.Dialog       --对话
Option =j.Option        --对话选项
OptionConfirm = j.OptionConfirm
SMessage = j.SMessage   --弹出提示
SendSysInfo = j.SendSysInfo --Tips
CloseInteract = j.CloseInteract --结束交互
Yaopin={651,652,653,654,834,835}

thisId = 9
NPCName = nil

------------------------------------------
--以下为脚本部分：
------------------------------------------
function NpcMain(pUser,missionId)
	if NPCName == nil then
		NPCName = j.GetNpcName(thisId)
	end
	if HaveLetter(pUser,NPCName,thisId, missionId) then
		return
	end

	--Dialog(pUser,NPCName,"百年老店，远近闻名！客官，买点药备着吧！")

	-- Option(pUser,NPCName,"百年老店，远近闻名！客官，买点药备着吧！","1|交易|2|离开")
	-- pUser:SetCallFun("DoSelect")

	--要求做成交互直接打开界面
	local selectId = 0
	local num = 1
	if missionId ~= 0 then
		if pUser:HaveCMission(missionId) then
			local s=j.GetCMissionInts(pUser,missionId)
			if string.len(s) == 0 then
				print("9.lua NpcMain(pUser) error !  roleId="..pUser:GetRoleId())
				return
			end
			local t=FormatMission(s)
			if tonumber(t[1]) == 2 then
				selectId = tonumber(t[2])
			end
			num = tonumber(t[3])
			pUser:SetExtData8(618, missionId)
		end
	end
	
	j.SellItem(pUser,3,table.concat(Yaopin,"|"),selectId, num)
	pUser:SetCallFun("Trade")
end

function DoSelect(pUser,input)
	if input==1 then
		j.SellItem(pUser,3,table.concat(Yaopin,"|"))
		pUser:SetCallFun("Trade")
	-- elseif input==2 then
	-- 	j.OpenPackage(pUser,1);
	-- 	pUser:SetCallFun("SellItem")
	elseif input==2 then
		CloseInteract(pUser)
	end
end


function Trade(pUser,sell,idx,num)
	if num == nil then
		return
	end
	if num <= 0 then
		SendSysInfo(pUser,LANGUAGE_TRANSFORM_1334)
		pUser:SetCallFun("Trade")
		return
	end
	if sell==0 then
		local id = Yaopin[idx+1]
		local it=j.GetItem(id)
		local need = it.jiage*num
		--OptionConfirm(pUser,NPCName,LANGUAGE_TRANSFORM_1335..GONGGAO_BLUE.."]"..need..LANGUAGE_TRANSFORM_1336..GONGGAO_BLUE.."]"..num..LANGUAGE_TRANSFORM_1337..it.name:c_str()..LANGUAGE_TRANSFORM_1338,LANGUAGE_TRANSFORM_1339)
	
		pUser:SetVal(1,idx)
		pUser:SetVal(2,num)
		BuyItem(pUser,1)
		return
	elseif sell==1 then
		local item
		local pitem
		local money

		pitem=pUser:GetItem(idx)

		if pitem==nil then
			j.CloseInteract(pUser)
			pUser:SetCallFun("Trade")
			return
		end

		if pitem:IsLock() then
			SendSysInfo(pUser,LANGUAGE_TRANSFORM_1340)
			pUser:SetCallFun("Trade")
			return
		end

		item=j.GetItem(pitem.tmplId)
		if item.type==17 or item.type==18 or type==23 then
			SendSysInfo(pUser,LANGUAGE_TRANSFORM_1341)
			pUser:SetCallFun("Trade")
			return
		end
		if item.type <= 5 or (item.type >= 31 and item.type <= 52) then
			SendSysInfo(pUser,LANGUAGE_TRANSFORM_1342)
			pUser:SetCallFun("Trade")
			return
		end

		money=GetSellCost(pitem,num,item)

		pUser:SetVal(1,idx);
		pUser:SetVal(2,num);
		OptionConfirm(pUser,NPCName,item.name:c_str()..LANGUAGE_TRANSFORM_1343..money,LANGUAGE_TRANSFORM_1344)
		pUser:SetCallFun("SellItem")
		return
	end
	--为了某些二层界面返回到当前界面的回调
	pUser:SetCallFun("Trade")
end

function BuyItem(pUser,sel)
	local idx
	local id
	local it
	local num
	local money
	local need

	if sel==1 then
		idx=pUser:GetVal(1)
		num=pUser:GetVal(2)
		id = Yaopin[idx+1]
		it=j.GetItem(id)
		money=pUser:GetMoney()
		need=it.jiage*num
		if money<need then
			SendSysInfo(pUser,LANGUAGE_TRANSFORM_1345);
			pUser:SetCallFun("Trade")
			return
		end
		local ocup = math.floor(num/20)
		pUser:AddBangDingPackage(id,num)
		-- money=money-need
		-- pUser:SetMoney(money)
		pUser:AddMoney(-need)
		SendSysInfo(pUser,LANGUAGE_TRANSFORM_1346)
		j.UpdateDCMissionComplate(pUser, MISSION_ID_DC_61, id,num)
--		local mid = pUser:GetExtData8(618)
		
		if pUser:IsCMissionFinished(MISSION_ID_SHIMEN) then
			j.SendYinDaoNPCPos(pUser, 11, -1, -1, 19)
			return
		end

		if pUser:IsCMissionFinished(MISSION_ID_ZHOUSHIMEN) then
			j.SendYinDaoNPCPos(pUser, 11, -1, -1, ZHOU_SHI_MEN_NPCID)
			return
		end
		
		pUser:SetCallFun("Trade")
		return
	end
	CloseInteract(pUser)
	pUser:SetCallFun("Trade")
end

function SellItem(pUser,sel)
	local t
	local num

	if sel==1 then
		t=pUser:GetVal(1)
		num=pUser:GetVal(2)
		pitem=pUser:GetItem(t)
		if pitem==nil then
			CloseInteract(pUser)
			return
		end
		if num<1 or pitem.num<num then
			CloseInteract(pUser)
			return
		end    
		item=j.GetItem(pitem.tmplId)
		money=GetSellCost(pitem,num,item)
		if (pitem.tmplId==632) and (not pitem:IsBangDing()) then
			pUser:AddCurrency(money)
		else	
			pUser:AddMoney(money)
		end
		pUser:SaveSellItem(t,num)
		pUser:DelPackage(t,num)
		SendSysInfo(pUser,LANGUAGE_TRANSFORM_1347)
		pUser:SetCallFun("Trade")
		return
	end
	CloseInteract(pUser)
	pUser:SetCallFun("Trade")
end


function GetState(pUser)
	local s 
	
	return 0
end

function GetChatMsg(pUser)
	return NPC_HEAD_NONE
end

