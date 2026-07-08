LDataConstMgr = LDataBase:New()
LDataConstMgr.__index = LDataConstMgr
-- function LDataConstMgr:New()
--     local o = LUIBase:New()
--     setmetatable(o,LDataConstMgr)    
--     o:Init()
--     return o
-- end
  
function LDataConstMgr:Init()
    self.m_MapPetList = {} --宠物列表
    self.m_VecPetList = {} -- 宠物数组列表
    self.m_VecPetArmorAdvStone = {}--宠铠升星石
    self.m_VecPetLevelUpPill = {}--宠物升级材料数量
    self.m_VecPetBookSkill = {}--宠物技能书对应技能    
    self.m_VecPetHuanHuaType = {}--宠物幻化需要的材料宠类型
    self.m_VecPetHuanHuaQuality = {}--宠物幻化需要的材料宠品质
    self.m_VecItemStrenStoneNum = {}--强化装备消耗材料数量
    self.m_VecItemStrenStoneId = {}--强化装备消耗材料ID
    self.m_VecXueMaiInfo = {}--宠物血脉加成
    self.m_VecXueMaiCost = {}--宠物血脉觉醒消耗
    self.m_VecNpcHeight = {}--npc身高配置
    self.m_VecXueMaiMaxExp = {}--宠物血脉每级最大经验
    self.m_VecPetPill = {}
    self.m_horseConfigList = {}--坐骑信息
    
   
    self.m_horseConfigArr = {}--坐骑信息
    self.m_otherHorseConfigArr = {}--坐骑信息
    self.m_jingjieConfigList={}--境界信息
    self.m_jingjieConfigArr={}--境界信息

    --self.m_VecSkillDetail = {}--技能信息
    self.m_pSkillBasicList = {}--技能基础信息
    self.m_pSkillActiveList = {}--主动技能效果信息
    self.m_pSkillAdditiveList = {}--附加技能效果信息
    --self._MapHeroSkillDescData = {}          --人物技能描述
    self.m_VecItemList = {}                   --本地物品列表
    self.m_MapItemtList = {} --本地物品列表

    self.m_petBookSkillStudyList = nil--宠物天书技能学习表
    self.m_petBookSkStudyArr = nil--宠物天书技能升级表,这个是数组
    self.m_petLearnSkLvUpList = nil--宠物天书技能升级表
    self.m_petBornSkLvUpList = nil--宠物天生技能升级表
    self.m_petSXAddValueList = nil--宠物升星对应职业属性加成
    self.m_itemCpdList = nil--道具+宠物的合成数据
    self.m_petCpdList = nil --宠物合成数据
    self.m_itemFjList = nil --道具分解数据
    self.m_MapitemCpdList = {} --道具的合成数据（key为合成材料ID）
    self.m_petXiuLianList = nil--宠物修炼数据表
    self.m_petCpdMap = nil --碎片与宠物对应Map

    --宠物升星相关配置数据
    ------------------------------------------
    self.m_petStarList = nil--宠物升星配置数据
    self.m_petQualityList = nil--宠物升星品质配置数据
    self.m_petStarStepList = nil--宠物升星节点配置数据
    ------------------------------------------

    self.m_formationList = nil--阵型信息
    self.m_formationArr = nil--阵型信息,保存的数据和上面的一样，只不过以数组形式
    self.m_formationLvUpList = nil--阵型升级信息

    self.m_petDrawBasic = {}--抽宠配置信息
    self.m_petDrawConfig = {}--抽宠详细信息

    self.m_retEquipList = nil -- 宠物装备列表

    self.m_attrConfigList = {}--基础属性表

    self.m_pNoviceMap = {}--新功能预告表
    self.m_pNoviceVec = {}--新功能预告表
    self.m_pFunctionLevelMap = {}--功能开启表
    self.m_pFLTypeMap = {}--功能开启表
    self.m_pGuideMap = {}--新手引导Map表
    self.m_pGuideVec = {}--新手引导Vec表
    self.m_pGuideTypeMap = {}--根据类型区分的新手引导Map表
    self.m_dieWarning = {}--战斗失败数据表

    self.m_ItemNum = 0
    self.m_ItemMaxNum = 0
    self.m_CopyData = LCopyData:New()
    self.m_CopyData.SweepData = {}
    self.m_VipAwardInfo = {} -- vip信息
    self.m_CardInfo = LMCAwardInfo:New()  --月卡界面信息
    self.m_PrivilegeCardInfo = LPrivilegeCard:New() --特权卡界面信息
    --self.m_VecMapData = {}

    self.m_btSkAtkData = nil--技能动作配置表
    self.m_btHitData = nil--被击动作配置表
    self.m_btActData = nil--战斗动作配置表
    self.m_btModelAtkData = nil--模型动作配置表
    self.m_btBufData = nil--战斗buff消息
    self.m_btShakeData = nil--战斗震屏消息
    self._VecHeroHit = nil
    self._VecMonsterHit = nil
    self._defalutHitData = nil
    self.m_VecShenQiList = nil
    self.m_VecShenQiCultureData = nil
    self.m_maxShenqiLevel = 0
    self.m_maxShenqiStar = 0

    self.m_sysTime = 0
    self.m_serverTime = 0

    self.m_medalTotalNum = 0
    self.m_medalTable = {}
    self.m_scheduler = nil
    self.m_FlyFaryInfo = LFlyFaryFieldInfo:New()
    self.m_BaoZangInfo = LCangBaotuData:New()

    self.m_VecPetRecommondInfo = nil --神将推荐阵型
    self.m_VecLvPets = {}--神将图鉴信息-key为宠物类型、value为id列表
    self:InitPetSkillBook()

    self.m_VecEquipStrengthen = nil --装备强化属性
    self.m_VecEquipStrengthenCost = nil --装备强化支付数据
    self.m_VecEquipUpgrade = nil --装备升阶支付数据

    --藏宝图坐标数据  
    self.m_cangbaotuInfo = {}
    self:initCangbaotuData()
    
    ------------------登录奖励数据
    self.m_LoginRewardData = {}
    ------------------VIP至尊数据
    self.m_vipConfigData = {}

    --通天塔奖励数据
    self.m_MapTower = nil

    --任务数据
    -- self.m_missionConfig = {}
    --斗神数据
    self.m_doushenConfig = nil
    self.m_doushenVector = nil

    self.m_loadingBgTotalNum = 0
    --Loading背景数据
    self.m_loadingBgTable = nil
    --洗练配置
    self.m_xiLianData = nil
    --怪物数据
    self.m_monsterConfig = nil
    self.m_monsterMap = nil
    --帮派炼器阁
    self.m_bpKejiData = nil

	--强化大师数据
	self.m_masterMap = nil
    --------------------------------------------
    --推图剧情对话
    self.m_missionDialog = nil

end

function LDataConstMgr:GetSysTimeStr()

    local IntSysTime = math.floor(self.m_sysTime)
 
    local h =  math.floor(IntSysTime/ 3600)
    local m = math.floor((IntSysTime % 3600) / 60)

    --修正24点错误
    h = (h >= 24) and 0 or h

    return string.format("%02d:%02d", h, m)
end

function LDataConstMgr:LoadData()
    self.m_scheduler = nil 
    local loadStep = 2
    local addStep = 0.1
    local function tick(dt)
        if loadStep == 2 then
            --先加载新表
            JsonConfig.initConfig()
        elseif loadStep == 3 then
            --self:LoadItemData()
        elseif loadStep == 4 then
            self:LoadSkillBasic()
        elseif loadStep == 5 then
            self:LoadSkillActive()
        elseif loadStep == 6 then
            self:LoadSkillAdditive()
        elseif loadStep == 7 then
            -- self:LoadMissionDialog()
        elseif loadStep == 8 then
            self:LoadFubenConfigData()
        elseif loadStep == 9 then
            self:LoadStageNodeData()
        elseif loadStep == 10 then
            self:InitMedalInfo()
        elseif loadStep == 11 then
            self:LoadBattleData()
        elseif loadStep == 12 then
            self:LoadPetBookSkillStudyList()
        elseif loadStep == 13 then
            self:LoadPetStarConfig()
            self:LoadPetQualityConfig()
            self:LoadPetStarStepConfig()
        elseif loadStep == 14 then
            self:LoadPetDrawBasicData()
        elseif loadStep == 15 then
            self:LoadPetDrawConfigData()
        elseif loadStep == 16 then
            -- JsonConfig.m_vecFightConfig = {}
            self:LoadFightConfigData()
        elseif loadStep == 17 then
            self:LoadNovicePreviewData()
        elseif loadStep == 18 then
            --self:LoadFunctionLevelData()
        elseif loadStep == 19 then
            self:LoadSkillOpenLevel()
        elseif loadStep == 20 then
          self:LoadGuideData()
        elseif loadStep == 21 then
            self:LoadSkillLvUpCost()
        elseif loadStep == 22 then
            self:LoadDieWarningData()
        elseif loadStep == 23 then
            --self:LoadLoginRewardData()
        elseif loadStep == 24 then
            --self:LoadVIPConfigData()
        elseif loadStep == 25 then
            -- self:LoadMissionConfig()
        elseif loadStep == 26 then
            self:LoadDouShenConfig()
        elseif loadStep == 27 then
            self:LoadJingjieConfigData()
        elseif loadStep == 28 then
            self:LoadBpKejiDataByConfig()
		elseif loadStep == 29 then
			self:LoadMonsterConfig()
		elseif loadStep == 30 then
			self:LoadMasterConfig()
        elseif loadStep==31 then
            AppDef.Director:getScheduler():unscheduleScriptEntry(self.m_scheduler)
            self.m_scheduler = nil
            LGameMsg.m_baseMsg:ChangeEventId(LGameNetEvent.ConfigDataLoadFinish)
            self:SendMsg(LGameMsg.m_baseMsg)
        end
        loadStep = loadStep + 1
    end 

    self.m_scheduler = AppDef.Director:getScheduler():scheduleScriptFunc(tick, addStep, false)
end

--[[
获取单个属性对应的战斗力
@param1:attrType属性类型
@param2:attrValue属性值
@retrun:power战斗力
]]
function LDataConstMgr:GetSingleAttrPower(attrType, attrValue)
    local power = 0
    local attrData = self:GetAttrConfigData(attrType)
    if attrData == nil then
        return power
    end
    power = math.floor(attrValue * attrData.powerRatio)
    return power
end

--[[
获取属性对应的战斗力
@param1:attrTypeArr属性类型数组
@param2:attrValueArr属性值数组
@retrun:power战斗力
]]
function LDataConstMgr:GetAttrPower(attrTypeArr, attrValueArr)
    local power = 0
    for i = 1, #attrTypeArr do
        power = power + self:GetSingleAttrPower(attrTypeArr[i], attrValueArr[i])
    end
    return power
end

--[[
获取属性对应的战斗力
@param1:attrTypeArr属性类型数组
@param2:attrValueArr属性值数组
@retrun:power战斗力
]]
function LDataConstMgr:GetAttrPowerByOneArr(attrs)
    local power = 0
    for k,v in pairs(attrs) do
        power = power + self:GetSingleAttrPower(tonumber(v[1]), tonumber(v[2]))
    end
    return power
end

function LDataConstMgr:GetAttrConfigData(attrType)
    if #self.m_attrConfigList == 0 then
        self:LoadAttrConfig()
    end
    return self.m_attrConfigList[attrType]
end

function LDataConstMgr:LoadAttrConfig()
    if #self.m_attrConfigList > 0 then
        return
    end
    local objs = require("ConfigData.attr_type_dat");
    for i = 1, #objs do
        local data = objs[i];
        data.powerRatio = data.powerRatio / 10.0--属性战斗力换算比率
        self.m_attrConfigList[data.attrType] = data
    end
end

--[[
根据id获取阵容信息
@param1:fid,阵容id
@param1:flv,阵容等级
@return:LFormationData
]]
function LDataConstMgr:GetFormationLvUpData(fid, flv)
    -- if self.m_formationLvUpList == nil then
    --    self:LoadFormationLvUpData()
    --end
    --for i = 1, #self.m_formationLvUpList do
    --    if self.m_formationLvUpList[i].id == fid and self.m_formationLvUpList[i].lv == flv then
    --        return self.m_formationLvUpList[i]
    --    end
    --end
    --return nil
	local key = fid.."_"..flv
	return JsonConfig.m_zhenfaLevelMap[key]
end

--[[
加载阵型升级配置信息
]]
function LDataConstMgr:LoadFormationLvUpData()
    if self.m_formationLvUpList ~= nil then
        return
    end
    self.m_formationLvUpList = {}
    local objs = require("ConfigData.zhenfa_level_dat")
    local str
    local strArrs
    local strArrs2
    for i = 1, #objs do
        local data = objs[i]
        data.lv = data.level
        data.addAttrValue = {}
        data.addAttrType = {}
        
        for j = 1,AppDef.Formation.MaxFightNum do
            local typeData = {}
            local valueData = {}
            table.insert(data.addAttrValue,valueData)
            table.insert(data.addAttrType,typeData)
            local attrDatas =  data["index" .. j .. "_attr"]
            for k = 1, #attrDatas do
                valueData[k] = attrDatas[k][2]
                typeData[k] = attrDatas[k][1]
            end
        end
        
        data.costItemId = data.cost_itemid---升级消耗的道具id
        data.costItemNum = data.cost_itemnum---升级消耗的道具数量
        data.addPower = data.zhanli
        table.insert(self.m_formationLvUpList,data)
    end
end

--[[
根据id获取阵容信息
@param1:fid,阵容id
@return:LFormationData
]]
function LDataConstMgr:GetFormationDataById(fid)
    --if self.m_formationList == nil then
    --    self:LoadFormationData()
    --end
    --return self.m_formationList[fid]
	return JsonConfig.m_zhenfaConfig.getDefByID(fid)
end

--[[
根据下标获取阵容信息
@param1:find阵容下标
@return:LFormationData
]]
function LDataConstMgr:GetFormationDataByInd(find)
    --if self.m_formationList == nil then
    --    self:LoadFormationData()
    --end
    --return self.m_formationArr[find]
	return JsonConfig.m_zhenfaConfig.getDefByID(find)
end

--[[
获取阵容列表数组
]]


function LDataConstMgr:GetFormationDataList()
    --if self.m_formationList == nil then
    --    self:LoadFormationData()
    --end
    --return self.m_formationArr
	return JsonConfig.m_zhenfaConfig.definitionList
end

--[[
加载阵型配置表
]]
function LDataConstMgr:LoadFormationData()
    if self.m_formationList ~= nil then
        return
    end
    self.m_formationList = {}--阵型信息
    self.m_formationArr = {}
    -- local stream = StreamBase:CreateReadStreamFromFile("ConfigData/zhenfa_config.dat")
    -- if stream == nil then
    --     return
    -- end
    local objs = require("ConfigData.zhenfa_config_dat")
    for i = 1, #objs do
        local data = objs[i]
        data.posList = {}
        data.posOpenLvList = {}
        for j = 1,AppDef.Formation.MaxFightNum do
            data.posList[j] = data["index" .. j]
            data.posOpenLvList[j] = data["index" .. j .. "_openlevel"]
        end
        data.restraintList = data.counter;
        self.m_formationList[data.id] = data
        table.insert(self.m_formationArr, data)
    end
end

--[[
获取宠物神将修炼数据
@param1:quality,宠物资质
@param2:需要修炼的等级
]]
function LDataConstMgr:GetPetXiulianData(quality, level)
    ------print("GetPetXiulianData",quality, level)
    if self.m_petXiuLianList == nil then
        self:LoadPetXiulianData()
    end
    for i = 1,#self.m_petXiuLianList do
        if self.m_petXiuLianList[i].quality == quality
            and self.m_petXiuLianList[i].level == level then
            return self.m_petXiuLianList[i]
        end
    end
    return nil
end

--[[
宠物修炼数据
]]
function LDataConstMgr:LoadPetXiulianData()
    if self.m_petXiuLianList ~= nil then
        return
    end
    self.m_petXiuLianList = {}

    local stream = StreamBase:CreateReadStreamFromFile("ConfigData/pet_xiulian.dat")
    if stream == nil then
        return
    end
    local num = stream:ReadUInt()
    local str
    local strArrs
    local strArrs2
    for i = 1, num do
        local data = LPetXiulianData:New()
        data.quality = stream:ReadUInt()--资质
        data.level = stream:ReadUInt()--修炼等级列表，总共5类修炼
        local ind = 1
        for j = 1, 5 do
            str = stream:ReadUTF8String()
            strArrs = string.split(str,";")
            for k = 1, #strArrs do
                strArrs2 = string.split(strArrs[k],"-")
                data["attrType" .. k .. "List"][j] = tonumber(strArrs2[1])
                data["attrValue" .. k .. "List"][j] = tonumber(strArrs2[2])
            end
            data.heroLvList[j] = stream:ReadUInt()--对应英雄等级要求
        end
        
        str = stream:ReadUTF8String()
        strArrs = string.split(str,";")
        for j = 1, #strArrs do
            strArrs2 = string.split(strArrs[j],"-")
            data.needItemIdList[j] = tonumber(strArrs2[1])
            data.needItemNumList[j] = tonumber(strArrs2[2])
        end
        table.insert(self.m_petXiuLianList,data)
    end
end

--[[
获取道具合成信息
param1:pid 材料道具id
return:LItemCpdData道具合成的数据类
]]
function LDataConstMgr:GetItemCpdData(pid)
    if self.m_itemCpdList == nil then
        self:LoadItemCpdData()
    end
    return self.m_MapitemCpdList[pid]
end
--[[
获取道具合成信息
param1:pid 材料道具id
return:LItemCpdData道具合成的数据类
]]
function LDataConstMgr:GetItemCpdList()
  if self.m_itemCpdList == nil then
        self:LoadItemCpdData()
  end
  return self.m_MapitemCpdList
end

--[[
获取宠物合成信息
param1:pid需要合成的宠物id
return:LItemCpdData宠物合成的数据类
]]
function LDataConstMgr:GetPetCpdData(pid)
    --self.m_itemCpdList
    if self.m_itemCpdList == nil then
        self:LoadItemCpdData()
    end
    --宠物固定在原有的基础上加60002，以便和道具区分开来
    --获取的时候减去60002就行
    return self.m_itemCpdList[pid + 60002]
end

--[[
获取所有宠物合成信息
return:LItemCpdData宠物合成的数据类
]]
function LDataConstMgr:GetALLPetCpdData()
    --self.m_itemCpdList
    if self.m_itemCpdList == nil then
        self:LoadItemCpdData()
    end
    return self.m_petCpdList
end

function LDataConstMgr:GetPetCpdDataByItemId(itemId)
    if itemId == nil then
        return nil
    end
    if self.m_petCpdMap == nil then
        self:LoadItemCpdData()
    end
    return self.m_petCpdMap[itemId]
end

--[[
获取道具分解信息
param1:pid需要分解的道具id
]]
function LDataConstMgr:GetResolveData(itemId)
    if self.m_itemFjList == nil then
        self:LoadItemCpdData()
    end
    return self.m_itemFjList[itemId]
end

--[[
解析合成数据
]]
function LDataConstMgr:LoadItemCpdData()
    if self.m_itemCpdList ~= nil then
        return
    end
    self.m_itemCpdList = {}
    self.m_petCpdList = {}
    self.m_petCpdMap = {}
    self.m_itemFjList = {}
    local stream = StreamBase:CreateReadStreamFromFile("ConfigData/hecheng.dat")
    if stream == nil then
        return
    end
    local num = stream:ReadUInt()
    for i = 1, num do
        local data = LItemCpdData:New()
        data.type = stream:ReadUInt()--类型，1合成道具2合成宠物神将
        data.itemId = stream:ReadUInt()--需求的道具id
        data.itemNum = stream:ReadUInt()--需求的道具id数量
        local str = stream:ReadUTF8String()
        local strArrs = string.split(str,"-")
        if data.type == 1 then
            data.targetId = tonumber(strArrs[1])
            self.m_MapitemCpdList[data.itemId] = data
            self.m_itemCpdList[data.targetId] = data
        elseif data.type == 2 then
            --宠物固定在原有的基础上加60002，以便和道具区分开来
            --获取的时候减去60002就行
            data.targetId = tonumber(strArrs[2]) + 60002
            data.petStarLv = tonumber(strArrs[3])
            data.petLv = tonumber(strArrs[4])
            table.insert(self.m_petCpdList,data)
            self.m_itemCpdList[data.targetId] = data
            self.m_petCpdMap[data.itemId] = data
        elseif data.type == 3 then
            --分解
            data.targetId = tonumber(strArrs[1])--分解获得道具ID
            data.petLv = tonumber(strArrs[2])--分解获得道具数量
            self.m_itemFjList[data.itemId] = data
        end
    end
end

--[[
解析通天塔数据
]]
function LDataConstMgr:LoadTongtianTowerData()
    if self.m_MapTower ~= nil then
        return
    end
    self.m_MapTower = {}
    local stream = StreamBase:CreateReadStreamFromFile("ConfigData/tongtiantower.dat")
    if stream == nil then
        return
    end
    local num = stream:ReadUInt()
    for i = 1, num do
        local data = LTowerData:New()
        data.id = stream:ReadUInt()--
        data.rewards = {}
        local str = stream:ReadUTF8String()
        local rewards = string.split(str,";")
        for k=1,#rewards do
            local temp = string.split(rewards[k],"-")
            if temp ~= nil and #temp == 2 then
                local reward = {}
                reward.itemId = tonumber(temp[1])
                reward.itemNum = tonumber(temp[2])
                table.insert(data.rewards,reward)
            end
        end      
        str = stream:ReadUTF8String()
        rewards = string.split(str,";")
        for k=1,#rewards do
            local temp = string.split(rewards[k],"-")
            if temp ~= nil and #temp == 2 then
                local reward = {}
                reward.itemId = tonumber(temp[1])
                reward.itemNum = tonumber(temp[2])
                table.insert(data.sweepRewards,reward)
            end
        end    
        str = stream:ReadUTF8String()
        if #str > 0 then
            local arr = string.split(str, '-')
            for j=1,#arr do
                if #arr[j] > 10 then
                    table.insert(data.targetReward, arr[j])
                else
                    table.insert(data.targetReward, tonumber(arr[j]))
                end
            end
        end
        data.targetRewardName = stream:ReadUTF8String()
        table.insert(self.m_MapTower,data)
    end
end

--[[
获取通天塔信息
]]
function LDataConstMgr:GetTowerData(id)
    if self.m_MapTower == nil then
        self:LoadTongtianTowerData()
    end
    return self.m_MapTower[id]
end

function LDataConstMgr:GetNextTowerTargetRewardData(lv)
    if self.m_MapTower == nil then
        self:LoadTongtianTowerData()
    end
    if self.m_MapTower == nil or lv == nil or lv > #self.m_MapTower then
        return nil
    end
    local function checkValid(data)
        if data == nil then
            return false
        end
        if #data.targetRewardName > 0 and #data.targetReward > 0 then
            return true
        end
        return false
    end
    for i=lv,#self.m_MapTower do
        local data = self.m_MapTower[i]
        if checkValid(data) then
            return data,i
        end
    end
    return nil
end

--[[
获取宠物升星对应的职业加成信息
]]
function LDataConstMgr:GetPetSXAddValue(zhiye)
    if self.m_petSXAddValueList == nil then
        self:LoadPetAddValueData()
    end
    return self.m_petSXAddValueList[zhiye]
end

--[[
加载宠物升星职业属性加成数据
]]
function LDataConstMgr:LoadPetAddValueData()
    if self.m_petSXAddValueList ~= nil then
        return
    end
    self.m_petSXAddValueList = {}
    local stream = StreamBase:CreateReadStreamFromFile("ConfigData/pet_type_attr_ratio.dat")
    if stream == nil then
        return
    end
    --[[
type    attackRatio    wufangRatio    fashangRatio    suduRatio    qixueRatio    mingzhongRatio    shanbiRatio    baojiRatio    kangbaoRatio
神将类型    攻击倾向比例    物防倾向比例    法防倾向比例    速度倾向比例    气血倾向比例    命中倾向比例    闪避倾向比例    暴击倾向比例    抗暴倾向比例

    ]]
    local num = stream:ReadUInt()
    for i = 1, num do
        local data = LPetSXAddValue:New()
        data.zhiye = stream:ReadUInt()--职业
        data.attackRatio = stream:ReadUInt() / 10000--攻击比例
        data.wufangRatio = stream:ReadUInt() / 10000--物防倾向比例
        data.fashangRatio =stream:ReadUInt() / 10000--法防倾向比例
        data.suduRatio = stream:ReadUInt() / 10000--速度倾向比例
        data.qixueRatio = stream:ReadUInt() / 10000--气血倾向比例
        data.mingzhongRatio = stream:ReadUInt() / 10000--命中倾向比例
        data.shanbiRatio = stream:ReadUInt() / 10000--闪避倾向比例
        data.baojiRatio = stream:ReadUInt() / 10000--暴击倾向比例
        data.kangbaoRatio = stream:ReadUInt() / 10000--抗暴倾向比例
        self.m_petSXAddValueList[data.zhiye] = data
    end
end
--[[
获取宠物真实的属性加成
param1:zhiye宠物职业
param2:attrType属性类型
param3:attrValue属性值
return:finalAttrValue
]]
function LDataConstMgr:GetPetFinalAttrAddValue(zhiye, attrType, attrValue)
    local  tmp = LDataConstMgr:GetPetSXAddValue(zhiye)
    if attrType == AppDef.EAttrType.EAT_ATTACK then--攻击比例
        attrValue = attrValue * tmp.attackRatio
    elseif attrType == AppDef.EAttrType.EAT_DEFENSE then--物防倾向比例
        attrValue = attrValue * tmp.wufangRatio
    elseif attrType == AppDef.EAttrType.EAT_MAGICD_EFENSE then--法防倾向比例
        attrValue = attrValue * tmp.fashangRatio
    elseif attrType == AppDef.EAttrType.EAT_SPEED then--速度倾向比例
        attrValue = attrValue * tmp.suduRatio
    elseif attrType == AppDef.EAttrType.EAT_HP then--气血倾向比例
        attrValue = attrValue * tmp.qixueRatio
    elseif attrType == AppDef.EAttrType.EAT_HP then--命中倾向比例
        attrValue = attrValue * tmp.mingzhongRatio
    elseif attrType == AppDef.EAttrType.EAT_DODGE then--闪避倾向比例
        attrValue = attrValue * tmp.shanbiRatio
    elseif attrType == AppDef.EAttrType.EAT_CRIT then--暴击倾向比例
        attrValue = attrValue * tmp.baojiRatio
    elseif attrType == AppDef.EAttrType.EAT_RESISIT_CRIT then--抗暴倾向比例
        attrValue = attrValue * tmp.kangbaoRatio
    end
    attrValue = math.floor(attrValue + 0.5)
    return attrValue
end

function LDataConstMgr:GetPetBookSkillStudyData(sid)
    return self.m_petBookSkillStudyList[sid]
end

--[[
获取所有天生技能列表数组，里面保存的是技能id
return {sid1, sid2, sid3,...}
]]
function LDataConstMgr:GetPetBookSkillList()
    return self.m_petBookSkStudyArr
end

--[[
获取天生技能升级配置
]]
function LDataConstMgr:GetPetBornSKLvUpData(skInd, skLv)
    
    if self.m_petBornSkLvUpList == nil then
        self:LoadPetBornSkList()
    end
    for i = 1, #self.m_petBornSkLvUpList do
        if self.m_petBornSkLvUpList[i].skillInd == skInd
            and self.m_petBornSkLvUpList[i].skillLv == skLv then
            return self.m_petBornSkLvUpList[i]
        end
    end
    return nil
end

function LDataConstMgr:LoadPetBornSkList()
    if self.m_petBornSkLvUpList ~= nil then
        return
    end
    self.m_petBornSkLvUpList = {}
    local stream = StreamBase:CreateReadStreamFromFile("ConfigData/pet_born_skill_LvUp.dat")
    if stream == nil then
        return
    end
    local num = stream:ReadUInt()
    for i = 1, num do
        local data = {}
        data.skillInd =  stream:ReadUInt()--    
        data.skillLv = stream:ReadUInt()
        data.needLv = stream:ReadUInt()
        local str = stream:ReadUTF8String()

        local strArrs = string.split(str,";")
        data.costItemId = {}
        data.costItemNum = {}
        for j = 1, #strArrs do
            if string.len(strArrs[j]) == 0 then
                break
            end
            local strArrs2 = string.split(strArrs[j],"-")
            data.costItemId[j] = tonumber(strArrs2[1]) 
            data.costItemNum[j] = tonumber(strArrs2[2]) 
        end
        table.insert(self.m_petBornSkLvUpList, data)
    end
end

--[[
获取天书技能升级信息
]]
function LDataConstMgr:GetPetLearnSkillLvUpData(skid, lv)
    if self.m_petLearnSkLvUpList == nil then
        self:LoadPetLearnSkillLvUpList()
    end
    for i = 1,#self.m_petLearnSkLvUpList do
        if self.m_petLearnSkLvUpList[i].skId == skid 
            and self.m_petLearnSkLvUpList[i].skLv == lv then
            return self.m_petLearnSkLvUpList[i]
        end
    end
    return nil
end

--[[
宠物天书技能升级表
]]
function LDataConstMgr:LoadPetLearnSkillLvUpList()
    if self.m_petLearnSkLvUpList ~= nil then
        return
    end
    self.m_petLearnSkLvUpList = {}
    local stream = StreamBase:CreateReadStreamFromFile("ConfigData/pet_skill_LvUp.dat")
    if stream == nil then
        return
    end
    local num = stream:ReadUInt()
    for i = 1, num do
        local data = {}
        
        data.skId = stream:ReadUInt()
        data.skLv = stream:ReadUInt()
        local str = stream:ReadUTF8String()
        local strArrs = string.split(str,"-")
        data.itemId =  tonumber(strArrs[1])
        data.itemNum =  tonumber(strArrs[2])
        table.insert(self.m_petLearnSkLvUpList, data)
    end
end

--[[
宠物天书技能学习配置
]]
function LDataConstMgr:LoadPetBookSkillStudyList()
    ------print("LoadPetBookSkillStudyList")
    if self.m_petBookSkillStudyList ~= nil then
        return
    end
    self.m_petBookSkillStudyList  = {}
    self.m_petBookSkStudyArr = {}
    local stream = StreamBase:CreateReadStreamFromFile("ConfigData/pet_skill_add.dat")
    if stream == nil then
        return
    end
    local num = stream:ReadUInt()
    for i = 1, num do
        local data = LBookSkStudyData:New()
        data.itemId =  stream:ReadUInt()--    
        data.skId = stream:ReadUInt()
        data.skLv = stream:ReadUInt()
        self.m_petBookSkillStudyList[data.skId] = data

        table.insert(self.m_petBookSkStudyArr, data)
    end
end

function LDataConstMgr:LoadBattleData()
    self:LoadSkillHitData()
    self:LoadModelBTData()
    self:LoadSkBTData()
    self:LoadHitBTData()
    self:LoadBTActData()
    self:LoadBTBuffData()
    self:LoadBTShakeData()
end

function LDataConstMgr:GetBTShakeData(sid)
    if self.m_btShakeData[sid] == nil then
        return self.m_btShakeData[1]
    end
    return self.m_btShakeData[sid]
end

function LDataConstMgr:LoadBTShakeData()
    if self.m_btShakeData ~= nil then
      return
    end
    self.m_btShakeData = {}
    local stream = StreamBase:CreateReadStreamFromFile("ConfigData/battle/skill_camerashock.dat")
    if stream == nil then
        return
    end
    local num = stream:ReadUInt()
    for i = 1, num do
        local data = LBTShakeCfg:New()
        data.m_id = stream:ReadUInt()
        data.m_delayTime = stream:ReadUInt() / 100.0
        data.m_time = stream:ReadUInt() / 1000.0
        data.m_strength = stream:ReadUInt()
        self.m_btShakeData[data.m_id] = data
    end
end

function LDataConstMgr:LoadBTBuffData()
    if self.m_btBufData ~= nil then
        return
    end
    self.m_btBufData  = {}
    local stream = StreamBase:CreateReadStreamFromFile("ConfigData/battle/buff_client.dat")
    if stream == nil then
        return
    end
    local num = stream:ReadUInt()
    for i = 1, num do
        local data = LBTBuffCfg:New()
        data.id = stream:ReadUInt()--   
        data.name = stream:ReadUTF8String() 
        data.textType = stream:ReadUInt()
        data.showType = stream:ReadUInt()
        data.resName = stream:ReadUTF8String()--
        data.hit = stream:ReadUInt()--
        local str = stream:ReadUTF8String()
        local arr = string.split(str,"-")
        data.offPoint.x = tonumber(arr[1])
        data.offPoint.y = tonumber(arr[2])
        data.showText = stream:ReadUTF8String()--  
        data.tipIcon = stream:ReadUTF8String()--  
        data.desc = stream:ReadUTF8String()--

        -- data.stateInd = math.ceil(data.id/32)
        -- data.stateOffset = data.id%32 - 1
        -- data.stateValue = math.abs(bit.lshift(1,data.stateOffset))
        table.insert(self.m_btBufData, data)
        --self.m_btBufData[data.m_id] = data
    end
end

function LDataConstMgr:GetBTBuffById(bid)
    return self.m_btBufData[bid]
end

function LDataConstMgr:GetBTBuffList()
    return self.m_btBufData
end

function LDataConstMgr:HasBTAction(aid)
    if self.m_btActData[aid] == nil then
        return false
    else
        return true
    end
end

function LDataConstMgr:GetBTAction(aid, actionType)
    --------print("GetBTAction",aid)
    --[[
    同一个技能有可能是buff类型
    ]]
    if actionType ~=nil and actionType == AppDef.BTConst.ActionType.BAT_BUFF then
        local newaid = aid + 100000
        if self.m_btActData[newaid] ~= nil then
            return self.m_btActData[newaid]
        end
    end
    if self.m_btActData[aid] == nil then
        return self.m_btActData[0]
    end
    return self.m_btActData[aid]
end

--[[
获取战斗模型表现配置表
]]
function LDataConstMgr:GetBTModelAct(aid)
    --------print("GetBTModelAct",aid)
    return self.m_btModelAtkData[aid]
end

--[[
获取战斗技能表现配置表
]]
function LDataConstMgr:GetBTSkAct(aid)
    return self.m_btSkAtkData[aid]
end

--[[
获取战斗被击表现配置表
]]
function LDataConstMgr:GetBTHurtAct(aid)
    return self.m_btHitData[aid]
end

function LDataConstMgr:LoadBTActData()
    if self.m_btActData ~= nil then
        return
    end
    self.m_btActData = {}
    local stream = StreamBase:CreateReadStreamFromFile("ConfigData/battle/skill_client.dat")
    if stream == nil then
        return
    end
    local num = stream:ReadUInt()
    for i = 1, num do
        local data = LBTCfg:New()
        data.m_id = stream:ReadUInt()
        local cfg = stream:ReadUTF8String()
        --------print("LoadBTActData:",cfg)
        local arr = string.split(cfg,";")
        for j = 1, #arr do
            local arr2 = string.split(arr[j],"-")
            local clip = LBTClipCfg:New()
            clip.m_id = tonumber(arr2[4])
            clip.m_delay = tonumber(arr2[2]) / 100.0--转秒
            clip.m_clipType = tonumber(arr2[3])
            --------print("clip:",clip.m_id,clip.m_delay, clip.m_clipType)
            table.insert(data.m_cfgBuf,clip)
        end
        data.m_lianjiInd = stream:ReadUInt()
        data.m_mulitType = stream:ReadUInt()
        data.m_mulitTgtInd = stream:ReadUInt()
        self.m_btActData[data.m_id] = data
        
    end
end

--[[
加载战斗被击数据
]]
function LDataConstMgr:LoadHitBTData()
    if self.m_btHitData ~= nil then
        return
    end
    self.m_btHitData = {}
    local stream = StreamBase:CreateReadStreamFromFile("ConfigData/battle/skill_behit_client.dat")
    if stream == nil then
        return
    end
    local num = stream:ReadUInt()
    for i = 1, num do
        local data = LBTHitCfg:New()
        data.m_id = stream:ReadUInt()
        data.m_file = stream:ReadUTF8String()
        self.m_btHitData[data.m_id] = data
    end
end

--[[
加载技能动画战斗数据
]]
function LDataConstMgr:LoadSkBTData()
    if self.m_btSkAtkData ~= nil then
        return
    end
    self.m_btSkAtkData = {}
    local stream = StreamBase:CreateReadStreamFromFile("ConfigData/battle/skill_effect_client.dat")
    if stream == nil then
        return
    end
    local num = stream:ReadUInt()
    for i = 1, num do
        local data = LBTSkillCfg:New()
        data.m_id = stream:ReadUInt()
        data.m_file = stream:ReadUTF8String()
        data.m_resType = stream:ReadUInt()
        data.m_moveStartType = stream:ReadUInt()--开始移动类型--对应LBtActCfg.MoveType值
        data.m_moveEndType = stream:ReadUInt()--结束移动类型--对应LBtActCfg.MoveType值
        data.m_moveTime = stream:ReadUInt() / 1000.0--移动时间，0没有移动
        local str = stream:ReadUTF8String()
        if string.len(str) > 0 then
            local strArr = string.split(str,"-")
            data.m_leftOff.x = tonumber(strArr[1])
            data.m_leftOff.y = tonumber(strArr[2])
        end
        str = stream:ReadUTF8String()
        if string.len(str) > 0 then
            local strArr = string.split(str,"-")
            data.m_rightOff.x = tonumber(strArr[1])
            data.m_rightOff.y = tonumber(strArr[2])
        end
        data.m_hitpoint = stream:ReadUInt()--    0-地面；1-脚；2-腰；3-头
        data.m_soundFile = stream:ReadUTF8String()
        data.m_shakeId = stream:ReadUInt()
        data.m_scale = stream:ReadUInt() / 100.0
        self.m_btSkAtkData[data.m_id] = data
        --------print("LoadSkBTData:",data.m_file)
    end
end

--[[
加载模型战斗数据
]]
function LDataConstMgr:LoadModelBTData()
    if self.m_btModelAtkData ~= nil then
        return
    end
    self.m_btModelAtkData  = {}
    local stream = StreamBase:CreateReadStreamFromFile("ConfigData/battle/skill_attack_client.dat")
    if stream == nil then
        return
    end
    local num = stream:ReadUInt()
    for i = 1, num do
        local data = LBtActCfg:New()
        data.m_id = stream:ReadUInt()
        data.m_act = stream:ReadUTF8String()
        data.m_moveStartType = stream:ReadUInt()--开始移动类型--对应LBtActCfg.MoveType值
        data.m_moveEndType = stream:ReadUInt()--结束移动类型--对应LBtActCfg.MoveType值
        data.m_moveTime = stream:ReadUInt() / 1000.0--移动时间，0没有移动
        data.m_soundFile = stream:ReadUTF8String()
        data.m_shakeId = stream:ReadUInt()
        self.m_btModelAtkData[data.m_id] = data
        --------print("LoadModelBTData:",data.m_id, data.m_act)
    end
end

function LDataConstMgr:LoadSkillHitData()
    if self._VecHeroHit ~= nil then
        return
    end
    self._VecHeroHit = {}
    self._VecMonsterHit = {}
    self._defalutHitData = LBTUnitHitData:New()
    local function ReadPoint(s, point)
            point.x = s:ReadFloat(4)
            point.y = s:ReadFloat(4)
    end

    local l_stream = StreamBase:CreateReadStreamFromFile("ConfigData/hit_monster.dat")
    if l_stream == nil then
        return
    end
    local num = l_stream:ReadUInt()
    for i = 0, num do
        local data = LBTUnitHitData:New()
        data.id = l_stream:ReadUInt()
        ReadPoint(l_stream,data.hpBarPos)
        ReadPoint(l_stream, data.headPos)
        ReadPoint(l_stream, data.waistPos)
        ReadPoint(l_stream, data.footPos)
        self._VecMonsterHit[data.id] = data
    end
    local data2 = self._VecMonsterHit[304]
    if data2 == nil then
        data2 = LBTUnitHitData:New()
        data2.id = 304
        self._VecMonsterHit[data2.id] = data2
    end
    data2.hpBarPos.x = 0
    data2.hpBarPos.y = 145
    data2.headPos.x = 0
    data2.headPos.y = 92
    data2.waistPos.x = 0
    data2.waistPos.y = 55
    data2.footPos.x = 0
    data2.footPos.y = 0

    self._VecHeroHit = AppDef.HeroHitData

    --读取人物
    -- local heroFileList = 
    -- {
    --     "ConfigData/hit_m_z.dat","ConfigData/hit_f_z.dat","ConfigData/hit_m_f.dat",
    --     "ConfigData/hit_f_f.dat","ConfigData/hit_m_c.dat","ConfigData/hit_f_c.dat" 
    -- }
    -- for i = 1, #heroFileList do
    --     local hs = StreamBase:CreateReadStreamFromFile(heroFileList[i])
    --     if hs ~= nil then
    --         local data = LBTUnitHitData:New()
    --         data.id = l_stream:ReadUInt()
    --         ReadPoint(l_stream,data.hpBarPos)
    --         ReadPoint(l_stream, data.headPos)
    --         ReadPoint(l_stream, data.waistPos)
    --         ReadPoint(l_stream, data.footPos)
    --         table.insert(self._VecHeroHit, data)
    --     end
    -- end
end

function LDataConstMgr:GetHeroHitByIdx(id)
    if id <= #self._VecHeroHit then
      return self._VecHeroHit[id]
    end
    return self._defalutHitData
end

function LDataConstMgr:GetMonsterHitById(id)
    if self._VecMonsterHit[id] == nil then
      return self._defalutHitData
    else
      return self._VecMonsterHit[id]
    end
end


function LDataConstMgr:getCItemByID(id)
    return JsonConfig.m_Item.getDefByID(id)
end

function LDataConstMgr:GetItemList() 
    return self.m_VecItemList
end

function LDataConstMgr:GetItemMaxNum() 
    return self.m_ItemMaxNum
end

function LDataConstMgr:GetCopyData() return self.m_Copy end
function LDataConstMgr:GetVipAwardInfo() return self.m_VipAwardInfo end
function LDataConstMgr:GetMyCardInfo() return self.m_CardInfo end

--获取技能详细信息列表
function LDataConstMgr:GetSkillDetailList(sid) 
    local skInfo = self.m_pSkillBasicList[sid]
    if skInfo == nil then
      skInfo = self.m_pSkillBasicList[0]
    end
    return skInfo
end

function LDataConstMgr:AddItem(it)
    local ind
    if self.m_ItemNum >= self.m_ItemMaxNum then
        it:Delete()
        return
    end

    ind = self.m_ItemNum
    local i = 1
    for i = 1, self.m_ItemNum do
        if it.m_id < self.m_VecItemList[i].m_id then
            ind=i
            break
        elseif it.m_id == self.m_VecItemList[i].m_id then
            it:Delete()
            return
        end
    end
    table.insert(self.m_VecItemList,ind,it)
    self.m_ItemNum = self.m_ItemNum + 1
end
--------------------------------------------------------------------------------------
function LDataConstMgr:GetSkillActiveEffectValue(id, paramInd, skillLv)
    --print("GetSkillActiveEffectValue",id, paramInd, skillLv)
    if skillLv == 0 then
        skillLv = 1
    end
    local data = self.m_pSkillActiveList[id]
    --print("#NUM",#data.params)
    local value = data.params[paramInd][2] + (skillLv - 1)*data.params[paramInd][3]
    value = math.abs(value)
    if paramInd <= 2 then
        local newvalue = value/100
        local newValue2 = math.floor(newvalue)
        if newValue2 < newvalue then
            return string.format("%.2f",newvalue) .. "%"
        else
            return newValue2 .. "%"
        end
        return string.format("%.2f",newvalue) .. "%"
        --return math.floor(value/100) .. "%"
    end
    return "" .. value
end

function LDataConstMgr:GetSkillActiveEffectName(id, paramInd)
    local data = self.m_pSkillActiveList[id]
    return data.params[paramInd][1]
end

--[[
加载技能主动效果表
]]
function LDataConstMgr:LoadSkillActive()
    if #self.m_pSkillActiveList > 0 then
        return
    end
    local stream = StreamBase:CreateReadStreamFromFile("ConfigData/skill_active_effect.dat")
    if stream == nil then
        return
    end
    local num = stream:ReadUInt()
    for i = 1, num do
        local data = LSkillActiveCfg:New()
        data.id = stream:ReadUInt()
        -- --print("data.id = ",data.id)
        data.actionType = stream:ReadUInt()
        data.targetType = stream:ReadUInt()
        data.targetRange = stream:ReadUInt()
        data.targetSelect = stream:ReadUInt()
        data.targetNum = stream:ReadUInt()
        data.buffId = stream:ReadUInt()
        for i = 1, 3 do
            data.params[i][1] = stream:ReadUTF8String()
            data.params[i][2] = stream:ReadInt()
            data.params[i][3] = stream:ReadInt()
        end
        self.m_pSkillActiveList[data.id] = data
    end
end

function LDataConstMgr:GetSkillAdditiveEffectValue(id, paramInd, skillLv)
    if skillLv == 0 then
        skillLv = 1
    end
    local data = self.m_pSkillAdditiveList[id]
    if data == nil then
        return "ErrorData"
    end
    local value = data.params[paramInd][2] + (skillLv - 1)*data.params[paramInd][3]
    value = math.abs(value)
    if paramInd <= 3 then
        local newvalue = value/100
        local newValue2 = math.floor(newvalue)
        if newValue2 < newvalue then
            return string.format("%.2f",newvalue) .. "%"
        else
            return newValue2 .. "%"
        end
        
        --return math.floor(value/100) .. "%"
    end
    return "" .. value
end

function LDataConstMgr:GetSkillAdditiveEffectName(id, paramInd)
    local data = self.m_pSkillAdditiveList[id]
    return data.params[paramInd][1]
end

--[[
加载技能附加效果表
]]
function LDataConstMgr:LoadSkillAdditive()
    if #self.m_pSkillAdditiveList > 0 then
        return
    end
    local stream = StreamBase:CreateReadStreamFromFile("ConfigData/skill_additive_effect.dat")
    if stream == nil then
        return
    end
    local num = stream:ReadUInt()
    for i = 1, num do
        local data = LSkillAdditiveCfg:New()
        data.id = stream:ReadUInt()
        data.showStr = stream:ReadUTF8String()
        data.trigger = stream:ReadUInt()
        data.addType = stream:ReadUInt()
        self.buffId = stream:ReadUInt()
        for i = 1, 5 do
            data.params[i][1] = stream:ReadUTF8String()
            data.params[i][2] = stream:ReadInt()
            data.params[i][3] = stream:ReadInt()
        end
        self.m_pSkillAdditiveList[data.id] = data
    end
    
end
--[[
加载基础技能表
]]
function LDataConstMgr:LoadSkillBasic()
    if #self.m_pSkillBasicList > 0 then
        return
    end
    local stream = StreamBase:CreateReadStreamFromFile("ConfigData/skill_basic.dat")
    if stream == nil then
        return
    end
    local num = stream:ReadUInt()
    for i = 1, num do
        local data = LSkillBasicCfg:New()
        data.id = stream:ReadUInt()--id
        data.skillType = stream:ReadUInt()
        data.name = stream:ReadUTF8String()--名字
        local str = stream:ReadUTF8String()
        local strArr = string.split(str,";")
        for j = 1, #strArr do
            local strArr2 = string.split(strArr[j],"-")
            table.insert(data.effects,{tonumber(strArr2[1]),tonumber(strArr2[2])})
        end
        data.cd = stream:ReadUInt()  
        local desc = stream:ReadUTF8String()
        data:SetDesc(desc)
        data.picFile = stream:ReadUTF8String()
        data.skillTypeTitle = stream:ReadUTF8String()
        self.m_pSkillBasicList[data.id] = data
    end
end

function LDataConstMgr:LoadItemData()
    if #self.m_VecItemList > 0 then
        return
    end

    local itemListData = JsonConfig.m_Item.getList()
    self.m_ItemNum = #itemListData
    self.m_ItemMaxNum = self.m_ItemNum + 200
    for i = 1, self.m_ItemNum do
        local it = LCItem:New()
        local configData = itemListData[i]
        it.m_id = configData.id
        it.m_type = configData.type
        it.m_pos = 0
        it.m_quality = configData.quality
        it.m_level = 0
        it.m_priority = configData.sort_priority
        it.m_sex = 0

        it.m_baseAttrTypes = {}
        it.m_baseAttrValues = {}
        for i=1,AppDef.EAttrType.EAT_RESISIT_CRIT do
            --属性移除
            local attrValue = 0
            if attrValue > 0 then
                table.insert(it.m_baseAttrTypes,i)
                table.insert(it.m_baseAttrValues,attrValue)
            end
        end

        it.additionalValue = 0
        if configData.sub_value and configData.sub_value[1] and configData.sub_value[1][2] then
            it.additionalValue = configData.sub_value[1][2]
        end
        it.m_price = configData.jiage
        it.m_pic = configData.pic
        it.m_name = configData.name
        it.m_desc = configData.des
        it.m_from = configData.item_from
        local source = configData.item_source
        it.m_sell = 0
        -- print("LoadItemData it.m_sell ==> ", it.m_sell)
        it.m_source = {}
        if #source > 0 then   
            local list = string.split(source,";")       
            for i=1,#list do
                local temp = string.split(list[i],"-")
                if temp[1] ~= nil and temp[1] ~= "" then
                    local sysValue = {}
                    sysValue.id = tonumber(temp[1])
                    if sysValue.id == AppDef.EModuleID.EMID_FUBEN then
                        if temp[2] ~= nil then
                            sysValue.value = tonumber(temp[2])
                        else
                            sysValue.value = 1
                        end
                    end
                    if sysValue.id ~= nil and sysValue.id > 0 then
                        table.insert(it.m_source,sysValue)
                    end
                end
            end
        end
        table.insert(self.m_VecItemList,it)
        self.m_MapItemtList[it.m_id] = it
    end
end

function LDataConstMgr:LoadPetStarConfigData( ... )
    -- body
    -- local str = LDataConstMgr.pcStartParamrter

    local function getValueByIndex(arr, index)
        -- body
        local data1 = string.split(arr[index], ":")
        local value = data1[2]
        return value
    end

    local str = LUserConfigMgr:GetPCSartParameter()
    -- print("InitGameVersion ==>", str)
    if str ~= nil and string.len(str) > 0 then
        local arr = string.split(str, " ")
        -- dump(arr, " 1234567>")
        GameSdk.auth_key = getValueByIndex(arr, 1) or ""
        GameSdk.uid = getValueByIndex(arr, 2) or ""
        GameSdk.extraInfo = getValueByIndex(arr, 3) or ""
        print("LoadPetStarConfigData ===>", GameSdk.auth_key, GameSdk.uid, GameSdk.extraInfo)
    end
end

--装备强化属性表
function LDataConstMgr:LoadEquipStrengthenAttrData()
	if self.m_VecEquipStrengthen ~= nil then
		return
	end
	local stream = StreamBase:CreateReadStreamFromFile("ConfigData/equip_qianghua_attr.dat")
	if stream == nil then
		return
	end
    self.m_VecEquipStrengthen = {}

	local maxNum = stream:ReadUInt()
	for i = 1, maxNum do
        local itemType = stream:ReadUInt()
        local level = stream:ReadUInt()
        if self.m_VecEquipStrengthen[itemType] == nil then
            self.m_VecEquipStrengthen[itemType] = {}
        end
        local it =  self.m_VecEquipStrengthen[itemType]
        if it[level] == nil then
            it[level] = LCEquipStrengthen:New()
        end
        it[level].m_type = itemType
		it[level].m_level = level
        local attrStr = stream:ReadUTF8String()
        local attrList = string.split(attrStr,";")
        for k = 1,#attrList do
            local list = string.split(attrList[k],"-")
            if list ~= nil and #list == 2 then
                table.insert(it[level].m_attrTypes,tonumber(list[1]))
                table.insert(it[level].m_attrValues,tonumber(list[2]))
            end
        end
	end
end

function LDataConstMgr:GetEquipStrengthenData(itemType,level)
    if self.m_VecEquipStrengthen == nil then
        self:LoadEquipStrengthenAttrData()
    end
    if level < 1 then
        return nil
    end 
    return self.m_VecEquipStrengthen[itemType][level]
end

--装备强化Cost
function LDataConstMgr:LoadEquipStrengthenCost()
	if self.m_VecEquipStrengthenCost ~= nil then
		return
	end
	local stream = StreamBase:CreateReadStreamFromFile("ConfigData/equip_qianghua.dat")
	if stream == nil then
		return
	end
    self.m_VecEquipStrengthenCost = {}

	local maxNum = stream:ReadUInt()
	for i = 1, maxNum do
        local equipPos = stream:ReadUInt()
        local level = stream:ReadUInt()
        if self.m_VecEquipStrengthenCost[equipPos] == nil then
            self.m_VecEquipStrengthenCost[equipPos] = {}
        end
        local it =  self.m_VecEquipStrengthenCost[equipPos]
        if it[level] == nil then
            it[level] = LCEquipStrengthenCost:New()
        end
        it[level].m_pos = equipPos
		it[level].m_level = level
        it[level].m_baseRatio = stream:ReadUInt()
        local str = stream:ReadUTF8String()
        local costList = string.split(str,";")
        if #costList == 2 then
            --道具
            local list = string.split(costList[1],"-")
            if list ~= nil and #list == 2 then
                it[level].m_itemId = tonumber(list[1])
                it[level].m_itemNum = tonumber(list[2])
            end
            local list = string.split(costList[2],"-")
            if list ~= nil and #list == 2 then
                it[level].m_moneyType = tonumber(list[1])
                it[level].m_moneyValue = tonumber(list[2])
            end
        end
        str = stream:ReadUTF8String()
        costList = string.split(str,";")
        for k = 1,#costList do
            local list = string.split(costList[k],"-")
            if list ~= nil and #list == 2 then
                it[level].m_itemRatio[tonumber(list[1])] = tonumber(list[2])
            end
        end
	end
end

function LDataConstMgr:GetEquipStrengthenCost(equipPos,level)
    if self.m_VecEquipStrengthenCost == nil then
        self:LoadEquipStrengthenCost()
    end
	if self.m_VecEquipStrengthenCost[equipPos] == nil then
		return nil
	end
    return self.m_VecEquipStrengthenCost[equipPos][level]
end

--装备升阶表
function LDataConstMgr:LoadEquipUpgradeData()
	if self.m_VecEquipUpgrade ~= nil then
		return
	end
	local stream = StreamBase:CreateReadStreamFromFile("ConfigData/equip_shengjie.dat")
	if stream == nil then
		return
	end
    self.m_VecEquipUpgrade = {}

	local maxNum = stream:ReadUInt()
	for i = 1, maxNum do
        local equipPos = stream:ReadUInt()
        local level = stream:ReadUInt()
        if self.m_VecEquipUpgrade[equipPos] == nil then
            self.m_VecEquipUpgrade[equipPos] = {}
        end
        local it =  self.m_VecEquipUpgrade[equipPos]
        if it[level] == nil then
            it[level] = LCEquipUpgrade:New()
        end
        it[level].m_pos = equipPos
		it[level].m_level = level
        local str = stream:ReadUTF8String()
        local costList = string.split(str,";")
        if #costList == 2 then
            --道具
            local list = string.split(costList[1],"-")
            if list ~= nil and #list == 2 then
                it[level].m_itemId = tonumber(list[1])
                it[level].m_itemNum = tonumber(list[2])
            end
            local list = string.split(costList[2],"-")
            if list ~= nil and #list == 2 then
                it[level].m_moneyType = tonumber(list[1])
                it[level].m_moneyValue = tonumber(list[2])
            end
        end
	end
end

function LDataConstMgr:GetEquipUpgradeData(equipPos,level)
    if self.m_VecEquipUpgrade == nil then
        self:LoadEquipUpgradeData()
    end
    --print("LDataConstMgr:GetEquipUpgradeData",equipPos,level)
	if self.m_VecEquipUpgrade[equipPos] == nil then
		return nil
	end
    return self.m_VecEquipUpgrade[equipPos][level]
end

--装备淬炼表
function LDataConstMgr:LoadEquipCuiLianData()
	if self.m_MapCuiLianData ~= nil then
		return
	end
	local stream = StreamBase:CreateReadStreamFromFile("ConfigData/equip_cuilian_attr.dat")
	if stream == nil then
		return
	end
    self.m_MapCuiLianData = {}

	local maxNum = stream:ReadUInt()
	for i = 1, maxNum do
        local it =  LCEquipCuiLian:New()
        it.m_itemType = stream:ReadUInt()
        for k = 1,4 do
            local level = stream:ReadUInt() 
            local attrType = stream:ReadUInt() 
            local maxVal = stream:ReadUInt() 
            if level > 0 then
                it.m_level[k] = level
                it.m_attrType[k] = attrType
                it.m_attrMaxVal[k] = maxVal
            end
        end
        for k=1,3 do
            stream:ReadString()
        end
        self.m_MapCuiLianData[it.m_itemType] = it
	end
end

function LDataConstMgr:GetEquipCuiLianData(itemType)
    if self.m_MapCuiLianData == nil then
        self:LoadEquipCuiLianData()
    end
    return self.m_MapCuiLianData[itemType]
end

function LDataConstMgr:GetEquipCuiLianMaxValue(itemType,attrType)
    if self.m_MapCuiLianData == nil then
        self:LoadEquipCuiLianData()
    end
    local data = self.m_MapCuiLianData[itemType]
    if data == nil then return 0 end
    for i =1,4 do
        if data.m_attrType[i] == attrType then
             return data.m_attrMaxVal[i]
        end
    end
    return 0
end

--神器 配置
function LDataConstMgr:LoadShenQiData()
	if self.m_VecShenQiList ~= nil then
		return
	end
    self.m_VecShenQiList = {}
	local stream = StreamBase:CreateReadStreamFromFile("ConfigData/shenqi_config.dat")
	if stream == nil then
		return
	end

	self.m_ShenqiNum = stream:ReadUInt()
	for i = 1, self.m_ShenqiNum do
		local it = LCShenQi:New()
		it.m_id = stream:ReadUInt()
		it.m_name = stream:ReadUTF8String()
		local attrStr = stream:ReadUTF8String()
        local attrList = string.split(attrStr,";")
        for k = 1,#attrList do
            local list = string.split(attrList[k],"-")
            if list ~= nil and #list == 2 then
                local attrInfo = { ["attrType"] = 0, ["attrValue"] = 0 } 
                attrInfo.attrType = tonumber(list[1])
                attrInfo.attrValue = tonumber(list[2])
                table.insert(it.m_attrList,attrInfo)
            end
        end
		it.m_desc = stream:ReadUTF8String()
		table.insert(self.m_VecShenQiList,it)
	end
end

function LDataConstMgr:GetShenQiData()
    if self.m_VecShenQiList == nil then
        self:LoadShenQiData()
    end
    return self.m_VecShenQiList
end

function LDataConstMgr:GetShenQiById(id)
    if self.m_VecShenQiList == nil then
        self:LoadShenQiData()
    end
    return self.m_VecShenQiList[id]
end

--神器 培养
function LDataConstMgr:LoadShenQiCultureData()
	if self.m_VecShenQiCultureData ~= nil then
		return
	end
    self.m_VecShenQiCultureData = {}
	local stream = StreamBase:CreateReadStreamFromFile("ConfigData/shenqi_peiyang.dat")
	if stream == nil then
		return
	end

	self.m_ShenqiNum = stream:ReadUInt()
	for i = 1, self.m_ShenqiNum do
        local level = stream:ReadUInt()
        if self.m_VecShenQiCultureData[level] == nil then
            self.m_VecShenQiCultureData[level] = {}
        end
        local it = LCShenQiCultureData:New()
		it.m_level = level
        it.m_star = stream:ReadUInt()             
        it.m_needExp = stream:ReadUInt() 
        it.m_cur_shenqi = stream:ReadUInt()   
        it.m_next_shenqi = stream:ReadUInt()        
        it.m_add_shenqi =stream:ReadUInt()
		local attrStr = stream:ReadUTF8String()
        local attrList = string.split(attrStr,";")
        for k = 1,#attrList do
            local list = string.split(attrList[k],"-")
            if list ~= nil and #list == 2 then
                local attrInfo = { ["attrType"] = 0, ["attrValue"] = 0 } 
                attrInfo.attrType = tonumber(list[1])
                attrInfo.attrValue = tonumber(list[2])
                table.insert(it.m_attrList,attrInfo)
            end
        end
        self.m_VecShenQiCultureData[level][it.m_star] = it
        if self.m_maxShenqiLevel < level then
            self.m_maxShenqiLevel = level
        end
        if self.m_maxShenqiStar < it.m_star then
            self.m_maxShenqiStar = it.m_star
        end
	end
end

function LDataConstMgr:GetShenQiCultureData(level,star)
    if self.m_VecShenQiCultureData == nil then
        self:LoadShenQiCultureData()
    end
    if self.m_VecShenQiCultureData[level] == nil then
        return nil
    end
    return self.m_VecShenQiCultureData[level][star]
end

function LDataConstMgr:GetItemAttrName(type,profession)
    local cfgData =  LDataConstMgr:GetAttrConfigData(type)
    if cfgData == nil then
        return ""
    end

    local attrName = cfgData.attrName
    if profession ~= nil and type == AppDef.EAttrType.EAT_ATTACK then
        local data = self.m_skills[profession]
        if data == nil then 
            return attrName
        end
        if data.attack_type == 1 then
            attrName = GUITips.Item_Info_Attr178
        elseif data.attack_type == 2 then
            attrName = GUITips.Item_Info_Attr179
        end
    end
    return attrName
end

--获取人物升级经验
function LDataConstMgr:GetHeroLevelUpExp(level) 
    local exp = 0
    local cfg = JsonConfig.m_expConfig.getDefByID(level)
    if cfg ~= nil then
        exp = cfg.exp or 0
    end
    return exp
end

 function LDataConstMgr:IsLimitedLevel(limLv,lv)
     if limLv < lv then
        return true
    end
    return false
 end

function LDataConstMgr:IsLimitedLevel2(str, lv)
    if type(str) ~= "string" then
        return false, nil
    end
    local _sIndex, _eIndex = string.find(str, "|")
    local levelLimit = tonumber(string.sub(str, 1, _sIndex-1))
    local retStr = string.sub(str, _sIndex+1)
    if lv < levelLimit then
        return true, retStr
    else
        return false, nil
    end
end

function LDataConstMgr:GetSkillAttrDesc(skillid,level)
    local skCfg = LDataConstMgr:GetSkillDetailList(skillid)
    local params = skCfg.descParams
    if #params == 0 then
        return {}
    end
    local strArr = {}
    for i = 1, #params do
        local param = params[i]
        local valueStr1
        local valueStr2
        local valueName
        if param[1] == 1 then
            valueName = self:GetSkillActiveEffectName(param[2],param[3])
            valueStr1 = self:GetSkillActiveEffectValue(param[2],param[3],level)
            valueStr2 = self:GetSkillActiveEffectValue(param[2],param[3],level + 1)
        elseif param[1] == 2 then
            valueName = self:GetSkillAdditiveEffectName(param[2],param[3])
            valueStr1 = self:GetSkillAdditiveEffectValue(param[2],param[3],level)
            valueStr2 = self:GetSkillAdditiveEffectValue(param[2],param[3],level + 1)
        end
        if string.len(valueName) > 0 then
            table.insert(strArr,{valueName,valueStr1,valueStr2})
        end
    end
    return strArr
end

function LDataConstMgr:GetHeroSkillDesc(skillid, level)
    local skCfg = LDataConstMgr:GetSkillDetailList(skillid)
    if skCfg == nil then return "" end
    --[[
  技能描述参数
  {
    {类型，id, 参数},--数组
    {类型，id, 参数},--数组
    {类型，id, 参数},--数组
  }
  参数解释：
    类型： 1：skill_active_effect技能主动效果表
        2：skill_addtive_effect技能附加效果表
    id:   对应类型表里面的id值
    参数: 对应效果表里面的param索引
    比如{1-11-2}:取skill_active_effect表里面id为11字段里面的para2这个参数值
  ]]
    local params = skCfg.descParams
    if #params == 0 then
        return skCfg.desc
    end
    local strArr = {}
    for i = 1, #params do
        local param = params[i]
        local valueStr
        if param[1] == 1 then
            valueStr = self:GetSkillActiveEffectValue(param[2],param[3],level)
        elseif param[1] == 2 then
            valueStr = self:GetSkillAdditiveEffectValue(param[2],param[3],level)
        end
        table.insert(strArr,valueStr)
    end
    local desc = ""
    local function GetDesc()
        desc = string.format(skCfg.desc,unpack(strArr))
    end
    local function GetDescErr()
        desc = skCfg.desc
    end
    xpcall(GetDesc,GetDescErr)
    return desc
end

function LDataConstMgr:VectorSafeVal(vec, idx, DefValue)
    ----------print("VectorSafeVal",idx,DefValue,#vec,vec[idx])
    if idx > 0 and idx <= #vec then
        return vec[idx]
    else
        return DefValue
    end
end

function LDataConstMgr:VectorSafeVal2(vec, idx, idxSub,DefValue)
    if idx <= 0 or idx > #vec or idxSub <= 0 or idxSub > #vec[idx] then
        return DefValue
    end
    return vec[idx][idxSub]
end




function LDataConstMgr:SortHorseConfig()
	if #self.m_horseConfigArr == 0 then
		self:LoadHorseConfigData()
	end
    function sortFunc(a, b) 
	    if a.isGet == true and b.isGet == true then 
	        return a.id < b.id 
	    elseif a.isGet == false and b.isGet == false then 
	        return a.id < b.id
	    elseif a.isGet == true then
	        return true
	    else
	        return false
	    end 
    end 
    table.sort(self.m_horseConfigArr, sortFunc)
end

function LDataConstMgr:GetOtherHorseConfigData(hid)

    if self.m_otherHorseConfigArr == nil then
        return nil
    end

    if #self.m_otherHorseConfigArr == 0 then
        self:LoadHorseConfigData()
    end
    return self.m_otherHorseConfigArr[hid]
end

function LDataConstMgr:GetOtherHorseConfigArr()
    if #self.m_otherHorseConfigArr == 0 then
        self:LoadHorseConfigData()
    end
    return self.m_otherHorseConfigArr
end

function LDataConstMgr:GetHorseConfigArr()
    if #self.m_horseConfigArr == 0 then
        self:LoadHorseConfigData()
    end
    return self.m_horseConfigArr
end

function LDataConstMgr:LoadHorseConfigData()
    if #self.m_horseConfigList > 0 then
        return
    end
    local stream = StreamBase:CreateReadStreamFromFile("ConfigData/mount_config.dat")
    if stream == nil then
        return
    end
    local attrStr
    local num = stream:ReadUInt()
    for i = 1, num do
        local data = LHorseConfig:New()
        data.id = stream:ReadUInt()
        data.name = stream:ReadUTF8String()
        data.getWayType = stream:ReadUInt()
        data.getWayNum = stream:ReadUInt()
        data.getWayItem = stream:ReadUInt()

        data.jinjieId = stream:ReadUInt()--进阶后的坐骑id
        local jinjieStr = stream:ReadUTF8String()
        local strArr = string.split(jinjieStr,";")
        for j = 1, #strArr do
            local strArr2 = string.split(strArr[j],"-")
            table.insert(data.jinjieCostIds,tonumber(strArr2[1]))
            table.insert(data.jingjieCostNums,tonumber(strArr2[2]))
        end
        stream:ReadUInt()
        data.moveSpeed = stream:ReadUInt() + 100
        local attrStr = stream:ReadUTF8String()
        strArr = string.split(attrStr,";")
        for j = 1, #strArr do
            local strArr2 = string.split(strArr[j],"-")
            table.insert(data.attrTypeArr,tonumber(strArr2[1]))
            table.insert(data.attrValueArr,tonumber(strArr2[2]))
        end
        data.desc = stream:ReadUTF8String()
        stream:ReadUTF8String()
        self.m_horseConfigList[data.id] = data
        table.insert(self.m_horseConfigArr, data)
        table.insert(self.m_otherHorseConfigArr, data)
    end
end
--获取境界属性
function LDataConstMgr:GetJingjieConfifArr()
    if #(self.m_jingjieConfigArr)==0 then
        self:LoadJingjieConfigData()
    end
    return self.m_jingjieConfigArr
end
--获取境界信息byid
function LDataConstMgr:GetJingjieInfoById(id)
     return self.m_jingjieConfigArr[id]
end

--[[
C++调用
]]
function LDataConstMgr.GetJingjieNameById(id)
    if LDataConstMgr.m_jingjieConfigArr == nil then
        return ""
    end
    if LDataConstMgr.m_jingjieConfigArr[id] == nil then
        return ""
    else
        return LDataConstMgr.m_jingjieConfigArr[id].name
    end
    print("境界"..LDataConstMgr.m_jingjieConfigArr[id].name)
end

--[[
C++调用
]]
function LDataConstMgr.GetJingjieColorById(id)
    if LDataConstMgr.m_jingjieConfigArr == nil then
        return 0
    end
    if LDataConstMgr.m_jingjieConfigArr[id] == nil then
        return 0
    else
        return LDataConstMgr.m_jingjieConfigArr[id].color
    end
end

--[[
C++调用
]]

function LDataConstMgr.setPcStartParamrter(str)
    self.pcStartParamrter = str
    print("setPcStartParamrter ==>", self.pcStartParamrter)
end


--加载境界配置信息
function LDataConstMgr:LoadJingjieConfigData()
    if #self.m_jingjieConfigList > 0 then
        return
    end
    local stream = StreamBase:CreateReadStreamFromFile("ConfigData/jingjie_config.dat")
    if stream == nil then
        return
    end
  
    local attrStr
    local num = stream:ReadUInt()
 
    for i = 1, num do
        local data = LJingJieConfig:New()
        data.id = stream:ReadUInt()
        data.name = stream:ReadUTF8String()

        data.color = stream:ReadUInt()       
        local upgradeConsume = stream:ReadUTF8String()

        local strArr = string.split(upgradeConsume,"-")   
        local UpgradeData = {
             uptype =tonumber(strArr[1]),
             upnum = tonumber(strArr[2])

         }   
       
        table.insert(data.upgrade,UpgradeData)  
        
        local attrStr = stream:ReadUTF8String()
        strArr = string.split(attrStr,";")
        for j = 1, #strArr do
            local strArr2 = string.split(strArr[j],"-")
            local arr = {
                attrType=tonumber(strArr2[1]),
                attrValue=tonumber(strArr2[2])
             }
             table.insert(data.attrList,arr)        
        end
         local  salary = stream:ReadUTF8String()
         strArr=salary.split(salary,"-")
         local arr = {
                attrType=tonumber(strArr[1]),
                attrValue=tonumber(strArr[2])
         }
         data.salary = arr
        local icon = stream:ReadUTF8String()
        data.icon=icon
        self.m_jingjieConfigList[data.id] = data
        table.insert(self.m_jingjieConfigArr, data)
    end
end

--神将信息
function LDataConstMgr:LoadPetData()
    if #self.m_VecPetList > 0 then
        return
    end
    local stream = StreamBase:CreateReadStreamFromFile("ConfigData/pet_basic_config.dat")
    if stream == nil then
        return
    end

    local num = stream:ReadUInt()
    for i = 1, num do
        local data = LPetConfigInfo:New()
        data.id = stream:ReadUInt()
        data.pic = stream:ReadUInt()
        data.name = stream:ReadUTF8String()
        data.petType = stream:ReadUInt()
        data.joinLv = stream:ReadUInt()
        data.quality = stream:ReadUInt()
        data.initStar = stream:ReadUInt()
        local skillStr = stream:ReadUTF8String()
        local strArr = string.split(skillStr,";")
        for j = 1, #strArr do
            data.skills[j] = tonumber(strArr[j])
        end

        skillStr = stream:ReadUTF8String()
        strArr = string.split(skillStr,";")
        for j = 1, #strArr do
            data.recommend_skill[j] = tonumber(strArr[j])
        end
        data.desc = stream:ReadUTF8String()
        data.defaultFace = stream:ReadUInt()
        data.itemId = stream:ReadUInt()
        data.fenjieNum = stream:ReadUInt()
        data.attackType = stream:ReadUInt()
        data.baseAttrs[AppDef.EAttrType.EAT_ATTACK] = stream:ReadUInt()
        data.baseAttrs[AppDef.EAttrType.EAT_DEFENSE] = stream:ReadUInt()
        data.baseAttrs[AppDef.EAttrType.EAT_MAGICD_EFENSE] = stream:ReadUInt()
        data.baseAttrs[AppDef.EAttrType.EAT_HP] = stream:ReadUInt()    
        data.baseAttrs[AppDef.EAttrType.EAT_SPEED] = stream:ReadUInt()
        data.baseAttrs[AppDef.EAttrType.EAT_HIT] = stream:ReadUInt()
        data.baseAttrs[AppDef.EAttrType.EAT_DODGE] = stream:ReadUInt()
        data.baseAttrs[AppDef.EAttrType.EAT_CRIT] = stream:ReadUInt()
        data.baseAttrs[AppDef.EAttrType.EAT_RESISIT_CRIT] = stream:ReadUInt()

        data.growAttrs[AppDef.EAttrGrowType.EAT_ATTACK_CHENGZHANG] = stream:ReadUInt()
        data.growAttrs[AppDef.EAttrGrowType.EAT_DEFENSE_CHENGZHANG] = stream:ReadUInt()
        data.growAttrs[AppDef.EAttrGrowType.EAT_MD_CHENGZHANG] = stream:ReadUInt()
        data.growAttrs[AppDef.EAttrGrowType.EAT_HP_CHENGZHANG] = stream:ReadUInt()
        data.growAttrs[AppDef.EAttrGrowType.EAT_SPEED_CHENGZHANG] = stream:ReadUInt()
        data.growAttrs[AppDef.EAttrGrowType.EAT_HIT_CHENGZHANG] = stream:ReadUInt()
        data.growAttrs[AppDef.EAttrGrowType.EAT_DODGE_CHENGZHANG] = stream:ReadUInt()
        data.growAttrs[AppDef.EAttrGrowType.EAT_CRIT_CHENGZHANG] = stream:ReadUInt()
        data.growAttrs[AppDef.EAttrGrowType.EAT_RCRIT_CHENGZHANG] = stream:ReadUInt()
        for j = 1,4 do
            stream:ReadUInt()
        end
        data.baseAttrs[AppDef.EAttrType.EAT_CRIT_DAMAGE] = stream:ReadUInt()/100
        data.baseAttrs[AppDef.EAttrType.EAT_DAMAGE_RATE] = stream:ReadUInt()/100
        data.baseAttrs[AppDef.EAttrType.EAT_WM_RATE] = stream:ReadUInt()/100
        data.baseAttrs[AppDef.EAttrType.EAT_FM_RATE] = stream:ReadUInt()/100
        data.baseAttrs[AppDef.EAttrType.EAT_DOUBLE_RATE] = stream:ReadUInt()/100
        data.baseAttrs[AppDef.EAttrType.EAT_RDOUBLE_RATE] = stream:ReadUInt()/100
        data.baseAttrs[AppDef.EAttrType.EAT_DOUBLE_DAMAGE] = stream:ReadUInt()/100
        data.baseAttrs[AppDef.EAttrType.EAT_COUNTER_RATE] = stream:ReadUInt()/100
        data.baseAttrs[AppDef.EAttrType.EAT_RCOUNTER_RATE] = stream:ReadUInt()/100
        data.baseAttrs[AppDef.EAttrType.EAT_COUNTER_DAMAGE] = stream:ReadUInt()/100
        data.baseAttrs[AppDef.EAttrType.EAT_SHOCK_RATE] = stream:ReadUInt()/100
        data.baseAttrs[AppDef.EAttrType.EAT_RSHOCK_RATE] = stream:ReadUInt()/100
        data.baseAttrs[AppDef.EAttrType.EAT_SHOCK_DAMAGE] = stream:ReadUInt()/100
        data.baseAttrs[AppDef.EAttrType.EAT_FUMIANQIANGHUA] = stream:ReadUInt()/100
        data.baseAttrs[AppDef.EAttrType.EAT_FUMIANDIKANG] = stream:ReadUInt()/100
        data.cv = stream:ReadUTF8String()
        data.tag = stream:ReadUInt()
        local bgmStr = stream:ReadUTF8String()
        strArr = string.split(bgmStr,";")
        data.skillBgms = {}
        for i = 1, #strArr do
            data.skillBgms[i] = {}
            if string.len(strArr[i]) > 0 then
                local arr2 = string.split(strArr[i],"|")
                for j = 1, #arr2 do
                    table.insert(data.skillBgms[i],arr2[j])
                end
            end
        end
        local suitStr = stream:ReadUTF8String()
        data.tuijianSuit = {}
        local suitList = string.split(suitStr,";")
        for i=1,#suitList do
            table.insert(data.tuijianSuit,tonumber(suitList[i]))
        end

        table.insert(self.m_VecPetList,data)
        self.m_MapPetList[data.id] = data

        if self.m_VecLvPets[data.petType] == nil then
            self.m_VecLvPets[data.petType] = {}
        end

        if self.m_VecLvPets[data.petType][data.tag] == nil then
            self.m_VecLvPets[data.petType][data.tag] = {}
        end

        if self.m_VecLvPets[data.petType][data.tag].value == nil then
            self.m_VecLvPets[data.petType][data.tag].value = {}
            self.m_VecLvPets[data.petType][data.tag].tag = data.tag
        end

        table.insert(self.m_VecLvPets[data.petType][data.tag].value,data.id) 
    end
end

--神将推荐阵容:配置
function LDataConstMgr:LoadPetFormationConfig()
    if next(self.m_VecPetRecommondInfo) ~= nil then
        return
    end
    local stream = StreamBase:CreateReadStreamFromFile("ConfigData/pet_recommend_config.dat")
    if stream == nil then
        return
    end

    local num = stream:ReadUInt()
    for i = 1, num do
        local profession = stream:ReadUInt()
        if self.m_VecPetRecommondInfo[profession] == nil then
            self.m_VecPetRecommondInfo[profession] = LPetRecommendInfo:New()
        end
        local data = self.m_VecPetRecommondInfo[profession]
        data.profession = profession
        local info = {["level"] = 0, ["name"] = "", ["formation"] = 0, ["pets"] = "",["desc"] = ""} 
        info.level = stream:ReadUInt()
        info.name = stream:ReadUTF8String()
        info.formation = stream:ReadUInt()
        info.pets = stream:ReadUTF8String()
        info.desc = stream:ReadUTF8String()
        if data.vecFormation[info.level] == nil then
            data.vecFormation[info.level] = {}
            table.insert(data.levels,info.level)
        end
        table.insert(data.vecFormation[info.level],info)
    end
end

function LDataConstMgr:GetPetFormationConfig(profession,level)
    if self.m_VecPetRecommondInfo == nil then
        self.m_VecPetRecommondInfo = {}
        self:LoadPetFormationConfig()
    end
    local info = self.m_VecPetRecommondInfo[profession]
    if info == nil then return nil end
    local size = #info.levels
    for i=1,size do
       if i+1 > size then
          return info.vecFormation[info.levels[i]]
       end
       if level >= info.levels[i] and level < info.levels[i+1] then
          return info.vecFormation[info.levels[i]]
       end
    end
      
    return nil
end


function LDataConstMgr:TransPetQualityName(quality)
    local NAME_MAP = {
        "", GUITips.RSI_WELFARE_MSG31, GUITips.RSI_WELFARE_MSG32, 
        GUITips.RSI_WELFARE_MSG33, GUITips.RSI_WELFARE_MSG34, GUITips.RSI_WELFARE_MSG35,
        GUITips.RSI_WELFARE_MSG36, GUITips.RSI_WELFARE_MSG37, GUITips.RSI_WELFARE_MSG40
        }
    if quality >= 1 and quality <= 8 then
        return NAME_MAP[quality+1]
    else
        return NAME_MAP[1]
    end
end

function LDataConstMgr:GetColorNameByIndex(idx)
	local NAME_MAP = 
	{
		GUITips.RSI_FOLLOWER_CL_WHITE, GUITips.RSI_FOLLOWER_CL_GREEN, GUITips.RSI_FOLLOWER_CL_BLUE, 
		GUITips.RSI_FOLLOWER_CL_PURPLE, GUITips.RSI_FOLLOWER_CL_ORANGE,GUITips.RSI_FOLLOWER_CL_GOLDEN, GUITips.RSI_FOLLOWER_CL_PINK, 
		GUITips.RSI_FOLLOWER_CL_RED
	}
	if idx < 1 or idx > #NAME_MAP then
		return NAME_MAP[1]
	else
		return NAME_MAP[idx]
	end
end

--获取宠物基础信息
function LDataConstMgr:GetPetData(pid)
    return JsonConfig.m_heroCfg.getDefByID(pid)
end

--神将装备信息
function LDataConstMgr:LoadPetEquipData()
    if self.m_petEquipList ~= nil then
        return
    end
    local stream = StreamBase:CreateReadStreamFromFile("ConfigData/pet_equip.dat")
    if stream == nil then
        return
    end
    self.m_petEquipList = {}
    local num = stream:ReadUInt()
    for i = 1, num do
        local data = LPetEquipCfgInfo:New()
        data.id = stream:ReadUInt()
        data.name = stream:ReadUTF8String()
        data.pos = stream:ReadUInt()
        data.suitType = stream:ReadUInt()
        data.quality = stream:ReadUInt()
        data.pic = stream:ReadUTF8String()
        data.sortId = stream:ReadUInt()
        data.desc = stream:ReadUTF8String()
        data.unKnowDesc = stream:ReadUTF8String()
        local source = stream:ReadUTF8String()
        data.from = {}
        if #source > 0 then   
            local list = string.split(source,";")       
            for i=1,#list do
                table.insert(data.from,tonumber(list[i]))
            end
        end
        stream:ReadUTF8String()    
        self.m_petEquipList[data.id] = data
    end
end

--获取宠物装备信息
function LDataConstMgr:GetPetEquipCfgData(id)
    if self.m_petEquipList == nil then
        self:LoadPetEquipData()
    end
    return self.m_petEquipList[id]
end

--神将套装信息
function LDataConstMgr:LoadPetSuitData()
    if self.m_petSuitList ~= nil then
        return
    end
    local stream = StreamBase:CreateReadStreamFromFile("ConfigData/suit.dat")
    if stream == nil then
        return
    end
    self.m_petSuitList = {}
    local num = stream:ReadUInt()
    for i = 1, num do
        local data = {}
        data.id = stream:ReadUInt()
        data.name = stream:ReadUTF8String()
        local suitSrc = stream:ReadUTF8String()
        local temp = string.split(suitSrc,"|")
        data.skillId = {}
        data.skillLv = {}
        data.suitNum = {}
        for i=1,#temp do
            local infos = string.split(temp[i],"-")
            if #infos == 3 then
               data.suitNum[i] = tonumber(infos[1])   --套装件数
               data.skillId[i] = tonumber(infos[2])
               data.skillLv[i] = tonumber(infos[3])
            end
        end
        data.maxAttrNum = #temp
        self.m_petSuitList[data.id] = data
    end
    AppDef.Pet.MaxSuitTypeNum = num
end

--获取神将套装信息
function LDataConstMgr:GetPetSuitCfgData(id)
    if self.m_petSuitList == nil then
        self:LoadPetSuitData()
    end
    return self.m_petSuitList[id]
end

--神将装备强化信息
function LDataConstMgr:LoadPetEquipQHData()
    if self.m_petEquipQhList ~= nil then
        return
    end
    local stream = StreamBase:CreateReadStreamFromFile("ConfigData/pet_equip_qianghua.dat")
    if stream == nil then
        return
    end
    self.m_petEquipQhList = {}
    local num = stream:ReadUInt()
    for i = 1, num do
        local data = {}
        data.id = stream:ReadUInt()
        local costStr = stream:ReadUTF8String()
		local costlist =  string.split(costStr,";")
		if #costlist > 1 then
			local temp = string.split(costlist[1],"-")
			if #temp > 1 then
				data.costMoneyType = tonumber(temp[1])
				data.costMoneyVal = tonumber(temp[2])
			end
			local temp2 = string.split(costlist[2],"-")
			if #temp2 > 1 then
				data.costStarType = tonumber(temp2[1])
				data.costStarVal = tonumber(temp2[2])
			end
		end
        data.fenJieRatio = stream:ReadUInt()--分解返还万分比
        data.upRatio = stream:ReadUInt()--提示基础属性万分比
        local str = stream:ReadUTF8String()
        if #str> 0 then
            if self.m_petEquipQHSigns == nil then
                self.m_petEquipQHSigns = {}
            end
            table.insert(self.m_petEquipQHSigns,data.id)
        end
        self.m_petEquipQhList[data.id] = data
    end
end

--获取神将装备强化信息
function LDataConstMgr:GetPetEquipQHCfgData(id)
    if self.m_petEquipQhList == nil then
        self:LoadPetEquipQHData()
    end
    return self.m_petEquipQhList[id]
end

--获取神将装备强化描述参数
function LDataConstMgr:GetPetEquipQHStrParam(id)
    if self.m_petEquipQHSigns == nil then
        return 0
    end
    local param = 0
    for i=1,#self.m_petEquipQHSigns do
        if self.m_petEquipQHSigns[i] > id then
            param = self.m_petEquipQHSigns[i]
            break
        end
    end
    return param
end

--神将装备星级信息
function LDataConstMgr:LoadPetEquipStarData()
    if self.m_petEquipStarList ~= nil then
        return
    end
    local stream = StreamBase:CreateReadStreamFromFile("ConfigData/equip_star.dat")
    if stream == nil then
        return
    end
    self.m_petEquipStarList = {}
    local num = stream:ReadUInt()
    for i = 1, num do
        local data = {}
        data.star = stream:ReadUInt()
        data.quality = stream:ReadUInt()
        data.maxStoneLv = stream:ReadUInt()
        data.costRatio = stream:ReadUInt() --强化消耗万分比
        stream:ReadUTF8String()
        local reCycleStr = stream:ReadUTF8String()--分解价格
		
        local temp = string.split(reCycleStr,";")
        if #temp > 1 then
			local value = string.split(temp[1],"-")
			data.reCycleXinxiuType = tonumber(value[1])
            data.reCycleXinxiuVal = tonumber(value[2])
			value = string.split(temp[2],"-")
			data.reCycleMoneyType = tonumber(value[1])
            data.reCycleMoneyVal = tonumber(value[2])
        end
        self.m_petEquipStarList[data.star] = data
    end
end

--获取神将装备星级信息
function LDataConstMgr:GetPetEquipStarCfgData(star)
    if self.m_petEquipStarList == nil then
        self:LoadPetEquipStarData()
    end
    return self.m_petEquipStarList[star]
end

-- function LDataConstMgr:LoadMapData()
--     if #self.m_VecMapData > 0 then
--         return
--     end
--     local stream = StreamBase:CreateReadStreamFromFile("ConfigData/map_scene.dat")
--     if stream == nil then
--         return
--     end

--     local mapCount = stream:ReadByte()
--     for i = 1, mapCount do
--         local map = LMapInfo:New()--MapInfo
--         map.id = stream:ReadWord()
--         map.pid = stream:ReadWord()
--         map.name = stream:ReadString()
--         local gateCount = stream:ReadByte()
--         map.GateVec = {}
--         if gateCount > 0 then
--             for j = 1, gateCount do
--                 local Data = LMapGateData:New()
--                 Data.pos.x = stream:ReadWord()
--                 Data.pos.y = stream:ReadWord()
--                 Data.id = stream:ReadWord()
--                 table.insert(map.GateVec,Data)
--             end
--         end
--         table.insert(self.m_VecMapData, map)
--     end
-- end

-- --根据场景ID获取地图资源ID
-- function LDataConstMgr:GetMapPicIdBySid(sceneId)
--     --------print("GetMapPicIdBySid",sceneId)
--     for i = 1, #self.m_VecMapData do
--         --------print("self.m_VecMapData[i].id=",self.m_VecMapData[i].id)
--         if self.m_VecMapData[i].id == sceneId then
--             return self.m_VecMapData[i].pid
--         end
--     end
--     return -1
-- end

--称号相关
function LDataConstMgr:InitMedalInfo()

    if self.m_medalTotalNum > 0 then
        return;
    end

    local l_stream = StreamBase:CreateReadStreamFromFile("ConfigData/title_config.dat")
    if l_stream == nil then
        return
    end
    local num = l_stream:ReadUInt()
    --------print("********************************* num = ", num)
    for i = 1,num do
        local data = LMedalAttributeInfo:New()
        data.id = l_stream:ReadUInt()
        data.name = l_stream:ReadUTF8String()
        data.desc = l_stream:ReadUTF8String()
        data.attr = l_stream:ReadUTF8String();
        data.isShow = l_stream:ReadUInt()
        local strArrs = string.split(data.attr, ";")

        local arrInfo = {}
        for j = 1, #strArrs do
          strArrs2 = string.split(strArrs[j],"-")
          local oneInfo = {}
          oneInfo.type = tonumber(strArrs2[1])
          oneInfo.value = tonumber(strArrs2[2])
          table.insert(arrInfo, oneInfo)
        end

        data.newAttribute = arrInfo
        table.insert(self.m_medalTable, data)
        self.m_medalTotalNum = self.m_medalTotalNum + 1
    end

end

function LDataConstMgr:GetMedalNote(id)
    ----print("LDataConstMgr:GetMedalNote id", id)
    -- if id <= 0 or id > self.m_medalTotalNum then
    --     id = 1
    -- end

     for i = 1, #self.m_medalTable do
        if self.m_medalTable[i].id == id then
            return self.m_medalTable[i]
        end
     end

    return nil;
end

function LDataConstMgr:GetMedalAttrValue(id, type)
  -- body
  local data = self:GetMedalNote(id)
  for i = 1, #data.newAttribute do
    if data.newAttribute[i].type == type then
      return data.newAttribute[i].value
    end
  end
  return 0;
end

function LDataConstMgr:GetMedalColorIdx(medalId)

    if(medalId <= 11 or medalId == 27 or medalId == 30 or medalId == 33 or medalId == 36 or medalId == 39 or medalId == 42 or medalId == 45 or medalId == 49 or medalId == 50 or medalId == 51 or medalId == 52) then
        return 4;
    elseif(medalId <= 20 or medalId == 28 or medalId == 31 or medalId == 34 or medalId == 37 or medalId == 40 or medalId == 43 or medalId == 46 or medalId == 48) then
        return 2;
    elseif(medalId < 24 or medalId == 29 or medalId == 32 or medalId == 35 or medalId == 38 or medalId == 41 or medalId == 44 or medalId == 47) then
        return 1;
    else
        return 0;
    end
end

function LDataConstMgr:InitPetSkillBook()
    local ary = {
        --原有技能
        {540,17}, {541,18}, {542,19}, {543,20}, {544,21}, {545,57}, {546,0}, {547,0}, {548,60}, {549,61}, {550,62}, {551,104},
        {552,105},{553,157},{554,158},{555,159},{556,161},{557,162},{558,163},{559,164},{560,165},{561,166},
        {562,167},{563,168},{564,170},{565,171},{566,172},{567,173},{568,174},{569,175},{570,176},{571,32},
        {572,33}, {573,10}, {574,11}, {575,12}, {576,13}, {577,14}, {578,15}, {579,16}, {585,22}, {586,23},
        {587,24}, {588,25}, {589,26}, {590,27}, {591,28}, {592,29}, {593,30}, {594,31}, {595,63}, {596,64},
        {597,236},{598,237},{599,238},
        --新增技能
        {900,177}, {901,178}, {902,179}, {903,180}, {904,181}, {905,182}, {906,183}, {907,184}, {908,185}, {909,186},
        {910,187}, {911,188}, {912,189}, {913,190}, {914,191}, {915,192}, {916,193}, {917,194}, {918,195}, {919,196},
        {920,197}, {921,198}, {922,199}, {923,200}, {924,201}, {925,202}, {926,203}, {927,204}, {928,205}, {929,206},
        {930,207}, {931,208}, {932,209}, {933,210}, {934,211}, {935,212}, {936,213}, {937,214}, {938,215}, {939,216},
        {940,217}, {941,218}, {942,219}, {943,220}, {944,221}, {945,222}, {946,223}, {947,224}, {948,225}, {949,226},
        {950,227}, {951,228}, {952,229}, {953,230}, {954,231}, {955,232}, {956,233}, {957,234}
    }
    self.m_VecPetBookSkill = arr
end

--宠物技能书与技能对应数据[type: 1-bookId 2-skillId]
function LDataConstMgr:GetPetSkillBookOpt(idx, type)
 -- { return VectorSafeVal(_VecPetBookSkill, idx, type, 0); } 
    return self.m_VecPetBookSkill[idx][idxSub]
end

function LDataConstMgr:GetPetSkillBookSize()
    return #self.m_VecPetBookSkill
end

function LDataConstMgr:GetPetSkillIdByBookId(bookid)
    local skillId = 0
    for k=1, self:GetPetSkillBookSize() do
        if(self:GetPetSkillBookOpt(k, 1) == bookid) then
            skillId = self:GetPetSkillBookOpt(k, 2)
            break
        end
    end
    return skillId
end

--获取宠物装甲升级经验(x品质y星级)
function LDataConstMgr:GetPetArmorAdvStone(x, y)
    local cfg = self.m_VecPetArmorAdvStone[x+1][y+1]
    return (cfg and {cfg} or {0})[1]
end

--获取宠物升级所需经验丹数量
function LDataConstMgr:GetPetLevelUpPill(lv)
    return self:VectorSafeVal(self.m_VecPetLevelUpPill, lv, 1)
end

--获取宠物分解经验(x资质)
function LDataConstMgr:GetPetSplitExp(x) 
    return self:VectorSafeVal(self.m_VecPetSplitExp, x, 1)
end

--加载抽宠配置
function LDataConstMgr:LoadPetDrawBasicData()
    if #self.m_petDrawBasic > 0 then
        return
    end
    local stream = StreamBase:CreateReadStreamFromFile("ConfigData/pet_draw_basic.dat")
    if stream == nil then
        return
    end

    local num = stream:ReadUInt()
    for i=1,num do
        local it = {}
        it.kind = stream:ReadUInt()
        it.name = stream:ReadUTF8String()
        it.openLevel = stream:ReadUInt()
        it.type = stream:ReadUInt()
        it.needItemId = stream:ReadUInt()
        it.needItemNum = stream:ReadUInt()
        it.needYuanBao = stream:ReadUInt()
        local _ = stream:ReadUInt()
        local _ = stream:ReadUInt()
        local _ = stream:ReadUInt()
        table.insert(self.m_petDrawBasic, it)
        if i == 2 then--TODO：补丁，只显示一个炉子
            break
        end
    end

end

function LDataConstMgr:getPetDrawConfig(kind, type)
    for i=1,#self.m_petDrawBasic do
        if self.m_petDrawBasic[i].kind == kind and self.m_petDrawBasic[i].type == type then
            return self.m_petDrawBasic[i]
        end
    end
    return nil
end

--加载抽宠获奖信息
function LDataConstMgr:LoadPetDrawConfigData()
    if #self.m_petDrawConfig > 0 then
        return
    end
    local stream = StreamBase:CreateReadStreamFromFile("ConfigData/pet_draw_config.dat")
    if stream == nil then
        return
    end

    local num = stream:ReadUInt()
    for i=1,num do
        local it = {}
        local kind = stream:ReadUInt()
        if self.m_petDrawConfig[kind] == nil then
            self.m_petDrawConfig[kind] = {}
        end
        it.type = stream:ReadUInt()
        if self.m_petDrawConfig[kind][it.type] == nil then
          self.m_petDrawConfig[kind][it.type] = {}
        end
        
        local str = stream:ReadUTF8String()
        local arr = string.split(str, '-')
        if #arr >= 2 then
            local _type = tonumber(arr[1])
            if _type == 60002 then
                it.id = tonumber(arr[2])
                it.star = tonumber(arr[3])
                it.level = tonumber(arr[4])
            else
                it.itemID = _type
                it.itemNum = tonumber(arr[2])
            end
        end
        local _ = stream:ReadUInt()
        table.insert(self.m_petDrawConfig[kind][it.type], it)
    end
end

function LDataConstMgr:getPetDrawDetailConfig(kind, otype)
    otype = otype or 1
    if self.m_petDrawConfig == nil then
        return nil
    end
    return self.m_petDrawConfig[kind][otype]
end

function LDataConstMgr:AttrSummation(attrs, addAttrs)
	for _,av in pairs(addAttrs) do
		local add = true
        for _,v in pairs(attrs) do
            if v[1] == av[1] then
                v[2] = v[2] + av[2]
                add = false
                break
            end
        end
        if add then
        	local addV = {}
        	addV[1] = av[1]
        	addV[2] = av[2]
        	table.insert(attrs, addV)
        end
    end
end

local function splitCondition(str, key)
  local ret = {}
  local arr = string.split(str, key or ',')
  for i=1,#arr do
    local subStr = arr[i]
    local subArr = string.split(subStr, '-')
    if #subArr == 2 then
      table.insert(ret, {cType=tonumber(subArr[1]), cValue=tonumber(subArr[2])})
    end
  end
  return ret
end
--加载新功能预告
function LDataConstMgr:LoadNovicePreviewData()
    if #self.m_pNoviceVec > 0 then
        return
    end
    local stream = StreamBase:CreateReadStreamFromFile("ConfigData/NovicePreview.dat")
    if stream == nil then
        return
    end

    local num = stream:ReadUInt()
    for i=1,num do
        local it = {}
        local id = stream:ReadUInt()
        it.id = id
        it.functionId = stream:ReadUInt()
        it.open_condition = splitCondition(stream:ReadUTF8String(), ';')
        it.condition = splitCondition(stream:ReadUTF8String(), ';')
        it.isAnd = Utils:ToBool(stream:ReadUInt())
        local iconStr = stream:ReadUTF8String()
        local arr = string.split(iconStr, '-')
        it.icon = {}
        for j=1,#arr do
            if #arr[j] > 10 then
                table.insert(it.icon, arr[j])
            else
                table.insert(it.icon, tonumber(arr[j]))
            end
        end
        it.name = stream:ReadUTF8String()
        it.desc = stream:ReadUTF8String()
        it.isOpenTips = Utils:ToBool(stream:ReadUInt())
        it.tips = stream:ReadUTF8String()
        it.sound = stream:ReadUTF8String()
        self.m_pNoviceMap[it.id] = it
        table.insert(self.m_pNoviceVec, it)
    end
end

function LDataConstMgr:GetNovicePreviewData(id)
    if self.m_pNoviceMap == nil then
        return nil
    end
    return self.m_pNoviceMap[id]
end

function LDataConstMgr:GetNovicePreviewConfig()
  return self.m_pNoviceVec
end

--加载功能开启配置
-- function LDataConstMgr:LoadFunctionLevelData()
--     for k,v in pairs(self.m_pFunctionLevelMap) do
--       return
--     end

--     local stream = StreamBase:CreateReadStreamFromFile("ConfigData/Function.dat")
--     -- local stream = StreamBase:CreateReadStreamFromFile("ConfigData/Function_Level.dat")
--     if stream == nil then
--         return
--     end
--     local temp = {}
--     local num = stream:ReadUInt()
--     print("load function num =", num)
--     for i=1,num do
--         local it = {}
--         it.functionId = stream:ReadUInt()
--         -- it.open_condition = splitCondition(stream:ReadUTF8String(), ';')
--         it.name = stream:ReadUTF8String()
--         it.open_condition = json.decode(stream:ReadUTF8String(), 1)
--         -- dump(it.open_condition, "LoadFunctionLevel ====>")
--         it.isDefaultShow = Utils:ToBool(stream:ReadUInt())
--         it.isAnd = Utils:ToBool(stream:ReadUInt())
--         it.isOpenTips = Utils:ToBool(stream:ReadUInt())
--         it.tips = stream:ReadUTF8String()
--         it.noOpenTips = stream:ReadUTF8String()
--         it.sound = stream:ReadUTF8String()
--         it.page = stream:ReadInt()
--         it.icon = stream:ReadUTF8String()
--         it.show = json.decode(stream:ReadUTF8String(), 1)
--         it.des = stream:ReadUTF8String()
--         it.revert = stream:ReadUInt()
--         it.revert_count = stream:ReadUInt()
--         it.revert_reward = json.decode(stream:ReadUTF8String(), 1)

--         self.m_pFunctionLevelMap[it.functionId] = it
--         temp = {}
--         for i=1,#it.open_condition do
--           local cType = it.open_condition[i][1]
--           if self.m_pFLTypeMap[cType] == nil then
--             self.m_pFLTypeMap[cType] = {}
--           end
--           if temp[cType] == nil then
--             table.insert(self.m_pFLTypeMap[cType], it)
--           end
--           temp[cType] = true
--         end
--     end
--     -- dump(self.m_pFunctionLevelMap, "LoadFunctionLevelData ================= 11111111 >")
--     -- dump(self.m_pFLTypeMap)
-- end

function LDataConstMgr:GetFunctionLevelData(functionId)
    return JsonConfig.m_functionConfig.getDefByID(functionId)
end

function LDataConstMgr:isModuleDefaultShow(functionId)
    local cfg = self:GetFunctionLevelData(functionId)
    local ret = false
    if cfg ~= nil then
        ret = Utils:ToBool(cfg.Default_display) or false
    end
    return ret
end

function LDataConstMgr:GetFLDataByCondition(cType)
  if cType == nil then
    return {}
  end
  local ret = JsonConfig.m_mapFunction[cType] or {}
  return ret
end

function LDataConstMgr:GetFuctionCondition(functionId, cType)
  local cfg = self:GetFunctionLevelData(functionId)
  local pCondition = cfg.open_condition
  local cValue = 0
  for i=1,#pCondition do
      if pCondition[i][1] == cType then
          cValue = pCondition[i][2]
          break
      end
  end
  return cValue
end

function LDataConstMgr:GetHeroSkillBgm(pro,skillId)
    for i = 1, #self.m_skills do
        if self.m_skills[i].profession == pro then
            for j = 1, #self.m_skills[i].skillOpenLv do
                if self.m_skills[i].skillOpenLv[j][1] == skillId then
                    return self.m_skills[i].skillOpenLv[j][3]
                end
            end
        end
    end
    return ""
end

--[[
加载人物技能配置文件
]]
function LDataConstMgr:LoadSkillOpenLevel()
    local stream = StreamBase:CreateReadStreamFromFile("ConfigData/role_basic_config.dat")
    if stream == nil then
        return
    end
    --[[
    type  attack_type attrs  skill
    职业  攻击类别    {19}   skillid-openlv;skillid-openlv
    ]]
    --print("LoadSkillOpenLevel")
    self.m_skills = {}
    local num = stream:ReadUInt()
    for i=1,num do
        local skill = {}
        skill.profession = stream:ReadUInt()
        skill.attack_type = stream:ReadUInt()
        for j=1,19 do
            stream:ReadUInt()
        end
        local iconStr = stream:ReadUTF8String()
        local arr = string.split(iconStr, ';')
        skill.skillOpenLv = {}

        -- for k,v in pairs(arr) do
        --     local value = string.split(v, '-')
        --     table.insert(skill.skillOpenLv, {tonumber(value[1]), tonumber(value[2])})
        -- end
        for i = 1, #arr do
            local value = string.split(arr[i], '-')
            table.insert(skill.skillOpenLv, {tonumber(value[1]), tonumber(value[2])})
        end
        local bgmStr = stream:ReadUTF8String()
        local arr = string.split(bgmStr, ';')
        for i = 1, #arr do
            if i > #skill.skillOpenLv then
                skill.skillOpenLv[i][3] = ""
            else
                skill.skillOpenLv[i][3] = arr[i]
            end
        end
        table.insert(self.m_skills, skill)
    end
end

--[[
加载人物技能升级配置文件
]]
function LDataConstMgr:LoadSkillLvUpCost()
    local stream = StreamBase:CreateReadStreamFromFile("ConfigData/role_skill_LvUp.dat")
    if stream == nil then
        return
    end
    --[[
    skill_idx level learn_level cost
    位置      等级   升级要求   消耗
    ]]
    self.m_skillLvUps = {}
    local num = stream:ReadUInt()
    for i=1,num do
        local skill = {}
        skill.pos = stream:ReadUInt()
        skill.level = stream:ReadUInt()
        skill.learn_level = stream:ReadUInt()
        local str = stream:ReadUTF8String()
        local arr = string.split(str, ';')
        skill.cost = {}
        for k,v in pairs(arr) do
            local value = string.split(v, '-')
            table.insert(skill.cost, {tonumber(value[1]), tonumber(value[2])})
        end
        table.insert(self.m_skillLvUps, skill)
    end
end

-- 获取指定位置技能学习消耗
function LDataConstMgr:GetSkillLvUpCost(pos, level)
    for k,v in pairs(self.m_skillLvUps) do
        if v.pos == pos and v.level == level then
            return v
        end
    end
    return nil
end

function LDataConstMgr:GetFunctionLevelMap()
    return JsonConfig.m_functionConfig.getList()
end
--[[
加载引导资源
]]
function LDataConstMgr:LoadGuideData()
  if #self.m_pGuideVec > 0 then
    return
  end
  local stream = StreamBase:CreateReadStreamFromFile("ConfigData/guide_client.dat")
  if stream == nil then
      return
  end
  local num = stream:ReadUInt()
  for i=1,num do
    local it = {}
    it.stepId = stream:ReadUInt()
    it.nextStepId = stream:ReadUInt()
    it.type = stream:ReadUInt()
    it.missionId = stream:ReadUInt()
    it.isOpen = Utils:ToBool(stream:ReadUInt())
    local _ = stream:ReadUInt()
    it.desc = stream:ReadUTF8String()
    it.towards = stream:ReadUInt()
    it.deviant = cc.p(stream:ReadInt(), stream:ReadInt())
    it.fixId = stream:ReadUInt()
    it.sizeTowards = stream:ReadUInt()
    it.maskOffset = cc.p(stream:ReadInt(), stream:ReadInt())
    it.fingerOffset = cc.p(stream:ReadInt(), stream:ReadInt())
    it.breakingMark = stream:ReadUInt()
    it.sound = stream:ReadUTF8String()
    local str = stream:ReadUTF8String()
    if str and #str > 0 then
        local arr = string.split(str, ':')
        if #arr >= 2 then
            it.size = cc.size(tonumber(arr[1]), tonumber(arr[2]))
        end
    end
    local str = stream:ReadUTF8String()
    if str and #str > 0 then
        local arr = string.split(str, ':')
        if #arr >= 4 then
            local x,y = tonumber(arr[1]),tonumber(arr[2])
            local w,h = tonumber(arr[3]),tonumber(arr[4])
            it.maskSize = cc.size(w, h)
            it.pos = cc.p(x+w/2, y+h/2)
        end
    end
    self.m_pGuideMap[it.stepId] = it
    table.insert(self.m_pGuideVec, it)
    if self.m_pGuideTypeMap[it.type] == nil then
      self.m_pGuideTypeMap[it.type] = {}
    end
    table.insert(self.m_pGuideTypeMap[it.type], it)
  end
  -- dump(self.m_pGuideVec)
end
--[[
获取引导数据
]]
function LDataConstMgr:GetGuideData(stepId)
  if stepId == nil then
    return nil
  end
  return self.m_pGuideMap[stepId]
end
--[[
获取引导列表
]]
function LDataConstMgr:GetGuideList()
  return self.m_pGuideVec
end
--[[
获取下一步引导数据
]]
function LDataConstMgr:GetNextGuideData(stepId)
  if stepId == nil then
    return nil
  end
  local info = self.m_pGuideMap[stepId]
  if info == nil then
    return nil
  end
  return self:GetGuideData(info.nextStepId)
end
--[[
根据类型获取引导列表
]]
function LDataConstMgr:GetGuideListByType(typeId)
  if typeId == nil then
    return nil
  end
  return self.m_pGuideTypeMap[typeId]
end

function LDataConstMgr:LoadDieWarningData()
  if #self.m_dieWarning > 0 then
    return
  end
  local stream = StreamBase:CreateReadStreamFromFile("ConfigData/die_warning.dat")
  if stream == nil then
      return
  end
  local num = stream:ReadUInt()
  for i=1,num do
    local it = {}
    it.id = stream:ReadUInt()
    it.minLv = stream:ReadUInt()
    it.maxLv = stream:ReadUInt()
    it.functionId = {}
    local str = stream:ReadUTF8String()
    local arr = string.split(str, ';')
    for j=1,#arr do
      if #(arr[j]) > 0 then
        table.insert(it.functionId, tonumber(arr[j]))
      end
    end
    table.insert(self.m_dieWarning, it)
  end
end

function LDataConstMgr:getDieWarningData(level)
  if level == nil or type(level) ~= "number" then
    return nil
  end
  local isMaxLevel = false
  for i=1,#self.m_dieWarning do
    local it = self.m_dieWarning[i]
    if it.minLv <= level and level <= it.maxLv then
      return it.functionId
    end
    if level > it.maxLv then
      isMaxLevel = true
    end
  end
  if isMaxLevel and (#self.m_dieWarning) > 0 then
    return self.m_dieWarning[#self.m_dieWarning].functionId
  end
  return nil
end

function LDataConstMgr:initCangbaotuData()
    -- body
    self.m_cangbaotuInfo = {{1, "灵雾村", {{2466, 687}, {1926, 917}, {912, 1347}}},
                        {2, "黄河滩", {{966, 1169}, {1476, 1093}, {1822, 893}}},
                        {3, "东夷", {{838, 750}, {819, 1236}, {1808, 1340}}},
                        {4, "女娲庙", {{337, 637}, { 1763, 402}, { 2300, 1273}}},
                        {5, "西岐城", {{1726, 972}, { 1483, 950}, {913, 267}}},
                        {6, "陈塘关", {{1520, 547}, {1351, 884}, {783, 1281}}},
                        {11, "朝歌城", {{2938, 722}, {2580, 981}, {1294, 1580}}},
    }
end

function LDataConstMgr:getCangBaoTuPosData(data)
    -- body
    if data <= 0 then
        return 0, 0, 0, ""
    end

    local mapId = math.floor(data / 100)

    if mapId > #self.m_cangbaotuInfo then
        Utils:ShowScrollTips(GUITips.RSI_TIPS_TREASUERMAPTIPS)
        return 
    end

    local index = data % 100
    local dataCell = self.m_cangbaotuInfo[mapId][3]
    local realmapID = self.m_cangbaotuInfo[mapId][1]
    local name = self.m_cangbaotuInfo[mapId][2]
    return realmapID, dataCell[index][1], dataCell[index][2], name
end
--加载七日登录奖励
function LDataConstMgr:LoadLoginRewardData()
    if #self.m_LoginRewardData > 0 then
        return
    end
    local stream = StreamBase:CreateReadStreamFromFile("ConfigData/LoginReward.dat")
    if stream == nil then
        return
    end

    local num = stream:ReadUInt()
    for i=1,num do
        local it = {}
        it.id = stream:ReadUInt()
        it.itemId = stream:ReadUInt()
        it.name = stream:ReadUTF8String()
        it.isAnim = Utils:ToBool(stream:ReadUInt())
        local typeStr = stream:ReadUTF8String()
        local arr = string.split(typeStr, '-')
        it.type = {}
        for j=1,#arr do
            if #arr[j] > 10 then
                table.insert(it.type, arr[j])
            else
                table.insert(it.type, tonumber(arr[j]))
            end
        end
        it.path = stream:ReadUTF8String()
        table.insert(self.m_LoginRewardData, it)
    end
end

function LDataConstMgr:GetLoginRewardData()
    return self.m_LoginRewardData
end

function LDataConstMgr:GetLoginRewardDataByIndex(ind)
    return self.m_LoginRewardData[ind]
end

--加载VIP配置
function LDataConstMgr:LoadVIPConfigData()
    if self.m_vipConfigData and #self.m_vipConfigData > 0 then
        return
    end
    if self.m_vipConfigData == nil then
        self.m_vipConfigData = {}
    end
    local stream = StreamBase:CreateReadStreamFromFile("ConfigData/guizu_config.dat")
    if stream == nil then
        return
    end

    local num = stream:ReadUInt()
    for i=1,num do
        local it = {}
        it.id = stream:ReadUInt()
        it.name = stream:ReadUTF8String()
        it.isAnim = Utils:ToBool(stream:ReadUInt())
        local typeStr = stream:ReadUTF8String()
        local arr = string.split(typeStr, '-')
        it.type = {}
        for j=1,#arr do
            if #arr[j] > 10 then
                table.insert(it.type, arr[j])
            else
                table.insert(it.type, tonumber(arr[j]))
            end
        end
        it.path = stream:ReadUTF8String()
        it.tips = stream:ReadUTF8String()
        it.tqIcons = {}--特权ICON
        for i=1,9 do
            table.insert(it.tqIcons, stream:ReadUTF8String())
        end
        table.insert(self.m_vipConfigData, it)
    end
end

function LDataConstMgr:GetVIPConfigData()
    return self.m_vipConfigData
end

function LDataConstMgr:GetVIPConfigDataByIndex(ind)
    return self.m_vipConfigData[ind]
end

--加载宠物升星配置数据
function LDataConstMgr:LoadPetStarConfig()
    if self.m_petStarList and #self.m_petStarList > 0 then
        return
    end
    if self.m_petStarList == nil then
        self.m_petStarList = {}
    end
    local stream = StreamBase:CreateReadStreamFromFile("ConfigData/pet_star.dat")
    if stream == nil then
        return
    end

    local num = stream:ReadUInt()
    for i=1,num do
        local it = {}
        it.star = stream:ReadUInt()
        it.starRatio = stream:ReadUInt()/10000
        it.stepAttr = stream:ReadUInt()
        it.totalCost = stream:ReadUInt()
        it.levelLimit = stream:ReadUInt()
        table.insert(self.m_petStarList, it)
    end
end

function LDataConstMgr:GetPetStarLevelLimit(star)
    if star == nil then
        return 999
    end
    if self.m_petStarList == nil then
        self:LoadPetStarConfig()
    end
    local cfg = self.m_petStarList[star]
    if cfg == nil or cfg.levelLimit == nil then
        return 999
    end
    return cfg.levelLimit
end

--加载宠物升星品质配置数据
function LDataConstMgr:LoadPetQualityConfig()
    if self.m_petQualityList and #self.m_petQualityList > 0 then
        return
    end
    if self.m_petQualityList == nil then
        self.m_petQualityList = {}
    end
    local stream = StreamBase:CreateReadStreamFromFile("ConfigData/pet_quality.dat")
    if stream == nil then
        return
    end

    local num = stream:ReadUInt()
    for i=1,num do
        local it = {}
        it.quality = stream:ReadUInt()
        it.totalCostRadio = stream:ReadUInt()/10000
        table.insert(self.m_petQualityList, it)
    end
end
--加载宠物升星节点配置数据
function LDataConstMgr:LoadPetStarStepConfig()
    if self.m_petStarStepList and #self.m_petStarStepList > 0 then
        return
    end
    if self.m_petStarStepList == nil then
        self.m_petStarStepList = {}
    end
    local stream = StreamBase:CreateReadStreamFromFile("ConfigData/pet_star_step.dat")
    if stream == nil then
        return
    end

    local num = stream:ReadUInt()
    for i=1,num do
        local it = {}
        it.step = stream:ReadUInt()
        it.attr = stream:ReadUInt()
        it.attrRadio = stream:ReadUInt()/10000
        it.costRadio = stream:ReadUInt()/10000
        self.m_petStarStepList[it.step] = it
    end
end
--[[
获取神将升星属性加成
--id：神将ID
--star：神将星级
--subStar：星级节点级别(一共10个节点)
]]
function LDataConstMgr:GetPetAddAttr(id, star, subStar)
    if id == nil or star == nil or subStar == nil then
        return nil,nil
    end
    local basePetData = LDataConstMgr:GetPetData(id)
    if basePetData == nil then
        return nil,nil
    end

    if self.m_petStarList == nil then
        self:LoadPetStarConfig()
    end

    if self.m_petStarStepList == nil then
        self:LoadPetStarStepConfig()
    end

    local starStepConfig = self.m_petStarStepList[subStar]
    if starStepConfig == nil then
        return nil,nil
    end

    local starConfig = self.m_petStarList[star]
    if starConfig == nil then
        return nil,nil
    end

    local attrType = starStepConfig.attr
    local growAttr = basePetData.growAttrs[attrType]
    local stepAttr = starConfig.stepAttr
    local stepRatio = starStepConfig.attrRadio
    return attrType, math.floor(growAttr*stepAttr*stepRatio)
end
--[[
获取神将属性
--id：神将ID
--star：神将星级
--subStar：星级节点级别(一共10个节点)
]]
function LDataConstMgr:GetPetAttr(id, star, subStar, level)
    if id == nil or star == nil or subStar == nil or level == nil then
        return {}
    end
    local basePetData = LDataConstMgr:GetPetData(id)
    if basePetData == nil then
        return {}
    end

    if self.m_petStarList == nil then
        self:LoadPetStarConfig()
    end

    if self.m_petStarStepList == nil then
        self:LoadPetStarStepConfig()
    end

    local starConfig = self.m_petStarList[star]
    if starConfig == nil then
        return {}
    end

    local attrTypes = {}
    local attrValues = {}
    local temp = {
        AppDef.EAttrType.EAT_ATTACK, 
        AppDef.EAttrType.EAT_DEFENSE, 
        AppDef.EAttrType.EAT_MAGICD_EFENSE, 
        AppDef.EAttrType.EAT_HP,
    }
    for i=1,#temp do
        local attrType = temp[i]
        table.insert(attrTypes, attrType)
        local growAttr = basePetData.growAttrs[attrType]
        local addAttr = growAttr * level * starConfig.starRatio
        -- dump({addAttr, growAttr, level, starConfig.starRatio}, "addAttr--->")
        local addSubAttrSum = 0
        for j=1,star-1 do
            for k=1,AppDef.Pet.MaxSubStar do
                local addSubAttrType,addSubAttrValue = LDataConstMgr:GetPetAddAttr(id, j, k)
                -- dump({addSubAttrType,addSubAttrValue}, "addSubAttrValue---->")
                if addSubAttrType and addSubAttrType == attrType and addSubAttrValue then
                    addSubAttrSum = addSubAttrSum + addSubAttrValue
                end
            end
        end
        -- dump(addSubAttrSum, "addSubAttrSum--->")
        table.insert(attrValues, math.floor(addAttr + addSubAttrSum))
    end
    temp = {
        AppDef.EAttrType.EAT_SPEED,
        AppDef.EAttrType.EAT_HIT,
        AppDef.EAttrType.EAT_DODGE,
        AppDef.EAttrType.EAT_CRIT,
        AppDef.EAttrType.EAT_RESISIT_CRIT,
    }
    for i=1,#temp do
        local attrType = temp[i]
        table.insert(attrTypes, attrType)
        local growAttr = basePetData.growAttrs[attrType]
        table.insert(attrValues, math.floor(growAttr * level))
    end
    -- dump({attrTypes, attrValues}, "------------->")
    return attrTypes, attrValues
end
--[[
获取神将升星需要消耗的神魂
--id：神将ID
--star：神将星级
--subStar：星级节点级别(一共10个节点)
]]
function LDataConstMgr:GetPetShenXingCost(id, star, subStar)
    if id == nil or star == nil or subStar == nil then
        return 0
    end
    local basePetData = LDataConstMgr:GetPetData(id)
    if basePetData == nil then
        return 0
    end

    if self.m_petStarList == nil then
        self:LoadPetStarConfig()
    end

    if self.m_petQualityList == nil then
        self:LoadPetQualityConfig()
    end

    if self.m_petStarStepList == nil then
        self:LoadPetStarStepConfig()
    end

    local starConfig = self.m_petStarList[star]
    if starConfig == nil then
        return 0
    end

    local qualityConfig = self.m_petQualityList[basePetData.quality]
    if qualityConfig == nil then
        return 0
    end

    local starStepConfig = self.m_petStarStepList[subStar]
    if starStepConfig == nil then
        return 0
    end

    local totalCost = starConfig.totalCost
    local totalCostRadio = qualityConfig.totalCostRadio
    local stepCostRatio = starStepConfig.costRadio
    -- dump({totalCost, totalCostRadio, stepCostRatio})
    if totalCost and totalCostRadio and stepCostRatio then
        return math.floor(totalCost * totalCostRadio * stepCostRatio)
    end
    return 0
end

function LDataConstMgr:GetPetGrowAttr(id, star)
    if id == nil or star == nil then
        return nil
    end
    local basePetData = LDataConstMgr:GetPetData(id)
    if basePetData == nil then
        return nil
    end

    if self.m_petStarList == nil then
        self:LoadPetStarConfig()
    end
    local starConfig = self.m_petStarList[star]
    if starConfig == nil then
        return nil
    end
    local data = {}
    for k,v in pairs(basePetData.growAttrs) do
        if k and v then
            data[k] = math.floor(v * starConfig.starRatio + 0.5)
        end
    end
    return data
end

function LDataConstMgr:LoadMissionConfig()
    -- if #self.m_missionConfig > 0 then
    --     return
    -- end
    -- local stream = StreamBase:CreateReadStreamFromFile("ConfigData/mission_config.dat")
    -- if stream == nil then
    --     return
    -- end

    -- local num = stream:ReadUInt()
    -- for i=1,num do
    --     local data = {}
    --     data.id = stream:ReadUInt()

    --     data.name = stream:ReadUTF8String()
    --     local premission_limit = stream:ReadUTF8String()
    --     if #premission_limit > 0 then
    --         local arr = string.split(premission_limit, ';')
    --         if #arr > 0 then
    --             data.premissionLimit = {}--前置任务列表
    --             for j=1,#arr do
    --                 table.insert(data.premissionLimit, tonumber(arr[j]))
    --             end
    --         end
    --     end
    --     data.minLevel = stream:ReadUInt()
    --     local doing_target = stream:ReadUTF8String()
    --     -- dump(doing_target, "doing_target-->")
    --     local arr = string.split(doing_target, '-')
    --     -- dump(arr, "arr-->")
    --     if #arr >= 3 then
    --         data.target = {type=arr[1], maxNum=arr[2], value=arr[3]}
    --     end
    --     local desc = stream:ReadUTF8String()
    --     if data.target then
    --         -- desc = string.gsub(desc, '<num>', '%d')
    --         desc = string.gsub(desc, '<maxnum>', data.target.maxNum)
    --         data.desc = string.gsub(desc, '<level>', data.target.value)
    --     end
    --     -- dump(data.desc, "data.desc--->")

    --     local finish_reward = stream:ReadUTF8String()
    --     local arr = string.split(finish_reward, ';')
    --     data.rewards = {}
    --     for j=1,#arr do
    --         local subArr = string.split(arr[j], '-')
    --         if #subArr > 0 then
    --             table.insert(data.rewards, subArr)
    --         end
    --     end
    --     local finish_reward2 = stream:ReadUTF8String()
    --     self.m_missionConfig[data.id] = data
    -- end
    -- dump(self.m_missionConfig, "self.m_missionConfig-->")
end

function LDataConstMgr:GetMissionData(mid)
    -- if self.m_missionConfig == nil or mid == nil then
    --     return nil
    -- end
    -- return self.m_missionConfig[mid]
    return nil
end


--Loading背景相关
function LDataConstMgr:InitLoadingCfgData()
    if self.m_loadingBgTotalNum > 0 then
        return;
    end
    self.m_loadingBgTable = {}
    local  stream = StreamBase:CreateReadStreamFromFile("ConfigData/LoginBg.dat")
    if stream == nil then
        return
    end
    self.m_loadingBgTotalNum = stream:ReadUInt()
    for i = 1,self.m_loadingBgTotalNum do
        local data = LLoadingBgData:New()
        data.id = stream:ReadUInt()
        data.bgPic = stream:ReadUTF8String()
        data.iconPic = stream:ReadUTF8String()
        data.name = stream:ReadUTF8String()
        data.quality = stream:ReadUInt()
        data.value = {}
        for k = 1,4 do
            table.insert(data.value,stream:ReadUInt())
        end
        for k = 1,4 do
            local str = stream:ReadUTF8String()
            if #str > 0 then
                table.insert(data.content,str)
            end
        end
        table.insert(self.m_loadingBgTable, data)
    end
end

function LDataConstMgr:GetLoadingCfgData(id)
    if self.m_loadingBgTable == nil or self.m_loadingBgTotalNum == 0 or id <= 0 then
        self:InitLoadingCfgData()
    end
    return self.m_loadingBgTable[id]
end

function LDataConstMgr:GetLoadingCfgDataMaxNum()
    if self.m_loadingBgTable == nil or self.m_loadingBgTotalNum == 0 then
        self:InitLoadingCfgData()
    end
    return self.m_loadingBgTotalNum
end

function LDataConstMgr:LoadDouShenConfig()
    if self.m_doushenConfig then
        return
    end
    local stream = StreamBase:CreateReadStreamFromFile("ConfigData/doushen_config.dat")
    if stream == nil then
        return
    end

    self.m_doushenConfig = {}
    self.m_doushenVector = {}
    local num = stream:ReadUInt()
    for i=1,num do
        local data = {}
        data.id = stream:ReadUInt()
        data.name = stream:ReadUTF8String()
        data.minLevel = stream:ReadUInt()
        data.maxLevel = stream:ReadUInt()
        self.m_doushenConfig[data.id] = data
        table.insert(self.m_doushenVector, data)
    end
end

function LDataConstMgr:GetDouShenConfig(id)
    if id == nil then
        return nil
    end
    if self.m_doushenConfig == nil then
        self:LoadDouShenConfig()
        if self.m_doushenConfig == nil then
            return nil
        end
    end
    return self.m_doushenConfig[id]
end

function LDataConstMgr:GetAllDouShenConfig()
    return self.m_doushenConfig
end

function LDataConstMgr:GetAllDouShenVector()
    return self.m_doushenVector
end

function LDataConstMgr:LoadXiLianConfig()
    if self.m_xiLianData then
        return
    end
    local stream = StreamBase:CreateReadStreamFromFile("ConfigData/equip_xilian.dat")
    if stream == nil then
        return
    end

    self.m_xiLianData = {}
    local num = stream:ReadUInt()
    local temp = nil
    for i=1,num do
        local pos = stream:ReadUInt()
        local data = nil
        if self.m_xiLianData[pos] ~= nil then
            data = self.m_xiLianData[pos]
        else
            data = {costList = {}}
            self.m_xiLianData[pos] = data
        end
        local cost = {}
        local str = stream:ReadUTF8String()
        local arr = string.split(str, ';')
        if #arr > 0 then
            for i=1,#arr do
                local subStr = arr[i]
                local subArr = string.split(subStr, '-')
                if #subArr >=2 then
                    local itemId = tonumber(subArr[1])
                    local itemNum = tonumber(subArr[2])
                    cost[itemId] = itemNum
                end
            end
        end
        table.insert(data.costList, cost)
    end
end

function LDataConstMgr:GetXiLianData(pos)
    if pos == nil then
        return nil
    end
    if self.m_xiLianData == nil then
        self:LoadXiLianConfig()
    end
    if self.m_xiLianData == nil then
        return nil
    end
    return self.m_xiLianData[pos]
end

function LDataConstMgr:LoadMonsterConfig()
    if self.m_monsterConfig then
        return
    end

    self.m_monsterConfig = {}
    self.m_monsterMap = {}
    local objs = require("ConfigData/monster_boss_basic_dat");
    for i = 1, #objs do
        local monster = objs[i];
		self.m_monsterMap[monster.id] = monster
        table.insert(self.m_monsterConfig, monster)
    end
    -- dump(self.m_monsterConfig, "self.m_monsterConfig-->")
end

function LDataConstMgr:GetMonsterData(id)
    if id == nil then
        return nil
    end
    if self.m_monsterMap == nil then
        self:LoadMonsterConfig()
    end
    if self.m_monsterMap == nil then
        return nil
    end
    return self.m_monsterMap[id]
end

function LDataConstMgr:LoadBpKejiDataByConfig( ... )
    -- body
    if self.m_bpKejiData ~= nil then
        return
    end
    local stream = StreamBase:CreateReadStreamFromFile("ConfigData/bang_pai_keji.dat")
    if stream == nil then
        return
    end
    self.m_bpKejiData = {}
    self.m_bpSkillData = {}
    local num = stream:ReadUInt()
    -- print("LoadBpKejiDataByConfig num =", num)
    for i=1, num do
        local data = {}
        local level = stream:ReadUInt()
        local name = stream:ReadUTF8String()
        local buff = stream:ReadUTF8String()
        local cost = stream:ReadUTF8String()
        local pic = stream:ReadUTF8String()
        local isShowStr = stream:ReadUTF8String()
        local des = stream:ReadUTF8String()
        local nameArr = string.split(name, "|")
        local buffArr = string.split(buff, "|")
        local costArr = string.split(cost, "|")
        local picArr = string.split(pic, "|")
        local isShowArr = string.split(isShowStr, "|")
        local desArr = string.split(des, "|")
        for i=1, #costArr do
            local attrData = {}
            local oneArr = string.split(buffArr[i], "-")
            attrData.name = nameArr[i]
            attrData.buffType = oneArr[1]
            attrData.buffAdd = oneArr[2]
            attrData.cost = costArr[i]
            attrData.pic = picArr[i]
            attrData.isShow = tonumber(isShowArr[i]) > 0
            attrData.des = string.format(desArr[i], attrData.buffAdd)
            attrData.level = level
            attrData.effectType = 0
            table.insert(data, attrData)
        end
        -- dump(data, "LoadBpKejiDataByConfig ====>")
        table.insert(self.m_bpKejiData, data)
    end

    local streamSkill = StreamBase:CreateReadStreamFromFile("ConfigData/bang_pai_skill.dat")
    if streamSkill == nil then
        return
    end

    local numSkill = streamSkill:ReadUInt()
    print("numSkill ====================>", numSkill)
    for i=1, numSkill do
        local attrData = {}
        attrData.buffType = streamSkill:ReadUInt()
        attrData.name = streamSkill:ReadUTF8String()
        attrData.level = streamSkill:ReadUInt()
        local des = streamSkill:ReadUTF8String()
        local desArr = string.split(des, "-")
        attrData.des = Utils:getAttrStr(tonumber(desArr[1]), tonumber(desArr[2]))
        --print("attrData.des ====", attrData.des, desArr[1], desArr[2])
        attrData.effectType = streamSkill:ReadUInt()
        attrData.BpCost = {}
        local bpCostStr = streamSkill:ReadUTF8String()
        local costArr = string.split(bpCostStr, "-")
        attrData.BpCost.id = tonumber(costArr[1])
        attrData.BpCost.num = tonumber(costArr[2])

        attrData.playerCost = {}
        local playerCostStr = streamSkill:ReadUTF8String()
        local playerCostArr = string.split(playerCostStr, ";")
        for i=1, #playerCostArr do
            local oneArr = string.split(playerCostArr[i], "-")
            local data = {}
            data.id = tonumber(oneArr[1])
            data.num = tonumber(oneArr[2])
            table.insert(attrData.playerCost, data)
        end
        attrData.pic = streamSkill:ReadUTF8String()
        attrData.isShow = true
        --更新数据
        local data = self.m_bpKejiData[attrData.level + 1]
        if data == nil then
            self.m_bpKejiData[attrData.level + 1] = {}
            data = self.m_bpKejiData[attrData.level + 1]
        end
        --dump(attrData, " ============>")
        table.insert(data, attrData)
    end
--    dump(self.m_bpKejiData., "LoadBpKejiDataByConfig ====>")
end

function LDataConstMgr:getBpKejiDataByLevel(level, type)
    -- body
    if self.m_bpKejiData == nil then
        return nil
    end
    --等级和index相差1, 减少循环
    local kejiData = self.m_bpKejiData[level + 1]
    if kejiData == nil then
        return nil
    end
    
    for j=1, #kejiData do
        local dataInfo = kejiData[j]
        if tonumber(dataInfo.buffType) == type then
            return dataInfo
        end
    end

    return nil
end

function LDataConstMgr:getLVMaxByType( type )
    -- body
    for i=1, #LRoleDataMgr.Faction.Info.kejiInfo do
        local data = LRoleDataMgr.Faction.Info.kejiInfo[i]
        if data.buffType == type then
            return data.buffLevel
        end
    end
    return 0
end

function LDataConstMgr:getIsCanEnough( data )
    -- body
    if data == nil then
        return 1
    end

    local maxLv = self:getLVMaxByType(data.buffType)
    if maxLv <= data.level then
        return 1
    end

    if LRoleDataMgr.Faction.Info.selfBangGong < data.playerCost[2].num then
        return 2
    end

    local myCoin = LRoleDataMgr.MyHeroInfo.DetailData:getMoney()
    if myCoin < data.playerCost[1].num then
        return 2
    end
    return 0
end

-----------------------------------------新表数据-----------------------------------------------------------

function LDataConstMgr:LoadFubenConfigData(  )
    -- body
    if JsonConfig.m_FuBenMapConfig.definitionArr and #JsonConfig.m_FuBenMapConfig.definitionArr > 0 then
        return
    end
    local objs = require("ConfigData.bigmap_dat");
    local cf = {}
    cf.definitionList = {}--HashMap
    cf.definitionArr = {}
     for i = 1, #objs do
        local bigMapData =  objs[i]
        cf.definitionList[bigMapData.Id] = bigMapData
        table.insert(cf.definitionArr, bigMapData)
    end

    cf.getDefByID = function(id)
        return cf.definitionList[id]
    end
    cf.getList = function()
        return cf.definitionArr
    end

    JsonConfig.m_FuBenMapConfig = cf
    JsonConfig.LoadBigMapDataComplete()
end


function LDataConstMgr:LoadStageNodeData()
    -- body
    if JsonConfig.m_stageNodeConfig.definitionArr and #JsonConfig.m_stageNodeConfig.definitionArr > 0 then
        return
    end
    local objs = require("ConfigData.maplist_dat");
    local cf = {}
    cf.definitionList = {}--HashMap
    cf.definitionArr = {}

    JsonConfig.m_stageNodeByMapidDict = {}

    for i = 1, #objs do
        local stageData =  objs[i]
        cf.definitionList[stageData.ID] = stageData
        table.insert(cf.definitionArr, stageData)
        if JsonConfig.m_stageNodeByMapidDict[stageData.mapid] == nil then
            JsonConfig.m_stageNodeByMapidDict[stageData.mapid] = {}
        end
        JsonConfig.m_stageNodeByMapidDict[stageData.mapid][stageData.ID] = stageData
        -- table.insert(JsonConfig.m_stageNodeByMapidDict[stageData.mapid], stageData)
    end

    cf.getDefByID = function(id)
        return cf.definitionList[id]
    end
    cf.getList = function()
        return cf.definitionArr
    end

    JsonConfig.m_stageNodeConfig = cf

end


function LDataConstMgr:LoadFightConfigData(  )
    -- body
    if JsonConfig.m_vecFightConfig.definitionArr and #JsonConfig.m_vecFightConfig.definitionArr > 0 then
        return
    end

    local cf = {}
    cf.definitionList = {}--HashMap
    cf.definitionArr = {}
    local objs = require("ConfigData/fight_config_dat")
    for i = 1, #objs do
        local fightData =  objs[i];
        cf.definitionList[fightData.id] = fightData
        table.insert(cf.definitionArr, fightData)
    end
    cf.getDefByID = function(id)
        return cf.definitionList[id]
    end
    cf.getList = function()
        return cf.definitionArr
    end

    JsonConfig.m_vecFightConfig = cf
end

-- function LDataConstMgr:LoadMissionDialog( ... )
--     -- body
--     if self.m_missionConfig and #self.m_missionConfig > 0 then
--         return
--     end

--     if self.m_missionConfig == nil then
--         self.m_missionConfig = {}
--     end

--     local stream = StreamBase:CreateReadStreamFromFile("ConfigData/mission_dialog.dat")
--     if stream == nil then
--         return
--     end

--     local num = stream:ReadUInt()

--     for i=1, num do
--         local misstionDialog =  LMisstionDialog:New()
--         misstionDialog.dialogid = stream:ReadUInt()
--         misstionDialog.order = stream:ReadUInt()
--         misstionDialog.npcid = stream:ReadUInt()
--         misstionDialog.position = stream:ReadUInt()
--         misstionDialog.dialog = stream:ReadUTF8String()
--         misstionDialog.scale = stream:ReadUInt()
--         misstionDialog.speed = stream:ReadUInt()
--         misstionDialog.delay = stream:ReadUInt()
--         misstionDialog.showskip = stream:ReadUInt()
--         table.insert(self.m_missionConfig, misstionDialog)
--     end
    
-- end

function LDataConstMgr:LoadMasterConfig()
	--local stream = StreamBase:CreateReadStreamFromFile("ConfigData/master.dat")
    --if stream == nil then
    --    return
    --end

    --self.m_masterMap = {}
	--local num = stream:ReadUInt()
    --for i=1,num do
	--	local master = {}
	--	master.type = stream:ReadUInt()
	--	master.level = stream:ReadUInt()
	--	master.condition = stream:ReadUInt()
	--	local attr = stream:ReadUTF8String()
	--	master.attrs = json.decode(attr)
	--	local id = (master.type * 1000) + master.level
	--	self.m_masterMap[id] = master
	--end

	if JsonConfig.m_Master.definitionArr and #JsonConfig.m_Master.definitionArr > 0 then
        return
    end
    local objs = require("ConfigData.master_dat");
    local cf = {}
    cf.definitionList = {}--HashMap
    cf.definitionArr = {}
     for i = 1, #objs do
        local bigMapData =  objs[i]
		local id = (bigMapData.type * 1000) + bigMapData.level
        cf.definitionList[id] = bigMapData
        table.insert(cf.definitionArr, bigMapData)
    end

    cf.getDefByID = function(id)
        return cf.definitionList[id]
    end
    cf.getList = function()
        return cf.definitionArr
    end

    JsonConfig.m_Master = cf
end

function LDataConstMgr:GetMasterData(type, level)
    if type == nil or level == nil or type == 0 or level == 0 then
        return nil
    end
   -- if self.m_masterMap == nil then
   --     self:LoadMasterConfig()
   -- end
   -- if self.m_masterMap == nil then
   --     return nil
   -- end
	--local id = (type * 1000) + level
   -- return self.m_masterMap[id]
	local id = (type * 1000) + level
	return JsonConfig.m_Master.getDefByID(id)
end

--用于奖励表中的Item图标显示
--@param value[id,0,num]
function LDataConstMgr:GetRewardItemPicPath(value)
    local itemId = value[1] or 0
    if itemId == 0 then
        return "",0
    end
    local cfg = nil
    if itemId == AppDef.RewardItem.RD_ITEM_PET then
        cfg = JsonConfig.m_MonsterBoss.getDefByID(value[2])
        return "res2/Monster_Bust"..value[2].."_tou.png",cfg.quality
    elseif itemId == AppDef.RewardItem.RD_ITEM_EQUIP then
        cfg = JsonConfig.m_equipConfig.getDefByID(value[2])
        return "item/"..cfg.pic..".png",cfg.quality
    elseif itemId == AppDef.RewardItem.RD_ITEM_FABAO then
        cfg = JsonConfig.m_faBaoConfig.getDefByID(value[2])
        return "item/"..cfg.pic..".png",cfg.quality
    end
    cfg = LItemMgr:getItem(itemId)
    if cfg == nil then
        return "",0
    end
    return "item/equip"..cfg.pic..".png",cfg.quality
end

LDataConstMgr:Init()