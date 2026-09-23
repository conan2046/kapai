require "language"
--配置常用的常量，尽量在不在小版改动中修改本配置
---门派三个，但保留原来的不去除

NPC_HEAD_KILLED = 1	-- 位运算(1byte)

MISSION_ID_ZhuoGui = 100
MISSION_ID_SHIMEN = 101
MISSION_ID_XUNBAO = 102 -- 寻宝任务id
MISSION_ID_DANYUAN = 103
MISSION_ID_DUOBAO = 104 -- 夺宝任务id
MISSION_ID_HUSONG = 105 -- 护送神将
MISSION_ID_ZHOUSHIMEN = 106 -- 周师门
MISSION_ID_DC_44 = 44 -- 完成x次宝图任务 
MISSION_ID_DC_45 = 45 -- 使用x次藏宝图
MISSION_ID_DC_46 = 46 -- 使用x次高级藏宝图
MISSION_ID_DC_48 = 48 -- 护送神将
MISSION_ID_DC_59 = 59 -- 师门任务
MISSION_ID_DC_61 = 61 -- 购买引导

MISSION_ID_KUAFULILIAN = 10001 -- 跨服历练
KUAFULILIAN_MAX_CNT = 5
SHI_LIAN_NPCID = 250
KUAFULILIAN_DATA8 = 641

MENPAI_NAME ={LANGUAGE_TRANSFORM_472,LANGUAGE_TRANSFORM_473,"-","-",LANGUAGE_TRANSFORM_474}
MENPAI_MASTERNAME={LANGUAGE_TRANSFORM_475,LANGUAGE_TRANSFORM_476,"-~","-~",LANGUAGE_TRANSFORM_477}
MENPAI_SHIXIONGNAME={LANGUAGE_TRANSFORM_478,LANGUAGE_TRANSFORM_479,"-~","-~",LANGUAGE_TRANSFORM_480}
MENPAI_SKILLNAME={LANGUAGE_TRANSFORM_481,LANGUAGE_TRANSFORM_482,"-~","-~",LANGUAGE_TRANSFORM_483}

MENPAI_MASTER_ID={56,57,0,0,55}
MENPAI_SHIXIONG_ID={59,60,0,0,58}
MENPAI_MAP_ID = {13,14,0,0,12}

BANNER_TYPE_ACCETP=0
BANNER_TYPE_FINISH=1

-- NPC头顶标识
NPC_HEAD_NONE = 0				-- 无头顶标识
NPC_HEAD_YUNBIAO = 1		-- 运镖
NPC_HEAD_HUSONG = 2			-- 护送
NPC_HEAD_SEED = 3				-- 种子商人
NPC_HEAD_XUNCHASHI = 4	-- 巡察使
YUANBAO_LILV = 10

-- 系统公告颜色
GONGGAO_WHITE = 0
GONGGAO_GREEN = 3
GONGGAO_BLUE = 2
GONGGAO_PURPLE = 7
GONGGAO_ORANGE = 8
GONGGAO_GOLD = 4
GONGGAO_PINK = 5
GONGGAO_RED = 1
GONGGAO_WINE_RED = 9
GONGGAO_BROWN = 10
GONGGAO_GRAY_SHADOW =11
GONGGAO_GREEN_SHADOW =12
GONGGAO_BLUE_SHADOW =13
GONGGAO_PURPLE_SHADOW =14
GONGGAO_ORANGE_SHADOW =15
GongGaoColor = {{GONGGAO_GREEN,LANGUAGE_TRANSFORM_484},{GONGGAO_BLUE,LANGUAGE_TRANSFORM_485},{GONGGAO_PURPLE,LANGUAGE_TRANSFORM_486},{GONGGAO_ORANGE,LANGUAGE_TRANSFORM_487},
								{GONGGAO_GOLD,LANGUAGE_TRANSFORM_488},{GONGGAO_PINK,LANGUAGE_TRANSFORM_489},{GONGGAO_RED,LANGUAGE_TRANSFORM_490},{GONGGAO_WINE_RED,LANGUAGE_TRANSFORM_491}}
ROLE_NAME_COLOR = GONGGAO_BLUE_SHADOW
ITEM_NAME_COLOR = GONGGAO_GREEN_SHADOW


--角色经验、神将经验、道具奖励、道行、潜能、银锭、金锭、其他
AWARD_EXP = 1		-- 角色经验
AWARD_PET_EXP = 2	-- 神将经验不用了
AWARD_ITEM	= 3		-- 后面跟itemId,品质,强化等级,数量
AWARD_DAOHANG = 4	-- 道行
AWARD_QIANNENG = 5	-- 潜能
AWARD_BD_MONEY = 6	-- 绑定金钱
AWARD_MONEY = 7		-- 不绑定金钱
AWARD_OTHER = 8
---END

--新手引导提示类型
GUIDE_ACCEPT_MISSION = 1
GUIDE_FINISH_MISSION = 2
GUIDE_SHORTCUT = 3
GUIDE_TRACK_MISSION = 4

--具体引导种类
GUIDE_LEARN_SKILL = 1
GUIDE_PUT_EQUIP =2
GUIDE_CATCH_PET =3
GUIDE_PET_TRANCFER=4
GUIDE_PET_XIZI =5
GUIDE_FUBEN_ENTER =6
GUIDE_QIANGHUA =7
GUIDE_SHUIJING_JIANDING =8
GUIDE_LANZHUANG =9
GUIDE_LVZHUANG =10
GUIDE_ZHUANGBEI_SHENGHUA =11
GUIDE_SHIPIN_HECHENG =12
GUIDE_SHIPIN_SHENGJI =13


NEW_SHI_MEN_MISSION_STR = {"1|3|7|1","1|1|3|9|5|0","1|2|652|1"}

--活动类型
HD_FESTIVAL = 21	--节日
HD_MEIRI_HUANHAOLI = 38  		--每日换好礼
HD_SHENGDAN_FENGSHOU = 39  		--圣诞大丰收

SHI_MEN_NPCID = 19
ZHOU_SHI_MEN_NPCID = 517

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

function FormatTimeString(s)
	local h1,m1,h2,m2 = string.gmatch(s,"(%d+):(%d+)-(%d+):(%d+)")()
	return h1,m1,h2,m2
end

function Timing(startTime,endTime)
	local nowTime = os.time()
	if nowTime > startTime and nowTime < endTime then
		return true
	end
	return false
end

function TimingEnd(endTime)
	local nowTime = os.time()
	if nowTime < endTime then
		return true
	end
	return false
end

function GetMonsterByLevel(level)
	if level > 80 then
		level = 80
	end
	local mapId = math.ceil(level/10)-1
	local monsterId = mapId*4 + 1 - math.random(1,4)
	if monsterId < 5 then
		monsterId = math.random(5,8)
	elseif monsterId > 40 then
		monsterId = math.random(5,40)
	end
	return mapId,monsterId
end

-----------------英勇试炼start---------------------------------

SHI_LIAN_BOX_POS = {{729,413},{990,403},{1195,475},{1222,622},{1074,727}}
SHI_LIAN_NPC_POS = {1009,499}

function ShiLianAddBoxNpc(pUser)
	local boxIdx = pUser:GetExtData8(137)
	for i=1,5 do
		if boxIdx < 5 then
			pic = 61
			name = LANGUAGE_TRANSFORM_1204
		elseif boxIdx < 10 then
			pic = 63
			name = LANGUAGE_TRANSFORM_1205
		else
			pic = 65
			name = LANGUAGE_TRANSFORM_1206
		end
		scene:AddNpcWithIndex(179,pic,SHI_LIAN_BOX_POS[i][1],SHI_LIAN_BOX_POS[i][2],2,boxIdx*10+i,LANGUAGE_TRANSFORM_1207..(boxIdx+1)..LANGUAGE_TRANSFORM_1208..name,0)
	end
end

-----------------英勇试炼end-----------------------------------



--------------------师门start----------------------

LetterNPC={5,7,9,14,17}
PanTuPos={11,1225,1623,0, 11,2546,946,0, 11,3162,649,0, 11,2947,1633,0, 4,2353,1106,0, 4,1378,507,0, 4,716,425,0, 2,953,732,0, 2,1736,470,0, 2,1572,1245,0, 3,894,582,0, 3,1474,1108,0, 3,2279,753,0}
SHI_MEN_NUM = 10
ZHOU_SHI_MEN_NUM = 10
ZHOU_SHI_MEN_TURN = 7

function AcceptShiMen(pUser)
	local mission = CreateShiMenMission(pUser)
	if pUser:HaveCMission(MISSION_ID_SHIMEN) then
		pUser:UpdateCMission(MISSION_ID_SHIMEN,mission,"")
		pUser:UpdateCMissionState(MISSION_ID_SHIMEN,0)
	else
		pUser:AcceptCMission(MISSION_ID_SHIMEN,mission,"")
	end
	
	local t=FormatMission(mission)
	local type = tonumber(t[1])
	if type == 1 then
		local monsterId = tonumber(t[2])
		local sid = j.GetMonsterFindPathSidById(monsterId)
		j.SendYinDaoMonsterPos(pUser,sid,-1,-1,monsterId)
	elseif type == 2 then
		if pUser:GetItemNum(tonumber(t[2])) < tonumber(t[3]) then
			j.SendYinDaoMissionNPCPos(pUser,11,-1,-1,9, MISSION_ID_SHIMEN)
		else
			pUser:UpdateCMissionState(MISSION_ID_SHIMEN,1)
			j.SendYinDaoMissionNPCPos(pUser,11,-1,-1,19, MISSION_ID_SHIMEN)
			j.UpdateNpcState(pUser,SHI_MEN_NPCID,3)
			return
		end

	elseif type == 3 then
		local npcId = tonumber(t[2])
		j.SendYinDaoMissionNPCPos(pUser,11,-1,-1,npcId, MISSION_ID_SHIMEN)
	elseif type == 4 then
		local npcId = tonumber(t[2])
		local idx = tonumber(t[4]) - 1
		if idx >= math.floor(#PanTuPos/4) or idx < 0 then
			idx = 0
		end
		j.AddNpcDirect(pUser,npcId,PanTuPos[idx*4+1],PanTuPos[idx*4+2],PanTuPos[idx*4+3],PanTuPos[idx*4+4])
		j.SendYinDaoMissionNPCPos(pUser,PanTuPos[idx*4+1],-1,-1,npcId, MISSION_ID_SHIMEN)
	end
	j.UpdateNpcState(pUser,SHI_MEN_NPCID,2)

--	if tonumber(t[1])==2 then
--		if pUser:GetItemNum(tonumber(t[2]))>=tonumber(t[3]) then
--			pUser:UpdateCMissionState(MISSION_ID_SHIMEN,1)	-- 完成
--			j.UpdateNpcState(pUser,SHI_MEN_NPCID,3)
--		end
--	end
end

function CreateShiMenMission(pUser)
	local type -- 1:打野怪,2：找草药,3：送信,4：讨伐生成怪
	local num
	local mission
	local r = math.random(100)
	local turn=pUser:GetSaveVal(2)
	local level = pUser:GetLevel()
	if turn == SHI_MEN_NUM - 1 then
		r = 51
	end
--	if r<=25 then		-- 打怪
--		r = 49
--	end
--[[
	if r<=25 then		-- 打怪
		type=1
		local monsterId = (math.ceil(level/10)-1)*4 + 1 - math.random(4)
		num = math.random(4) + 2
		mission = type.."|"..monsterId.."|"..num.."|0"
--]]
	if r<=20 then	-- 买药
		type=2
		local itemId = 650 + math.random(4)
		num = 1
		mission = type.."|"..itemId.."|"..num.."|0"
	elseif r<=40 then	-- 送信
		type=3
		local npcId = LetterNPC[math.random(#LetterNPC)]
		local idx = math.random(2)
		mission = type.."|"..npcId.."|"..idx
	else		-- 杀叛徒
		type=4
		local npcId = 139
		local idx = math.random(#PanTuPos/4)
		local sid = PanTuPos[(idx-1)*4+1]
		mission = type.."|"..npcId.."|"..sid.."|"..idx
	end
	return mission
end

function FinishShiMen(pUser, inBattle)
	if not pUser:IsCMissionFinished(MISSION_ID_SHIMEN) then
		return
	end

	local turn=pUser:GetSaveVal(2)+1
	-- 以后放开这段
	local curDay=pUser:GetSaveVal(3)
	if curDay==1 then --完成了前一天的任务
		pUser:SetSaveVal(3,0)
		pUser:SetSaveVal(2,0)
	else
		pUser:SetSaveVal(2,turn)
		pUser:CheckMissionHuoYueDu()
	end
	
	local exp = j.GetShiMenExp(pUser)
	local money = j.GetShiMenMoney(pUser)
	local battle = inBattle and inBattle or false
	pUser:AddExp(exp, true, battle)
	pUser:AddMoney(money)
	if not inBattle then
		j.SendSysInfo(pUser, LANGUAGE_TRANSFORM_134..money)
	else
		j.SendSysInfoFightEnd(pUser, LANGUAGE_TRANSFORM_134..money)
	end
	
	local s=j.GetCMissionInts(pUser,MISSION_ID_SHIMEN)
	if s==nil or string.len(s) == 0 then
		print("FinishShiMen(pUser) error !  roleId="..pUser:GetRoleId())
		return
	else
		local t=FormatMission(s)
		if tonumber(t[1])==4 then
			local npcId = tonumber(t[2])
			j.DelNpc(pUser,npcId)
		elseif tonumber(t[1])==2 then
			local itemId = tonumber(t[2])
			local itemNum = tonumber(t[3])
			pUser:DelPackageById(itemId,itemNum)
		end
	end
	
	pUser:SetExtData16(36,pUser:GetExtData16(36)+1)	-- 师门任务总次数计数
	j.UpdateDCMissionComplate(pUser, MISSION_ID_DC_59, 1, MISSION_ID_SHIMEN)
	if turn>=SHI_MEN_NUM then
		pUser:DelCMission(MISSION_ID_SHIMEN)
		j.UpdateNpcState(pUser,SHI_MEN_NPCID,0)
	else
		j.UpdateNpcState(pUser,SHI_MEN_NPCID,1)
		AcceptShiMen(pUser)
	end
	
	j.HD_DropExchangeItem(pUser,3)
	j.HD_DropHDItem(pUser,3)
end

--送信任务
function HaveLetter(pUser,name,id, missionId)
	local s
	local t
	local nid
	local type
	
	if missionId == 0 then
		return
	end
	
	local s=j.GetCMissionInts(pUser,missionId)
	if string.len(s) == 0 then
		print("HaveLetter(pUser) error !  roleId="..pUser:GetRoleId()..", id="..id)
		return false
	end
	
	t=FormatMission(s)
	type=tonumber(t[1])

	if type~=3 then
		return false
	end
	nid=tonumber(t[2])
	idx=tonumber(t[3])
	if nid~=id then
		return false
	end

	if idx==1 then
		local dia
		if math.random(2)==1 then
			dia=LANGUAGE_TRANSFORM_518
		else
			dia=LANGUAGE_TRANSFORM_519
		end

		if tonumber(missionId) == tonumber(MISSION_ID_SHIMEN) then
			Option(pUser,name,dia,LANGUAGE_TRANSFORM_520)
		else
			Option(pUser,name,dia,LANGUAGE_ZQX_0026)
		end
	else
		if tonumber(missionId) == tonumber(MISSION_ID_SHIMEN) then
			Option(pUser,name,LANGUAGE_TRANSFORM_521,LANGUAGE_TRANSFORM_522)
		else
			Option(pUser,name,LANGUAGE_TRANSFORM_521,LANGUAGE_ZQX_0027)
		end
	end
	pUser:SetCallFun("HaveLetter2")
	return true
end

function HaveLetter2(pUser,sel)	----因为任务状态进行完成更新时，客户端会触发寻路，所以要把更新任务状态单独放在回调里
	if sel == 1 then
		pUser:UpdateCMissionState(MISSION_ID_SHIMEN,1)
		FinishShiMen(pUser)
	elseif sel == MISSION_ID_ZHOUSHIMEN then
		pUser:UpdateCMissionState(MISSION_ID_ZHOUSHIMEN,1)
		FinishZhouShiMen(pUser)
	end
end
--------------------------------师门end------------------------------------------

--------------------------------周师门------------------------------------------
function AcceptZhouShiMen(pUser)
	local mission = CreateZhouShiMenMission(pUser)
	if pUser:HaveCMission(MISSION_ID_ZHOUSHIMEN) then
		pUser:UpdateCMission(MISSION_ID_ZHOUSHIMEN,mission,"")
		pUser:UpdateCMissionState(MISSION_ID_ZHOUSHIMEN,0)
	else
		pUser:AcceptCMission(MISSION_ID_ZHOUSHIMEN,mission,"")
	end
	
	local t=FormatMission(mission)
	local type = tonumber(t[1])
	if type == 1 then
		local monsterId = tonumber(t[2])
		local sid = j.GetMonsterFindPathSidById(monsterId)
		j.SendYinDaoMonsterPos(pUser,sid,-1,-1,monsterId)
	elseif type == 2 then
		if pUser:GetItemNum(tonumber(t[2])) < tonumber(t[3]) then
			j.SendYinDaoMissionNPCPos(pUser,11,-1,-1,9, MISSION_ID_ZHOUSHIMEN)
		else
			pUser:UpdateCMissionState(MISSION_ID_ZHOUSHIMEN,1)
			j.SendYinDaoMissionNPCPos(pUser,11,-1,-1,ZHOU_SHI_MEN_NPCID, MISSION_ID_ZHOUSHIMEN)
			j.UpdateNpcState(pUser,ZHOU_SHI_MEN_NPCID,3)
			return
		end

	elseif type == 3 then
		local npcId = tonumber(t[2])
		j.SendYinDaoMissionNPCPos(pUser,11,-1,-1,npcId, MISSION_ID_ZHOUSHIMEN)
	elseif type == 4 then
		local npcId = tonumber(t[2])
		local idx = tonumber(t[4]) - 1
		if idx >= math.floor(#PanTuPos/4) or idx < 0 then
			idx = 0
		end
		j.AddNpcDirect(pUser,npcId,PanTuPos[idx*4+1],PanTuPos[idx*4+2],PanTuPos[idx*4+3],PanTuPos[idx*4+4])
		j.SendYinDaoMissionNPCPos(pUser,PanTuPos[idx*4+1],-1,-1,npcId, MISSION_ID_ZHOUSHIMEN)
	end
	j.UpdateNpcState(pUser,ZHOU_SHI_MEN_NPCID,2)
end

function CreateZhouShiMenMission(pUser)
	local type -- 1:打野怪,2：找草药,3：送信,4：讨伐生成怪
	local num
	local mission
	local r = math.random(100)
	local times=pUser:GetExtData8(616)
	local level = pUser:GetLevel()
	if times ==  ZHOU_SHI_MEN_NUM - 1 then
		r = 49
	end
	
	if level> 80 then
		level=80
	end
	if r<=25 then		-- 打怪
		type=1
		local monsterId = (math.ceil(level/10)-1)*4 + 1 - math.random(4)
		num = math.random(6) + 4
		mission = type.."|"..monsterId.."|"..num.."|0"
	elseif r<=50 then	-- 买药
		type=2
		local itemId = 650 + math.random(4)
		num = 1
		mission = type.."|"..itemId.."|"..num.."|0"
	elseif r<=75 then	-- 送信
		type=3
		local npcId = LetterNPC[math.random(#LetterNPC)]
		local idx = math.random(2)
		mission = type.."|"..npcId.."|"..idx
	else		-- 杀叛徒
		type=4
		local npcId = 140
		local idx = math.random(#PanTuPos/4)
		local sid = PanTuPos[(idx-1)*4+1]
		mission = type.."|"..npcId.."|"..sid.."|"..idx
	end
	return mission
end

function FinishZhouShiMen(pUser, inBattle)
	if not pUser:IsCMissionFinished(MISSION_ID_ZHOUSHIMEN) then
		return
	end

	local times=pUser:GetExtData8(616)+1
	local turn=pUser:GetExtData8(619)
	pUser:SetExtData8(616,times)
	pUser:CheckMissionHuoYueDu()
	if times >= ZHOU_SHI_MEN_NUM then
		turn = turn + 1
		pUser:SetExtData8(616,0)
		pUser:SetExtData8(619,turn)
	end
	local exp = pUser:GetLevel() * 2000 + 4000
	local battle = inBattle and inBattle or false
	pUser:AddExp(exp, true, battle)

	j.UpdateDCMissionComplate(pUser, MISSION_ID_DC_59, 1, MISSION_ID_ZHOUSHIMEN)
	local s=j.GetCMissionInts(pUser,MISSION_ID_ZHOUSHIMEN)
	if s==nil or string.len(s) == 0 then
		print("FinishZhouShiMen(pUser) error !  roleId="..pUser:GetRoleId())
		return
	else
		local t=FormatMission(s)
		if tonumber(t[1])==4 then
			local npcId = tonumber(t[2])
			j.DelNpc(pUser,npcId)
		elseif tonumber(t[1])==2 then
			local itemId = tonumber(t[2])
			local itemNum = tonumber(t[3])
			pUser:DelPackageById(itemId,itemNum)
		end
	end
	
	if turn >= ZHOU_SHI_MEN_TURN then
		pUser:DelCMission(MISSION_ID_ZHOUSHIMEN)
		j.UpdateNpcState(pUser,ZHOU_SHI_MEN_NPCID,0)
	else
		j.UpdateNpcState(pUser,ZHOU_SHI_MEN_NPCID,1)
		AcceptZhouShiMen(pUser)
	end
	
	j.HD_DropExchangeItem(pUser,3)
	j.HD_DropHDItem(pUser,3)
end

--------------------------------周师门end------------------------------------------


function GetMenPaiName(pUser)
	return MENPAI_NAME[pUser:GetXiang()]
end

function GetMenPaiMasterName(pUser)
	return MENPAI_MASTERNAME[pUser:GetXiang()]
end

function GetMenPaiMasterId(pUser)
	return MENPAI_MASTER_ID[pUser:GetXiang()]
end

function GetMenPaiShiXiongName(pUser)
	return MENPAI_SHIXIONGNAME[pUser:GetXiang()]
end

function GetMenPaiShiXiongId(pUser)
	return MENPAI_SHIXIONG_ID[pUser:GetXiang()]
end

function GetMpMapId(pUser)
	return MENPAI_MAP_ID[pUser:GetXiang()]
end

function GetMenpaiSkillName(pUser)
	return MENPAI_SKILLNAME[pUser:GetXiang()]
end

function InOriginalScene(pUser)
	local sid = pUser:GetSrcSceneId()
	if sid == 1 or sid == 2 or sid == 11 then
		return true
	else
		return false
	end
end

--计算卖店价格
function GetSellCost(pitem,num,item)
	local money

	if pitem.tmplId==1827 or pitem.tmplId==1828 or pitem.tmplId==1829 then
		money=math.floor(pitem:GetItemValue()/10)
	elseif pitem.tmplId==632 then
		money=math.floor(item.jiage*num)
	else
		--money=math.floor(item.selJia*num)
		money=math.floor(item.selJia*num)
	end
	if money<1 then
		money=1
	end
	return money
end

function figureMission214Exp(pUser,turn)
	local exp = 0
	if turn == 1 then
		exp = j.GetHuoDongExpWithType(pUser,19,1/5)
	elseif turn == 2 then
		exp = j.GetHuoDongExpWithType(pUser,19,1/5)
	elseif turn == 3 then
		exp = j.GetHuoDongExpWithType(pUser,19,1/5)
	elseif turn == 4 then
		exp = j.GetHuoDongExpWithType(pUser,19,1/5)
	elseif turn >= 5 then
		exp = j.GetHuoDongExpWithType(pUser,19,1/5)
	end
	exp = math.floor(exp)
	return exp
end

function GetMasterId(pUser)
	local thisId
	local men=pUser:GetMenPai()
	if men==5 then
		thisId=55
	elseif men==1 then
		thisId=56
	else
		thisId=57
	end
	return thisId
end

-- 类CG动画实现技术框架结构
-- 主体结构：
-- id|片段总数|类型:相应解析内容|类型：相应解析内容|

-- 分支类型说明：
--  	1 - 对话：对话包括普通文本和表情，普通文本不支持着色解析，表情解析同聊天框内的规则，即[e+id],如打哈欠就是[e47]。;
-- 		2 - 动画播放：直接传相应动画的文件名，后面跟屏幕坐标,紧跟该动画在多少帧结束，开始播下一个CG段;
-- 		3 - 切换地图坐标：
-- 		4 - 生成NPC：(包括生成主角,坐标为屏幕坐标),后面跟id，神将id对应加10000,后面跟坐标，坐标为屏幕坐标;
-- 		5 - 动画播放（带删除功能，成对出现）：基本同第二种，在最后面跟两个标记（第一个标识是哪个动画，成对是一样的，第二个标识是删除标记：0-播放,1-删除）
-- 		6 - 主角走动（屏幕坐标）
--		7 - 动画播放（扩展点击事件，屏幕坐标，点击范围宽高）	
--		8 - 飞入动画: 飞入动画的id（同5的id），飞入目标坐标
-- 		9 - 特殊动画：由客户端实现
function GetCgInfo(pUser,id)
	if id==1 then
		pUser:SendCgInfo(LANGUAGE_TRANSFORM_523)
	elseif id==2 then
		pUser:SendCgInfo(LANGUAGE_TRANSFORM_524)
	elseif id==3 then
		pUser:SendCgInfo("3|1|9:0|")
	elseif id==4 then
		-- 服务器代码里调用的	
	elseif id==5 then	
		pUser:SendCgInfo("5|1|9:0|")
	-- elseif id==6 then
	-- 	pUser:SendCgInfo("6|1|2:UI/petEffect2:672:506:3|")
	end
end

function GetRecommenderZL_Huan(pUser,idx)
	local lv=pUser:GetLevel()

	if idx==1 then
		return lv*185*5
	elseif idx==2 then
		return lv*268*5
	elseif idx==3 then
		return lv*296*5
	elseif idx==4 then
		return lv*326*5
	elseif idx==5 then
		return lv*351*5
	end
end

function GetHuanExp(pUser,idx)
	local lv = pUser:GetLevel()
	local curNeedExp=j.GetLvUpExp(lv)
	local huanRate = 0.1

	if lv>=30 and lv<40 then
		huanRate = 0.9
	elseif lv>=40 and lv<50 then
		huanRate = 0.81
	elseif lv>=50 and lv<60 then
		huanRate = 0.729
	elseif lv>=60 and lv<70 then
		huanRate = 0.5832
	elseif lv>=70 and lv<80 then
		huanRate = 0.46656
	elseif lv>=80 and lv<90 then
		huanRate = 0.37325
	elseif lv>=90 and lv<100 then
		huanRate = 0.2986
	elseif lv>=100 and lv<110 then
		huanRate = 0.23888
	elseif lv>=110 and lv<120 then
		huanRate = 0.1911
	elseif lv>=120 and lv<130 then
		huanRate = 0.15288
	elseif lv>=130 then--and lv<120 then
		huanRate = 0.09173
	elseif lv<30 then
		-- 主线里做的环线特殊比率
		huanRate = 5.5
	end

	if idx==1 then
		return  math.floor(0.05*0.3*huanRate*curNeedExp)
	elseif idx==2 then
		return  math.floor(0.05*0.5*huanRate*curNeedExp)
	elseif idx==3 then
		return  math.floor(0.05*0.7*huanRate*curNeedExp)
	elseif idx==4 then
		return  math.floor(0.05*0.85*huanRate*curNeedExp)
	elseif idx==5 then
		return  math.floor(0.05*huanRate*curNeedExp)
	end
end


function GetYaBiaoMissionExp(mission)
	if mission == nil then
		return 0
	end
	
	local t = FormatMission(mission)
	local qualityRatio = {100,106,111,128,156}	-- 品质对应的加成经验
	local quality = tonumber(t[2])
	local exp = math.floor(qualityRatio[quality+1]*tonumber(t[3])/100 - tonumber(t[4]))
	exp = exp - exp%1000

	local money = math.floor(qualityRatio[quality+1]*tonumber(t[7])/100 - tonumber(t[8]))
	local item_id = 2818
	local item_num={1,1,1,1,2}
	return exp,money,item_id,item_num[quality+1]
end

-- 测试输出堆栈
function PrintTraceBack(pUser)
	--print("lua traceback：",pUser:GetName(),debug.traceback())
end
	
function UpdateNpcStateByLevel(pUser, npcId, limitLv)
	local lv=pUser:GetLevel()
	if lv >= limitLv then
		j.UpdateNpcState(pUser,npcId,1)
		return true
	else
		j.UpdateNpcState(pUser,npcId,0)
		return false
	end
end

function GetWorldExp(pUser, awardExp)
	return j.GetWorldExp(pUser:GetLevel(), awardExp)
end

function GetWorldExpPercent(pUser)
	return j.GetWorldExpPercent(pUser:GetLevel())
end

function GetAward(pUser, missionId, notFinish, exp)
	local baseStr = ""
	local ratio = j.GetMonthCardExpRatio(pUser) / 100

	if exp then
		baseStr =AWARD_EXP..","..math.floor(exp*ratio)..","..math.floor(GetWorldExp(pUser,exp)*ratio)..";"
	else
		baseStr = AWARD_EXP..","..math.floor(MISSION_EXP[missionId]*ratio)..","..math.floor(GetWorldExp(pUser, MISSION_EXP[missionId])*ratio)..";"..AWARD_MONEY..","..MISSION_MONEY[missionId]..";"..AWARD_QIANNENG..","..MISSION_QIANNENG[missionId]..";"
	end
	
	if notFinish then
		return baseStr
	else
		return baseStr .."|"
	end
end

function UpdateState(oldState,newState)
	if oldState == 0 then
		return newState
	elseif newState == 3 or oldState == 3 then
		return 3
	else
		return oldState < newState and oldState or newState
	end
end

function string:split(sep)
    local sep, fields = sep or "\t", {}
    local pattern = string.format("([^%s]+)", sep) 
    self:gsub(pattern, function(c) fields[#fields+1] = c end) 
    return fields
end

-- --------------------------------------------------------------------------
_AllMissionCache = {} -- 所有任务数据的缓存,玩家正在进行中的任务
-- --------------------------------------------------------------------------
-- 挖宝
_Wbconf = {}  -- 挖宝的配置
_DailyWBMax = 10
_DailyUseCangBaoTuMax = 10
_WbAward = {2441, 2442} -- 2441 低阶藏宝图 2442 高级藏宝图
_WbFightType = {51886, 51887}
_WbCurrentCangBaotuId = {} -- 保存当前使用的藏宝图的id
_WbCangBaotuFightAward = {62900, 62901} -- 92900 高级掉落 62901 低级掉落
function InitWbConf()
	table.insert(_Wbconf, { mapid = 3, level = 40, 	randpos = {{1818, 196}, {2277,753}, {892,585}, {1186,957}, {2162,1497}, {2637,1203}, {1476,247}}})
	table.insert(_Wbconf, { mapid = 4, level = 50,	randpos = {{1145,894},{2320,1107},{237,761},{1057,422},{1774,418},{1252,1002},{1503,1366}}})
	table.insert(_Wbconf, { mapid = 5, level = 60, 	randpos = {{180,402},{1781,466},{1760,717},{1844,416},{2435,622},{2230,508}}})
end

-- ---------------------------------------------
function CreateWaBaoMission(pUser,type)
	local npcId = {300,301}	-- 挖宝任务，使用藏宝图
	local npcPic = {109,110,111,209,210,210}
	local npcPicType = 2
	
	if #_Wbconf<=0 then
		InitWbConf() 
	end 
	local userlv = pUser:GetLevel()
	local ci = 1
	if userlv < 50 then 
		ci = 1
	elseif userlv >= 50 and userlv < 60 then
		ci = math.random(1,2)   -- 1,2 选一个
	elseif userlv >= 60 then 
		ci = math.random(1,3) -- 1,3 选一个
	end 

	local cf = _Wbconf[ci]
	local monsterid = npcId[type]
	local monsterpos = cf.randpos[math.random(1, #cf.randpos)]
	local mapid = cf.mapid
	local pic = npcPic[math.random(1,#npcPic)]
	local picType = npcPicType
	local name = j.GetNpcTmplName(monsterid)
	local mission = mapid.."|"..monsterid.."|"..monsterpos[1].."|"..monsterpos[2].."|".._DailyWBMax.."|"..0
	return mission, {mapid = mapid, monsterpos = monsterpos, monsterid = monsterid, pic=pic, picType=picType, name=name}
end

function CreateXunbaoMission(pUser)
	local monsterInfo = {
		[1] = {map=1,pos={{x=849,y=785},{x=1034,y=1340},{x=2634,y=1077}}},
		[2] = {map=2,pos={{x=428,y=441},{x=1211,y=1349},{x=1784,y=779}}},
		[3] = {map=3,pos={{x=1931,y=859},{x=1777,y=940},{x=1008,y=808}}},
		[4] = {map=4,pos={{x=2546,y=1191},{x=1382,y=1068},{x=858,y=382}}},
		[5] = {map=5,pos={{x=236,y=691},{x=1422,y=693},{x=723,y=1012}}},
		[6] = {map=6,pos={{x=510,y=1020},{x=1811,y=1240},{x=1995,y=419}}},
		[7] = {map=11,pos={{x=1866,y=492},{x=2726,y=1483},{x=3101,y=1664}}},
		}

	local pos
	local monsterid = 300
	local monsterPic = {109,110,111,209,210,210}
	local levelCeil  = math.ceil(pUser:GetLevel()/10)
	if levelCeil > #monsterInfo then levelCeil = #monsterInfo end
	local midx = math.random(1, levelCeil)
	local pic = monsterPic[math.random(1,#monsterPic)]
	local posIdx = math.random(1, #monsterInfo[midx].pos)
	local mapid = monsterInfo[midx].map
	pos = monsterInfo[midx].pos[posIdx]
	local name = j.GetNpcTmplName(monsterid)
	local mission = mapid.."|"..monsterid.."|"..pos.x.."|"..pos.y.."|".._DailyWBMax.."|"..0
	return mission, {mapid = mapid, monsterpos = pos, monsterid = monsterid, pic=pic, picType=2, name=name}
end

function GetXunbaoMap(info)
	local mapInfo = {
		[1] = {map=1,pos={{x=2466,y=687},{x=1926,y=917},{x=912,y=1347}}},
		[2] = {map=2,pos={{x=966,y=1169},{x=1476,y=1093},{x=1822,y=893}}},
		[3] = {map=3,pos={{x=838,y=750},{x=819,y=1236},{x=1808,y=1340}}},
		[4] = {map=4,pos={{x=337,y=637},{x=1763,y=402},{x=2300,y=1273}}},
		[5] = {map=5,pos={{x=1726,y=972},{x=1483,y=950},{x=913,y=267}}},
		[6] = {map=6,pos={{x=1520,y=547},{x=1351,y=884},{x=783,y=1281}}},
		[7] = {map=11,pos={{x=2938,y=722},{x=2580,y=981},{x=1294,y=1580}}},
	}

	local midx = math.floor(info/100)
	if midx == 0 then midx = 7 end
	local pidx = info%100
	print("GetXunbaoMap midx =  "..midx..", pidx  = "..pidx)
	return mapInfo[midx].map, mapInfo[midx].pos[pidx]
end

-- ---------------------------------------------
function UpdateUserUseCangBaotu(pUser, uid , itempos, itemid)
	print("UpdateUserUseCangBaotu itempos =  "..itempos..", itemid  = "..itemid.." uid ="..uid)
	local find = false
	for i = 1, #_WbCurrentCangBaotuId do
		local it = _WbCurrentCangBaotuId[i]
		if it.uid == uid then 
			it.itempos = itempos
			it.itemid = itemid
			find = true
		end 
	end
	
	if not find then
		table.insert(_WbCurrentCangBaotuId,{ uid = uid, itempos = itempos, itemid = itemid })
	end 
	pUser:SetExtData32(446, 51887)
end 

function GetUserUseCangBaoTuCache(uid)
	for i = 1, #_WbCurrentCangBaotuId do
		local it = _WbCurrentCangBaotuId[i]
		if it.uid == uid then 
			return it
		end 
	end
	return nil 
end 

-- ---------------------------------------------
function UpdateDailyUseCangBaotuTimes(pUser)
	local today_wbtimes = pUser:GetExtData32(445)
	today_wbtimes = today_wbtimes + 1
	pUser:SetExtData32(445 , today_wbtimes)
end 

-- ---------------------------------------------
-- 接挖宝任务
function AcceptWaBao(pUser, sel)
	local mission , mcf = CreateXunbaoMission(pUser)
	local uid = pUser:GetRoleId()
	if pUser:HaveCMission(MISSION_ID_XUNBAO) then
		return
	else
		j.AddNpcWithInfo(pUser, mcf.monsterid, mcf.mapid, mcf.monsterpos.x, mcf.monsterpos.y,mcf.picType,mcf.pic,mcf.name)
		pUser:AcceptCMission(MISSION_ID_XUNBAO, mission,"")
		j.SendYinDaoMissionNPCPos(pUser,mcf.mapid,-1,-1,mcf.monsterid, MISSION_ID_XUNBAO)
	end
end 

-- ---------------------------------------------
function TodayCanWb(pUser)
	local today_wbtimes = pUser:GetExtData32(444)
	if today_wbtimes >= _DailyWBMax then 
		return false 
	end
	return true 
end

-- ---------------------------------------------
function TodayCanUseCangBaoTu(pUser)
	local today_wbtimes = pUser:GetExtData32(445)
	print("TodayCanUseCangBaoTu  = "..today_wbtimes)
	if today_wbtimes >= _DailyUseCangBaoTuMax then 
		return false 
	end
	return true 
end 

-- ---------------------------------------------
-- 删除挖宝任务
function ClearWbMission(pUser)
	if pUser:HaveCMission(MISSION_ID_XUNBAO)  then 
		pUser:DelCMission(MISSION_ID_XUNBAO)
	end 
end 


-- ---------------------------------------------
-- 挖宝任务战斗回调
function WbMissionFightCallBack(pUser, monsterid)
	local awardid
	local random = math.random(1,100)
	if random >= 80 then 
		local h = pUser:GetExtData32(448) + 1 
		pUser:SetExtData32(448,h)
		awardid = _WbAward[2] -- 高级藏宝图
	else
		local h = pUser:GetExtData32(447) + 1
		pUser:SetExtData32(447, h)
		awardid = _WbAward[1]  -- 低级藏宝图
	end
	local exp = j.GetHuoDongExpWithType(pUser,25,0.1)
	pUser:AddExp(exp, true, true)
	pUser:AddPackage(awardid, 1)
	j.SendSysInfoFightEnd(pUser,LANGUAGE_TRANSFORM_4848..j.GetItemName(awardid))

	-- 完成次数+1
	pUser:SetExtData32(444,pUser:GetExtData32(444) + 1)
	j.DelNpc(pUser, monsterid)
	pUser:DelCMission(MISSION_ID_XUNBAO)
	j.UpdateDCMissionComplate(pUser, MISSION_ID_DC_59, 1, MISSION_ID_XUNBAO)
	local can = TodayCanWb(pUser)
	if not can then 
		pUser:NotifyUserShowCangBaoTuPanel()
	else
		AcceptWaBao(pUser)
	end
end 



-- ---------------------------------------------
-- 藏宝图战斗回调
function  WbUseCangBaotuFightCallBack(pUser,monsterid)
	-- ====================
	-- 扣除藏宝图 
	DeleteWbMonster(pUser, monsterid)
	local uid = pUser:GetRoleId()
	local itemid = pUser:GetExtData16(62)
	if itemid == 2441 then 
		pUser:DelPackageById(itemid, 1) 
		j.GetAwardFromLevelAward(pUser, 62900)
	elseif itemid == 2442 then 
		pUser:DelPackageById(itemid, 1)
		j.GetAwardFromLevelAward(pUser, 62901)
	else
		return
	end 

	pUser:SetExtData16(62,0)
	UpdateDailyUseCangBaotuTimes(pUser)
	
--	local can = TodayCanUseCangBaoTu(pUser)
--	if not can then 
--		return 
--	end

	ContinueUseCangBaoTu(pUser)
--	pUser:NotifyTreasureMapUseResult()
end

function ContinueUseCangBaoTu(pUser)
	local itemNum2441 = pUser:GetItemNum(2441)
	local itemNum2442 = pUser:GetItemNum(2442)
	if itemNum2441 > 0 then
		UseCangBaoTu(pUser,2441,true)
	elseif itemNum2442 > 0 then
		UseCangBaoTu(pUser,2442,true)
	end
end

function UseCangBaoTu(pUser, itemId, showTips)
	local rand = math.random(1,100)
	local awardId = 62900
	local awardRand = 0
	if itemId == 2441 then
		awardId = 62900
		awardRand = 20
	elseif itemId == 2442 then
		awardId = 62901
		awardRand = 30
	else
		return
	end
	
	if rand <= awardRand then
		j.GetAwardFromLevelAward(pUser, awardId)
		UpdateDailyUseCangBaotuTimes(pUser)
		if showTips then
			j.SendSysInfo(pUser,LANGUAGE_SSJ_0154..j.GetItemName(itemId).."*1")
		end
		ContinueUseCangBaoTu(pUser)
		return
	end
	
	pUser:SetExtData16(62,itemId)
	local _, mcf = CreateWaBaoMission(pUser,2)
	j.AddNpcWithInfo(pUser, mcf.monsterid, mcf.mapid, mcf.monsterpos[1], mcf.monsterpos[2],mcf.picType,mcf.pic,mcf.name)
--	j.AddNpcDirect(pUser, mcf.monsterid, mcf.mapid, mcf.monsterpos[1], mcf.monsterpos[2], 0)
	j.SendYinDaoNPCPos(pUser,mcf.mapid,-1,-1,mcf.monsterid)
	if showTips then
		j.SendSysInfo(pUser,LANGUAGE_SSJ_0154..j.GetItemName(itemId).."*1")
	end
end

-- ---------------------------------------------
function DeleteWbMonster(pUser, mid)
	print("DeleteWbMonster mid = "..mid)
	j.DelNpc(pUser, mid)
end

-- ----------------------------------------------
-- 构造丹园任务
_DDYMMT = 10
function DodayCanDoDanYuanMission(pUser)
	local todaytimes = pUser:GetExtData8(101)
	if todaytimes >= _DDYMMT then
		return false
	end
	return true  
end

-- ---------------------------------------------
function UpdateDailyDanYuanMissionTimes(pUser)
	local todaytimes = pUser:GetExtData8(101) + 1
	pUser:SetExtData8(101, todaytimes)
	return todaytimes
end 

-- ---------------------------------------------
function ZeroDailyDanYuanMissionTimes(pUser)
	pUser:SetExtData8(101, 0)
end 

-- ---------------------------------------------
function CreateDanYuanMission(pUser)
	local flowerInfo = {
		[1] = {map=1,pos={{x=1660,y=969},{x=1721,y=999}}},
		[2] = {map=1,pos={{x=2466,y=687},{x=2487,y=730}}},
		[3] = {map=1,pos={{x=2447,y=1134},{x=2497,y=1171}}},
		[4] = {map=2,pos={{x=941,y=741},{x=908,y=756}}},
		[5] = {map=2,pos={{x=1503,y=1056},{x=1476,y=1093}}},
		[6] = {map=2,pos={{x=2125,y=577},{x=2109,y=606}}},
		[7] = {map=3,pos={{x=965,y=584},{x=933,y=609}}},
		[8] = {map=3,pos={{x=1388,y=1033},{x=1351,y=1049}}},
		[9] = {map=3,pos={{x=1436,y=280},{x=1409,y=307}}},
		[10] = {map=4,pos={{x=1327,y=428},{x=1296,y=457}}},
		[11] = {map=4,pos={{x=1316,y=982},{x=1287,y=1011}}},
		[12] = {map=4,pos={{x=2458,y=1054},{x=2430,y=1080}}},
		[13] = {map=5,pos={{x=867,y=1028},{x=824,y=1049}}},
		[14] = {map=5,pos={{x=1935,y=892},{x=1913,y=915}}},
		[15] = {map=5,pos={{x=1671,y=525},{x=1644,y=551}}},
		[16] = {map=6,pos={{x=708,y=503},{x=674,y=541}}},
		[17] = {map=6,pos={{x=1800,y=454},{x=1766,y=484}}},
		[18] = {map=6,pos={{x=2603,y=737},{x=2563,y=765}}},
		}

	local rand = math.random(1, 10000)  -- 1杀怪2采集
	local mission
	local type
	local pos
	local tarId = 0
	local sceneId = 0
	if rand <= 5000 then
		sceneId,tarId = GetMonsterByLevel(pUser:GetLevel())
		local num = 5
		type = 1
		mission = type.."|"..sceneId.."|"..tarId.."|"..num.."|0"
	else
		local mapId = math.ceil(pUser:GetLevel()/10) - 1
		if mapId > 6 then
			mapId = 6
		end
		local idx = math.random(mapId*3-2,mapId*3)
		local collectId = 125
		local num = 2
		sceneId = flowerInfo[idx].map
		pos = flowerInfo[idx].pos
		type = 2
		tarId = collectId
		mission = type.."|"..mapId.."|"..collectId.."|"..num.."|0"
	end
	return mission,type,sceneId,pos,tarId
end  

-- ---------------------------------------------
function AcceptDanYuan(pUser, sel)
	local uid = pUser:GetRoleId()
	local mission,type,sceneId,pos,targetId = CreateDanYuanMission(pUser)
	pUser:AcceptCMission(MISSION_ID_DANYUAN, mission,"")
	if type == 1 then	--打怪
		j.SendYinDaoMonsterPos(pUser,sceneId,-1,-1,targetId)
	elseif type == 2 then	-- 采集
		for i=1,#pos do
			pUser:AddCollect(targetId,i,sceneId,pos[i].x,pos[i].y)
		end
		j.SendYinDaoNPCPos(pUser,sceneId,-1,-1,targetId)
	end
end

-- -------------------------------------------------
-- 判定当前丹园任务的类型 1 杀怪 2 采集
function DanYuanMissionType(pUser)
	local mission = j.GetCMissionInts(pUser, MISSION_ID_DANYUAN)
	if not mission or mission == "" then 
		return 0 
	end
	local t = FormatMission(mission)
	return tonumber(t[1])
end 

-- ---------------------------------------------
function DanYuanMissionFinish(pUser, isFight)
	 if pUser:IsCMissionFinished(MISSION_ID_DANYUAN) then
        local mtype = DanYuanMissionType(pUser)
        if mtype == 2 then
			pUser:DelCollect(125,1,3)
			pUser:DelCollect(125,2,3)
			pUser:DelCollect(125,3,3)
		end

	    local exp = pUser:GetLevel() * 1250 + 2500
	    pUser:AddMaterial(613,3, isFight)
	    pUser:AddMaterial(614,3, isFight)
	    pUser:AddExp(exp, true, isFight)
	    j.HD_DropExchangeItem(pUser,10)
	    j.HD_DropHDItem(pUser,10)

		pUser:SetExtData8(101, pUser:GetExtData8(101) + 1)
		pUser:DelCMission(MISSION_ID_DANYUAN)
		
		TodayCanDoDanYuanMission(pUser, isFight)
		j.UpdateDCMissionComplate(pUser, MISSION_ID_DC_59, 1, MISSION_ID_DANYUAN)
	end
end 

-- ---------------------------------------------
function TodayCanDoDanYuanMission(pUser, isFight)
    local cando = DodayCanDoDanYuanMission(pUser)
    if cando then 
        j.UpdateNpcState(pUser, 106, 1)
        AcceptDanYuan(pUser, sel)
    else
        j.UpdateNpcState(pUser,106,0)
		j.ChangeClientGuaJiState(pUser, 2)
		-- j.SendYinDaoNPCPos(pUser,11,-1,-1,-1)

		if isFight then
			j.SendSysInfoFightEnd(pUser, LANGUAGE_ZQX_0018)
		else
			j.SendSysInfo(pUser, LANGUAGE_ZQX_0018)
		end
    end
end

-- ---------------------------------------------
function GetDanYuanMissionContent(pUser)
	if not pUser:HaveCMission(MISSION_ID_DANYUAN) then
		return nil 
	end 
	local mission = j.GetCMissionInts(pUser, MISSION_ID_DANYUAN)
	local t = FormatMission(mission)
	return t
end 

-- ---------------------------------------------
function  CreateShaDiDuoBaoMission(pUser)
	local monsterNum = {3,6,9,12,15}--半小时
	local turn = pUser:GetExtData16(39) + 1
--	pUser:SetExtData16(39,turn)
	local lv=pUser:GetLevel()
	if lv >= 80 then
		lv = 80
	end
	
	local mapid = math.ceil(lv/10)-1
	local mid = (mapid*4) + 1 - math.random(4)
	local rate = 10
	local item = 833
	local num = 0
	if turn > 5 then
		num = monsterNum[5]
	else
		num = monsterNum[turn]
	end
	local mission = "0|"..rate.."|"..mid.."|"..mapid.."|"..item.."|0|0|"..turn.."|"..num
	return mission, {mapid = mapid, mid = mid}
end 

-- --------------------------------------------
function AcceptShaDiDuoBao(pUser)
	if pUser:HaveCMission(MISSION_ID_DUOBAO) then
		if pUser:IsCMissionFinished(MISSION_ID_DUOBAO) then 
			pUser:UpdateCMissionState(MISSION_ID_DUOBAO, 1 ) -- 任务进行中
			j.UpdateNpcState(pUser,thisId,3)
		end 
	else
		local mission,  t  = CreateShaDiDuoBaoMission(pUser)
		pUser:DelCMission(MISSION_ID_DUOBAO)
		pUser:AcceptCMission(MISSION_ID_DUOBAO, mission,"")
		j.SendYinDaoMonsterPos(pUser, t.mapid , -1, -1, t.mid)
		j.UpdateNpcState(pUser,thisId,2)
	end

end 

function AcceptKuaFuShiLian(pUser)
	local mission

	local idx=pUser:GetExtData8(KUAFULILIAN_DATA8) + 1
	local level = pUser:GetLevel()
	local type
	local num = 1
	if idx == 1 then
		type = 1
		mission = type.."|"..num.."|0"
	elseif idx == 2 or idx == 4 then -- 切磋
		local pro = math.random(1, 6)
		type = 2
		mission = type.."|"..pro.."|"..num.."|0"
	elseif idx == 3 or idx == 5 then -- 心魔
		j.GetKuaFuXinMo(pUser)
		pUser:UpdateCMissionState(MISSION_ID_KUAFULILIAN,0)
		j.UpdateNpcState(pUser,SHI_LIAN_NPCID,2)
		return
	end
	if pUser:HaveCMission(MISSION_ID_KUAFULILIAN) then
		pUser:UpdateCMission(MISSION_ID_KUAFULILIAN,mission,"")
		pUser:UpdateCMissionState(MISSION_ID_KUAFULILIAN,0)
	else
		pUser:AcceptCMission(MISSION_ID_KUAFULILIAN,mission,"")
	end
	j.UpdateNpcState(pUser,SHI_LIAN_NPCID,2)
end

function FinishKuaFuShiLian(pUser, inBattle)
	if not pUser:IsCMissionFinished(MISSION_ID_KUAFULILIAN) then
		return
	end
	local turn = pUser:GetExtData8(KUAFULILIAN_DATA8) + 1
	pUser:AddMaterial(2798, 5, inBattle)
	local s=j.GetCMissionInts(pUser,MISSION_ID_KUAFULILIAN)
	if s==nil or string.len(s) == 0 then
		print("FinishKuaFuShiLian(pUser) error !  roleId="..pUser:GetRoleId())
		return
	else
		local t=FormatMission(s)
		if tonumber(t[1])==3 then
			local npcId = tonumber(t[2])
			j.DelNpc(pUser,npcId)
		end
	end
	
	pUser:SetExtData8(KUAFULILIAN_DATA8,turn)	-- 总次数计数
	if turn>=KUAFULILIAN_MAX_CNT then
		pUser:DelCMission(MISSION_ID_KUAFULILIAN)
		j.UpdateNpcState(pUser,SHI_LIAN_NPCID,0)
	else
		j.UpdateNpcState(pUser,SHI_LIAN_NPCID,1)
		AcceptKuaFuShiLian(pUser)
	end
	
	j.HD_DropExchangeItem(pUser,3)
	j.HD_DropHDItem(pUser,3)
end

-- --------------------------------------------------
local _SDDBMDT = 5
function DodayCanDoShaDiDuoBaoMission(pUser)
	local todaytimes = pUser:GetExtData16(39)
	if todaytimes >= _SDDBMDT then
		return false
	end
	return true  
end

-- -----------------------------------------------------
local _HSSJST = 5
function DodayCanHuSongShenJiangMission(pUser)
	local todaytimes = pUser:GetExtData8(81)
	if todaytimes >= _HSSJST then
		return false
	end
	return true  

end

-- NPC state callbacks are optional in the shipped scripts.  The server queries
-- both callbacks for every visible NPC, so provide neutral defaults that an
-- individual NPC script can override.
function GetState(pUser)
	return 0
end

function GetHeadTitle(pUser,index)
	return 0
end


