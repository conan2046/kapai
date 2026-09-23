--21105.lua--锻造礼盒
-------------------------
require "global"
Dialog = j.Dialog       --对话
Option =j.Option        --对话选项
SMessage = j.SMessage   --弹出提示
CloseInteract=j.CloseInteract
SendSysInfo = j.SendSysInfo

-----------------------------
---       2级炼化石,高级幸运符,3级炼化石,4级炼化石
ITEM_LIMIT_NUM = {}
ITEM_DRAW_NUM = {0,0,0,0}
G_DAY = 0

SHOW_ITEM_MAX_NUM = 8

-- type 1物品,2经验，3潜能，4金币
Award_Item_List = 
{
--			ratio,type=1,itemId,num,gonggao 1show
--			ratio,type=2,3, value

	[1] = {1817,4,5000,1,0},	-- 金币5000	
	[2] = {3028,4,7500,1,0},		-- 金币7500
	[3] = {4845,4,10000,1,0},		-- 金币10000
	[4] = {5209,1,501,1,0},		-- 低级幸运符
	[5] = {5330,1,502,1,1},		-- 中级幸运符
	[6] = {5370,1,503,1,1},		-- 高级幸运符
	[7] = {5976,1,801,1,0},		-- 1级炼化石
	[8] = {6178,1,802,1,0},		-- 2级炼化石
	[9] = {6245,1,803,1,1},			-- 3级炼化石
	[10] = {8062,1,851,1,0},		-- 1级强化石
	[11] = {9879,1,610,1,0},		-- 初级洗炼石
	[12] = {10000,1,2516,1,1},		-- 中级洗炼石
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
	for i=1,#Award_Item_List,1 do
--		ratio = ratio + Award_Item_List[i][1]
		if r <= Award_Item_List[i][1] then
			if i > #Award_Item_List - #ITEM_LIMIT_NUM then	--限制性物品
				if Award_Item_List[i][2] == 1 then	-- 物品
					index = i - (#Award_Item_List - #ITEM_LIMIT_NUM)
					if ITEM_DRAW_NUM[index] >= ITEM_LIMIT_NUM[index] then
						addItemId = 851
						addItemNum = 1

--						pUser:AddPackage(851,1)
						name = j.GetItemName(851)
						userMsg = LANGUAGE_TRANSFORM_1226..name.."*1[/c]"
						j.SaveDate(pUser,13,851,"")
					else
						ITEM_DRAW_NUM[index] = ITEM_DRAW_NUM[index]+1
						addItemId = Award_Item_List[i][3]
						addItemNum = Award_Item_List[i][4]
						
--						pUser:AddPackage(Award_Item_List[i][3],Award_Item_List[i][4])
						name = j.GetItemName(Award_Item_List[i][3])
						userMsg = LANGUAGE_TRANSFORM_1227..name.."*"..Award_Item_List[i][4].."[/c]"
						j.SaveDate(pUser,13,Award_Item_List[i][3],"")
						if Award_Item_List[i][5] == 1 then
							pUser:PushGongGao("[c"..ROLE_NAME_COLOR.."]"..pUser:GetName()..LANGUAGE_TRANSFORM_1228..ITEM_NAME_COLOR..LANGUAGE_TRANSFORM_1229..ITEM_NAME_COLOR.."]"..name.."*"..Award_Item_List[i][4].."[/c]")
						end
						j.SaveDate(pUser,13,Award_Item_List[i][3],"")
					end
				elseif Award_Item_List[i][2] == 2 then	-- 经验
					pUser:AddExp(Award_Item_List[i][3])
					local worldExpPer = GetWorldExpPercent(pUser)
					if worldExpPer > 0 then
						userMsg = LANGUAGE_TRANSFORM_1230..Award_Item_List[i][3]..LANGUAGE_TRANSFORM_1231..worldExpPer..LANGUAGE_TRANSFORM_1232
					else
						userMsg = LANGUAGE_TRANSFORM_1233..Award_Item_List[i][3]..LANGUAGE_TRANSFORM_1234
					end
					
					j.SaveDate(pUser,13,20000,"")
				elseif Award_Item_List[i][2] == 3 then	-- 潜能
					pUser:AddQianNeng(Award_Item_List[i][3])
					userMsg = LANGUAGE_TRANSFORM_1235..Award_Item_List[i][3]..LANGUAGE_TRANSFORM_1236
					j.SaveDate(pUser,13,30000,"")
				elseif Award_Item_List[i][2] == 4 then	-- 金币
					pUser:AddMoney(Award_Item_List[i][3])
					userMsg = LANGUAGE_TRANSFORM_1237..Award_Item_List[i][3]..LANGUAGE_TRANSFORM_1238
					j.SaveDate(pUser,13,40000,"")
				end
			else	-- 一般物品
				if Award_Item_List[i][2] == 1 then	-- 物品
					addItemId = Award_Item_List[i][3]
					addItemNum = Award_Item_List[i][4]

--					pUser:AddPackage(Award_Item_List[i][3],Award_Item_List[i][4])
					name = j.GetItemName(Award_Item_List[i][3])
					userMsg = LANGUAGE_TRANSFORM_1239..name.."*"..Award_Item_List[i][4].."[/c]"
					if Award_Item_List[i][5] == 1 then
						pUser:PushGongGao("[c"..ROLE_NAME_COLOR.."]"..pUser:GetName()..LANGUAGE_TRANSFORM_1240..ITEM_NAME_COLOR..LANGUAGE_TRANSFORM_1241..ITEM_NAME_COLOR.."]"..name.."*"..Award_Item_List[i][4].."[/c]")
					end
					j.SaveDate(pUser,13,Award_Item_List[i][3],"")
				elseif Award_Item_List[i][2] == 2 then	-- 经验
					pUser:AddExp(Award_Item_List[i][3])
					local worldExpPer = GetWorldExpPercent(pUser)
					if worldExpPer > 0 then
						userMsg = LANGUAGE_TRANSFORM_1242..Award_Item_List[i][3]..LANGUAGE_TRANSFORM_1231..worldExpPer..LANGUAGE_TRANSFORM_1232
					else
						userMsg = LANGUAGE_TRANSFORM_1245..Award_Item_List[i][3]..LANGUAGE_TRANSFORM_1246
					end
					j.SaveDate(pUser,13,20000,"")
				elseif Award_Item_List[i][2] == 3 then	-- 潜能
					pUser:AddQianNeng(Award_Item_List[i][3])
					userMsg = LANGUAGE_TRANSFORM_1247..Award_Item_List[i][3]..LANGUAGE_TRANSFORM_1248
					j.SaveDate(pUser,13,30000,"")
				elseif Award_Item_List[i][2] == 4 then	-- 金币
					pUser:AddMoney(Award_Item_List[i][3])
					userMsg = LANGUAGE_TRANSFORM_1249..Award_Item_List[i][3]..LANGUAGE_TRANSFORM_1250
					j.SaveDate(pUser,13,40000,"")
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
		userMsg = LANGUAGE_TRANSFORM_1251..name.."*"..Award_Item_List[1][4].."[/c]"
		j.SaveDate(pUser,13,Award_Item_List[1][3],"")
	end
	
	local s = j.GetRandomSequence(#Award_Item_List)
	local seq = FormatMission(s)
	local count = 1
	for i=1,#Award_Item_List,1 do
		local idx = tonumber(seq[i])
		if idx ~= awardId then
			count = count+1
			showMsg = showMsg..Award_Item_List[idx][2]..","..Award_Item_List[idx][3]..","..Award_Item_List[idx][4].."|"
			if count >= SHOW_ITEM_MAX_NUM then
				break
			end
		end
	end
	j.ShowBaiHuaAwardPanel(pUser,showMsg,userMsg)
	
	if addItemId > 0 then
		pUser:AddPackage(addItemId,addItemNum)
	end
end



