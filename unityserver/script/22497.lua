--22497.lua--真金白银豪华礼盒(玩家)
-------------------------
require "global"
Dialog = j.Dialog       --对话
Option =j.Option        --对话选项
SMessage = j.SMessage   --弹出提示
CloseInteract=j.CloseInteract
SendSysInfo = j.SendSysInfo

-----------------------------
ITEM_LIMIT_NUM = {}
ITEM_DRAW_NUM = {}
G_DAY = 0
SHOW_ITEM_MAX_NUM = 8

-- type 1物品,2经验，3潜能，4金币
Award_Item_List_1 = 
{
--			ratio,type=1,itemId,num,gonggao 1show
--			ratio,type=2,3, value

	[1] = {4405,4,1000,1,0},		-- 金币1000
	[2] = {6607,4,2000,1,0},		-- 金币2000
	[3] = {7488,4,5000,1,0},	-- 金币5000
	[4] = {7928,1,836,1,0},	-- 高级神将内丹
	[5] = {7999,1,837,1,1},	-- 特级神将内丹
	[6] = {8087,1,2377,1,1},	-- 低级招募券
	[7] = {8146,1,2380,1,1},	-- 中级招募券
	[8] = {8190,1,2382,1,1},	-- 高级招募券
	[9] = {9071,1,613,1,0},	-- 灵石	
	[10] = {9952,1,614,1,0},	-- 魄石
	[11] = {9996,1,1817,1,0},-- 低级天书
	[12] = {10000,1,1818,1,1},-- 高级天书	  	
}

Award_Item_List_Taiwan = 
{
--			ratio,type=1,itemId,num,gonggao 1show
--			ratio,type=2,3, value

	[1] = {1110,1,852,1,0},				-- 2级强化宝石*1   
	[2] = {2890,1,507,1,0},       -- 中级装备升阶石*1
	[3] = {4000,1,2370,5,0},      -- 进化丹*5        
	[4] = {5110,1,614,5,0},       -- 魄石*5          
	[5] = {6220,1,613,5,0},       -- 灵石*5          
	[6] = {7330,1,801,1,0},       -- 1级炼化石*1     
	[7] = {7687,1,802,1,0},       -- 2级炼化石*1     
	[8] = {7807,1,803,1,1},       -- 3级炼化石*1     
	[9] = {8917,1,2370,2,0},      -- 神将进化丹
	[10] = {9807,1,502,1,0},      -- 中级幸运符      
	[11] = {9985,1,503,1,1},      -- 高级幸运符      
	[12] = {9995,1,2386,1,1},     -- 金币大礼包
	[13] = {10000,1,2576,1,1},    -- 大额金币大礼包
	[14] = {10000,1,2386,1,1},    -- 金币大礼包
	[15] = {10000,1,2386,1,1},    -- 金币大礼包
	[16] = {10000,1,2386,1,1},    -- 金币大礼包
	[17] = {10000,1,2386,1,1},    -- 金币大礼包
	[18] = {10000,1,2386,1,1},    -- 金币大礼包
}


function Main(pUser,pos,num)
	pItem=pUser:GetItem(pos)
	if pItem==nil then
		return
	end
	if G_DAY ~= j.GetDay() then
		G_DAY = j.GetDay()
		for i=1,#ITEM_DRAW_NUM,1 do
			ITEM_DRAW_NUM[i] = 0
		end
	end
	
	pUser:DelPackage(pos)
	
	local addItemId = 0
	local addItemNum = 0
	local awardId = 0
	local r=math.random(10000)
	local name
	local ratio = 0
	local showMsg = ""
	local userMsg = ""
	local Award_Item_List
	local stype = j.GetServerType()
	if stype == "taiwan" or stype == "hanban" then
		Award_Item_List = Award_Item_List_Taiwan
	else
		Award_Item_List = Award_Item_List_1
	end
	
	for i=1,#Award_Item_List,1 do
		if r <= Award_Item_List[i][1] then
			if i > #Award_Item_List - #ITEM_LIMIT_NUM then	--限制性物品
				if Award_Item_List[i][2] == 1 then	-- 物品
					index = i - (#Award_Item_List - #ITEM_LIMIT_NUM)
					if ITEM_DRAW_NUM[index] >= ITEM_LIMIT_NUM[index] then
						addItemId = 851
						addItemNum = 1
					
--					pUser:AddPackage(851,1)
						name = j.GetItemName(851)
						userMsg = LANGUAGE_TRANSFORM_4560..name.."*1[/c]"
						j.SaveDate(pUser,20,851,"")
					else
						ITEM_DRAW_NUM[index] = ITEM_DRAW_NUM[index]+1
						addItemId = Award_Item_List[i][3]
						addItemNum = Award_Item_List[i][4]
						
--					pUser:AddPackage(Award_Item_List[i][3],Award_Item_List[i][4])
						name = j.GetItemName(Award_Item_List[i][3])
						userMsg = LANGUAGE_TRANSFORM_4561..name.."*"..Award_Item_List[i][4].."[/c]"
						j.SaveDate(pUser,20,Award_Item_List[i][3],"")
						if Award_Item_List[i][5] == 1 then
							pUser:PushGongGao("[c"..ROLE_NAME_COLOR.."]"..pUser:GetName()..LANGUAGE_TRANSFORM_4562..ITEM_NAME_COLOR..LANGUAGE_TRANSFORM_4563..ITEM_NAME_COLOR.."]"..name.."*"..Award_Item_List[i][4].."[/c]")
						end
						j.SaveDate(pUser,20,Award_Item_List[i][3],"")
					end
				elseif Award_Item_List[i][2] == 2 then	-- 经验
					pUser:AddExp(Award_Item_List[i][3])
					local worldExpPer = GetWorldExpPercent(pUser)
					if worldExpPer > 0 then
						userMsg = LANGUAGE_TRANSFORM_4564..Award_Item_List[i][3]..LANGUAGE_TRANSFORM_4565..worldExpPer..LANGUAGE_TRANSFORM_4566	
					else
						userMsg = LANGUAGE_TRANSFORM_4567..Award_Item_List[i][3]..LANGUAGE_TRANSFORM_4568		
					end
					
					j.SaveDate(pUser,20,20000,"")
				elseif Award_Item_List[i][2] == 3 then	-- 潜能
					pUser:AddQianNeng(Award_Item_List[i][3])
					userMsg = LANGUAGE_TRANSFORM_4569..Award_Item_List[i][3]..LANGUAGE_TRANSFORM_4570
					j.SaveDate(pUser,20,30000,"")
				elseif Award_Item_List[i][2] == 4 then	-- 金币
					pUser:AddMoney(Award_Item_List[i][3])
					userMsg = LANGUAGE_TRANSFORM_4571..Award_Item_List[i][3]..LANGUAGE_TRANSFORM_4572
					j.SaveDate(pUser,20,40000,"")
				end
			else	-- 一般物品
				if Award_Item_List[i][2] == 1 then	-- 物品
					addItemId = Award_Item_List[i][3]
					addItemNum = Award_Item_List[i][4]
					
--				pUser:AddPackage(Award_Item_List[i][3],Award_Item_List[i][4])
					name = j.GetItemName(Award_Item_List[i][3])
					userMsg = LANGUAGE_TRANSFORM_4573..name.."*"..Award_Item_List[i][4].."[/c]"
					if Award_Item_List[i][5] == 1 then
						pUser:PushGongGao("[c"..ROLE_NAME_COLOR.."]"..pUser:GetName()..LANGUAGE_TRANSFORM_4574..ITEM_NAME_COLOR..LANGUAGE_TRANSFORM_4575..ITEM_NAME_COLOR.."]"..name.."*"..Award_Item_List[i][4].."[/c]")
					end
					j.SaveDate(pUser,20,Award_Item_List[i][3],"")
				elseif Award_Item_List[i][2] == 2 then	-- 经验
					pUser:AddExp(Award_Item_List[i][3])
					local worldExpPer = GetWorldExpPercent(pUser)
					if worldExpPer > 0 then
						userMsg = LANGUAGE_TRANSFORM_4576..Award_Item_List[i][3]..LANGUAGE_TRANSFORM_4565..worldExpPer..LANGUAGE_TRANSFORM_4566	
					else
						userMsg = LANGUAGE_TRANSFORM_4579..Award_Item_List[i][3]..LANGUAGE_TRANSFORM_4580		
					end

					j.SaveDate(pUser,20,20000,"")
				elseif Award_Item_List[i][2] == 3 then	-- 潜能
					pUser:AddQianNeng(Award_Item_List[i][3])
					userMsg = LANGUAGE_TRANSFORM_4581..Award_Item_List[i][3]..LANGUAGE_TRANSFORM_4582
					j.SaveDate(pUser,20,30000,"")
				elseif Award_Item_List[i][2] == 4 then	-- 金币
					pUser:AddMoney(Award_Item_List[i][3])
					userMsg = LANGUAGE_TRANSFORM_4583..Award_Item_List[i][3]..LANGUAGE_TRANSFORM_4584
					j.SaveDate(pUser,20,40000,"")
				end
			end
			
			showMsg = showMsg..Award_Item_List[i][2]..","..Award_Item_List[i][3]..","..Award_Item_List[i][4].."|"
			awardId = i
			break
		end
	end
	
	if awardId == 0 then
		awardId = 1
		showMsg = showMsg..Award_Item_List[1][2]..","..Award_Item_List[1][3]..","..Award_Item_List[1][4].."|"
		
		pUser:AddPackage(Award_Item_List[1][3],Award_Item_List[1][4])
		name = j.GetItemName(Award_Item_List[1][3])
		userMsg = LANGUAGE_TRANSFORM_4585..name.."*"..Award_Item_List[1][4].."[/c]"
		j.SaveDate(pUser,20,Award_Item_List[1][3],"")
	end
	
	local s = j.GetRandomSequence(#Award_Item_List)
	local seq = FormatMission(s)
	local count = 1
	for i=1,#seq,1 do
		local idx = tonumber(seq[i])
		if idx ~= awardId then
			count = count+1
			showMsg = showMsg..Award_Item_List[idx][2]..","..Award_Item_List[idx][3]..","..Award_Item_List[idx][4].."|"
			if count >= SHOW_ITEM_MAX_NUM - 1 then
				break
			end
		end
	end

	--[[if stype == "taiwan" or stype == "hanban" then
		showMsg = showMsg.."1,2370,5|1,502,1|1,503,1|"
	else
		showMsg = showMsg.."1,2494,1|1,2495,1|1,2496,1|"
	end}
	--]]
	j.ShowBaiHuaAwardPanel(pUser,showMsg,userMsg)
	
	if addItemId > 0 then
		pUser:AddBangDingPackage(addItemId,addItemNum)
	end
end


