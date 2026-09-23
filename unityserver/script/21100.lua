--21100.lua--百花礼盒
-------------------------
require "global"
Dialog = j.Dialog       --对话
Option =j.Option        --对话选项
SMessage = j.SMessage   --弹出提示
CloseInteract=j.CloseInteract
SendSysInfo = j.SendSysInfo

-----------------------------
---           十连抽券,幻化丹
ITEM_LIMIT_NUM = {}
ITEM_DRAW_NUM = {0,0}
G_DAY = 0

SHOW_ITEM_MAX_NUM = 8

-- type 1物品,2经验，3潜能，4金币
Award_Item_List = 
{
--			ratio,type=1,itemId,num,gonggao 1show
--			ratio,type=2,3, value

	[1] = {1770,4,5000,1,0},		-- 金币5000
	[2] = {2948,4,7500,1,0},		-- 金币7500
	[3] = {3833,4,10000,1,0},	-- 金币10000
	[4] = {4718,1,836,1,0},	-- 高级神将内丹
	[5] = {4859,1,837,1,1},	-- 特级神将内丹
	[6] = {6275,1,2377,1,1},	-- 低级招募券
	[7] = {6275,1,2380,1,1},	-- 中级招募券
	[8] = {6275,1,2382,1,1},	-- 高级招募券
	[9] = {8045,1,613,1,0},	-- 灵石	
	[10] = {9814,1,614,1,0},	-- 魄石
	[11] = {9991,1,1817,1,0},-- 低级天书
	[12] = {10000,1,1818,1,1},-- 高级天书
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

	local serverType = j.GetServerType()
	local serverId = pUser:GetServerId()
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
						userMsg = LANGUAGE_TRANSFORM_294..name.."*1[/c]"
						j.SaveDate(pUser,12,851,"")
					else
						ITEM_DRAW_NUM[index] = ITEM_DRAW_NUM[index]+1
						addItemId = Award_Item_List[i][3]
						addItemNum = Award_Item_List[i][4]
						
--						pUser:AddPackage(Award_Item_List[i][3],Award_Item_List[i][4])
						name = j.GetItemName(Award_Item_List[i][3])
						userMsg = LANGUAGE_TRANSFORM_295..name.."*"..Award_Item_List[i][4].."[/c]"
						if Award_Item_List[i][5] == 1 then
							pUser:PushGongGao("[c"..ROLE_NAME_COLOR.."]"..pUser:GetName()..LANGUAGE_TRANSFORM_296..ITEM_NAME_COLOR..LANGUAGE_TRANSFORM_297..ITEM_NAME_COLOR.."]"..name.."*"..Award_Item_List[i][4].."[/c]")
						end
						j.SaveDate(pUser,12,Award_Item_List[i][3],"")
					end
				elseif Award_Item_List[i][2] == 2 then	-- 经验
					pUser:AddExp(Award_Item_List[i][3])
					local worldExpPer = GetWorldExpPercent(pUser)
					local ratio = j.GetMonthCardExpRatio(pUser) / 100
					if worldExpPer > 0 then
						userMsg = LANGUAGE_TRANSFORM_298..math.floor(Award_Item_List[i][3]*ratio)..LANGUAGE_TRANSFORM_299..worldExpPer..LANGUAGE_TRANSFORM_300
					else
						userMsg = LANGUAGE_TRANSFORM_301..math.floor(Award_Item_List[i][3]*ratio)..LANGUAGE_TRANSFORM_302
					end
					
					j.SaveDate(pUser,12,20000,"")
				elseif Award_Item_List[i][2] == 3 then	-- 潜能
					pUser:AddQianNeng(Award_Item_List[i][3])
					userMsg = LANGUAGE_TRANSFORM_303..Award_Item_List[i][3]..LANGUAGE_TRANSFORM_304
					j.SaveDate(pUser,12,30000,"")
				elseif Award_Item_List[i][2] == 4 then	-- 金币
					pUser:AddMoney(Award_Item_List[i][3])
					userMsg = LANGUAGE_TRANSFORM_305..Award_Item_List[i][3]..LANGUAGE_TRANSFORM_306
					j.SaveDate(pUser,12,40000,"")
				end
			else	-- 一般物品
				if Award_Item_List[i][2] == 1 then	-- 物品
					addItemId = Award_Item_List[i][3]
					addItemNum = Award_Item_List[i][4]

--					pUser:AddPackage(Award_Item_List[i][3],Award_Item_List[i][4])
					name = j.GetItemName(Award_Item_List[i][3])
					userMsg = LANGUAGE_TRANSFORM_307..name.."*"..Award_Item_List[i][4].."[/c]"
					if Award_Item_List[i][5] == 1 then
						pUser:PushGongGao("[c"..ROLE_NAME_COLOR.."]"..pUser:GetName()..LANGUAGE_TRANSFORM_308..ITEM_NAME_COLOR..LANGUAGE_TRANSFORM_309..ITEM_NAME_COLOR.."]"..name.."*"..Award_Item_List[i][4].."[/c]")
					end
					j.SaveDate(pUser,12,Award_Item_List[i][3],"")
				elseif Award_Item_List[i][2] == 2 then	-- 经验
					pUser:AddExp(Award_Item_List[i][3])
					local worldExpPer = GetWorldExpPercent(pUser)
					local ratio = j.GetMonthCardExpRatio(pUser) / 100
					if worldExpPer > 0 then
						userMsg = LANGUAGE_TRANSFORM_310..math.floor(Award_Item_List[i][3]*ratio)..LANGUAGE_TRANSFORM_299..worldExpPer..LANGUAGE_TRANSFORM_300
					else
						userMsg = LANGUAGE_TRANSFORM_313..math.floor(Award_Item_List[i][3]*ratio)..LANGUAGE_TRANSFORM_314
					end
					
					j.SaveDate(pUser,12,20000,"")
				elseif Award_Item_List[i][2] == 3 then	-- 潜能
					pUser:AddQianNeng(Award_Item_List[i][3])
					userMsg = LANGUAGE_TRANSFORM_315..Award_Item_List[i][3]..LANGUAGE_TRANSFORM_316
					j.SaveDate(pUser,12,30000,"")
				elseif Award_Item_List[i][2] == 4 then	-- 金币
					pUser:AddMoney(Award_Item_List[i][3])
					userMsg = LANGUAGE_TRANSFORM_317..Award_Item_List[i][3]..LANGUAGE_TRANSFORM_318
					j.SaveDate(pUser,12,40000,"")
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
		userMsg = LANGUAGE_TRANSFORM_319..name.."*"..Award_Item_List[1][4].."[/c]"
		j.SaveDate(pUser,12,Award_Item_List[1][3],"")
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


