--22549.lua--白银宝箱
-------------------------
require "global"
Dialog = j.Dialog       --对话
Option =j.Option        --对话选项
SMessage = j.SMessage   --弹出提示
CloseInteract=j.CloseInteract
SendSysInfo = j.SendSysInfo

G_DAY = 0


--钥匙道具ID
KEY_ITEM_ID = 2553;
--宝箱道具ID
BOX_ITEM_ID = 2549;

REWAED_MONEY = 60000		-- 金币
REWARD_BD_YUANBAO = 60001	-- 绑元
REWARD_PET = 60002			--神将
REWARD_YUANBAO = 60003		--元宝
REWARD_EXP = 60004			--经验
REWARD_QIANNENG = 60005		--潜能

ARRY_ID =1
ARRY_NUM = 2
ARRY_PetLevel = 3
ARRY_PetStar = 4
ARRY_NOTICE = 5
ARRY_PET_NUM = 6


function Main(pUser,pos,num)
	
	
	if G_DAY ~= j.GetDay() then
		G_DAY = j.GetDay()
		j.clearRandomBoxSaveLimit()
	end

	pItem=pUser:GetItem(pos)
	if pItem == nil or num > 200 then
		return
	end


	keyNum = pUser:GetItemNum(KEY_ITEM_ID)
	boxNum = pItem.num;

	--删除当前pos的物品.........检查需求的钥匙数目	
	if keyNum < num  then  --钥匙道具数量不足
		j.SendSysInfo(pUser,LANGUAGE_TRANSFORM_1746..j.GetItemName(KEY_ITEM_ID)..LANGUAGE_TRANSFORM_1747)
		return
	elseif boxNum < num then  --宝箱道具数量不足
		j.SendSysInfo(pUser,LANGUAGE_TRANSFORM_1748)
		return
	end

	--扣除宝箱和钥匙道具
	pUser:DelPackageById(KEY_ITEM_ID,num)
	pUser:DelPackage(pos,num)

	
	reward ={} --奖励数组 seq type,id,num,notice
	local size = 0
	local isIn = 0
	for counter = 1 ,num, 1 do
		isIn = 0
		local reward_id = 0
		local reward_num = 0
		local reward_quality = 0
		local reward_quality_level = 0
		local reward_notice = 0
		local reward_pet_num = 0;
		local key = j.doRandomByRandomBoxCfg(BOX_ITEM_ID)	
		reward_id = j.getRandomBoxCfg(key,"id")
		if reward_id ==  REWARD_PET then
			reward_pet_num = 1
		end
		reward_num = j.getRandomBoxCfg(key,"num")
		reward_notice = j.getRandomBoxCfg(key,"notice")
		reward_petLevel = j.getRandomBoxCfg(key,"quality")
		reward_petStar = j.getRandomBoxCfg(key,"quality_level")
		isIn = 0	
		for reward_counter=1,#reward,1 do
		
			if reward_id ~= REWARD_PET and reward[reward_counter][ARRY_ID] == reward_id  then
				reward[reward_counter][ARRY_NUM] = reward[reward_counter][ARRY_NUM] + reward_num 
				isIn = 1
			end
		end -- end of for reward
		if isIn == 0 then
			reward[size+1]={reward_id ,reward_num,reward_petLevel ,reward_petStar,reward_notice,reward_pet_num}
			size = size + 1
		end
	end --end of for num




	--发送最后奖励
	
	for count =1  ,#reward,1 do
		if reward[count][ARRY_ID] < 60000 then  --道具
			pUser:AddPackage(reward[count][ARRY_ID],reward[count][ARRY_NUM])
			j.SendSysInfo(pUser,LANGUAGE_TRANSFORM_1749..j.GetItemName(reward[count][ARRY_ID]).."*"..reward[count][ARRY_NUM] .."[/c]")
			j.SaveDate(pUser,702,reward[count][ARRY_ID],LANGUAGE_TRANSFORM_1750) 
			if reward[count][ARRY_NOTICE] ~=0 then
				 j.SysInfoToAllUser("[c"..ROLE_NAME_COLOR.."]"..pUser:GetName()..LANGUAGE_TRANSFORM_1751..ITEM_NAME_COLOR.."]"..j.GetItemName(BOX_ITEM_ID)..LANGUAGE_TRANSFORM_1752..ITEM_NAME_COLOR.."]"..j.GetItemName(reward[count][ARRY_ID]).."*"..reward[count][ARRY_NUM].."[/c]")
				end
		elseif reward[count][ARRY_ID] == REWARD_EXP then -- 经验
			pUser:AddExp(reward[count][ARRY_NUM])
			local worldExpPer = GetWorldExpPercent(pUser)
			if worldExpPer > 0 then
				j.SendSysInfo(pUser,LANGUAGE_TRANSFORM_1753..reward[count][ARRY_NUM]..LANGUAGE_TRANSFORM_1754..worldExpPer ..LANGUAGE_TRANSFORM_1755)
				j.SaveDate(pUser,702,reward[count][ARRY_NUM],LANGUAGE_TRANSFORM_1756)
				if reward[count][ARRY_NOTICE] ~=0 then
					j.SysInfoToAllUser("[c"..ROLE_NAME_COLOR.."]"..pUser:GetName()..LANGUAGE_TRANSFORM_1757..ITEM_NAME_COLOR.."]"..j.GetItemName(BOX_ITEM_ID)..LANGUAGE_TRANSFORM_1758..ITEM_NAME_COLOR.."]"..reward[count][ARRY_NUM]..LANGUAGE_TRANSFORM_1759..blessExp ..LANGUAGE_TRANSFORM_1760)
				end   
			else
				j.SendSysInfo(pUser,LANGUAGE_TRANSFORM_1761..reward[count][ARRY_NUM]..LANGUAGE_TRANSFORM_1762)
				j.SaveDate(pUser,702,reward[count][ARRY_NUM],LANGUAGE_TRANSFORM_1763)
				if reward[count][ARRY_NOTICE] ~=0 then
				j.SysInfoToAllUser("[c"..ROLE_NAME_COLOR.."]"..pUser:GetName()..LANGUAGE_TRANSFORM_1764..ITEM_NAME_COLOR.."]"..j.GetItemName(BOX_ITEM_ID)..LANGUAGE_TRANSFORM_1765..ITEM_NAME_COLOR.."]"..reward[count][ARRY_NUM]..LANGUAGE_TRANSFORM_1766)
				end  
			end
		elseif reward[count][ARRY_ID] == REWARD_QIANNENG then -- 潜能
			pUser:AddQianNeng(reward[count][ARRY_NUM])
			j.SendSysInfo(pUser,LANGUAGE_TRANSFORM_1767..reward[count][ARRY_NUM]..LANGUAGE_TRANSFORM_1768)
			j.SaveDate(pUser,702,reward[count][ARRY_NUM],LANGUAGE_TRANSFORM_1769) 
		elseif reward[count][ARRY_ID] == REWAED_MONEY then --金币
			pUser:AddMoney(reward[count][ARRY_NUM])
			j.SendSysInfo(pUser,LANGUAGE_TRANSFORM_1770..reward[count][ARRY_NUM]..LANGUAGE_TRANSFORM_1771)
			j.SaveDate(pUser,702,reward[count][ARRY_NUM],LANGUAGE_TRANSFORM_1772)
			 if reward[count][ARRY_NOTICE] ~=0 then
			 j.SysInfoToAllUser("[c"..ROLE_NAME_COLOR.."]"..pUser:GetName()..LANGUAGE_TRANSFORM_1773..ITEM_NAME_COLOR.."]"..j.GetItemName(BOX_ITEM_ID)..LANGUAGE_TRANSFORM_1774..ITEM_NAME_COLOR.."]"..reward[count][ARRY_NUM]..LANGUAGE_TRANSFORM_1775)
			 end
		elseif reward[count][ARRY_ID] == REWARD_YUANBAO then --元宝
			pUser:AddTongBao(reward[count][ARRY_NUM])
			j.SendSysInfo(pUser,LANGUAGE_TRANSFORM_1776..reward[count][ARRY_NUM]..LANGUAGE_TRANSFORM_1777)
			j.SaveDate(pUser,702,reward[count][ARRY_NUM],LANGUAGE_TRANSFORM_1778) 
			if reward[count][ARRY_NOTICE] ~=0 then
			j.SysInfoToAllUser("[c"..ROLE_NAME_COLOR.."]"..pUser:GetName()..LANGUAGE_TRANSFORM_1779..ITEM_NAME_COLOR.."]"..j.GetItemName(BOX_ITEM_ID)..LANGUAGE_TRANSFORM_1780..ITEM_NAME_COLOR.."]"..reward[count][ARRY_NUM]..LANGUAGE_TRANSFORM_1781)
			end
		elseif reward[count][ARRY_ID] == REWARD_BD_YUANBAO then --绑元
			pUser:AddTongBao(reward[count][ARRY_NUM],1)
			j.SendSysInfo(pUser,LANGUAGE_TRANSFORM_1782..reward[count][ARRY_NUM]..LANGUAGE_TRANSFORM_1783)
			j.SaveDate(pUser,702,reward[count][ARRY_NUM],LANGUAGE_TRANSFORM_1784)
			if reward[count][ARRY_NOTICE] ~=0 then
			j.SysInfoToAllUser("[c"..ROLE_NAME_COLOR.."]"..pUser:GetName()..LANGUAGE_TRANSFORM_1785..ITEM_NAME_COLOR.."]"..j.GetItemName(BOX_ITEM_ID)..LANGUAGE_TRANSFORM_1786..ITEM_NAME_COLOR.."]"..reward[count][ARRY_NUM]..LANGUAGE_TRANSFORM_1787)
			end
		elseif reward[count][ARRY_ID] == REWARD_PET then --神将
			j.AddPet(pUser,reward[count][ARRY_NUM],reward[count][ARRY_PetLevel],reward[count][ARRY_PetStar],true)
			j.SendSysInfo(pUser,LANGUAGE_TRANSFORM_1788..GongGaoColor[reward[count][ARRY_PetLevel]][1].."]"..j.GetPetName(reward[count][ARRY_NUM]).."[/c]")
			j.SaveDate(pUser,702,reward[count][ARRY_NUM],LANGUAGE_TRANSFORM_1789)
			if reward[count][ARRY_NOTICE] ~=0 then
			j.SysInfoToAllUser("[c"..ROLE_NAME_COLOR.."]"..pUser:GetName()..LANGUAGE_TRANSFORM_1790..ITEM_NAME_COLOR.."]"..j.GetItemName(BOX_ITEM_ID)..LANGUAGE_TRANSFORM_1791..GongGaoColor[reward[count][ARRY_PetLevel]][1].."]"..j.GetPetName(reward[count][ARRY_NUM]).."[/c]")
			end
		end
			
	end

end

