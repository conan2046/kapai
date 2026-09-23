--184.lua 捉鬼大师
---------------------------------------
require "global"

Dialog = j.Dialog       --对话
ShowGuidance = j.ShowGuidance --任务引导
Option =j.Option        --对话选项
CloseInteract = j.CloseInteract --结束交互
MissionBanner = j.MissionBanner --新版任务面板接取模式
Dialog_End = j.Dialog_End
SMessage_End = j.SMessage_End

thisId = 184
NPCName = nil

------------------------------------------
--以下为脚本部分：
------------------------------------------
local TURN_LIMIT = 50
MONSTER_PIC = {18,19,22,24,34,36,58}
MONSTER_NAME1 = {LANGUAGE_TRANSFORM_1817,LANGUAGE_TRANSFORM_1818,LANGUAGE_TRANSFORM_1819,LANGUAGE_TRANSFORM_1820,LANGUAGE_TRANSFORM_1821,LANGUAGE_TRANSFORM_1822,LANGUAGE_TRANSFORM_1823,LANGUAGE_TRANSFORM_1824,LANGUAGE_TRANSFORM_1825,LANGUAGE_TRANSFORM_1826,LANGUAGE_TRANSFORM_1827,LANGUAGE_TRANSFORM_1828,LANGUAGE_TRANSFORM_1829,LANGUAGE_TRANSFORM_1830,LANGUAGE_TRANSFORM_1831,LANGUAGE_TRANSFORM_1832,LANGUAGE_TRANSFORM_1833,LANGUAGE_TRANSFORM_1834}
MONSTER_NAME2 = {LANGUAGE_TRANSFORM_1835,LANGUAGE_TRANSFORM_1836,LANGUAGE_TRANSFORM_1837,LANGUAGE_TRANSFORM_1838,LANGUAGE_TRANSFORM_1839,LANGUAGE_TRANSFORM_1840,LANGUAGE_TRANSFORM_1841,LANGUAGE_TRANSFORM_1842,LANGUAGE_TRANSFORM_1843,LANGUAGE_TRANSFORM_1844,LANGUAGE_TRANSFORM_1845,LANGUAGE_TRANSFORM_1846,LANGUAGE_TRANSFORM_1847,LANGUAGE_TRANSFORM_1848,LANGUAGE_TRANSFORM_1849}
BOSS_MONSTER_PIC = {44}
BOSS_MONSTER_NAME = {LANGUAGE_TRANSFORM_1850,LANGUAGE_TRANSFORM_1851,LANGUAGE_TRANSFORM_1852,LANGUAGE_TRANSFORM_1853}

function NpcMain(pUser,missionId)
	if NPCName == nil then
		NPCName = j.GetNpcName(thisId)
	end
	local lv = pUser:GetLevel()
	if lv >= j.GetCMissionAcceptLevel(MISSION_ID_ZhuoGui) then
		local serverType = j.GetServerType()
		Option(pUser,NPCName,LANGUAGE_TRANSFORM_1855,LANGUAGE_TRANSFORM_1856)
		pUser:SetCallFun("UserChoose")
	else
		Option(pUser,NPCName,LANGUAGE_TRANSFORM_1855)
		return
	end
end

function UserChoose(pUser,sel)
		
	if pUser:GetExtData16(50) >= TURN_LIMIT then
		Dialog(pUser,LANGUAGE_TRANSFORM_1863,LANGUAGE_ZQX_0017)
		return
	end
	
	if sel == 1 then
--[[
		if pUser:GetLevel() < 29 then
			Dialog(pUser,LANGUAGE_TRANSFORM_1857,LANGUAGE_TRANSFORM_1858)
			return
		end
		if pUser:GetMission(213) ~= nil then
			Dialog(pUser,LANGUAGE_TRANSFORM_1859,LANGUAGE_TRANSFORM_1860)
			return
		end
--]]
		if pUser:HaveCMission(MISSION_ID_HUSONG) then
			Dialog(pUser,LANGUAGE_TRANSFORM_1861,LANGUAGE_TRANSFORM_1862)
			return
		end
		if pUser:InTreasure() then
			Dialog(pUser,LANGUAGE_TRANSFORM_1863,LANGUAGE_TRANSFORM_1864)
			return
		end
		
--		if pUser:GetExtData8(88) >= 10 then
		if pUser:GetTeam() == 0 and pUser:TempLeaveTeam() == 0 then		-- 自动创建队伍
			local scene = pUser:GetScene()
			if scene ~= nil then
				scene:CreateTeam(pUser,0)
				scene:UpdateTeamData(pUser:GetTeam())
				j.SetTeamFaBuInfo(pUser,3,1,100,1);
			end
		end

		if pUser:GetTeam() ~= pUser:GetRoleId() then
			Dialog(pUser,LANGUAGE_TRANSFORM_1865,LANGUAGE_TRANSFORM_1866)
			return
		end
		if pUser:HaveCMission(MISSION_ID_ZhuoGui) then
			Dialog(pUser,LANGUAGE_TRANSFORM_1867,LANGUAGE_TRANSFORM_1868)
			return
		end

		local fightMonName = MONSTER_NAME1[math.random(1,#MONSTER_NAME1)]..MONSTER_NAME2[math.random(1,#MONSTER_NAME2)]
		local fightMonPic = MONSTER_PIC[math.random(1,#MONSTER_PIC)]
		local fightType = math.random(1,5)
		local minMonPic = MONSTER_PIC[math.random(1,#MONSTER_PIC)]
		if fightMonPic == minMonPic then
			if minMonPic == MONSTER_PIC[1] then
				minMonPic = MONSTER_PIC[2]
			else
				minMonPic = MONSTER_PIC[1]
			end
		end
		
		local monsterId = GetZhuoGuiMonsterId(pUser)
		pUser:AddTeamCMission(100,"1|"..fightMonPic.."|"..fightType.."|"..monsterId.."|"..minMonPic,fightMonName);
		print("name = ",pUser:GetName(),"1|"..fightMonPic.."|"..fightType.."|"..monsterId.."|"..minMonPic,fightMonName)
	elseif sel == 2 then
		j.SendYinDao2_Op(pUser,1004)	-- 打开组队界面
	end
end

function GetNextZhuoGuoMissInfo(pUser,turn,curMonsterId)
	local fightMonName
	local fightMonPic
	local fightType
	local endTime
	local minMonPic = MONSTER_PIC[math.random(1,#MONSTER_PIC)]
	
	turn = turn+1
	if turn % 10 ~= 0 then
		fightMonName = MONSTER_NAME1[math.random(1,#MONSTER_NAME1)]..MONSTER_NAME2[math.random(1,#MONSTER_NAME2)]
		fightMonPic = MONSTER_PIC[math.random(1,#MONSTER_PIC)]
		fightType = math.random(1,5)
		if fightMonPic == minMonPic then
			if minMonPic == MONSTER_PIC[1] then
				minMonPic = MONSTER_PIC[2]
			else
				minMonPic = MONSTER_PIC[1]
			end
		end
	else
		fightMonName = BOSS_MONSTER_NAME[math.random(1,#BOSS_MONSTER_NAME)]
		fightMonPic = BOSS_MONSTER_PIC[math.random(1,#BOSS_MONSTER_PIC)]
		fightType = 6
	end
--	endTime = os.time() + 30*60
	
	local sceneId = pUser:GetSrcSceneId()
	local monsterId = 0
	
	while (true)
	do
		monsterId = GetZhuoGuiMonsterId(pUser)
		if sceneId ~= math.ceil(monsterId / 4) then
			break
		end
	end
	
	local sid = j.GetMonsterFindPathSidById(monsterId)
	local x = j.GetMonsterFindPathX(monsterId)
	local y = j.GetMonsterFindPathY(monsterId)
	print("name = ",pUser:GetName(),turn.."|"..fightMonPic.."|"..fightType.."|"..monsterId.."|"..minMonPic,fightMonName)
	return turn.."|"..fightMonPic.."|"..fightType.."|"..monsterId.."|"..minMonPic,fightMonName,monsterId,sid,x,y
end

function GetZhuoGuiMonsterId(pUser)
	local lv = pUser:GetTeamLevel()
	if lv > 80 then
		lv = 80
	end
	local monsterId = math.random(5,(math.ceil(lv/10)-1)*4)
	if monsterId < 5 then
		monsterId = math.random(5,12)
	elseif monsterId > 40 then
		monsterId = math.random(5,40)
	end
	return monsterId
end

function GetState(pUser)
	local lv = pUser:GetLevel()
	if lv >= j.GetCMissionAcceptLevel(MISSION_ID_ZhuoGui) and pUser:GetExtData16(50) < TURN_LIMIT then
		if not pUser:HaveCMission(100) then
			return 1 -- 可接
		end 
	else 
		return 0 
	end 

	if pUser:IsCMissionFinished(100) then
		return 3 -- 完成
	else
		return 2 -- 未完成
	end

	return 0 
end

function GetChatMsg(pUser)
	return NPC_HEAD_NONE
end

