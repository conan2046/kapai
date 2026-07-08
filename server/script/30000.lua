-- 30000.lua
-- 积分任务、跑环任务功能脚本
---------------------------------------
require "global"

Dialog = j.Dialog       --对话
Option =j.Option        --对话选项
OptionConfirm = j.OptionConfirm
SendSysInfo = j.SendSysInfo
SMessage = j.SMessage   --弹出提示
CloseInteract = j.CloseInteract --结束交互
MissionBanner = j.MissionBanner --新版任务面板接取模式
Dialog_End = j.Dialog_End       
SMessage_End = j.SMessage_End

------------------------------------------
function FormatMission(s)
	local t = {}
	local i = 1

	for w in string.gmatch(s, "([^|]+)") do
		t[i] = w
		i = i + 1
	end
	return t
end
------------------------------------------
--以下为脚本部分：
------------------------------------------
function NpcMain(pUser)


end

---Mission Id  200,201,202 : 积分任务    203,304,205 :跑环任务

difficult = {1,2,3,4}			--{"简单","普通","中等","困难"}
needLevel = {30,45,60,70,80}
recommendLevel = {36,41,46,51,56,61,66,71,76,81,86,91}
--monsterId = {34,37,38,40,41}
monsterId = {
{605, 410, 310, 304},
{311, 107, 309, 211},
{801, 508, 409, 705},
}
monsterName = {
{LANGUAGE_ZQX_0005, LANGUAGE_ZQX_0006, LANGUAGE_ZQX_0007, LANGUAGE_ZQX_0008},
{LANGUAGE_ZQX_0009, LANGUAGE_ZQX_0010, LANGUAGE_ZQX_0011, LANGUAGE_ZQX_0012},
{LANGUAGE_ZQX_0013, LANGUAGE_ZQX_0014, LANGUAGE_ZQX_0015, LANGUAGE_ZQX_0016},
}
TaskExpRatio = {0.60000000,0.64000000,0.67982113,0.70523985,0.72560884,0.74268746,0.75744046,0.77045676,0.78212350,0.79270937,
								0.80240883,0.81136733,0.81969665,0.82748461,0.83480153,0.84170460,0.84824102,0.85445021,0.86036543,0.86601501,
								0.87142331,0.87661142,0.88159773,0.88639836,0.89102756,0.89549794,0.89982076,0.90400609,0.90806299,0.91199963,
								0.91582341,0.91954106,0.92315870,0.92668194,0.93011591,0.93346532,0.93673453,0.93992754,0.94304808,0.94609957,
								0.94908522,0.95200800,0.95487069,0.95767588,0.96042600,0.96312330,0.96576992,0.96836787,0.97091902,0.97342515,
								0.97588793,0.97830893,0.98068965,0.98303150,0.98533582,0.98760387,0.98983686,0.99203593,0.99420217,0.99633661}

ItemAward = {
-- id*10+star    itemId,itemNum
[11] =  {2251,4},
[12] =  {2251,4},
[13] =  {2251,5},
[21] =  {2251,5},
[22] =  {2251,5},
[23] =  {2251,6},
[31] =  {2251,6},
[32] =  {2251,6},
[33] =  {2251,7},
[41] =  {2251,7},
[42] =  {2251,7},
[43] =  {2251,8},
[51] =  {2251,8},
[52] =  {2251,8},
[53] =  {2251,9},
[61] =  {2251,9},
[62] =  {2251,9},
[63] =  {2251,10},
[71] =  {2251,10},
[72] =  {2251,10},
[73] =  {2251,11},
[81] =  {2251,11},
[82] =  {2251,11},
[83] =  {2251,12},
[91] =  {2251,12},
[92] =  {2251,12},
[93] =  {2251,13},
[101] = {2251,13},
[102] = {2251,13},
[103] = {2251,14},
[111] = {2251,14},
[112] = {2251,14},
[113] = {2251,15},
[121] = {2251,15},
[122] = {2251,15},
[123] = {2251,16},
}
								
								
function GetRingMissionInfo(pUser,type)
	local saveStr
	local s
	local info=""
	local lv = pUser:GetLevel()

	-- int MakeDailyBossInfo(CUser *pUser,int type,int sid,int x,int y,const char *str)
	-- int UpdateDailyBossInfo(CUser *pUser,int type,int sid,int x,int y,const char *str)

	local bossStarInfo = pUser:GetBossMissionStarInfo()
	local bossStar = FormatMission(bossStarInfo)
		
	-- index,星级，难度，怪ID，经验,描述

	for i=0,2,1 do
		for k=1,4,1 do
			local exp = j.GetDailyBossExp((i*4+k - 1)*3 + 1)
			info = info..(i*4+k).."|"..bossStar[i*4+k].."|"..difficult[k].."|"..monsterId[i+1][k].."|"..exp.."|"..ItemAward[(i*4+k)*10+1][1].."|"..ItemAward[(i*4+k)*10+1][2].."|"
			local h = i*4+k
			if h == 1 then
				info = info.." |1| |1|"
			else
				if lv >= needLevel[i+1] then
					info = info..LANGUAGE_TRANSFORM_1797..needLevel[i+1]..LANGUAGE_TRANSFORM_1798
				else
					info = info..LANGUAGE_TRANSFORM_1799..needLevel[i+1]..LANGUAGE_TRANSFORM_1800
				end
				if tonumber(bossStar[h-1]) >= 3 then
					info = info..LANGUAGE_TRANSFORM_1801
				else
					info = info..LANGUAGE_TRANSFORM_1802
				end
			end
			info = info..monsterName[i+1][k].."|"..recommendLevel[i*4+k]
			
			if i ~= 2 or k ~= 4 then
				info=info.."|"
			end
		end
	end
	
	j.MakeDailyBossInfo(pUser,type,0,0,0,info)
end


-- 201:  finish|monsterId|sid|x|y|index
--			finish 0 未完成 1完成
-- res 0 失败 1 胜利

function RingTask_FightEnd(pUser,res,turn,index)
	local s
	local t
--	local StarTurn = {0,8,6}
	local StarTurn = {0,6,3}
	if res== 1 then		--success	
			local exp0 = 0      -- = j.GetHuoDongExpWithType(pUser,16)
			local star = 0
			if turn <= StarTurn[3] then
				star = 3
			elseif turn <= StarTurn[2] then
				star = 2
			else
				star = 1
			end
			
			exp0 = j.GetDailyBossExp((index-1)*3+star)
			
			if not pUser:HaveBitSet(336) then
				pUser:SetBitSet(336)
				if  star >= 2 then
					j.SysInfoToAllUser("[c"..ROLE_NAME_COLOR.."]"..pUser:GetName()..LANGUAGE_TRANSFORM_1803..StarTurn[star]..LANGUAGE_TRANSFORM_1804..star..LANGUAGE_TRANSFORM_1805,true)
				end
			end
--[[
			if not pUser:HaveBitSet(225) then
				if index>1 or (index==1 and star==3) then
					s = pUser:GetMission(225)
					if s ~= nil and tonumber(s) == 0 then
						pUser:UpdateMission(225,"2")
						j.UpdateNpcState(pUser,17,3)
					end
				end
			end
--]]			
			pUser:AddExpByItemWithTips(exp0,true)
			if pUser:GetExtData16(44) == j.GetYDay() then
				pUser:SetExtData8(74,pUser:GetExtData8(74)+1)
			end
			
			local itemIdx = index*10 + star
			local itemId = 0
			local itemNum = 0
			if ItemAward[itemIdx] ~= nil then
				itemId = ItemAward[itemIdx][1]
				itemNum = ItemAward[itemIdx][2]
				pUser:AddMaterial(itemId,itemNum,true)
			end
			
			-- 增加的星星数
			local bossStarInfo = pUser:GetBossMissionStarInfo()
			local bossStar = FormatMission(bossStarInfo)
			local addStar = star - bossStar[index]
			if addStar < 0 then
				addStar = 0
			end
			
			pUser:SetBossMissionData(index,star)
			pUser:CheckMissionHuoYueDu()
			j.ShowDailyBossFightEnd(pUser,star,exp0,index,1,addStar,itemId,itemNum)
			
			local maxStar = pUser:GetBossMissionStarNum(index)
			if maxStar > star then
				star = maxStar
			end
			local lv = pUser:GetLevel()
			local res1 = ""
			local res2 = ""
			local flag1 = 0
			local flag2 = 0
			local nextIndex = index+1
			if nextIndex > 1 and nextIndex <= 20 then
				if lv >= needLevel[math.floor((nextIndex-1)/4) + 1] then
					res1 = LANGUAGE_TRANSFORM_1806..needLevel[math.floor((nextIndex-1)/4) + 1]..LANGUAGE_CHY_160
					flag1 = 1
				else
					res1 = LANGUAGE_TRANSFORM_1807..needLevel[math.floor((nextIndex-1)/4) + 1]..LANGUAGE_CHY_161
					flag1 = 0
				end
				if star >= 3 then
					res2 = LANGUAGE_TRANSFORM_1808
					flag2 = 1
				else
					res2 = LANGUAGE_TRANSFORM_1809
					flag2 = 0
				end
			end
			j.UpdateDailyBossInfo(pUser,index,star,res1,flag1,res2,flag2)
--[[
			if pUser:GetMission(223) ~= nil then
				pUser:UpdateMission(223,"2|1")
				j.UpdateNpcState(pUser,GetMasterId(pUser),3)
			end
--]]
			j.SendDailyBossShowIconInfo(pUser)

--[[			
			local info221 = pUser:GetMission(221)
			if info221 ~= nil then
				if pUser:GetBossMissionTotolStarNum() >= 3 then
					if tonumber(info221) ~= 2 then
						pUser:UpdateMission(221,"2")
						j.UpdateNpcState(pUser,GetMasterId(pUser),3)
					end
				end
			end
--]]
	else
--	j.ShowDailyBossFightEnd(pUser,0,0,index,1)
	end
end

function GetRingTaskItemStr(index)
	if index < 1 or index > 20 then
		return ""
	end

	--   itemId,itemNum
	local itemId = {{851,1},{851,2},{851,3},{501,1},{501,2},{501,3},{502,1},{502,2},{502,3},{503,1}}
	--	random 1-100000
	local itemRatio = 
				{{81600,8000,3000,3000,1500,1000,1000,500,300,100},
				{79925,9000,3100,3100,1600,1100,1100,575,350,150},
				{78250,10000,3200,3200,1700,1200,1200,650,400,200},
				{76575,11000,3300,3300,1800,1300,1300,725,450,250},
				{74900,12000,3400,3400,1900,1400,1400,800,500,300},
				{73225,13000,3500,3500,2000,1500,1500,875,550,350},
				{71550,14000,3600,3600,2100,1600,1600,950,600,400},
				{69875,15000,3700,3700,2200,1700,1700,1025,650,450},
				{68200,16000,3800,3800,2300,1800,1800,1100,700,500},
				{66525,17000,3900,3900,2400,1900,1900,1175,750,550},
				{64850,18000,4000,4000,2500,2000,2000,1250,800,600},
				{63175,19000,4100,4100,2600,2100,2100,1325,850,650},
				{61500,20000,4200,4200,2700,2200,2200,1400,900,700},
				{59825,21000,4300,4300,2800,2300,2300,1475,950,750},
				{58150,22000,4400,4400,2900,2400,2400,1550,1000,800},
				{56475,23000,4500,4500,3000,2500,2500,1625,1050,850},
				{54800,24000,4600,4600,3100,2600,2600,1700,1100,900},
				{53125,25000,4700,4700,3200,2700,2700,1775,1150,950},
				{51450,26000,4800,4800,3300,2800,2800,1850,1200,1000},
				{49775,27000,4900,4900,3400,2900,2900,1925,1250,1050}}
	
	local res = ""
	local r
	for i=1,3,1 do
		r = math.random(1,100000)
		local curRatio = 0
		for k=1,#itemId,1 do
			curRatio = curRatio+itemRatio[index][k]
			if r <= curRatio then
				res = res..itemId[k][1].."|"..itemId[k][2].."|"
				break
			end
		end
	end
	
	local endItem = {{501,3},{502,2},{502,3},{503,1},{851,3}}
	local item1 = 0
	for i=1,10,1 do
		r = math.random(1,#endItem)
		if item1 == 0 then
			item1 = r
			res = res..endItem[r][1].."|"..endItem[r][2].."|"
		elseif item1 ~= r then
			res = res..endItem[r][1].."|"..endItem[r][2]
			break		
		end
	end
	return res
end

