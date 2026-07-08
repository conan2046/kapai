



--装备相关
LCEquip = {}
LCEquip.__index = LCEquip
LCEquip.PACK_MAX = 1000
function LCEquip:New()
    local o = {}
    setmetatable(o,LCEquip)   
    
    o:Init()
    return o
end

function LCEquip:Init()
    --初始化10个装备
    self.GotEquip = {}--每次任务得到的装备，装备推送比较用
    for i=1,10 do
    	table.insert(self.GotEquip, LPItem:New(0))
    end
    self.ShopItemList = {}     --0武器1防具2要点3
    self.FootList = {} --FootItem
    self.m_itemNum = 0
    self.PackageMap = {}       --背包物品map表(位置做索引)
end

function LCEquip:Reset()
    --初始化10个装备
    for i=1,10 do
        self.GotEquip.m_id = 0
    end

    self.ShopItemList = {}     --0武器1防具2要点3
    self.FootList = {} --FootItem
    self.m_itemNum = 0
    self.PackageMap = {}
end

function LCEquip:Delete()
end

--index:从1开始
function LCEquip:UpdateGotEquip(pitem)
    local index = pitem.m_item.m_pos
    if self.GotEquip[index].m_id == 0 or LItemMgr:CalcFTP(pitem) > LItemMgr:CalcFTP(self.GotEquip[index]) then
        self.GotEquip[index]:Delete()
        self.GotEquip[index] = Utils:deepCopy(pitem)
    end
end
function LCEquip:ResetGotEquip()
    for i=1,(#self.GotEquip) do
        self.GotEquip[i].m_id = 0
    end
end

function LCEquip:CheckEquipPush(it,pro,lv)
    --------------------------------------------------------------------------
    --判断是不是新增的装备，如果是同一部位的装备
    --则选出最优和穿上的装备比较，不同部位的装备依次推送
    --------------------------------------------------------------------------
    if not it:IsEquip() or it.m_item.m_level > lv then
        return
    end
    local professionLimit = it.m_type %10
    if professionLimit ~= pro then --职业限制
        return
    end
    -- self:UpdateGotEquip(it)
end

function LCEquip:GetPacSize()
    return self.m_itemNum
end

function LCEquip:EquipFootId(footId,flag)
    local footItem
    for i = 1,#self.FootList do
        footItem = self.FootList[i]
        if footItem.id == footId then
            if isEquipFlag == true then
                footItem.isEquip = 1
            else
                footItem.isEquip = 0
            end
            self.FootList[i] = footItem
        end
        if footItem.id ~= footId and footItem.isEquip == 1 and isEquipFlag == true then
            footItem.isEquip = 0
            self.FootList[i] = footItem
        end
    end
end


function LCEquip:FindPackageItemById1(itemId)
    for k,v in pairs(self.PackageMap) do
        if v.m_id == itemId then
            return k
        end
    end
    return 0
end

function LCEquip:FindPackageItemById2(minItemId, maxItemId)
    local mapPos = {}
    for k,v in pairs(self.PackageMap) do
        local CID = v.m_id
        if CID >= minItemId and CID <= maxItemId then
            mapPos[CID] = k
        end
    end
    return mapPos
end

--通过ID获得道具
function LCEquip:FindPackageItemById3(itemId)
    return self:FindPackageItemById1(itemId)
end

function LCEquip:CountItemNumById(itemId)
    local result = 0
    for k,v in pairs(self.PackageMap) do
        if v and v.m_id == itemId then
            result = result + v.m_num
        end
    end
    return result
end
--判断背包是否还有容量
function LCEquip:IsPackFull()
    return false
end

function LCEquip:GetPackageMap()
    return self.PackageMap
end

function LCEquip:UpdateItemData(pos, pItem)
    if pos == nil then
        return
    end
    if pItem and (pItem.m_id == 0 or pItem.m_num == 0) then
        self.PackageMap[pos] = nil
        return
    end 
    self.PackageMap[pos] = pItem
end

--任务相关
LCTask = {}
LCTask.__index = LCTask

function LCTask:New()
    local o = {}
    setmetatable(o,LCTask)   
    
    o:Init()
    return o
end

function LCTask:Init()
    self.m_taskTrackData = {} --当前任务数量
    self.m_taskCompleteData = {} --已经完成的任务数量
    self.m_finishNum = 0
end

function LCTask:GetTaskTrackData( ... )
    -- body
    return self.m_taskTrackData
end

function LCTask:ResetData( ... )
    -- body
    self.m_taskTrackData = {}
    self.m_taskCompleteData = {}
end

function LCTask:GetCompleteTaskData( ... )
    -- body
    return self.m_taskCompleteData
end

function LCTask:UpdateTaskData(id,cnt)
    self.m_taskTrackData[id].taskActiveNum = cnt
end

function LCTask:GetTaskData(id)
    return self.m_taskTrackData[id]
end

function LCTask:GetTaskDataByType(tType)
    local datas = {}
    for k,v in pairs(self.m_taskTrackData) do
        local id = k
        local cfg = JsonConfig.m_dailyConfig.getDefByID(id)
        if cfg ~= nil and cfg.type == tType then
            table.insert(datas,v)
        end
    end
    return datas
end

function LCTask:Delete()
    self.m_taskTrackData = nil
    self.m_taskCompleteData = nil
end

--[[
宠物相关
]]
LCPet = {}
LCPet.__index = LCPet

function LCPet:New()
    local o = {}
    setmetatable(o,LCPet)
    o:Init()
    return o
end

function LCPet:Init()
	self.petlist = {}
	self.bestPet = nil
	self.followPetId = 0--跟随宠物id
    self.totalExpInBag = -1--背包里面可以升级的宠物经验丹的经验总和，-1表示没有初始化
    self.skBooksInBag = nil--背包里面所有的技能书
    self.equipList = LPetEquipBag:New() --宠物装备背包
    self.faBaoList = LPetFaBaoBag:New() --宠物碎片背包
	self.masterList = {} --宠物阵型位置装备和法宝强化大师等级
    self.ShowPosList = {} --宠物出站顺序
end

function LCPet:Reset()
    for i = #self.petlist, 1, -1 do
        self.petlist[i]:Delete()
        self.petlist[i] = nil
    end
    self.petlist = {}
    self.bestPet = nil
    self.followPetId = 0--跟随宠物id
    self.totalExpInBag = -1--背包里面可以升级的宠物经验丹的经验总和，-1表示没有初始化
    self.skBooksInBag = nil--背包里面所有的技能书

    for i = #self.equipList, 1, -1 do
        self.equipList[i]:Delete()
        self.equipList[i] = nil
    end
    self.equipList = {}
    self.faBaoList = LPetFaBaoBag:New()
    self.ShowPosList = {} --宠物出站顺序
end

function LCPet:ResetFightPos()
    for k,v in pairs(self.petlist) do
        v.fightPos = 0
    end
end

function LCPet:getFaBaoPos( uid )
    -- body
    local index = 0
    for k,v in pairs(self.faBaoList.m_petFaBaos) do
        idnex = index + 1
        if v.m_uid == uid then
            return index
        end
    end
    return index 
end

--[[
根据宠物id获取宠物
]]
function LCPet:GetPetById(pid)
	for i = 1, #self.petlist do
		if self.petlist[i].id == pid then
			return self.petlist[i]
		end
	end
	return nil
end

--[[
根据装备uid,获取装备数据
]]
function LCPet:GetEquipByUId(uid)
    return self.equipList.m_petEquips[uid]
end

--[[
根据法宝uid,获取法宝数据
]]
function LCPet:GetFaBaoById(uid)
    return self.faBaoList.m_petFaBaos[uid]
end

--[[
是否拥有宠物
]]
function LCPet:IsOwnPetById(pid)
    for i = 1, #self.petlist do
        if self.petlist[i].id == pid then
            return true
        end
    end
    return false
end

--[[
阵容展示位置
]]
function LCPet:GetPetByFightPos(posInd)
    local petId = self.ShowPosList[posInd]
	for i = 1, #self.petlist do
		if self.petlist[i].id == petId then
			return self.petlist[i]
		end
	end
    --默认数据
	return self.petlist[1]
end

--[[
根据宠物出站位获取宠物
param1:posInd出站位
return:LPetData
]]
function LCPet:GetPetByFightPosFormation(posInd)
    for i = 1, #self.petlist do
        if self.petlist[i].fightPos == posInd then
            return self.petlist[i]
        end
    end
    return nil
end

function LCPet:GetPetPos( petID )
    -- body
    for i=1, #self.ShowPosList do
        if self.ShowPosList[i] == petID then
            return i
        end
    end
    return 0
end

function LCPet:GetPetListAndReset()
    if self.petlist == nil then
        self.petlist = {}
    end
	for i = #self.petlist, 1, -1 do
		self.petlist[i]:Delete()
		self.petlist[i] = nil
	end
	self.petlist = {}
	return self.petlist
end

function LCPet:SortPetList()
	--I、优先出战神将，出战神将按照站位顺序1、2、3、4、5排列显示
	--II、其次非出战神将，按照战力从高到低依次排序显示

    --[[
    备注：出站神将不按照站位顺序了，按照战斗力
    ]]
    function sortFunc(a, b)
        local showPosA = LRoleDataMgr.Pet:GetPetPos(a.id)
        local showPosB = LRoleDataMgr.Pet:GetPetPos(b.id)
        if showPosA > 0 and showPosB > 0 then 
            return showPosA < showPosB
        elseif showPosA == 0 and showPosB > 0 then
            return false
        elseif showPosA > 0 and showPosB == 0 then
            return true
        else
            return showPosA > showPosB
        end 
    end 
    table.sort(self.petlist, sortFunc)
    self.totalExpInBag = -1
 end

 --删除宠物
 function LCPet:DelPetById(petId)
     for k,v in pairs(self.petlist) do
         if petId == v.id then
             v:Delete()
		     table.remove(self.petlist,k)
             break
         end
     end
 end

 --删除法宝
 function LCPet:DelFabaoById(fabaoId)
    local index = 0
     for k, v in pairs(self.faBaoList.m_petFaBaos) do
        index = index + 1
        if fabaoId == v.m_uid then
            -- print("DelFabaoById==>", fabaoId, v.m_uid, k, index)
            self.faBaoList.m_petFaBaos[k] = nil
            break
        end
     end
     -- dump(self.faBaoList.m_petFaBaos, "DelFabaoById =======================>")
 end

--[[
阵容相关
]]
LCFormation = {}
LCFormation.__index = LCFormation

function LCFormation:New()
    local o = {}
    setmetatable(o,LCFormation)
    o:Init()
    return o
end

function LCFormation:Reset()
    self.useId = 0--当前使用的阵法id
    self.openFormationArr = {}--以开通的阵法，里面保存的是id和等级
end

function LCFormation:Init()
	self.useId = 0--当前使用的阵法id
	self.openFormationArr = {}--以开通的阵法，里面保存的是id和等级
end

--[[
获取我的阵容中的某个阵法的等级
@param1:fid 阵法id
@return:lv 0未学习，大于0当前阵法等级
]]
function LCFormation:GetMyZhenfaLvById(fid)
	for i = 1,#self.openFormationArr do
		if self.openFormationArr[i][1] == fid then
			return self.openFormationArr[i][2]
		end
	end
	return 0
end

-- --[[
-- 阵法是否开启
-- ]]
-- function LCFormation:IsLearned(fid)
-- 	for i = 1,#self.openFormationArr do
-- 		if self.openFormationArr[i][1] == fid then
-- 			return true
-- 		end
-- 	end
-- 	return false
-- end

function LCFormation:ResetMyFormations()
	for i = #self.openFormationArr, 1 -1 do
		self.openFormationArr[i] = nil
	end
	self.openFormationArr = {}
	return self.openFormationArr
end

function LCFormation:GetMyFormations()
	return self.openFormationArr
end

--[[
添加新阵法
]]
function LCFormation:AddFormation(fid, lv)
	for i = 1, #self.openFormationArr do
		if self.openFormationArr[i][1] == fid then
			self.openFormationArr[i][2] = lv
			return
		end
	end
	table.insert(self.openFormationArr,{ fid, lv })
end


LRoleDataMgr = LUIBase:New()
LRoleDataMgr.__index = LRoleDataMgr


function LRoleDataMgr:Init()
	self.msgIds = 
	{
		--LDataRoleEvent.InitRoleData,
        LUIRoleDataChangeEvent.InitRoleNode,
        LUIRoleDataChangeEvent.LvUp,
        LUILogicEvent.EnterBattle,
		LUILogicEvent.ExitBattle,
		LUIRoleDataChangeEvent.StartHangUp,
		LUIRoleDataChangeEvent.StopHangUp,
        LUIRoleDataChangeEvent.ChangeUser,
	}
	self:RegistSelf(self,self.msgIds)
    self.m_strCreateName = ""--创建角色时的名字，临时用
    self.m_iCreateId = ""--创建角色时的Id，临时用
    self.m_bIsCrossServer = false--跨服标志
    self.m_bIsChangeCrossServerState = false
	self.Account = LCAccount:New()
    self.MyHeroInfo = LRoleData:New()
    self.OtherHeroInfo = LRoleData:New()    --其他人物信息
    self.Faction = LCFaction:New()          --帮派信息
    self.IsOpenCharge = 0                   --0未开启，1开启
    self.Equip = LCEquip:New()
    self.HeroSkills = {}                    --我的人物技能

    self.Task = LCTask:New()                --我的任务
    self.m_ServerChiBangList = {}           --服务器下发的所有翅膀信息
    self.m_ServerShenQiList = {}            --服务器下发的神器信息
    self.m_otherShenqi = {}                 --其他人物的神器信息
    self.MysteryInfo = LShopMysteryInfo:New()   --神秘商店信息

    self.Chat = LCChat:New() --聊天信息
    self.Social = LCSocial:New() --社交信息

    --self.MedalList = LMedalInfo:New() --称号列表
    self.MedalList = {}
    self.m_bIsInBattle = false
    self.m_kunlunShanData = LKunlunShanData:New() -- 昆仑山

    self.Pet = LCPet:New()--神将相关数据
    self.m_book = LCBook:New()
    self.totalExpInBag = 0

    self.myFormation = LCFormation:New()--阵容数据
    --全局标志位
    self.isNextTimeRemond = Utils:initLuaTable(AppDef.MAX_REMOND_NUM, false)
    self.isInBattle = false
    self.isShowLvUp = false;
    self.MonopolyData = LMonopolyData:New()

    --挂机状态
    self.isHangUp = false

    --是否是第一次进入游戏
    self.isFirstLogin = true
    --是否开启充值奖励
    self.IsOpenCharge = 0
    --首充领取状态
    self.m_firstRechargeState = -1
    --次充领取状态
    self.m_secondRechargeState = -1

    self.m_consumptionGiftData = LActiveAward:New()  --累计消费充值

    --保存的客户端数据
    self.m_settingData = {}
    --保存的客户端字符串数据
    self.m_settingStringData = {}
    --已完成新手引导
    self.m_completeGuide = {}
    self.upgradeItems = {834,835,836,837}

    self.m_isShowRandPetUI = false
    --钓鱼房间Id
    self.FishRoomID = -1
    --开启的玩法Id，用于主界面按钮
    self.OpenedActData = {}

    --标志在高级挖宝中
    self.IsInHighTreasuer = false
    self.IsHighTreasuerMsg = ""
    --自动寻路
    self.autoPathCor = nil
	self.IsAutoPath = false
    --战斗速度
    self.m_fightSpeed = LUserConfigMgr:GetBattleSpeed()
    --自动寻路数据
    self.autoPathServer = {}

    --资源找回
    --self.recoveryData = LOfflineResInfo:New()
    self.recoveryData = {}

    --升星数据缓存
    self.tempPetUpStarData = {}

    --成长基金
    self.fundRebateData = nil

    self.huoyueJiJinData = nil

    --用于后台时间过长,重新登录游戏
    self.m_bIsmainInited = false

    --用于付费预告
    self.m_showIndex = 0
    self.m_petDiscPreView = 0
    self.m_isShowPaiHang = false

    --折扣商店倒计时
    self.m_DisCountShopEndTime = 0
    --世界等级加成级别
    -- self.WorldLevel=0
    -- self.WorldLevelPercent=0
    -- self.WorldLevelOpenLimit=0

    --是否延迟获得奖励动画
    self.m_delayAwardAnim = false
    self.m_delayAwardList = {}

    --采集中
    self.m_isNPCCollecting = false

    self.isUseHueYue = nil
    self.alreadyUseTime = nil
    self.curHuoYueBoxStr = ""

    --战斗回放数据
    self.m_replayInd = 0
    self:ClearBattleReplayData();

    self.m_shopTempInfo = nil--商城道具购买次数临时存储
    self.m_activityInfo = nil--活动临时数据存储
	
	self.m_fengshenshilianData = nil --封神试炼数据
	self.m_kunlunjuezhanData = nil --昆仑决战数据

    self.m_isTipPetCompound = true--提示宠物合成

    --是否是刚从后台回来
    self.m_isEnterIngForeground = false
end

function LRoleDataMgr:ProcessEvent(msg)
	local msgId = msg:GetMsgId()
    if msgId == LUIRoleDataChangeEvent.InitRoleNode then
        self.MyHeroInfo.node = msg:GetMyHeroNode()
    elseif msgId == LUIRoleDataChangeEvent.LvUp then
    	self:MyHeroLvUp()
    elseif msgId == LUILogicEvent.EnterBattle then
		self.m_bIsInBattle = true
	elseif msgId == LUILogicEvent.ExitBattle then
		self.m_bIsInBattle = false
	elseif msgId == LUIRoleDataChangeEvent.StartHangUp then
		self.isHangUp = true
	elseif msgId == LUIRoleDataChangeEvent.StopHangUp then
		self.isHangUp = false
        self.autoPathServer.opt = nil
    elseif msgId == LUIRoleDataChangeEvent.ChangeUser then
        self:ChangeUser()
    end
end

function LRoleDataMgr:ChangeUser()
    self.Account:Reset()
    self.MyHeroInfo:Reset()
    self.OtherHeroInfo:Reset()
    self.Faction:Reset()
    self.IsOpenCharge = 0                   --0未开启，1开启
    self.Equip:Reset()
    self.HeroSkills = {}                    --我的人物技能
    self.Task:Delete()
    self.Task = LCTask:New()                --我的任务
    self.m_ServerChiBangList = {}           --服务器下发的所有翅膀信息
    self.m_ServerShenQiList = {}            --服务器下发的神器信息
    self.m_otherShenqi = {}                 --其他人物的神器信息
    self.MysteryInfo:Delete()
    self.MysteryInfo = LShopMysteryInfo:New()   --神秘商店信息

    self.Chat:Reset()
    self.Social:Reset()

    -- for i = #self.MedalList, 1 -1 do
    --     self.MedalList[i]:Delete()
    --     self.MedalList[i] = nil
    -- end
    self.MedalList = {}
    self.m_bIsInBattle = false
    self.m_kunlunShanData:Reset()

    self.Pet:Reset()
    self.totalExpInBag = 0

    self.myFormation:Reset()
    --全局标志位
    self.isNextTimeRemond = Utils:initLuaTable(AppDef.MAX_REMOND_NUM, false)
    self.isInBattle = false
    self.isShowLvUp = false;
    self.MonopolyData:Reset()


    --挂机状态
    self.isHangUp = false

    --是否是第一次进入游戏
    self.isFirstLogin = true
    --是否开启充值奖励
    self.IsOpenCharge = false
    --首充领取状态
    self.m_firstRechargeState = -1
    --次充领取状态
    self.m_secondRechargeState = -1

    self.m_consumptionGiftData:Reset()

    --保存的客户端数据
    self.m_settingData = {}
    --保存的客户端字符串数据
    self.m_settingStringData = {}
    --已完成新手引导
    self.m_completeGuide = {}

    --资源找回
    --self.recoveryData = LOfflineResInfo:New()
    self.recoveryData = {}

    --同步战斗中BOSS血量
    self.m_bossHpData = nil

    --资源找回是否点击过,点击过将不在显示红点
    self.m_resRecoveryClicked = false

    --战斗结果数据
    self.m_fightResultData = nil

    --战斗回放数据
    self.m_replayInd = 0
    self:ClearBattleReplayData();

    self.m_shopTempInfo = nil
    self.m_activityInfo = nil

end

--设置商城道具购买次数暂存信息
function LRoleDataMgr:SetShopTempInfo(itemId,cnt)
    if self.m_shopTempInfo == nil then
        self.m_shopTempInfo = {}
    end
    self.m_shopTempInfo.itemId = itemId
    self.m_shopTempInfo.cnt = cnt
    print("LRoleDataMgr:SetShopTempInfo",itemId,cnt)
end

--活动暂存信息
function LRoleDataMgr:GetActivityInfo()
    if self.m_activityInfo == nil then
        self.m_activityInfo = {}
    end
    return self.m_activityInfo
end

--[[
帮派副本是否开启
]]
function LRoleDataMgr:GetBPChapterData(id)

    if self.Faction == nil then
        return nil
    end
    return self.Faction.chapterArr[id]
end

function LRoleDataMgr:IsReplayBattleOver()
    if self.m_battleRePlayData == nil or #self.m_battleRePlayData == 0 then
        return true;
    end
    if self.m_replayInd == #self.m_battleRePlayData then
        return true
    end
    local tmp = self.m_battleRePlayData[self.m_replayInd + 1];
    tmp:SetSeek(6);
    local cmdId = tmp:GetNetCmdId()
    if cmdId == LuaNetCmd.MSG_BATTLE_OVER then
        return true;
    end
    return false;
end

function LRoleDataMgr:ReplayBattle(isStart,op)
    if self.m_battleRePlayData == nil or #self.m_battleRePlayData == 0 then
        return;
    end
    isStart = isStart or false
    if isStart then
        self.m_replayInd = 0;
        self.m_rePlayType = op;
    end
    -- print("ReplayBattle",self.m_replayInd,#self.m_battleRePlayData)
    if self.m_replayInd  >= #self.m_battleRePlayData then
        self.m_replayInd = 0;
    end
    self.m_replayInd = self.m_replayInd + 1;
    local tmp = self.m_battleRePlayData[self.m_replayInd];
    tmp:SetSeek(6);
    local cmdId = tmp:GetNetCmdId()
    -- print("cmdId",cmdId)
    if cmdId == LuaNetCmd.MSG_ENTER_BATTLE then
        LuaNetRecvdMsg.RecvEnterBattle(tmp,true);
    elseif cmdId == LuaNetCmd.MSG_BATTLE then
        LuaNetRecvdMsg.RecvDoBattle(tmp,true);
    elseif cmdId == LuaNetCmd.MSG_BATTLE_OVER then
        LuaNetRecvdMsg.RecvBattleOver(tmp,true);
    end
end

function LRoleDataMgr:GenReplayResult()
    --self.m_battleRePlayData
    -- if self.m_rePlayType == 5 then
    --     local tmp = self.m_battleRePlayData[#self.m_battleRePlayData];
    --     tmp:SetSeek(6);
    --     local cmdId = tmp:GetNetCmdId()
    --     if cmdId == LuaNetCmd.MSG_BATTLE_OVER then
    --         LuaNetRecvdMsg.RecvBattleOver(tmp,true);
    --     end
    -- end

    local tmp = self.m_battleRePlayData[#self.m_battleRePlayData];
    tmp:SetSeek(6);
    local cmdId = tmp:GetNetCmdId()
    if cmdId == LuaNetCmd.MSG_BATTLE_OVER then
        LuaNetRecvdMsg.RecvBattleOver(tmp,true);
    end
end

-- function LRoleDataMgr:ReplayEnd()
--     if self.m_battleRePlayData == nil or #self.m_battleRePlayData == 0 then
--         return;
--     end
    
--     self.m_replayInd = 0
--     local tmp = self.m_battleRePlayData[#self.m_battleRePlayData];
--     tmp:SetSeek(6);
--     local cmdId = tmp:GetNetCmdId()
--     if cmdId == LuaNetCmd.MSG_ENTER_BATTLE then
--         LuaNetRecvdMsg.RecvEnterBattle(tmp,true);
--     elseif cmdId == LuaNetCmd.MSG_BATTLE then
--         LuaNetRecvdMsg.RecvDoBattle(tmp,true);
--     elseif cmdId == LuaNetCmd.MSG_BATTLE_OVER then
--         LuaNetRecvdMsg.RecvBattleOver(tmp,true);
--     end
-- end

function LRoleDataMgr:ClearBattleReplayData()
    if self.m_battleRePlayData ~= nil then
        for i = 1, #self.m_battleRePlayData do
            self.m_battleRePlayData[i]:release()
        end
    end
    self.m_battleRePlayData = nil
end

function LRoleDataMgr:AddBattleReplayData(data)
    if self.m_battleRePlayData == nil then
        self.m_battleRePlayData = {}
    end

    local tmp = data:CopyData();
    tmp:retain()
    table.insert(self.m_battleRePlayData,tmp);
end

function LRoleDataMgr:SetBattleReplayData(dataArr)
    self:ClearBattleReplayData()
    self.m_battleRePlayData = dataArr
end

function LRoleDataMgr:GetBattleReplayData()
    return self.m_battleRePlayData;
end

function LRoleDataMgr:SetFightDatum(pos,values)
    values = values or {0,0,0}
    if self.m_fightDatum == nil then
        self.m_fightDatum = {}
    end
    if self.m_fightDatum.Units == nil then
        self.m_fightDatum.Units = {}
    end
    for i=1,2 do
        if self.m_fightDatum.Units[i] == nil then
            self.m_fightDatum.Units[i] = {}
        end
        local sign = false
        local unitData = self.m_fightDatum.Units[i]
        for k=1,#unitData do
            if unitData[k].pos == pos then
                unitData[k].value = {}
                local max = math.max(#values,3)
                for n=1,#values do
                    unitData[k].value[n] = {}
                    unitData[k].value[n].curVal = values[n]
                end
                sign = true
                break
            end
        end
        if sign then
            break
        end
    end
end

function LRoleDataMgr:UpdateFightDatum()
    if self.m_fightDatum.Units == nil or self.m_fightDatum.Units == nil then
        return
    end
    local data = self.m_fightDatum.Units
    local maxVal = {0,0,0}
    for i=1,2 do
        local tmp = data[i]
        for k=1,#tmp do
            if tmp[k].value == nil then
                tmp[k].value = {}
            end
            for n = 1,3 do
                if tmp[k].value[n] == nil then
                    tmp[k].value[n] = {}
                end
                if tmp[k].value[n].curVal == nil then
                    tmp[k].value[n].curVal = 0
                end
                if maxVal[n] < tmp[k].value[n].curVal then
                    maxVal[n] = tmp[k].value[n].curVal
                end
            end
        end
    end
    for i=1,2 do
        local tmp = data[i]
        for k=1,#tmp do
            for n = 1,3 do
                tmp[k].value[n].maxVal = maxVal[n]
            end
        end
    end
end

function LRoleDataMgr:GetFightDatum()
    if self.m_fightDatum == nil then
        self.m_fightDatum = {}
    end
    return self.m_fightDatum
end


function LRoleDataMgr:MyHeroLvUp()

	--用户升级之后检查相关功能的小红点
	LRedDotCheckMgr:WanFaRedDotCheck()
    LRedDotCheckMgr:PetBagRedCheck()
	LRedDotCheckMgr:FuBenRedDotCheck()
    local level = LRoleDataMgr.MyHeroInfo.level  --声音冲突，等级语音不说
    if level< 4 or level == 8 or level == 10 or level == 14 or level == 19 or level == 23 then
        return
    end
    LGameMsg.m_baseMsgWithOne:Change(LAudioEvent.PlayEffect, AppDef.SysBGM.Upgrade)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)

 
	if self.MyHeroInfo.node == nil then
		return
	end
	if self.m_bIsInBattle == true then
		return
	end
--	local function ShowEffect()
--		local imod = ImodAnim:createWithFileSync("UI/shengjichutu")
--		imod:PlayAction(0)
--		local function AniPlayEndCallback(sender)
--			sender:removeFromParent()
--		end
--		imod:registerScriptEndCBHandler(AniPlayEndCallback)
--		self.MyHeroInfo.node:addChild(imod)

--		LGameMsg.m_baseMsgWithOne:Change(LAudioEvent.PlayEffect, AppDef.SysBGM.Upgrade)
--		self:SendMsg(LGameMsg.m_baseMsgWithOne)
--	end
--	Utils:DelayToCallFunc(self.MyHeroInfo.node, 0.1, ShowEffect)
--采用资源异步加载后不需要delay了
 --    local imod = ImodAnim:createWithFileSync("UI/shengjichutu")
	-- imod:PlayAction(0)
	-- local function AniPlayEndCallback(sender)
	-- 	sender:removeFromParent()
	-- end
	-- imod:registerScriptEndCBHandler(AniPlayEndCallback)
	-- self.MyHeroInfo.node:addChild(imod)

    local level = LRoleDataMgr.MyHeroInfo.level  --声音冲突，等级语音不说
    if level< 4 or level == 8 or level == 10 or level == 14 or level == 19 or level == 23 then
        return
    else
        if level > 25 then
            LGameMsg.m_baseMsgWithOne:Change(LAudioEvent.PlayShortEffect, AppDef.SysBGM.Upgrade)
            self:SendMsg(LGameMsg.m_baseMsgWithOne)
            if LUIRoleDataChangeEvent.CheckOpenBuffTips then
                LGameMsg.m_baseMsgWithOne:Change(LUIRoleDataChangeEvent.CheckOpenBuffTips,AppDef.BuffType.WorldLevel)
                self:SendMsg(LGameMsg.m_baseMsgWithOne)
                 LuaNetSendMsg:QueryWorldLevel()
            end
        else
            LGameMsg.m_baseMsgWithOne:Change(LAudioEvent.PlayEffect, AppDef.SysBGM.Upgrade)
            self:SendMsg(LGameMsg.m_baseMsgWithOne)
        end
        
    end	

end

function LRoleDataMgr:Instance()
	return self
end

function LRoleDataMgr:LoadData()
	
end

function LRoleDataMgr:ReadRoleData(stream)
	local heroData = self.MyHeroInfo
    heroData.id = stream:ReadUInt()
    heroData.name = stream:ReadString()
    --头像，不用
    heroData.sex = stream:ReadByte()
    heroData.model = stream:ReadByte()
    heroData.head = stream:ReadByte()
    heroData.level = stream:ReadWord()
    heroData.DetailData.exp = stream:ReadULongInt()
    --heroData.zhanDouLi = stream:ReadUInt()--人物战斗力
    heroData.zhanDouLiInAll = stream:ReadULongInt()--总战斗力
    --print("zhanDouLiInAll 1",heroData.zhanDouLiInAll)
    
    heroData.DetailData:setMoney(stream:ReadInt())
    heroData.DetailData:setTongBao(stream:ReadInt())
    heroData.DetailData:setBindTongBao(stream:ReadInt())
    heroData.DetailData:setPotential(stream:ReadUInt())
    local shenhun = stream:ReadUInt()
    heroData.DetailData:setShenHun(shenhun)
    --heroData.DetailData:setXinXiuJingHua(stream:ReadUInt())
    heroData.packageOpenNum = stream:ReadWord()
    ----------------------------------------------/
    --增加读取个人帮派信息
    heroData.FactionId = stream:ReadUInt()
    heroData.FactionRankType = stream:ReadByte()--职位
    heroData.FactionName = stream:ReadString()
    heroData.showFactionName = stream:ReadByte()
    if heroData.FactionId == 0 then
        heroData.showFactionName = 0
    end
    local banggong = stream:ReadUInt()
    
    --将个人帮派信息赋值给专门存个人储帮派信息的类
    info = self.Faction.Info
    info.id = heroData.FactionId
    info.rank = heroData.FactionRankType
    info.name = heroData.FactionName
    info.isShowBPName = heroData.showFactionName
    if LRoleDataMgr.Faction and LRoleDataMgr.Faction.Info then
        LRoleDataMgr.Faction.Info:SetselfBangGong(banggong)
    end
    ----------------------------------------------/
--     --TalkingData接入：设置账户 DATA_MGR->Account.uid
-- #if (CC_TARGET_PLATFORM ~= CC_PLATFORM_WIN32)
--     -- TDCCAccount* account = TDCCAccount::setAccount(INT2STR(heroData.id).c_str())
--     -- account->setGameServer(USER_CFG->GetLastSelServerName().c_str())
--     -- account->setLevel(heroData.level)
--     -- account->setAccountName(heroData.name.c_str())
-- #endif
    --台湾 Event
    -- if(ark_Download::IsTaiWanSdk())
    --     CallJava_goTaiWanLoginSuc(USER_CFG->GetLastSelServerId())

    local openRecharge = stream:ReadByte()  --0:未开启，1开启
    --heroData.yaoLingLv = stream:ReadByte()--妖靈等級
    
    --heroData.WingsId = stream:ReadByte()  --翅膀id
    heroData.ShapeId = stream:ReadUInt()
    heroData.shapeIdState = stream:ReadByte()
    
    heroData.meili =  stream:ReadUInt()
    heroData.create_time = stream:ReadUInt()
    heroData.serverId = stream:ReadUInt()
    if self.Account:IsMultiServer() == true then
        heroData.serzoneid = stream:ReadUInt()
    end
    --dump(self.MyHeroInfo)
    --heroData.DetailData:setXinXiuJingHua()

    --CCLOG("SELECT ROLE role===============================%d",heroData.create_time)
    self.IsOpenCharge = openRecharge
    -- if self.isFirstLogin == true then
    -- 	self.isFirstLogin = false
    -- 	local luaEvtsMsg = LuaEvtToC:new(CEnum.GameLogicEvent.SetLuaEvts,
    --                                     LGameEvent.ChangeMap,
    --                                     LGameEvent.ChangeMapSuccess,
    --                                     LUILoadingEvt.ShowLoadingProcess,
    --                                     LGameEvent.EnterBattle,
    --                                     LGameEvent.ExitBattle,
    --                                     LUIRoleDataChangeEvent.InitRoleNode,
    --                                     LUIMainEvent.ClickNearHeros,
    --                                     LPlantEvent.PlantEvent,
    --                                     LUIRoleDataChangeEvent.StartHangUp,
    --                                     LUIRoleDataChangeEvent.StopHangUp,
    --                                     LUIMainEvent.WorshipEvent,
    --                                     LAudioEvent.CPlayNPCEffect,
    --                                     LGameEvent.EnterBackGround,
    --                                     LGameEvent.EnterForeground,
    --                                     LUIRoleDataChangeEvent.ClickMapToMove)
    -- 	self:SendMsg(luaEvtsMsg)
    -- end
    
    -- local enterGameMsg = EnterGameMsg:new(CEnum.GameLogicEvent.EnterScene,
    -- 									heroData.id, heroData.name, 
    -- 									heroData.professional, 
    --                                     heroData.sex,
    -- 									heroData.WingsId,
    -- 									heroData.ConvoyType,
    -- 									heroData.m_Convoy.Quality,
    -- 									heroData.sid,heroData.posx,heroData.posy)
    -- self:SendMsg(enterGameMsg)
    
    LGameMsg.m_baseMsg:ChangeEventId(LGameEvent.EnterGame)
    self:SendMsg(LGameMsg.m_baseMsg)

    

    local target = cc.Application:getInstance():getTargetPlatform()
    if AppDef.OPEN_BUGLY and target == cc.PLATFORM_OS_ANDROID then
        buglySetUserId(tostring(heroData.id))
    end

    GameSdk:U8SendInfo(3, heroData.serverId, heroData.id, heroData.name)
    LGameMsg.m_baseMsg:ChangeEventId(LUIRoleDataChangeEvent.PowerChanged)
    self:SendMsg(LGameMsg.m_baseMsg)

    LGameMsg.m_baseMsg:ChangeEventId(LGameEvent.ChangeMapSuccess)
    self:SendMsg(LGameMsg.m_baseMsg)
    
    -- if target == cc.PLATFORM_OS_ANDROID and GameSdk:IsSDKUser() then
    --     GameSdk:U8SendInfo()
    --     GameSdk:U8SendRoleInfo(0, 0,"", heroData.DetailData:GetTongBao(), 
    --         heroData.id, LRoleDataMgr.MyHeroInfo.serverId,heroData.level,heroData.name,"DefaultServer")
    -- end
end

function LRoleDataMgr:GetPacSize()
    return self.MyHeroInfo.packageOpenNum
end

function LRoleDataMgr:GetServerChiBangList()   return self.m_ServerChiBangList end                 --服务器下发的所有翅膀信息
function LRoleDataMgr:GetMysteryInfo()   return self.MysteryInfo end

function LRoleDataMgr:GetServerChiBang(id)  -- 获取指定id的翅膀信息
    for key, wing in pairs(self.m_ServerChiBangList) do
        if wing.id == id then
            return wing
        end
    end
    return nil
end 

function LRoleDataMgr:SetShenQiState(shenqiId,state)--设置神器状态：0-未获得，1-休息，2-使用
    for i = 1,#self.m_ServerShenQiList do
       if self.m_ServerShenQiList[i].id == shenqiId then
          self.m_ServerShenQiList[i].state = state
          break
       end
    end
end

function LRoleDataMgr:GetShenQiDataById(shenqiId)
    if shenqiId == 0 then
        return nil
    end
    for i = 1,#self.m_ServerShenQiList do
       if self.m_ServerShenQiList[i].id == shenqiId then
          return self.m_ServerShenQiList[i]
       end
    end
    return nil
end

function LRoleDataMgr:GetShenQiIndxById(shenqiId)--获得神器索引
    if shenqiId == 0 then
        return nil
    end
    for i = 1,#self.m_ServerShenQiList do
       if self.m_ServerShenQiList[i].id == shenqiId then
          return i
       end
    end
    return nil
end

--获取神器列表(排序)
function LRoleDataMgr:SortShenQiList()
    local list = {}
    local idList = {}
    for i = 1,#self.m_ServerShenQiList do
       if self.m_ServerShenQiList[i].state == 0 then
          table.insert(list,self.m_ServerShenQiList[i])
          table.insert(idList,self.m_ServerShenQiList[i].id)
       end
    end
    for i=1,#idList do
        for k = 1,#self.m_ServerShenQiList do
            if idList[i] == self.m_ServerShenQiList[k].id then
               table.remove(self.m_ServerShenQiList,k)
               break
            end
        end
    end
    for i=1,#list do
        table.insert(self.m_ServerShenQiList,list[i])
    end
end

--称号按照战斗力排序
function LRoleDataMgr:SortMedalList()
    local function big_power(m1, m2)
        return m1.zhandouli > m2.zhandouli
    end

    table.sort(self.MedalList, big_power)
end

--是否拥有此称号
function LRoleDataMgr:isHaveTheMedal(id)
    -- body
    for i = 1, #self.MedalList do
        if self.MedalList[i].id == id then
            return true
        end
    end
    return false
end

--获取道具的图片ID
--C++使用，务必不要把.改成:
function LRoleDataMgr.GetItemPicId(itemId)
	local itemBaseData = LItemMgr:getItem(itemId)
	return itemBaseData.pic
end

--根据道具ID查找背包中数据
function LRoleDataMgr:GetPItemFromBagById(id)
    if id == nil or id == 0 then return nil end
    for k,v in pairs(self.Equip.PackageMap) do
        if v.m_id == id then
            return v
        end
    end
    return nil
end

function LRoleDataMgr:GetSkillDetailById(id)
    for i=1,#self.HeroSkills do
        if(self.HeroSkills[i].id == id) then
            return self.HeroSkills[i]
        end
    end
    return nil
end

function LRoleDataMgr:IsInSpaicialScene()
	local sid = self.MyHeroInfo.sid
	if((sid >= 1 and sid <= 14) or sid == 56) then
		SceneType = AppDef.SceneType.MSI_NORMAL
	elseif(sid == 45) then
		SceneType = AppDef.SceneType.MSI_FACTION_WAR_PRE
	elseif(sid == 46 or sid == 56 ) then
		SceneType = AppDef.SceneType.MSI_FACTION_WAR
	elseif(sid == 47) then
		SceneType = AppDef.SceneType.MSI_FACTION_ZONE
	elseif(sid == 51) then
		SceneType = AppDef.SceneType.MSI_LEITAISAI
	elseif(sid == 53 or sid == 170) then
		SceneType = AppDef.SceneType.MSI_FIARYLAND
	elseif(sid > 53 and sid < 56) then
		SceneType = AppDef.SceneType.MSI_FISHROOM
	elseif(sid == 70) then
		SceneType = AppDef.SceneType.MSI_CROSSSERVER
	elseif(sid == 71 or sid == 72) then
		SceneType = AppDef.SceneType.MSI_LUNDAO
	elseif(sid == 73) then
		SceneType = AppDef.SceneType.MSI_WEIWODUXIAN
	elseif(sid == 74 or sid == 75) then
		SceneType = AppDef.SceneType.MSI_SHENJIEMIJING
	elseif(sid == 76) then
		SceneType = AppDef.SceneType.MSI_MULTISER_FACTION_BATTLE_READY
	elseif(sid == 77) then
		SceneType = AppDef.SceneType.MSI_MULTISER_FACTION_BATTLE
	elseif(sid > 60 and sid < 121) then
		SceneType = AppDef.SceneType.MSI_TOWER
	elseif(sid > 120 and sid < 151) then
		SceneType = AppDef.SceneType.MSI_KUNLUN
	elseif(sid >= 162 and sid <= 165) then
		SceneType = AppDef.SceneType.MSI_PETCOPY
	elseif(sid == 161 or sid >=166 and sid < 174 ) then
		SceneType = AppDef.SceneType.MSI_COPY
	elseif(sid == 174) then
		SceneType = AppDef.SceneType.MSI_SHILIAN
	elseif(sid >= 175 and sid<=179) then
		SceneType = AppDef.SceneType.MSI_FLYFARY
	elseif(sid == 201) then
		SceneType = AppDef.SceneType.MSI_COUPLE_COPY
	end
	 --跨服场景是正常场景
	return (SceneType ~= AppDef.SceneType.MSI_NORMAL)
end

--获取藏宝图在背包中的位置(低阶优先)
function LRoleDataMgr:FindCangbaotuPos()
    for k,v in pairs(AppDef.CangBaotuIds) do
        local pos = self.Equip:FindPackageItemById1(v)
        if pos > 0 then
            return pos
        end 
    end
    return 0
end
--获取设置数据
function LRoleDataMgr:GetSettingConfig(id)
	id = tostring(id)
	return self.m_settingData[id]
end
--获取设置数据
function LRoleDataMgr:SetSettingConfig(id, val)
    id = tostring(id)
    self.m_settingData[id] = val
end
--获取设置数据
function LRoleDataMgr:GetSettingStringConfig(id)
	id = tostring(id)
	return self.m_settingStringData[id]
end
--设置设置数据
function LRoleDataMgr:SetSettingStringConfig(id, str)
	self.m_settingStringData[tostring(id)] = str
end
--获取是否完成引导
function LRoleDataMgr:isGuideComplete(step, transform)
	if step == nil then
		return false
	end
	if transform then
		step = math.floor(step / 100)
	end
	return Utils:ToBool(self.m_completeGuide[tostring(step)])
end
--设置完成引导
function LRoleDataMgr:setGuideComplete(step, transform, notNet, val)
	if step == nil then
		return
	end
	if transform then
		step = math.floor(step / 100)
	end
	self.m_completeGuide[tostring(step)] = (val ~= nil and {Utils:ToBool(val)} or {true})[1]
	if not Utils:ToBool(notNet) then
		self:QueryGuideComplete()
		LuaNetSendMsg:QuerySetSettingInfo(AppDef.ServerSetIndex.SSI_CURRENT_GUIDE, "0")
        LUserConfigMgr:SetUserCurGuide(0)
	end
end
--发送完成引导数据到服务端
function LRoleDataMgr:QueryGuideComplete(step, transform)
	local str = ""
	local temp = {}
	if transform and step then
		if not self:isGuideComplete(step, transform) then
			temp[tostring(math.floor(step / 100))] = true
		end
	end
	for k,v in pairs(self.m_completeGuide) do
		temp[tostring(k)] = true
	end
	for k,v in pairs(temp) do
        if #str > 0 then
		  str = str .. "," 
        end
        str = str .. tostring(k)
	end
    --dump(str,"@@@@@@@@@@@@@@@@ guide str==>")
	LRoleDataMgr:SetSettingStringConfig(AppDef.ServerSetIndex.SSI_FINISH_GUIDE, str)
	LuaNetSendMsg:QuerySetSettingInfo(AppDef.ServerSetIndex.SSI_FINISH_GUIDE, str)
    LUserConfigMgr:SetUserGuideCache()
end

---------------神将相关检测----------------------

--[[
检测是否有可以合成的神将
]]
function LRoleDataMgr:CheckPetCompound()
    if self.MyHeroInfo.level >= 35 or LRoleDataMgr.m_isTipPetCompound == false then
        return
    end
    local fragId = 0--碎片id
    local compId = 0
    local compQuality = 0;
    for k,v in pairs(self.Equip:GetPackageMap()) do
        --神将碎片
        -- dump(v, "PetBagFragmentSubUI:initData ===========>")
        if v.m_type == AppDef.ItemType.PetFrag then
            local pidId = PetkaPaiManager:getPetIdByItem(v)
            local isOwnPet = self.Pet:IsOwnPetById(pidId)
            if pidId and pidId > 0 and not isOwnPet then
                local isCanHecheng = PetkaPaiManager:isPetCanHeCheng(v)
                if isCanHecheng then
                    local baseData = JsonConfig.m_heroCfg.getDefByID(pidId)
                    if compQuality < baseData.quality then
                        compId = pidId;
                        fragId = v.m_id;
                        compQuality = baseData.quality;
                    end
                end
            end
        end
    end
    if compId > 0 then
        Utils:OpenFunction(AppDef.EModuleID.EMID_PETCOMPOUND,{fragId,compId})
    end
end

--[[
初始化神将背包里面所有宠物经验丹的累加值
@param1:isReset是否重新计算
]]
function LRoleDataMgr:InitPetTotalExpInBag(isReset) 
    isReset = isReset or false
    if self.Pet.totalExpInBag ~= -1 and isReset == false then
        return
    end
    self.Pet.totalExpInBag = 0
    for i = 1, #self.upgradeItems do
        local itemNum = LRoleDataMgr.Equip:CountItemNumById(self.upgradeItems[i])
        if itemNum > 0 then
            local citem = LDataConstMgr:getCItemByID(self.upgradeItems[i])
            self.Pet.totalExpInBag = self.Pet.totalExpInBag + citem.sub_value[1][2] * itemNum
        end
    end
    self.totalExpInBag = self.Pet.totalExpInBag
end

--[[ 
检测神将是否可以升
@param1:pind神将下表
]]
function LRoleDataMgr:PetCheckLvUp(pind)
    local function ExpCheck()
        if Utils:CheckModelNotOpened(AppDef.EModuleID.EMID_SJJINENG, true) then
            return false
        end
        local show = false
        for pk,pet in pairs(LRoleDataMgr.Pet.petlist) do
           if pet.fightPos>0 and pet.level<LRoleDataMgr.MyHeroInfo.level then
                for i = 1, AppDef.Pet.MaxUpgradeItems do
                     local itemNum = LRoleDataMgr.Equip:CountItemNumById(AppDef.Pet.UpgradsMats[i])
                     if itemNum>0 then
                       show=true
                       return show
                     end
                 end
            end
        end
        return show
    end 
    if pind > #self.Pet.petlist then
        return false
    end
    local petData = self.Pet.petlist[pind]

    if petData.fightPos <= 0 then
        return false
    end
    
    if petData.level >= self.MyHeroInfo.level then
        --不能大于玩家等级
        return false
    end

    if petData.level >= AppDef.Pet.MaxLevel then
        --达到最大宠物最大等级
        return false
    end
    if petData.exp + self.totalExpInBag > petData.expMax or ExpCheck() then
        return true
    else
        return false
    end
end

--[[
羽翼满阶
]]
function LRoleDataMgr:IsMyYuYiFullLevel()
    local OtInfo = self.MyHeroInfo.ChiBangExInfo
    local stage = OtInfo.Level + 1-- 阶段是从0 - 8 对应id 1 - 9
    local isFullLevel = false
    if OtInfo.Star >= 10 and stage >= 9 then -- 满级
        isFullLevel = true
    end
    return isFullLevel
end

--[[
更新宠物升级相关背包道具
]]
function LRoleDataMgr:UpdatePetUpItems()
    LRoleDataMgr:InitPetTotalExpInBag(true)
    LRoleDataMgr:InitSkillBooksInBag(true)
end

--[[
更新神将的装备信息
]]
function LRoleDataMgr:UpdatePetEquip(petid, equipvalue)
	local pos = equipvalue.m_wpos
	local oldequip = LRoleDataMgr.Pet:GetPetById(petid).petEquips[pos]
	if oldequip.m_uid == equipvalue.m_uid then
		LRoleDataMgr.Pet:GetPetById(petid).petEquips[pos] = equipvalue
	end
end

--[[
汇总背包里所有可以学习的技能书
]]
function LRoleDataMgr:InitSkillBooksInBag(isReset)
    isReset = isReset or false
    if isReset then
        self.Pet.skBooksInBag = {}
    else
        if self.Pet.skBooksInBag ~= nil then
            return
        end
    end
    self.Pet.skBooksInBag = {}
    local bookSkillList = LDataConstMgr:GetPetBookSkillList()--所有可以学习的技能id数组
    --插入背包技能列表
    local function InsertBagSkillList(studyData)
        local isExsit = false
        for k = 1, #self.Pet.skBooksInBag do
            if self.Pet.skBooksInBag[k] == studyData then
                isExsit = true
                break
            end
        end
        if not isExsit then
            table.insert(self.Pet.skBooksInBag, studyData)
        end
    end

    for i = 1, #bookSkillList do
        local consumeItemData = bookSkillList[i]
        local itemId = consumeItemData.itemId
        local itemNum = LRoleDataMgr.Equip:CountItemNumById(itemId)

        if itemNum > 0 then
            InsertBagSkillList(consumeItemData)
        end
    end
end

--[[
检测神将技能是否可以升级
@param1:petData 神将结构
@param2:skInd 技能下标
]]
function LRoleDataMgr:PetCheckSkillLvUp(petData, skInd)
    if petData.fightPos <= 0 then
        return false
    end

    local curSk = petData.skills[skInd]
    --[[
    检查是否有可学习的天书技能书
    ]]
    local function HasNewBookSkill()
        local hasNew = true
        for i = 1,#self.Pet.skBooksInBag do
            hasNew = true
            for j = AppDef.Pet.MaxBornSkillNum + 1, #petData.skills do
                if petData.skills[j].skDetail ~= nil and self.Pet.skBooksInBag[i].skId == petData.skills[j].skDetail.id then
                    hasNew = false
                end
            end
            if hasNew then
                break
            end
        end
        return hasNew
    end
      
    if skInd <= AppDef.Pet.MaxBornSkillNum then
        --检测天生技能
        if curSk.level == 0 then
            --天生技能达到等级自动升为1级，等于0就是还没有开启
            return false
        end
        local lvUpData = LDataConstMgr:GetPetBornSKLvUpData(skInd, curSk.level)
        if lvUpData == nil then
            return false--达到最大等级，不能再升级了
        end

        if petData.level < lvUpData.needLv then
            return false--主角等级没达到
        end

        if lvUpData.costItemNum[1] > LRoleDataMgr.MyHeroInfo:GetDetailData().Money then
            return false--背包金币不够
        end

        -- if lvUpData.costItemNum[2] > LRoleDataMgr.MyHeroInfo.DetailData.potential then
        --     return false--主角潜能不足
        -- end

        return true--可以升级
    else
        --检测天书技能
        if curSk.skDetail == nil then
            if petData.star < AppDef.Pet.LearnOpenStar[skInd - AppDef.Pet.MaxBornSkillNum] then
                --宠物等级小于可学习等级
                return false
            end
            --检测背包是否有天书道具
            if #self.Pet.skBooksInBag > 0 then
                return HasNewBookSkill()
            else
                return false
            end
        else
            if curSk.level >= AppDef.Pet.MaxLearnSkillLv then
                --天书技能达到最高等级了
                return false
            end
            --检测背包是否有相关道具可以升级
            local consumeItemData = LDataConstMgr:GetPetLearnSkillLvUpData(curSk.skDetail.id, curSk.level)
            local bagItemNum = LRoleDataMgr.Equip:CountItemNumById(consumeItemData.itemId)
            if bagItemNum < consumeItemData.itemNum then
                --需求升级的数量不足
                return false
            end
            return true
        end
    end
end

--[[
检查神将是否可以升星
@param1:petData 神将结构
@return:true 可以升星 false不可以升星
]]
function LRoleDataMgr:PetCheckStarUp(petData)
    
    if Utils:CheckModelNotOpened(AppDef.EModuleID.EMID_SJSHENGXING,true) then
        return false
    end

    if petData.fightPos == nil or petData.fightPos <= 0 then
        return false
    end


    if petData.star >= AppDef.Pet.MaxStar and petData.starStep >= AppDef.Pet.MaxSubStar then
        return false
    end

    local cpdData = LDataConstMgr:GetPetCpdData(petData.id)
    if cpdData == nil then
        return false
    end

    local levelLimit = LDataConstMgr:GetPetStarLevelLimit(petData.star)
    if petData.level < levelLimit then
        return false
    end

    local costNum = LDataConstMgr:GetPetShenXingCost(petData.id, 
                                        petData.star, 
                                        petData.starStep + 1)
    
    local myItemNum = LRoleDataMgr.MyHeroInfo:GetDetailData().shenHun
    if myItemNum >= costNum then
        return true
    else
        return false
    end
end

--[[
检查神将是否可以修炼
@param1:petData 神将结构
@param2:ind 修炼下标
@return:true 可以升星 false不可以升星
]]
function LRoleDataMgr:PetCheckXiulianUp(petData, ind)
    if Utils:CheckModelNotOpened(AppDef.EModuleID.EMID_SJXIULIAN,true) then
        return false
    end

    if petData.fightPos <= 0 then
        return false
    end

    local lv = petData.xiulianLv[ind]
    local basePetData = LDataConstMgr:GetPetData(petData.id)
    local xiulianData = LDataConstMgr:GetPetXiulianData(basePetData.quality, lv)
    if lv == nil then
        return false
    end
    if lv >=AppDef.Pet.MaxXliulianLv then
        --达到最大等级
        return false
    end

    --xiulianData = LDataConstMgr:GetPetXiulianData(basePetData.quality, lv + 1)

    for i = 1,2 do
        local itemId = xiulianData.needItemIdList[i]
        local itemNum = xiulianData.needItemNumList[i]
        local citem = LDataConstMgr:getCItemByID(itemId)
        local myItemNum = LRoleDataMgr.Equip:CountItemNumById(itemId)
        if myItemNum < itemNum then
            --道具不足
            return false
        end
    end

    if xiulianData.heroLvList[ind] > petData.level then
        return false
    end
    return true
end

--[[
检查阵容是否可以学习或者升级
@param1:ind 阵型下表
@return:true  false
]]
function LRoleDataMgr:FormationCheckUp(ind)
    if Utils:CheckModelNotOpened(AppDef.EModuleID.EMID_SJBUZHEN,true) then
        return false
    end
    local flist = LDataConstMgr:GetFormationDataList()
    local data = flist[ind]
    local myFData = LRoleDataMgr.myFormation
    local lv = myFData:GetMyZhenfaLvById(data.id)
    if lv == 10 then
        return false
    end
    local fdata = LDataConstMgr:GetFormationLvUpData(data.id,lv)
    if fdata == nil then
        --没有找到默认到了最大级
        return false
    end

    local itemId = fdata.cost[1][1]
    local itemNum =fdata.cost[1][3]
    local glodNum =fdata.cost[2][3]

    local myItemNum = LRoleDataMgr.Equip:CountItemNumById(itemId)
    
    if myItemNum < itemNum then
        --数量不足
        return false
    end
    if glodNum> LRoleDataMgr:GetMoney(AppDef.EMoneyType.EMT_Gold) then
        return false

    end
    return true
end
-------------------------------------------------
-------------境界小红点判断---------------------
--是否可以领取俸禄
function LRoleDataMgr:CheckJingJieSalary()
      LCheckImproveMgr:getInstance():JingJieSalary()
    if LCheckImproveMgr:getInstance()._ImproveOK.JingJie  == -1 then
        return false
    else
        return true
    end

end
--是否可以突破
function LRoleDataMgr:CheckJingJieBreak()
     LCheckImproveMgr:getInstance():JingJieBreak()
    if LCheckImproveMgr:getInstance()._ImproveOK.JingJie== -1 then
        return false
    else
        return true
    end
   
end
-----------------坐骑小红点判断------------------
--[[
是否有坐骑进阶
]]
function LRoleDataMgr:CheckMountUpgrade()
    if Utils:CheckModelNotOpened(AppDef.EModuleID.EMID_ZJJINJIE,true) then
        return false
    end

    LCheckImproveMgr:getInstance():TransformHorse()
    if LCheckImproveMgr:getInstance()._ImproveOK._HorseTransform == -1 then
        return false
    else
        return true
    end
end

--[[
是否有坐骑进阶
]]
function LRoleDataMgr:CheckMountEnforce()
    if Utils:CheckModelNotOpened(AppDef.EModuleID.EMID_ZJQIANGHUA,true) then
        return false
    end
    LCheckImproveMgr:getInstance():StrengthHorse()
    if LCheckImproveMgr:getInstance()._ImproveOK._HorseStrength == -1 then
        return false
    else
        return true
    end

end

--[[
是否有坐骑可激活\兑换
]]
function LRoleDataMgr:CheckMountExChange()
    if Utils:CheckModelNotOpened(AppDef.EModuleID.EMID_ZUOJI,true) then
        return false
    end
    LCheckImproveMgr:getInstance():ExchangeHorse()
    if LCheckImproveMgr:getInstance()._ImproveOK._HorseExchange == -1 then
        return false
    else
        return true
    end

end
-----------------坐骑小红点结束------------------
function LRoleDataMgr:SetFightSpeed(speed)
    if self.m_fightSpeed ~= speed then
        self.m_fightSpeed = speed
        LUserConfigMgr:SetBattleSpeed(speed);
        Utils:SendMsg(LBattleEvent.UpdateSpeed)
        Utils:SendMsg(LUIBattleEvent.UpdateSpeed)
        --dump(self.m_fightSpeed, "SetFightSpeed========>")
    end
end

function LRoleDataMgr:GetFightSpeed()
    -- local cur = LRoleDataMgr:GetSettingConfig(AppDef.ServerSetIndex.SSI_FIGHT_SPEED)
    -- if cur == nil then
    --     return 0
    -- end
    -- return math.min(cur, AppDef.MAX_FIGHT_SPEED-1)
    return self.m_fightSpeed
end

function LRoleDataMgr:GetFightSpeedFactor(serverSpeed)
    --test code
    -- if true then
    --     return 5
    -- end
    local cur = self:GetFightSpeed()
    if serverSpeed and serverSpeed > 0 then
        cur = serverSpeed
    end
    if cur == 0 then    --1级1倍速
        return 1
    elseif cur == 1 then    --2级2倍速
        return 2
    elseif cur == 2 then    --4级3倍速
        return 3
    elseif cur == 3 then    --7级5倍速
        return 3.5
    elseif cur == 4 then    --10级10倍速
        return 4
    elseif cur == 5 then    --12级15倍速
        return 4.5
    end
    return 1
end

-----------------藏宝图------------------
function LRoleDataMgr:useCangbaotu(itemPos)
    local item = self.Equip.PackageMap[itemPos]
    if item == nil then
        return
    end
    local mapId, posX, posY, name = LDataConstMgr:getCangBaoTuPosData(item.m_targetPos)
    if posX == nil or posY == nil then
        return
    end
    --print("itemPos =============", itemPos, item.m_targetPos)
    local pos = itemPos - 1
    local idTemp = item.m_id
    local function AutoPathCallBack()
        -- body
--        print("-----pos", pos)
        local dataInfo = {}
        dataInfo.pos = pos
        dataInfo.itemId = idTemp
        dataInfo.posX = posX
        dataInfo.posY = posY
        LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "Activity.AlearTreasureMap", AppDef.UIType.Normal, dataInfo)
        LUIManager:SendMsg(LGameMsg.m_initUIMsg)
		LGameMsg.m_baseMsgWithOne:Change(LUILogicEvent.IsAutoPath, false)
		LUIManager:SendMsg(LGameMsg.m_baseMsgWithOne)
        --寻路结束，恢复遇敌
        LuaNetSendMsg:QueryCanBattle(3)
    end

    LGameMsg.m_autoPathMsg:ChangeToStart(mapId, posX, posY,0,0,true,true, AutoPathCallBack)
    LUIManager:SendMsg(LGameMsg.m_autoPathMsg)
	LGameMsg.m_baseMsgWithOne:Change(LUILogicEvent.IsAutoPath, true)
	LUIManager:SendMsg(LGameMsg.m_baseMsgWithOne)
--挖宝不遇敌
    LuaNetSendMsg:QueryCanBattle(2)
end

--通过类型寻找低阶材料
function LRoleDataMgr:getLowMatrialIdByType(itemType)
    -- body
    if itemType == AppDef.EItemListType.EILTLianHuaStone then
        --炼化石
        return 801
    elseif itemType == AppDef.EItemListType.EILTXingYunCharm then
        --幸运符
        return 501
    elseif itemType == AppDef.EItemListType.EILTXiLianStone then
        --洗炼石
        return 610
    elseif itemType == AppDef.EItemListType.EILTYuyiStone then
        --羽翼仙石
        return 2538
    elseif itemType == AppDef.EItemListType.EILTWuSeStone then
        --五色石
        return 2818
    elseif itemType == AppDef.EItemListType.EILTMountUpgradeStone then
        --坐骑进阶丹
        return 2301
    elseif itemType == AppDef.EItemListType.EILTMountStone then
        return 2251
    else
        return 0
    end
end

--通过类型寻找材料数量
function LRoleDataMgr:getLowMatrialNumByType(itemType)
    local count = 0
    for i = 1, #self.Equip.PackageMap do
        if v.m_id > 0 and self:GetItemType(v.m_id) == itemType then
            count = count + v.m_num
        end
    end
    return count
end

--通过id查找总数量
function LRoleDataMgr:getItemNumById(id)
    local count = 0
    for k,v in pairs(self.Equip.PackageMap) do
        if v.m_id == id then
            count = count + v.m_num
        end
    end
    return count
end

--写死，通过ID来判断显示类型
function LRoleDataMgr:GetItemType(id)
    if id >= 801 and id <=  815 then 
        --炼化石
        return AppDef.EItemListType.EILTLianHuaStone
    elseif id >= 501 and id <=  505 then 
        --幸运符
        return AppDef.EItemListType.EILTXingYunCharm
    elseif id == 610 or id == 2516 or id == 2517 or id == 2577 then 
        --洗炼石
        return AppDef.EItemListType.EILTXiLianStone
    elseif id >= 2538 and id <=  2542 then 
        --羽翼仙石
        return AppDef.EItemListType.EILTYuyiStone
    elseif id >= 2818 and id <=  2821 then 
        --五色石
        return AppDef.EItemListType.EILTWuSeStone
    elseif id == 2301 then 
        --坐骑进阶丹
        return AppDef.EItemListType.EILTMountUpgradeStone
    else
        if LItemMgr:IsHorseStrengthStone(id) then
            return AppDef.EItemListType.EILTMountStone
        end
        
        return AppDef.EItemListType.EILTNone
    end
end

--获取宠物装备包裹信息
--@param suitType-套装ID
--@param part -装备部位
--@param isInverse 是否反向排序
--@param isLocked 是否显示锁定装备
function LRoleDataMgr:GetPetEquipBagInfo(suitType,wpos,isAll,isInverse,isLocked) 
    if self.Pet.equipList == nil or self.Pet.equipList == nil 
       or self.Pet.equipList.m_maxGridNum == 0 
       or self.Pet.equipList.m_petEquips == nil 
       or next(self.Pet.equipList.m_petEquips) == nil then
        return nil
    end
    
    local function _sort(a, b)
        local r = true
        if a.m_stoneLevel == b.m_stoneLevel then
            if a.m_star == b.m_star then
                if a.m_wpos == b.m_wpos then
                    r = a.m_id > b.m_id
                else
                    r = a.m_wpos < b.m_wpos
                end
            else
                r = a.m_star > b.m_star
            end
        else
            r = a.m_stoneLevel > b.m_stoneLevel
        end
        return r
    end

    local function _sort_inverse(a, b)
        local r = true
        if a.m_star == b.m_star then
            if a.m_id == b.m_id then
                r = a.m_stoneLevel < b.m_stoneLevel
            else
                r = a.m_id < b.m_id
            end
        else
            r = a.m_star < b.m_star
        end
        return r
    end

    local info = {}
    for k,v in pairs(self.Pet.equipList.m_petEquips) do
        if (isLocked == nil or (not isLocked and v.m_locked ~= 1)) and v.m_quality > 0 and (isAll or (suitType == 0 or v.m_suitType == suitType) and (wpos == 0 or v.m_wpos == wpos)) then
			table.insert(info,v)
        end
    end

    if isInverse == nil or not isInverse then
        table.sort(info,_sort)
    else
        table.sort(info,_sort_inverse)
    end
    return info
end

--检查宠物装备包裹信息
--@param suitType-套装ID
--@param part -装备部位
function LRoleDataMgr:CheckPetEquipBagInfo(suitType,part) 
    if self.Pet.equipList == nil or self.Pet.equipList == nil 
       or self.Pet.equipList.m_maxGridNum == 0 
       or self.Pet.equipList.m_petEquips == nil 
       or next(self.Pet.equipList.m_petEquips) == nil then
        return false
    end

    for k,v in pairs(self.Pet.equipList.m_petEquips) do
        if v.m_quality > 0 and (suitType == 0 or v.m_suitType == suitType) and (part == 0 or v.m_wpos == part) then
            return true
        end
    end
    return false
end

--获取玩家装备（锻造用，不删）
function LRoleDataMgr:GetEquipList(reset) 
    local set = reset or false
   
    if self.m_fEquips == nil or set or #self.m_fEquips == 0 then
        self.m_fEquips = DZ_LoadItemList()
    end
    return self.m_fEquips
end

function LRoleDataMgr:IsAllEquipFull( ... )
    -- body
    local equipList = self:GetEquipList()
    local equipNum = #equipList
    if equipNum < 1 then
        return true
    end
    for i=1, equipNum do
        local pItem = DZ_GetPItem(equipList[i].type, equipList[i].pos)
        if pItem ~= nil then
            if pItem.m_roleLevel < AppDef.MAX_EQUIP_UPGRADE_LEVEL then
                return false
            end
        else
            return false
        end
    end
    return true
end

function LRoleDataMgr:SetDelayShowAward(isDelay)
    self.m_delayAwardAnim = isDelay
end

function LRoleDataMgr:GetDelayShowAward()
    return self.m_delayAwardAnim
end

function LRoleDataMgr:InsertDelayAwardData(tag, data)
    if tag == nil or data == nil then
        return
    end
    table.insert(self.m_delayAwardList, {tag=tag, data=data})
end

function LRoleDataMgr:ShowAwardAnim()
    for k,v in pairs(self.m_delayAwardList) do
        if v and v.tag and v.data then
            if v.tag == 1 and type(v.data) == "table" then
                Utils:SendMsg(LUILogicEvent.ShowFlyItems, v.data)
            elseif v.tag == 2 and type(v.data) == "string" then
                Utils:ShowScrollTips(v.data)
            end
        end
        self.m_delayAwardList[k] = nil
    end
end

function LRoleDataMgr:getOtherRolePetDataById(pid)
	for i = 1, #self.OtherHeroInfo.VecFightPet do
		if self.OtherHeroInfo.VecFightPet[i].id == pid then
			return self.OtherHeroInfo.VecFightPet[i]
		end
	end
	return nil
end

--自动寻路到英勇试炼
function LRoleDataMgr:autoPathToShiLian(mapId, npcId)
    -- body
    local function AutoPathCallBack(npcId, npcIdx)
                -- body
        print("call back ----------->",npcId, npcIdx)

        LuaNetSendMsg:QueryNpcChatOpen(npcId, npcIdx, nil)

        LGameMsg.m_baseMsgWithOne:Change(LUILogicEvent.IsAutoPath, false)
        LUIManager:SendMsg(LGameMsg.m_baseMsgWithOne)

    end

    LGameMsg.m_autoPathMsg:ChangeToStart(mapId, -1, -1, 0, bit.lshift(npcId, 16), true, true, AutoPathCallBack)
    -- LGameMsg.m_autoPathMsg:ChangeToStart(174, posX, posY, 0, bit.lshift(0, 16), true, true, AutoPathCallBack)
    LUIManager:SendMsg(LGameMsg.m_autoPathMsg)

    LGameMsg.m_baseMsgWithOne:Change(LUILogicEvent.IsAutoPath, true)
    LUIManager:SendMsg(LGameMsg.m_baseMsgWithOne)
end

function  LRoleDataMgr:GetFactionRankTypeName(type)
    local index = type + 1
    local ARY_N = { "", GUITips.RSI_FACTION_BOSS, GUITips.RSI_FACTION_ELDERS, GUITips.RSI_FACTION_HUFA, GUITips.RSI_FACTION_BANGZHONG };
    if (index >= 1 and index <= 5) then
        return ARY_N[index]
    else
        return ARY_N[1];
    end
end

function LRoleDataMgr:getMyFactionRankTypeName( ... )
    -- body
    return self:GetFactionRankTypeName(self.MyHeroInfo:GetFactionRankType())
end

function LRoleDataMgr:CheckIsEnough(data)
    if data == nil or #data ~= 3 then 
        return false
    end
    --先判断金钱
    if data[1] == AppDef.EMoneyType.EMT_Gold then
        if LRoleDataMgr.MyHeroInfo.DetailData:getMoney() >= data[3] then
            return true
        end
    elseif data[1] == AppDef.EMoneyType.EMT_Cash then
        if LRoleDataMgr.MyHeroInfo.DetailData:GetTongBao() >= data[3] then
            return true
        end
    elseif data[1] == AppDef.EMoneyType.EMT_ArenaSorce then
        if LRoleDataMgr.MyHeroInfo.DetailData:GetArenaSorce() >= data[3] then
            return true
        end
    elseif data[1] == AppDef.EMoneyType.EMT_StarExp then
        if LRoleDataMgr.MyHeroInfo.DetailData:GetXinXiuJingHua() >= data[3] then
            return true
        end
    elseif data[1] == AppDef.EMoneyType.EMT_KunlunMoney then
        if LRoleDataMgr.MyHeroInfo.DetailData:GetKunLunMoney() >= data[3] then
            return true
        end
    elseif data[1] == AppDef.EMoneyType.EMT_ShenHun then
        if LRoleDataMgr.MyHeroInfo.DetailData.shenHun >= data[3] then
            return true
        end
    elseif data[1] == AppDef.EMoneyType.EMT_Banggong then
        if LRoleDataMgr.Faction.Info:GetselfBangGong() >= data[3] then
            return true
        end
    elseif data[1] == AppDef.EMoneyType.EMT_Tili then
        if LRoleDataMgr.MyHeroInfo.DetailData:getTili() >= data[3] then
            return true
        end
    else
        --道具
        local count = self:getItemNumById(data[1])
        if count >= data[3] then
            return true
        end
    end
    return false
end

function LRoleDataMgr:GetMoney(id)
    if id == nil or id == 0 then 
        return 0
    end
    --先判断金钱
    if id == AppDef.EMoneyType.EMT_Gold then
        return self.MyHeroInfo.DetailData:getMoney()
    elseif id == AppDef.EMoneyType.EMT_Cash then
        return  self.MyHeroInfo.DetailData:GetTongBao()
    elseif id == AppDef.EMoneyType.EMT_Tili then
        return self.MyHeroInfo.DetailData:getTili()
    elseif id == AppDef.EMoneyType.EMT_StarExp then
        return self.MyHeroInfo.DetailData:GetXinXiuJingHua()
    elseif id == AppDef.EMoneyType.EMT_ArenaSorce then
        return self.MyHeroInfo.DetailData:GetArenaSorce()
    elseif id == AppDef.EMoneyType.EMT_KunlunMoney then
        return self.MyHeroInfo.DetailData:GetKunLunMoney()
    elseif id == AppDef.EMoneyType.EMT_ShenHun then
        return self.MyHeroInfo.DetailData.shenHun
    elseif id == AppDef.EMoneyType.EMT_HuoYue then
        return self.MyHeroInfo.DetailData:GetHuoYue()
    elseif id == AppDef.EMoneyType.EMT_Banggong then
        return LRoleDataMgr.Faction.Info:GetselfBangGong()
    elseif id == AppDef.EMoneyType.EMT_ShengLing then
        return self.MyHeroInfo.DetailData:GetShengLing()
    elseif id == AppDef.EMoneyType.EMT_TurntableScore then
        return self.MyHeroInfo.DetailData:GetTurntableScore()
        -- return LRoleDataMgr.MyHeroInfo:GetDetailData().ZaDanScore
    end
    return 0
end

function LRoleDataMgr:SetMoney(id,val)
    if val == nil then
        return
    end
    id = id or 0
    if id == AppDef.EMoneyType.EMT_Gold then
        self.MyHeroInfo.DetailData:setMoney(val)
    elseif id == AppDef.EMoneyType.EMT_Cash or id == AppDef.EMoneyType.EMT_Cash1 then
        self.MyHeroInfo.DetailData:setTongBao(val)
    elseif id == AppDef.EMoneyType.EMT_StarExp then
        self.MyHeroInfo.DetailData:setXinXiuJingHua(val)
    elseif id == AppDef.EMoneyType.EMT_ArenaSorce then
        self.MyHeroInfo.DetailData:setArenaSorce(val)
    elseif id == AppDef.EMoneyType.EMT_KunlunMoney then
        self.MyHeroInfo.DetailData:setKunlunMoney(val)
    elseif id == AppDef.EMoneyType.EMT_ShenHun then
        self.MyHeroInfo.DetailData:setShenHun(val)
    elseif id == AppDef.EMoneyType.EMT_HuoYue then
        self.MyHeroInfo.DetailData:setHuoYue(val)
        LGameMsg.m_baseMsg:ChangeEventId(LUIRoleDataChangeEvent.HuoyueChanged)
        self:SendMsg(LGameMsg.m_baseMsg)
    elseif id == AppDef.EMoneyType.EMT_Banggong then
        LRoleDataMgr.Faction.Info:SetselfBangGong(val)
    elseif id == AppDef.EMoneyType.EMT_ShengLing then
        self.MyHeroInfo.DetailData:setShengLing(val)
    elseif id == AppDef.EMoneyType.EMT_TurntableScore then
        self.MyHeroInfo.DetailData:setTurntableScore(val)

    end
end

--检查宠物装备是否有未使用的
function LRoleDataMgr:CheckPetEquipUnused(part) 
    part = part or 0
    if part < 1 or part > 4 then
        return false
    end
    for k,v in pairs(self.Pet.equipList.m_petEquips) do
        if v.m_wpos == part and v.m_fpos == 0 then
            return true
        end
    end
    return false
end

--检查宠物装备是否有未使用的
function LRoleDataMgr:CheckFaBaoUnused()
    for k,v in pairs(self.Pet.faBaoList.m_petFaBaos) do
        if v.m_fpos == 0 then
            return true
        end
    end
    return false
end
--[[
宠物相关
]]
LCBook = {}
LCBook.__index = LCBook

function LCBook:New()
    local o = {}
    setmetatable(o,LCBook)
    o:Init()
    return o
end

function LCBook:Init()
    self.curLevel = 0
    self.curScore = 0
    self.bookStar = {}
    self.bookAttr = {}--图鉴属性
    self.bookScoreAttr = {}--图鉴分值属性
end

LRoleDataMgr:Init()
