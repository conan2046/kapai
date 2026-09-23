--22551.lua--钻石宝箱
-------------------------
require "global"
Dialog = j.Dialog       --对话
Option =j.Option        --对话选项
SMessage = j.SMessage   --弹出提示
CloseInteract=j.CloseInteract
SendSysInfo = j.SendSysInfo

G_DAY = 0


--钥匙道具ID
KEY_ITEM_ID = 2555;
--宝箱道具ID
BOX_ITEM_ID = 2551;

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
		j.SendSysInfo(pUser,LANGUAGE_TRANSFORM_4719..j.GetItemName(KEY_ITEM_ID)..LANGUAGE_TRANSFORM_4720)
		return
	elseif boxNum < num then  --宝箱道具数量不足
		j.SendSysInfo(pUser,LANGUAGE_TRANSFORM_4721)
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
			j.SendSysInfo(pUser,LANGUAGE_TRANSFORM_4722..j.GetItemName(reward[count][ARRY_ID]).."*"..reward[count][ARRY_NUM] .."[/c]")
			j.SaveDate(pUser,704,reward[count][ARRY_ID],LANGUAGE_TRANSFORM_4723) 
			if reward[count][ARRY_NOTICE] ~=0 then
				 j.SysInfoToAllUser("[c"..ROLE_NAME_COLOR.."]"..pUser:GetName()..LANGUAGE_TRANSFORM_4724..ITEM_NAME_COLOR.."]"..j.GetItemName(BOX_ITEM_ID)..LANGUAGE_TRANSFORM_4725..ITEM_NAME_COLOR.."]"..j.GetItemName(reward[count][ARRY_ID]).."*"..reward[count][ARRY_NUM].."[/c]")
				end
		elseif reward[count][ARRY_ID] == REWARD_EXP then -- 经验
			pUser:AddExp(reward[count][ARRY_NUM])
			local worldExpPer = GetWorldExpPercent(pUser)
			if worldExpPer > 0 then
				j.SendSysInfo(pUser,LANGUAGE_TRANSFORM_4726..reward[count][ARRY_NUM]..LANGUAGE_TRANSFORM_4727..worldExpPer..LANGUAGE_TRANSFORM_4728)
				j.SaveDate(pUser,704,reward[count][ARRY_NUM],LANGUAGE_TRANSFORM_4729)
				if reward[count][ARRY_NOTICE] ~=0 then
					j.SysInfoToAllUser("[c"..ROLE_NAME_COLOR.."]"..pUser:GetName()..LANGUAGE_TRANSFORM_4730..ITEM_NAME_COLOR.."]"..j.GetItemName(BOX_ITEM_ID)..LANGUAGE_TRANSFORM_4731..ITEM_NAME_COLOR.."]"..reward[count][ARRY_NUM]..LANGUAGE_TRANSFORM_4732..blessExp ..LANGUAGE_TRANSFORM_4733)
				end   
			else
				j.SendSysInfo(pUser,LANGUAGE_TRANSFORM_4734..reward[count][ARRY_NUM]..LANGUAGE_TRANSFORM_4735)
				j.SaveDate(pUser,704,reward[count][ARRY_NUM],LANGUAGE_TRANSFORM_4736)
				if reward[count][ARRY_NOTICE] ~=0 then
				j.SysInfoToAllUser("[c"..ROLE_NAME_COLOR.."]"..pUser:GetName()..LANGUAGE_TRANSFORM_4737..ITEM_NAME_COLOR.."]"..j.GetItemName(BOX_ITEM_ID)..LANGUAGE_TRANSFORM_4738..ITEM_NAME_COLOR.."]"..reward[count][ARRY_NUM]..LANGUAGE_TRANSFORM_4739)
				end  
			end
		elseif reward[count][ARRY_ID] == REWARD_QIANNENG then -- 潜能
			pUser:AddQianNeng(reward[count][ARRY_NUM])
			j.SendSysInfo(pUser,LANGUAGE_TRANSFORM_4740..reward[count][ARRY_NUM]..LANGUAGE_TRANSFORM_4741)
			j.SaveDate(pUser,704,reward[count][ARRY_NUM],LANGUAGE_TRANSFORM_4742) 
		elseif reward[count][ARRY_ID] == REWAED_MONEY then --金币
			pUser:AddMoney(reward[count][ARRY_NUM])
			j.SendSysInfo(pUser,LANGUAGE_TRANSFORM_4743..reward[count][ARRY_NUM]..LANGUAGE_TRANSFORM_4744)
			j.SaveDate(pUser,704,reward[count][ARRY_NUM],LANGUAGE_TRANSFORM_4745)
			 if reward[count][ARRY_NOTICE] ~=0 then
			 j.SysInfoToAllUser("[c"..ROLE_NAME_COLOR.."]"..pUser:GetName()..LANGUAGE_TRANSFORM_4746..ITEM_NAME_COLOR.."]"..j.GetItemName(BOX_ITEM_ID)..LANGUAGE_TRANSFORM_4747..ITEM_NAME_COLOR.."]"..reward[count][ARRY_NUM]..LANGUAGE_TRANSFORM_4748)
			 end
		elseif reward[count][ARRY_ID] == REWARD_YUANBAO then --元宝
			pUser:AddTongBao(reward[count][ARRY_NUM])
			j.SendSysInfo(pUser,LANGUAGE_TRANSFORM_4749..reward[count][ARRY_NUM]..LANGUAGE_TRANSFORM_4750)
			j.SaveDate(pUser,704,reward[count][ARRY_NUM],LANGUAGE_TRANSFORM_4751) 
			if reward[count][ARRY_NOTICE] ~=0 then
			j.SysInfoToAllUser("[c"..ROLE_NAME_COLOR.."]"..pUser:GetName()..LANGUAGE_TRANSFORM_4752..ITEM_NAME_COLOR.."]"..j.GetItemName(BOX_ITEM_ID)..LANGUAGE_TRANSFORM_4753..ITEM_NAME_COLOR.."]"..reward[count][ARRY_NUM]..LANGUAGE_TRANSFORM_4754)
			end
		elseif reward[count][ARRY_ID] == REWARD_BD_YUANBAO then --绑元
			pUser:AddTongBao(reward[count][ARRY_NUM],1)
			j.SendSysInfo(pUser,LANGUAGE_TRANSFORM_4755..reward[count][ARRY_NUM]..LANGUAGE_TRANSFORM_4756)
			j.SaveDate(pUser,704,reward[count][ARRY_NUM],LANGUAGE_TRANSFORM_4757)
			if reward[count][ARRY_NOTICE] ~=0 then
			j.SysInfoToAllUser("[c"..ROLE_NAME_COLOR.."]"..pUser:GetName()..LANGUAGE_TRANSFORM_4758..ITEM_NAME_COLOR.."]"..j.GetItemName(BOX_ITEM_ID)..LANGUAGE_TRANSFORM_4759..ITEM_NAME_COLOR.."]"..reward[count][ARRY_NUM]..LANGUAGE_TRANSFORM_4760)
			end
		elseif reward[count][ARRY_ID] == REWARD_PET then --神将
			j.AddPet(pUser,reward[count][ARRY_NUM],reward[count][ARRY_PetLevel],reward[count][ARRY_PetStar],true)
			j.SendSysInfo(pUser,LANGUAGE_TRANSFORM_4761..GongGaoColor[reward[count][ARRY_PetLevel]][1].."]"..j.GetPetName(reward[count][ARRY_NUM]).."[/c]")
			j.SaveDate(pUser,704,reward[count][ARRY_NUM],LANGUAGE_TRANSFORM_4762)
			if reward[count][ARRY_NOTICE] ~=0 then
			j.SysInfoToAllUser("[c"..ROLE_NAME_COLOR.."]"..pUser:GetName()..LANGUAGE_TRANSFORM_4763..ITEM_NAME_COLOR.."]"..j.GetItemName(BOX_ITEM_ID)..LANGUAGE_TRANSFORM_4764..GongGaoColor[reward[count][ARRY_PetLevel]][1].."]"..j.GetPetName(reward[count][ARRY_NUM]).."[/c]")
			end
		end
			
	end

end

