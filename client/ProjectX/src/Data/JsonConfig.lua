--表格配置结构
-- interface IConfig
-- {
--     jsonName: string;
--     key: string;
-- }
-- --配置数据通用方法结构
-- interface IConfigFunction
-- {
--     definitionList: HashMap;
--     json: JSON;
--     getDefByID( id );
--     getList(): any[];
-- }
local json = require 'json'
JsonConfig = {}
--
--全部表格配置
--
JsonConfig.m_FuBenMapConfig = {}--大地图表数据
JsonConfig.m_stageNodeConfig = {}--关卡数据
JsonConfig.m_stageNodeByMapidDict = {}--关卡数据
JsonConfig.m_BoxReward = {}--宝箱数据
JsonConfig.m_Item = {}--物品数据
JsonConfig.m_petBreakCost = {}--宝箱数据
JsonConfig.m_petLvUpExp = {}--宠物升级经验
JsonConfig.m_equipConfig = {}--装备配置
JsonConfig.m_heroCfg = {} --宠物数据
JsonConfig.m_star = {} --星级
JsonConfig.m_quality = {} --品质
JsonConfig.m_VecItemList = {} --物品
JsonConfig.m_mapRes = {} --关卡位置
JsonConfig.m_equipJingLian = {} --装备精炼配置
--JsonConfig.m_VecItemList = {} --物品
JsonConfig.m_suitList = {} --key-套装ID，value 套装装备ID列表
JsonConfig.m_typeItems = {} --type对应物品id
JsonConfig.m_drawConfig = {} --抽卡配置
JsonConfig.m_ShopConfig = {} --商城配置
JsonConfig.m_vecXueZhanReward = {} --血战奖励（商城解锁),value-{level,id,num}
JsonConfig.m_vecFightConfig = {} -- 战斗表
JsonConfig.m_MonsterBoss = {} --怪物Boss
JsonConfig.m_vecFengShenStoryId = {}
JsonConfig.m_bpFubenConfig = {}--帮派副本配置
JsonConfig.m_KunlunConfig = {} --昆仑决战奖励
JsonConfig.m_Reward = {}--通用奖励表
JsonConfig.m_SanJieConfig={}--游历三界
JsonConfig.m_OnLineConfig={}--在线奖励
JsonConfig.m_mapAchievement = {}
JsonConfig.m_NPCtemplate = {}

JsonConfig.m_Master = {}
JsonConfig.m_guildReward = {}
JsonConfig.m_revertConfig = {}
JsonConfig.m_loginReward = {}

function JsonConfig.initConfig()

    JsonConfig.m_BoxReward= JsonConfig.SetConfig(
    {
        jsonName = "reward_fixed",
        key = "ID"
    })
	
	JsonConfig.m_Reward= JsonConfig.SetConfig(
    {
        jsonName = "reward",
        key = "rewardid"
    })

    JsonConfig.m_petBreakCost=JsonConfig.SetConfig(
    {
        jsonName = "break",
        key = "break_level"
    })

    JsonConfig.m_Item = JsonConfig.SetConfig(
    {
        jsonName = "item",
        key = "id"
    })
    JsonConfig.LoadItemConfigComplete()



    JsonConfig.m_petLvUpExp = JsonConfig.SetConfig(
    {
        jsonName = "exp",
        key = "level"
    })
    
    JsonConfig.m_equipConfig = JsonConfig.SetConfig(
    {
        jsonName = "equip",
        key = "id"
    })
    JsonConfig.LoadEquipConfigComplete()

    JsonConfig.m_heroCfg = JsonConfig.SetConfig(
    {
        jsonName = "hero",
        key = "id"
    })
    JsonConfig.DecodeHero();

    JsonConfig.m_star = JsonConfig.SetConfig(
    {
        jsonName = "star",
        key = "star"
    })

    JsonConfig.m_quality = JsonConfig.SetConfig(
    {
        jsonName = "quality",
        key = "quality"
    })

    JsonConfig.m_HeCheng = JsonConfig.SetConfig(
    {
        jsonName = "hecheng",
        key = "id"
    })
    JsonConfig.LoadHeChengComplete()
    JsonConfig.m_heroBook = JsonConfig.SetConfig(
    {
        jsonName = "handbook",
        key = "id"
    })
    
    JsonConfig.m_mapRes = JsonConfig.SetConfig({
        jsonName = "map_res",
        key = "id"
    })
    JsonConfig.m_suitConfig = JsonConfig.SetConfig({
        jsonName = "suit",
        key = "id"
    })
    
    JsonConfig.m_equip_qianghua = JsonConfig.SetConfig({
        jsonName = "equip_qianghua",
        key = "level"
    })
    
    JsonConfig.m_equipJingLian = JsonConfig.SetConfig({
        jsonName = "equip_jinglian",
        key = "level"
    })
    
    JsonConfig.m_equipJueXing = JsonConfig.SetConfig({
        jsonName = "equip_juexing",
        key = "level"
    })
    
    JsonConfig.m_equipShenZhu = JsonConfig.SetConfig({
        jsonName = "equip_shenzhu",
        key = "level"
    })


    JsonConfig.m_drawConfig = JsonConfig.SetConfig({
        jsonName = "draw_config",
        key = "id"
    })
    
    JsonConfig.m_drawBasic = JsonConfig.SetConfig({
        jsonName = "draw_basic",
        key = "id"
    })

    JsonConfig.m_bloodBattle = JsonConfig.SetConfig({
        jsonName = "blood_battle",
        key = "id"
    })

    JsonConfig.m_bloodArrays = JsonConfig.SetConfig({
        jsonName = "blood_arrays",
        key = "id"
    })

    JsonConfig.m_bloodChapter = JsonConfig.SetConfig({
        jsonName = "blood_chapter",
        key = "id"
    })

    JsonConfig.m_config = JsonConfig.SetConfig({
        jsonName = "config",
        key = "id"
    })
    JsonConfig.m_rewardRank = JsonConfig.SetConfig({
        jsonName = "reward_rank",
        key = "id"
    })
    JsonConfig.LoadRewardRankComplete()

    JsonConfig.m_ShopInfo = JsonConfig.SetConfig({
        jsonName = "shop",
        key = "id"
    })
    JsonConfig.LoadShopComplete()

    JsonConfig.m_ShopConfig = JsonConfig.SetConfig({
        jsonName = "shop_config",
        key = "id"
    })

	JsonConfig.m_KunlunConfig = JsonConfig.SetConfig({
		jsonName = "kunlun",
		key = "id"
	})

    JsonConfig.m_dailyConfig = JsonConfig.SetConfig({
        jsonName = "daily",
        key = "id"
    })
    JsonConfig.LoadDailyComplete()

    JsonConfig.m_vipConfig = JsonConfig.SetConfig({
        jsonName = "vip",
        key = "vip"
    })
    JsonConfig.LoadVipComplete()

    JsonConfig.m_SanJieConfig=JsonConfig.SetConfig({
        jsonName = "sanjie",
        key = "id"
    })
    JsonConfig.m_OnLineConfig=JsonConfig.SetConfig({
        jsonName = "online_reward",
        key = "id"
    })

    JsonConfig.m_mapAchievement = JsonConfig.SetConfig({
        jsonName = "map_achievement",
        key = "id"
    })


    JsonConfig.m_NPCtemplate = JsonConfig.SetConfig({
        jsonName = "npc_template",
        key = "id"
    })

    JsonConfig.m_faBaoConfig = JsonConfig.SetConfig({
        jsonName = "fabao",
        key = "id"
    })

    JsonConfig.m_faBaoJingLian = JsonConfig.SetConfig({
        jsonName = "fabao_jinglian",
        key = "level"
    })

    JsonConfig.m_faBaoQiangHua = JsonConfig.SetConfig({
        jsonName = "fabao_qianghua",
        key = "level"
    })
	
	JsonConfig.m_MonsterBoss = JsonConfig.SetConfig({
		jsonName = "monster_boss_basic",
        key = "id"
	})

    JsonConfig.m_sevendays = JsonConfig.SetConfig({
        jsonName = "sevendays",
        key = "id"
    })

    JsonConfig.m_expConfig = JsonConfig.SetConfig({
        jsonName = "exp",
        key = "level"
    })

    JsonConfig.m_functionConfig = JsonConfig.SetConfig({
        jsonName = "function",
        key = "function_id"
    })
    JsonConfig.LoadFunctionComplete()

    JsonConfig.m_staminaConfig = JsonConfig.SetConfig({
        jsonName = "stamina",
        key = "id"
    })

    JsonConfig.m_robotConfig = JsonConfig.SetConfig({
        jsonName = "robot",
        key = "id"
    })

    JsonConfig.m_AttrType = JsonConfig.SetConfig({
        jsonName = "attr_type",
        key = "attrType"
    })

    JsonConfig.m_missionConfig = JsonConfig.SetConfig({
        jsonName = "mission_dialog",
        key = "dialogid"
    })

	JsonConfig.m_zhenfaConfig = JsonConfig.SetConfig({
        jsonName = "zhenfa_config",
        key = "id"
    })
	JsonConfig.LoadZhenfaComplete()
	JsonConfig.m_zhenfaLevelConfig = JsonConfig.SetConfig({
        jsonName = "zhenfa_level",
        key = "id"
    })

    JsonConfig.m_xiuLianConfig = JsonConfig.SetConfig({
        jsonName = "xiulian",
        key = "level"
    })

	JsonConfig.LoadZhenfaLevelComplete()

	JsonConfig.m_loginReward = JsonConfig.SetConfig({
        jsonName = "LoginReward",
        key = "id"
    })

	JsonConfig.m_jingjieConfig = JsonConfig.SetConfig({
		jsonName = "jingjie_config",
        key = "jingjie_id"
	})

    JsonConfig.m_lianChong = JsonConfig.SetConfig({
        jsonName = "lianchong",
        key = "id"
    })

    JsonConfig.m_youliConfig = JsonConfig.SetConfig({
        jsonName = "sanjie",
        key = "id"
    })
    JsonConfig.m_youliCost = JsonConfig.SetConfig({
        jsonName = "sanjie_cost",
        key = "id"
    })
    JsonConfig.m_youliDialog = JsonConfig.SetConfig({
        jsonName = "sanjie_dialogue",
        key = "id"
    })
end

function JsonConfig.DecodeHero()
    local list = JsonConfig.m_heroCfg.getList()
    for i = 1, #list do
        local bgmStr = list[i].skill_cv
        strArr = string.split(bgmStr,";")
        list[i].skillBgms = {}
        for j = 1, #strArr do
            list[i].skillBgms[j] = {}
            if string.len(strArr[j]) > 0 then
                local arr2 = string.split(strArr[j],"|")
                for k = 1, #arr2 do
                    table.insert(list[i].skillBgms[j],arr2[k])
                end
            end
        end
    end
end

function JsonConfig.SetConfig(info)
    local cf = {}
    cf.definitionList = {}--HashMap
    cf.definitionArr = {}
    local objs = require("ConfigData." .. info.jsonName .. "_dat")
    local function LoadJsonComplete(obj)
        for i = 1, #obj do
            cf.definitionList[obj[i][info.key]] = obj[i]
            table.insert(cf.definitionArr,obj[i])
        end
        cf.getDefByID = function(id)
            return cf.definitionList[id]
        end
        cf.getList = function()
            return cf.definitionArr
        end
        cf.getDefByIndex = function(idx)
            return cf.definitionArr[idx]
        end
    end
    LoadJsonComplete(objs)
    return cf
end

function JsonConfig.LoadFunctionComplete()
    JsonConfig.m_mapFunction = {}--key为条件类型
    local list = JsonConfig.m_functionConfig.getList()
    for i=1,#list do
        local value = list[i]
        if #value.open_condition > 0 then
             for k=1,#value.open_condition do
                local cType = value.open_condition[k][1]
                if JsonConfig.m_mapFunction[cType] == nil then
                    JsonConfig.m_mapFunction[cType] = {}
                end
                table.insert(JsonConfig.m_mapFunction[cType], value.function_id)
            end
        end
    end
end

--[[
获取活动func表
]]
function JsonConfig.GetActivityFunc()
    local datas = {}
    local list = JsonConfig.m_functionConfig.getList()
    for i=1,#list do
        local value = list[i]
        if value.page == 3 then
            table.insert(datas,value);
        end
    end
    return datas
end

function JsonConfig.LoadDailyComplete()
    JsonConfig.m_vecDailyData = {}
    local list = JsonConfig.m_dailyConfig.getList()
    for i=1,#list do
        local value = list[i]
        if JsonConfig.m_vecDailyData[value.type] == nil then
            JsonConfig.m_vecDailyData[value.type] = {}
        end
        table.insert(JsonConfig.m_vecDailyData[value.type],value)
    end
end

function JsonConfig.GetDailyByType(rType)
    return JsonConfig.m_vecDailyData[rType]
end

function JsonConfig.LoadVipComplete()
    local list = JsonConfig.m_vipConfig.getList()
    local last = list[#list]
    JsonConfig.m_maxVipLv = last.vip
end

function JsonConfig.LoadShopComplete()
    JsonConfig.m_vecXueZhanReward = {}
    --JsonConfig.m_mapShopIds = {} --key-道具ID，value-shopId
    local info = JsonConfig.m_vecXueZhanReward
    local list = JsonConfig.m_ShopInfo.getList()
    for i=1,#list do
        --dump(list[i],"list=>")
        if list[i].type == 8 and #list[i].condition == 1 and  list[i].condition[1][1] == 3 then
            local value = {}
            value.id = list[i].itemid[1]
            value.num = list[i].itemid[3]
            value.level = list[i].condition[1][2] or 0
            table.insert(info,value)
        end
        -- if #list[i].itemid == 3 then
        --     JsonConfig.m_mapShopIds[list[i].itemid[1]] = list[i].id
        -- end
    end
end

function JsonConfig.GetXueZhanRewardInfo(level)
    local dstIdx = 0
    local dstLevel = 0
    local info = JsonConfig.m_vecXueZhanReward
    --dump(info,"GetXueZhanRewardInfo =>")
    for i=1,#info do
        local value = info[i]
        if value.level > level and (dstLevel == 0 or value.level < dstLevel) then
            dstLevel = value.level
            dstIdx = i
        end
    end
    --print("JsonConfig.GetXueZhanRewardInfo dstIdx",dstIdx)
    if dstIdx == 0 then
        return nil
    end
    return info[dstIdx]
end

function JsonConfig.LoadRewardRankComplete()
    JsonConfig.m_mapRewardRank = {}
    local info = JsonConfig.m_mapRewardRank
    local list = JsonConfig.m_rewardRank.getList()
    for i=1,#list do
        local value = {}
        value.id = list[i].id
        value.min = list[i].rank[1]
        value.max = list[i].rank[2]
        if info[list[i].type] == nil then
            info[list[i].type] = {}
        end
        table.insert(info[list[i].type],value)
    end
end

function JsonConfig.GetRewardRankCfg(rtype,rank)
    if JsonConfig.m_mapRewardRank[rtype] == nil then
        return nil
    end
    local info = JsonConfig.m_mapRewardRank[rtype]
    local id = 0
    for i=1,#info do
        if rank >= info[i].min and rank <= info[i].max then
            id = info[i].id
            break
        end
    end
    if id == 0 then
        return nil
    end
    return JsonConfig.m_rewardRank.getDefByID(id)
end


function JsonConfig.LoadItemConfigComplete()
end

function JsonConfig.LoadHeChengComplete()
    JsonConfig.mapHeChengIds = {}
	JsonConfig.mapHeChengEquipIds = {}
    local list = JsonConfig.m_HeCheng.getList()
    for i=1, #list do
        local data = list[i]
        if JsonConfig.mapHeChengIds[data.type] == nil then
            JsonConfig.mapHeChengIds[data.type] = {}
        end
        for m=1,#data.item do
            local itemInfo = data.item[m]
            JsonConfig.mapHeChengIds[data.type][itemInfo[1]] = data.id
			if itemInfo[1] > 60000 then
				if JsonConfig.mapHeChengEquipIds[data.type] == nil then
					JsonConfig.mapHeChengEquipIds[data.type] = {}
				end
				JsonConfig.mapHeChengEquipIds[data.type][itemInfo[2]] = data.id
			end
        end
    end
end

function JsonConfig.GetHeChengCfg(hType,itemId)
    local id = 0
    if JsonConfig.mapHeChengIds[hType] ~= nil then
        id = JsonConfig.mapHeChengIds[hType][itemId] or 0
    end
    if id == 0 then
        return nil
    end
    return JsonConfig.m_HeCheng.getDefByID(id)
end

function JsonConfig.GetHeChengEquipCfg(hType,itemId)
    local id = 0
    if JsonConfig.mapHeChengEquipIds[hType] ~= nil then
        id = JsonConfig.mapHeChengEquipIds[hType][itemId] or 0
    end
    if id == 0 then
        return nil
    end
    return JsonConfig.m_HeCheng.getDefByID(id)
end

function JsonConfig.GetHeChengIdsByType(hType)
    local ids = {}
    if JsonConfig.mapHeChengIds[hType] == nil then
        return ids
    end
    local tmp = {}
    for k,v in pairs(JsonConfig.mapHeChengIds[hType]) do
        tmp[v] = true
    end
    for k,v in pairs(tmp) do
        table.insert(ids,k)
    end
    return ids
end

function JsonConfig.LoadEquipConfigComplete()
    local list = JsonConfig.m_equipConfig.getList()
    for i=1, #list do
        local data = list[i]
        if data.suit > 0 then
            if JsonConfig.m_suitList[data.suit] == nil then
                JsonConfig.m_suitList[data.suit] = {}
            end
            table.insert(JsonConfig.m_suitList[data.suit],data.id)
        end
    end
end

function JsonConfig.GetItemCfgByType(atype)
    local ids = JsonConfig.m_typeItems[atype]
    if ids ~= nil then
        return ids
    end

    local idArrs = {}
    local cfglist = JsonConfig.m_Item.getList()
    for i=1, #cfglist do
        local cfg = cfglist[i]
        if cfg.type == atype then
            idArrs[#idArrs + 1] = cfg
        end
    end
    JsonConfig.m_typeItems[atype] = idArrs
    return idArrs
end

function JsonConfig.LoadHeroConfigComplete( ... )
    -- body
    local list = JsonConfig.m_heroCfg.getList()
    for i=1, #list do
        local data = list[i]
        data.baseAttrs = {}
        data.baseAttrs[AppDef.EAttrType.EAT_ATTACK] = data.gongji
        data.baseAttrs[AppDef.EAttrType.EAT_DEFENSE] = data.wufang
        data.baseAttrs[AppDef.EAttrType.EAT_MAGICD_EFENSE] = data.fashang
        data.baseAttrs[AppDef.EAttrType.EAT_HP] = data.qixue
        data.baseAttrs[AppDef.EAttrType.EAT_SPEED] = 0
        data.baseAttrs[AppDef.EAttrType.EAT_HIT] = 0
        data.baseAttrs[AppDef.EAttrType.EAT_DODGE] = 0
        data.baseAttrs[AppDef.EAttrType.EAT_CRIT] = 0
        data.baseAttrs[AppDef.EAttrType.EAT_RESISIT_CRIT] = 0

        data.growAttrs = {}
        data.growAttrs[AppDef.EAttrGrowType.EAT_ATTACK_CHENGZHANG] = data.gongji_lv
        data.growAttrs[AppDef.EAttrGrowType.EAT_DEFENSE_CHENGZHANG] = data.wufang_lv
        data.growAttrs[AppDef.EAttrGrowType.EAT_MD_CHENGZHANG] = data.fafang_lv
        data.growAttrs[AppDef.EAttrGrowType.EAT_HP_CHENGZHANG] = data.qixue_lv
        data.growAttrs[AppDef.EAttrGrowType.EAT_SPEED_CHENGZHANG] = 0
        data.growAttrs[AppDef.EAttrGrowType.EAT_HIT_CHENGZHANG] = 0
        data.growAttrs[AppDef.EAttrGrowType.EAT_DODGE_CHENGZHANG] = 0
        data.growAttrs[AppDef.EAttrGrowType.EAT_CRIT_CHENGZHANG] = 0
        data.growAttrs[AppDef.EAttrGrowType.EAT_RCRIT_CHENGZHANG] = 0

        data.baseAttrs = {}
        data.baseAttrs[AppDef.EAttrType.EAT_CRIT_DAMAGE] = 0
        data.baseAttrs[AppDef.EAttrType.EAT_DAMAGE_RATE] = 0
        data.baseAttrs[AppDef.EAttrType.EAT_WM_RATE] = 0
        data.baseAttrs[AppDef.EAttrType.EAT_FM_RATE] = 0
        data.baseAttrs[AppDef.EAttrType.EAT_DOUBLE_RATE] = 0
        data.baseAttrs[AppDef.EAttrType.EAT_RDOUBLE_RATE] = 0
        data.baseAttrs[AppDef.EAttrType.EAT_DOUBLE_DAMAGE] = 0
        data.baseAttrs[AppDef.EAttrType.EAT_COUNTER_RATE] = 0
        data.baseAttrs[AppDef.EAttrType.EAT_RCOUNTER_RATE] = 0
        data.baseAttrs[AppDef.EAttrType.EAT_COUNTER_DAMAGE] = 0
        data.baseAttrs[AppDef.EAttrType.EAT_SHOCK_RATE] = 0
        data.baseAttrs[AppDef.EAttrType.EAT_RSHOCK_RATE] = 0
        data.baseAttrs[AppDef.EAttrType.EAT_SHOCK_DAMAGE] = 0
        data.baseAttrs[AppDef.EAttrType.EAT_FUMIANQIANGHUA] = 0
        data.baseAttrs[AppDef.EAttrType.EAT_FUMIANDIKANG] = 0
        data.defaultFace = 2

        --
        data.petType = data.SubType
        if data.petType == nil then
            data.petType = 1
        end
        
        function data:IsShiny()
            -- body
            return self.initstar > 7
        end

    end

end



function JsonConfig.getMapIdByStageID(stageID)
    -- body
    if stageID == nil or stageID <= 0 then
        return 0
    end
    local configData = JsonConfig.m_stageNodeConfig.getDefByID(stageID)
    if configData == nil then
        return 0
    end
    return configData.mapid
end

function JsonConfig.getFightMaxNum( stageID )
    -- body
    if stageID == nil or stageID <= 0 then
        return 0
    end
    return JsonConfig.m_stageNodeConfig.getDefByID(stageID).AttackCount
end

function JsonConfig.getUnLockStageData( stageID )
    -- body
    local stageNodeConfigList = JsonConfig.m_stageNodeConfig.getList()
    for i=1, #stageNodeConfigList do
        if stageNodeConfigList[i].UnlockID == stageID then
            return stageNodeConfigList[i]
        end
    end
    return nil
end


function JsonConfig.SortPetBookList( ... )
    -- body
    --按 可激活，可升级，已点亮
    function sortFunc(a, b) 
        local temp1 =PetkaPaiManager:getPetBookCanActive(a.id)
        local temp2 =PetkaPaiManager:getPetBookCanActive(b.id)
        if temp1==temp2 then
            local dataA=JsonConfig.m_heroCfg.getDefByID(a.id)
            local dataB= JsonConfig.m_heroCfg.getDefByID(b.id)
            local qualityA = dataA.quality
            local qualityB = dataB.quality
            if qualityA==qualityB then
                return a.id<b.id 
            else
                return qualityA>qualityB
            end    
        end
        return  temp1> temp2
    end 
    table.sort(JsonConfig.m_heroCfg:getList(), sortFunc)
end


function JsonConfig.LoadBigMapDataComplete()
    --封神列传数据
    JsonConfig.m_vecFengShenStoryId = {}
    local list =  JsonConfig.m_FuBenMapConfig.getList()
    for i=1,#list do
        if list[i].MapType == 4 then
            table.insert(JsonConfig.m_vecFengShenStoryId,list[i].Id)
        elseif list[i].MapType == 5 then
            table.insert(JsonConfig.m_bpFubenConfig,list[i])
        end
    end
end

function JsonConfig.GetFengShenStoryData(chatperId)
    if chatperId == nil or chatperId == 0 then
        return nil
    end
    local max = #JsonConfig.m_vecFengShenStoryId
    if max == 0 then
        return
    end
    local idx = chatperId%max 
    return JsonConfig.m_FuBenMapConfig.getDefByID(JsonConfig.m_vecFengShenStoryId[idx])
end

function JsonConfig.GetGuildRewardData(id)
    if #JsonConfig.m_guildReward == 0 then
        JsonConfig.m_guildReward = JsonConfig.SetConfig({
            jsonName = "guild_reward",
            key = "id"
        })
    end
    return JsonConfig.m_guildReward.getDefByID(id);
end

function JsonConfig.GetRevertData(id)
    if #JsonConfig.m_revertConfig == 0 then
        JsonConfig.m_revertConfig = JsonConfig.SetConfig({
            jsonName = "revert",
            key = "function_id"
        })
    end
    return JsonConfig.m_revertConfig.getDefByID(id);
end

function JsonConfig.GetDailyTaskConfig(id)
    return JsonConfig.m_dailyConfig.getDefByID(id);
end

function JsonConfig.GetDailyHuoyueRewardConfig()
    return JsonConfig.m_vecDailyData[0];
end

function JsonConfig.LoadZhenfaComplete()
	local datas = JsonConfig.m_zhenfaConfig.definitionList
	local zhenfalist = {}
	for k,v in pairs(datas) do
		local data = {}
		data.id = v.id
		data.name = v.name
		data.posList = {}
		data.posOpenLvList = {}
		for j = 1,AppDef.Formation.MaxFightNum do
			data.posList[j] = v["index" .. j]
			data.posOpenLvList[j] = v["index" .. j .. "_openlevel"]
		end
		data.restraintList = v.counter
		-- dump(data.restraintList, "======================================>")
		zhenfalist[k] = data
	end
	JsonConfig.m_zhenfaConfig.definitionList = zhenfalist
end

function JsonConfig.LoadZhenfaLevelComplete()
	JsonConfig.m_zhenfaLevelMap = {}
	local list = JsonConfig.m_zhenfaLevelConfig.getList()
	for i = 1,#list do
		local cfg = list[i]
		local key = cfg.id.."_"..cfg.level
		local data = {}
		data.lv = cfg.level
        data.addAttrValue = {}
        data.addAttrType = {}
        
        for j = 1,AppDef.Formation.MaxFightNum do
            local typeData = {}
            local valueData = {}
            table.insert(data.addAttrValue,valueData)
            table.insert(data.addAttrType,typeData)
            local attrDatas =  cfg["index" .. j .. "_attr"]
            for k = 1, #attrDatas do
                valueData[k] = attrDatas[k][2]
                typeData[k] = attrDatas[k][1]
            end
        end
		data.cost = cfg.cost
		data.costItemId = cfg.cost_itemid---升级消耗的道具id
        data.costItemNum = cfg.cost_itemnum---升级消耗的道具数量
        data.addPower = cfg.zhanli
		JsonConfig.m_zhenfaLevelMap[key] = data
	end
end