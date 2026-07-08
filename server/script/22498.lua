--22498.lua--真金白银豪华礼盒(内部)
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
Award_Item_List = 
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
		if r <= Award_Item_List[i][1] then
			if i > #Award_Item_List - #ITEM_LIMIT_NUM then	--限制性物品
				if Award_Item_List[i][2] == 1 then	-- 物品
					index = i - (#Award_Item_List - #ITEM_LIMIT_NUM)
					if ITEM_DRAW_NUM[index] >= ITEM_LIMIT_NUM[index] then
						addItemId = 851
						addItemNum = 1
						
--						pUser:AddPackage(851,1)
						name = j.GetItemName(851)
						userMsg = LANGUAGE_TRANSFORM_4646..name.."*1[/c]"
						j.SaveDate(pUser,20,851,"")
					else
						ITEM_DRAW_NUM[index] = ITEM_DRAW_NUM[index]+1
						addItemId = Award_Item_List[i][3]
						addItemNum = Award_Item_List[i][4]
						
--						pUser:AddPackage(Award_Item_List[i][3],Award_Item_List[i][4])
						name = j.GetItemName(Award_Item_List[i][3])
						userMsg = LANGUAGE_TRANSFORM_4647..name.."*"..Award_Item_List[i][4].."[/c]"
						j.SaveDate(pUser,20,Award_Item_List[i][3],"")
						if Award_Item_List[i][5] == 1 then
							pUser:PushGongGao("[c"..ROLE_NAME_COLOR.."]"..pUser:GetName()..LANGUAGE_TRANSFORM_4648..ITEM_NAME_COLOR..LANGUAGE_TRANSFORM_4649..ITEM_NAME_COLOR.."]"..name.."*"..Award_Item_List[i][4].."[/c]")
						end
						j.SaveDate(pUser,20,Award_Item_List[i][3],"")
					end
				elseif Award_Item_List[i][2] == 2 then	-- 经验
					pUser:AddExp(Award_Item_List[i][3])
					local worldExpPer = GetWorldExpPercent(pUser)
					if worldExpPer > 0 then
						userMsg = LANGUAGE_TRANSFORM_4650..Award_Item_List[i][3]..LANGUAGE_TRANSFORM_4651..worldExpPer..LANGUAGE_TRANSFORM_4652
					else
						userMsg = LANGUAGE_TRANSFORM_4653..Award_Item_List[i][3]..LANGUAGE_TRANSFORM_4654
					end

					j.SaveDate(pUser,20,20000,"")
				elseif Award_Item_List[i][2] == 3 then	-- 潜能
					pUser:AddQianNeng(Award_Item_List[i][3])
					userMsg = LANGUAGE_TRANSFORM_4655..Award_Item_List[i][3]..LANGUAGE_TRANSFORM_4656
					j.SaveDate(pUser,20,30000,"")
				elseif Award_Item_List[i][2] == 4 then	-- 金币
					pUser:AddMoney(Award_Item_List[i][3])
					userMsg = LANGUAGE_TRANSFORM_4657..Award_Item_List[i][3]..LANGUAGE_TRANSFORM_4658
					j.SaveDate(pUser,20,40000,"")
				end
			else	-- 一般物品
				if Award_Item_List[i][2] == 1 then	-- 物品
					addItemId = Award_Item_List[i][3]
					addItemNum = Award_Item_List[i][4]

--					pUser:AddPackage(Award_Item_List[i][3],Award_Item_List[i][4])
					name = j.GetItemName(Award_Item_List[i][3])
					userMsg = LANGUAGE_TRANSFORM_4659..name.."*"..Award_Item_List[i][4].."[/c]"
					if Award_Item_List[i][5] == 1 then
						pUser:PushGongGao("[c"..ROLE_NAME_COLOR.."]"..pUser:GetName()..LANGUAGE_TRANSFORM_4660..ITEM_NAME_COLOR..LANGUAGE_TRANSFORM_4661..ITEM_NAME_COLOR.."]"..name.."*"..Award_Item_List[i][4].."[/c]")
					end
					j.SaveDate(pUser,20,Award_Item_List[i][3],"")
				elseif Award_Item_List[i][2] == 2 then	-- 经验
					pUser:AddExp(Award_Item_List[i][3])
					local worldExpPer = GetWorldExpPercent(pUser)
					if worldExpPer > 0 then
						userMsg = LANGUAGE_TRANSFORM_4662..Award_Item_List[i][3]..LANGUAGE_TRANSFORM_4651..worldExpPer..LANGUAGE_TRANSFORM_4652
					else
						userMsg = LANGUAGE_TRANSFORM_4665..Award_Item_List[i][3]..LANGUAGE_TRANSFORM_4666
					end

					j.SaveDate(pUser,20,20000,"")
				elseif Award_Item_List[i][2] == 3 then	-- 潜能
					pUser:AddQianNeng(Award_Item_List[i][3])
					userMsg = LANGUAGE_TRANSFORM_4667..Award_Item_List[i][3]..LANGUAGE_TRANSFORM_4668
					j.SaveDate(pUser,20,30000,"")
				elseif Award_Item_List[i][2] == 4 then	-- 金币
					pUser:AddMoney(Award_Item_List[i][3])
					userMsg = LANGUAGE_TRANSFORM_4669..Award_Item_List[i][3]..LANGUAGE_TRANSFORM_4670
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
		userMsg = LANGUAGE_TRANSFORM_4671..name.."*"..Award_Item_List[1][4].."[/c]"
		j.SaveDate(pUser,20,Award_Item_List[1][3],"")
	end
	
	local s = j.GetRandomSequence(8)
	local seq = FormatMission(s)
	local count = 1
	for i=1,#seq,1 do
		local idx = tonumber(seq[i])+10
		if idx ~= awardId then
			count = count+1
			showMsg = showMsg..Award_Item_List[idx][2]..","..Award_Item_List[idx][3]..","..Award_Item_List[idx][4].."|"
		end
	end
	
	j.ShowBaiHuaAwardPanel(pUser,showMsg,userMsg)
	
	if addItemId > 0 then
		pUser:AddBangDingPackage(addItemId,addItemNum)
	end
end


