--169.lua--种植商人
---------------------------------------
require "global"

Dialog = j.Dialog       --对话
Option =j.Option        --对话选项
OptionConfirm = j.OptionConfirm
SMessage = j.SMessage   --弹出提示
SendSysInfo = j.SendSysInfo --Tips
CloseInteract = j.CloseInteract --结束交互
--add by zhudaolong
SeedList1={1207,1209,1203,1211,1201,1210,1205,1212}
SeedList2={1207,1209,1203,1211,1201,1210,1205,1212,1213}

thisId = 169
NPCName = nil

------------------------------------------
--以下为脚本部分：
------------------------------------------
function NpcMain(pUser,missionId)
	if NPCName == nil then
		NPCName = j.GetNpcName(thisId)
	end
	local s
	local lv

--add by zhudaolong
	SeedList = IsInHuoDong(80)
--	if j.GetSceneBang(pUser) ~= pUser:GetBangPai() then
--		Dialog(pUser,"种植商人","非本帮人员请速速离开。")
--		return
--	end

	j.SellSeedItem(pUser,table.concat(SeedList,"|"))
	pUser:SetCallFun("Trade")
end

function Trade(pUser,sell,idx,num)
--add by zhudaolong
	SeedList = IsInHuoDong(80)
	if num == nil then
		return
	end
	if num <= 0 then
		SendSysInfo(pUser,LANGUAGE_TRANSFORM_1425)
		pUser:SetCallFun("Trade")
		return
	end
	if sell==0 then
		local id = SeedList[idx+1]
		local it=j.GetSeedItem(id)
		local need = it.price*num
		
--		if it.priceType == 1 then	-- 金币
--			OptionConfirm(pUser,NPCName,LANGUAGE_TRANSFORM_1426..GONGGAO_BLUE.."]"..need..LANGUAGE_TRANSFORM_1427..GONGGAO_BLUE.."]"..num..LANGUAGE_TRANSFORM_1428..j.GetItemName(id)..LANGUAGE_TRANSFORM_1429,LANGUAGE_TRANSFORM_1430)
--		elseif it.priceType == 2 then	-- 元宝
--			OptionConfirm(pUser,NPCName,LANGUAGE_TRANSFORM_1431..GONGGAO_BLUE.."]"..need..LANGUAGE_TRANSFORM_1432..GONGGAO_BLUE.."]"..num..LANGUAGE_TRANSFORM_1433..j.GetItemName(id)..LANGUAGE_TRANSFORM_1434,LANGUAGE_TRANSFORM_1435)
--		end
		
		pUser:SetVal(1,idx)
		pUser:SetVal(2,num)
		BuyItem(pUser,1)
--		pUser:SetCallFun("BuyItem")
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
			SendSysInfo(pUser,LANGUAGE_TRANSFORM_1436)
			pUser:SetCallFun("Trade")
			return
		end

		item=j.GetItem(pitem.tmplId)
		if item.type==17 or item.type==18 or type==23 then
			SendSysInfo(pUser,LANGUAGE_TRANSFORM_1437)
			pUser:SetCallFun("Trade")
			return
		end
		if item.type <= 5 or (item.type >= 31 and item.type <= 52) then
			SendSysInfo(pUser,LANGUAGE_TRANSFORM_1438)
			pUser:SetCallFun("Trade")
			return
		end

		money=GetSellCost(pitem,num,item)

		pUser:SetVal(1,idx);
		pUser:SetVal(2,num);
		OptionConfirm(pUser,NPCName,item.name:c_str()..LANGUAGE_TRANSFORM_1439..money,LANGUAGE_TRANSFORM_1440)
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
--add by zhudaolong
	SeedList = IsInHuoDong(80)

	if sel==1 then
		idx=pUser:GetVal(1)
		num=pUser:GetVal(2)
		id = SeedList[idx+1]
		it=j.GetSeedItem(id)
		
		if it.priceType == 1 then	-- 金币
			money=pUser:GetMoney()
			need=it.price*num
			if money < need then
				SendSysInfo(pUser,LANGUAGE_TRANSFORM_1441);
				pUser:SetCallFun("Trade")
				return
			end
			pUser:AddBangDingPackage(id,num)
			pUser:AddMoney(-need)
			SendSysInfo(pUser,LANGUAGE_TRANSFORM_1442)
			pUser:SetCallFun("Trade")
		elseif it.priceType == 2 then	-- 元宝
			money=pUser:GetTongBao()
			
			need=it.price*num
			
			if money < need then
				SendSysInfo(pUser,LANGUAGE_TRANSFORM_1443);
				pUser:SetCallFun("Trade")
				return
			end
			pUser:AddBangDingPackage(id,num)
			pUser:AddTongBao(-need)
			SendSysInfo(pUser,LANGUAGE_TRANSFORM_1444)
			pUser:SetCallFun("Trade")
			
			j.SaveBuyShopItem(pUser:GetRoleId(),id,num,0,need,pUser:GetTongBao(),121)
		end
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
		SendSysInfo(pUser,LANGUAGE_TRANSFORM_1445)
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
	return NPC_HEAD_SEED
end

--add by zhudaolong
function IsInHuoDong(hd_type)
--	if j.InHuoDongTime(hd_type) then
--		return SeedList2
--	else
		return SeedList1
--	end
end
