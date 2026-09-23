--7.lua--锻造大使 id=7
---------------------------------------
require "global"

Dialog = j.Dialog       --对话
Option =j.Option        --对话选项
OptionConfirm = j.OptionConfirm --二层交互的确认框
SMessage = j.SMessage   --弹出提示
SendSysInfo = j.SendSysInfo --Tips
CloseInteract = j.CloseInteract --结束交互
MissionBanner = j.MissionBanner
ShowGuidance = j.ShowGuidance
DialogS_Start = j.DialogS_Start --剧情对话开始
DialogS_Doing = j.DialogS_Doing --剧情对话过程
DialogS_End = j.DialogS_End --剧情对话结束

Weapon={201,202,203,204,205,206,207,1,2,3,4,5,6,7,51,52,53,54,55,56,57,}

thisId = 7
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
	
	Dialog(pUser,LANGUAGE_TRANSFORM_4783,LANGUAGE_TRANSFORM_4784)
end

function DoSelect(pUser,input)
	if input==1 then
		j.SellItem(pUser,1,table.concat(Weapon,"|"))
		pUser:SetCallFun("Trade")
	elseif input==2 then
		CloseInteract(pUser)
	end
end

function Trade(pUser,sell,idx,num)
	if sell==0 then
		local id = Weapon[idx+1]
		local it=j.GetItem(id)
		OptionConfirm(pUser,LANGUAGE_TRANSFORM_4785,LANGUAGE_TRANSFORM_4786..GONGGAO_BLUE.."]"..it.jiage..LANGUAGE_TRANSFORM_4787..it.name:c_str()..LANGUAGE_TRANSFORM_4788,LANGUAGE_TRANSFORM_4789)
		
		pUser:SetVal(1,idx)
		pUser:SetCallFun("BuyItem")
		return
		--j.SellItem(pUser,1,table.concat(Weapon,"|"))
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
			--Dialog(pUser,"锻造大使","锁定物品不能卖店")
			SendSysInfo(pUser,LANGUAGE_TRANSFORM_4790)
			pUser:SetCallFun("Trade")
			return
		end
		item=j.GetItem(pitem.tmplId)
		if item.type==17 or item.type==18 or type==23 then
			SendSysInfo(pUser,LANGUAGE_TRANSFORM_4791)
			pUser:SetCallFun("Trade")
			return
		end
		if item.type <= 5 or (item.type >= 31 and item.type <= 52) then
			SendSysInfo(pUser,LANGUAGE_TRANSFORM_4792)
			pUser:SetCallFun("Trade")
			return
		end
		
		money=GetSellCost(pitem,num,item)
		pUser:SetVal(1,idx);
		pUser:SetVal(2,num);
		OptionConfirm(pUser,LANGUAGE_TRANSFORM_4793,item.name:c_str()..LANGUAGE_TRANSFORM_4794..money,LANGUAGE_TRANSFORM_4795)
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
	local money

	if sel==1 then
		idx=pUser:GetVal(1)
		id = Weapon[idx+1]
		it=j.GetItem(id)
		money=pUser:GetMoney()

		if money<it.jiage then
			SendSysInfo(pUser,LANGUAGE_TRANSFORM_4796);
			pUser:SetCallFun("Trade")
			return
		end
		pUser:AddBangDingPackage(id)
		money=money-it.jiage
		pUser:SetMoney(money)
		SendSysInfo(pUser,LANGUAGE_TRANSFORM_4797)
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
			j.CloseInteract(pUser);
			return;
		end
		if num<1 or pitem.num<num then
			j.CloseInteract(pUser);
			return;
		end    
		item=j.GetItem(pitem.tmplId)
		money=GetSellCost(pitem,num,item)
		if pitem.tmplId==632 then
			pUser:AddCurrency(money)
		else	
			pUser:AddMoney(money)
		end
			
		pUser:SaveSellItem(t,num)
		pUser:DelPackage(t,num)
		SendSysInfo(pUser,LANGUAGE_TRANSFORM_4798)
		pUser:SetCallFun("Trade")
		return
	end
	CloseInteract(pUser)
	pUser:SetCallFun("Trade")
end

function GetState(pUser)
	return 0
end

function GetChatMsg(pUser)
	return NPC_HEAD_NONE
end

