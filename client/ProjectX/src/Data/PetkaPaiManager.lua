PetkaPaiManager = LDataBase:New()
PetkaPaiManager.__index = PetkaPaiManager
local ShopDef = require("View.Shop.ShopDef")
local ITEMINDEXBEGIN = 833

function PetkaPaiManager:Awake()
    --用于抽卡
    self.m_curDarwKind = 0
    --用于标记十连抽抽卡
    self.m_curDarwType = 0

    self.m_DrawResult = {}
    self.m_DrawInfo = nil

    --用于标记继续抽卡
    self.m_isInDrawResult = false

    self.m_isInTenDrawResult = false
    --体力倒计时
    self.m_TiLiTime=0
    self.m_XunBaoTime=0
    self.m_TiliTimer=nil
    --商店数据
    self.m_AllShopData = {}

    self._serverOpenTime = 0 --开服第几天
    self.m_createRoleDays = 0
   
   -- 关卡节点数据
    self.m_StageInfo={}

end

function PetkaPaiManager:setTiLiTimer(tili,xunBao)
    self.m_TiLiTime=tili or self.m_TiLiTime
    self.m_XunBaoTime=xunBao or self.m_XunBaoTime
    if self.m_TiliTimer~=nil then
        return
    end
    self.m_TiliTimer=Utils:schedule(nil, function ()
       self.m_TiLiTime=self.m_TiLiTime+1
       self.m_XunBaoTime=self.m_XunBaoTime-1
       if  self.m_XunBaoTime<=0 then
           self.m_XunBaoTime=0


       end
    end, 1,false)
end



---------------------------------宠物升级相关---------------------------------------------
function PetkaPaiManager:getPetLevelUpData(petData, toLevel)
    -- body
    local needItem = {}
    local needExp =  self:getNeedExpData(petData, toLevel)
    --print("getPetLevelUpData needExp =", needExp)
    local curExp = 0
    --4中增加经验的道具
    for i=1, 4 do
    	local itemId = ITEMINDEXBEGIN + i
    	local itemData = {}
    	itemData.itemId = itemId
    	local num = LRoleDataMgr.Equip:CountItemNumById(itemId)
    	if num > 0 then
	    	local itemConfig = JsonConfig.m_Item.getDefByID(itemId)
	    	local ItemAddExp = itemConfig.sub_value[1][2]
	    	for j=1, num do
	    		curExp =  curExp + ItemAddExp
	    		if curExp >= needExp then
	    			itemData.itemNum = j
	    			table.insert(needItem, itemData)
	    			return needItem, curExp
	    		end
	    	end
	    	itemData.itemNum = num
	    	table.insert(needItem, itemData)
	    end
    end
    return needItem, curExp
end

function PetkaPaiManager:getItemMaxExp( ... )
    -- body
    local totalExp = 0
    for i=1, 4 do
        local itemId = ITEMINDEXBEGIN + i
        local num = LRoleDataMgr.Equip:CountItemNumById(itemId)
        if num > 0 then
            local itemConfig = JsonConfig.m_Item.getDefByID(itemId)
            local ItemAddExp = itemConfig.sub_value[1][2]
            totalExp = totalExp + ItemAddExp * num
        end
    end
    return totalExp
end

--caclType 区分是增加操作还是减少操作
--oldValue 操作之前的数据,递归计算用的
--
function PetkaPaiManager:getPetCanUpToLV( petData, level, caclType, oldValue)
    -- body
    local toLevel = petData.level + level

    if toLevel > AppDef.Pet.MaxLevel then
        toLevel = AppDef.Pet.MaxLevel
    end

    if toLevel > LRoleDataMgr.MyHeroInfo.level then
        toLevel = LRoleDataMgr.MyHeroInfo.level
    end

    -- local needExp = self:getNeedExpData(petData, toLevel)
    -- --print("getPetCanUpToLV needExp  11111111111 ===>", needExp, toLevel, oldValue)
    -- local totalExp = self:getItemMaxExp()

    local itemList, itemExp = self:getPetLevelUpData(petData, toLevel)
    --print("getPetCanUpToLV ==== 222222222222 ==>>", level, itemExp, totalExp, toLevel)
    local resultLevel = self:getCanToLvByExp(petData, itemExp)
    --print("getPetCanUpToLV ==== 44444444444444444444 ==>>", level, itemExp, resultLevel, toLevel)
    if resultLevel ~= toLevel then
        toLevel = resultLevel + petData.level
        itemList, itemExp = self:getPetLevelUpData(petData, toLevel)
    end
    
    --print("getPetCanUpToLV ===========>, oldValue", resultLevel, oldValue, level)
    if caclType == 2 and resultLevel == oldValue then
        return self:getPetCanUpToLV(petData, level - 1, caclType, oldValue)
    end
    return itemList, resultLevel
end

function PetkaPaiManager:getCanToLvByExp( petData, exp )
    -- body
    
    if petData == nil then
        return 0
    end

    local configData = JsonConfig.m_petLvUpExp.getDefByID(petData.level)
    local needExp = configData.exp_hero - petData.exp
    --print("getCanToLvByExp petData ==>", exp, needExp)
    if needExp > exp then
        return 0
    end

    for i= 1, AppDef.Pet.MaxLevel do
        local levelTemp = petData.level + i
        if levelTemp >= AppDef.Pet.MaxLevel then
            return i
        end
        if levelTemp >= LRoleDataMgr.MyHeroInfo.level then
            return i
        end
        local expData = JsonConfig.m_petLvUpExp.getDefByID(levelTemp)
        needExp = needExp + expData.exp_hero
        --print("getCanToLvByExp petData == 1111>", exp, needExp)
        if needExp > exp then
            return i
        end
    end
    return 0
end

-----------------------------------------------------------------------
--装备 --通过 fightPos来判断宠物装的哪些装备
function PetkaPaiManager:getPetEquipByPos(pos)
    -- body
    local function sortFuc(a, b)
        return a.m_wpos < b.m_wpos
    end
    local equipList = {}
    for k,v in pairs(LRoleDataMgr.Pet.equipList.m_petEquips) do
        if v.m_fpos == pos then
            table.insert(equipList, v)
        end
    end
    table.sort(equipList, sortFuc)
    return equipList
end

--法宝 --通过 fightPos来判断宠物装的哪些法宝
function PetkaPaiManager:getpetFaBaoByPos(pos)
    local function sortFuc(a, b)
        return a.m_wpos < b.m_wpos
    end
    local faBaoList = {}
    for k,v in pairs(LRoleDataMgr.Pet.faBaoList.m_petFaBaos) do
        if v.m_fpos == pos then
            table.insert(faBaoList, v)
        end
    end
    table.sort(faBaoList, sortFuc)
    return faBaoList
end


function PetkaPaiManager:FaBaoCanHeCheng( hcData )
    -- body
    if hcData == nil or hcData.item == nil then
        return false
    end
    local size = #hcData.item
    if size < 1 then
        return false
    end

    for i=1, 5 do
        if i <= size then
            local itemData = hcData.item[i]
            local itemNum = LRoleDataMgr.Equip:CountItemNumById(itemData[1])
            if itemNum < 1 then
                return false
            end
        end
    end
    return true
end

--法宝强化 一键选择材料
function PetkaPaiManager:oneKeySelectFBQHItem( uid )
    -- body
    --local index 
    local resutList = {}
    local maxNum = 8
    --选蓝经验法宝
    for k,v in pairs(LRoleDataMgr.Pet.faBaoList.m_petFaBaos) do
        --神将碎片
        -- dump(v, "PetBagFragmentSubUI:initData ===========>")
        -- --print("FaBaoSuiPianBagUI:InitData ===>", v.m_id, uid, v.m_uid)
        if v.m_id == AppDef.fabaoExpItemID.normal_fbExp and uid ~= v.m_uid then
            table.insert(resutList, v)
            if #resutList >= maxNum then
                return resutList
            end
        end
    end

    --紫经验法宝
    for k,v in pairs(LRoleDataMgr.Pet.faBaoList.m_petFaBaos) do
        --神将碎片
        -- dump(v, "PetBagFragmentSubUI:initData ===========>")
        if v.m_id == AppDef.fabaoExpItemID.mid_fbExp and uid ~= v.m_uid then
            table.insert(resutList, v)
            if #resutList >= maxNum then
                return resutList
            end
        end

    end

    --橙经验法宝
    for k,v in pairs(LRoleDataMgr.Pet.faBaoList.m_petFaBaos) do
        --神将碎片
        -- dump(v, "PetBagFragmentSubUI:initData ===========>")
        if v.m_id == AppDef.fabaoExpItemID.high_fbExp and uid ~= v.m_uid then
            table.insert(resutList, v)
            if #resutList >= maxNum then
                return resutList
            end
        end
    end

    --蓝属性法宝
    for k,v in pairs(LRoleDataMgr.Pet.faBaoList.m_petFaBaos) do
        --神将碎片
        -- dump(v, "PetBagFragmentSubUI:initData ===========>")
        if v.m_id > AppDef.fabaoExpItemID.high_fbExp and v.baseData.quality  == 3  and uid ~= v.m_uid and v.m_fpos < 1 then
            if v.jlLv <= 0 and v.qhLv <= 0 then
                table.insert(resutList, v)
                if #resutList >= maxNum then
                    return resutList
                end
            end
        end
    end

    --紫色属性
    -- for k,v in pairs(LRoleDataMgr.Pet.faBaoList.m_petFaBaos) do
    --     --神将碎片
    --     -- dump(v, "PetBagFragmentSubUI:initData ===========>")
    --     if v.m_id > AppDef.fabaoExpItemID.high_fbExp and v.baseData.quality  == 4  and uid ~= v.m_uid and v.m_fpos < 1 then
    --         table.insert(resutList, v)
    --         if #resutList >= maxNum then
    --             return resutList
    --         end
    --     end
    -- end

    return resutList

end


-----------------------------------------------------------------------

--宠物可激活
function PetkaPaiManager:getPetBookCanActive( pid )
    -- body
    local petData = LRoleDataMgr.Pet:GetPetById(pid)
    if petData ~= nil then
        local book = LRoleDataMgr.m_book.bookStar[pid]
        if book == nil then
            --可激活
            return 3
        else
            local condi = JsonConfig.m_star.getDefByID(book.star+ 1)
            if condi==nil then
                return 0
            end

            if petData.star>=condi.handbook_condition then
                local costData = self:getBookLvUpCost(condi, petData)
                if costData == nil then
                    return 0
                end
                local num = LRoleDataMgr.Equip:CountItemNumById(costData.type)
                if num >= costData.value then
                    return 2
                end
            end
           --可升级
            return 1
        end
    else
        --点亮
        return 0  
    end
    return 0
end

function PetkaPaiManager:getBookLvUpCost(condition, petData)
    -- body
    if condition == nil then
        return nil
    end

    for i=1, #condition.handbook_cost do
        local value = condition.handbook_cost[i]
        if value[1] == petData.baseData.quality then
            local starCost = {}
            starCost.type = value[2]
            starCost.value = value[3]
            return starCost
        end
    end

    return nil

end

function PetkaPaiManager:getPetFragMentCanUpgrade( itemData )
    -- body
    if itemData == nil then
        return 0
    end

    local petID =  self:getPetIdByItem(itemData)
    local petData = JsonConfig.m_heroCfg.getDefByID(petID)
    
    if petData == nil then
        return 0
    end
    local priority = petData.quality

    local num = LRoleDataMgr.Equip:CountItemNumById(itemData.m_id)

    if self:isPetCanHeCheng(itemData) then
        return priority * 1000 + num + 15999
    end

    if self:isPetCanStarUpByItemID(itemData.m_id) then
        return priority * 1000 + num + 8999
    end

    return priority * 1000 + num

end

--宠物可升星
function PetkaPaiManager:getPetBookCanUpgrade( petData )

    if petData.baseData == nil then
        return 0
    end

    local itemData = LRoleDataMgr:GetPItemFromBagById(petData.baseData.itemId)
    local priority = petData.baseData.quality
    if self:isPetCanHeCheng(itemData) then
        return 4 * 7 + priority + 5000
    end

    if self:isPetCanStarUp(petData) then
        return 3 * 7 + priority + 4000
    end

    local showPos = LRoleDataMgr.Pet:GetPetPos(petData.id)
    if  showPos > 0 then
        return 3000 - showPos
    end


    if petData.isFragment then
        return priority
    end

    return priority * 20 + petData.star * 20 + petData.breakLevel * 10 + petData.level
end

function PetkaPaiManager:getPetChangePriority( petData )
    -- body
    if petData == nil or petData.baseData == nil then
        return 0
    end
    local priority = petData.baseData.quality
    return priority * 20 + petData.star * 20 + petData.breakLevel * 10 + petData.level
end


function PetkaPaiManager:getNextPetPos(pos, type)
    local nextPos = 0
    if type == 1 then
        for i=1, 5 do
            nextPos = pos + i
            if nextPos > 5 then
                nextPos = nextPos - 5
            end
            local petId = LRoleDataMgr.Pet.ShowPosList[nextPos]
            if petId > 0 then
                return nextPos
            end
        end
    else
        for i=1, 5 do
            nextPos = pos - i
            if nextPos < 1 then
                nextPos = nextPos + 5
            end
            local petId = LRoleDataMgr.Pet.ShowPosList[nextPos]
            if petId > 0 then
                return nextPos
            end 
        end
    end
    return nextPos
end


function PetkaPaiManager:getFabaoProp(fabaoData)
    if fabaoData == nil then
        return 0
    end

    local priority = fabaoData.baseData.quality * 10 + fabaoData.qhLv * 3 + fabaoData.jlLv * 3

    if fabaoData.m_fpos > 0 then
        return 300 * 2 + priority
    end

    if fabaoData.baseData.equip > 0 then
        return 200 + priority
    end

    return priority
end


function PetkaPaiManager:getNeedExpData( petData, level )
    -- body
    -- self._value --要升的级数
    if level > AppDef.Pet.MaxLevel then
        level = AppDef.Pet.MaxLevel
    end

    local configData = JsonConfig.m_petLvUpExp.getDefByID(petData.level)
    local needExp = configData.exp_hero - petData.exp
    -- --print("getNeedExpData ===>", petData.level, level)
    local addLevel = level - petData.level
    if addLevel < 2 then
        return needExp
    end
    for i= petData.level + 1, level - 1 do
        -- --print("getNeedExpData == 3333333>", i)
        local levelTemp = i
    	local expData = JsonConfig.m_petLvUpExp.getDefByID(levelTemp)
        if expData == nil then
            break
        end
        -- --print("expData.exp_hero ===", expData.exp_hero)
    	needExp = needExp + expData.exp_hero
    end
    -- --print("PetkaPaiManager:getNeedExpData needExp=", needExp)
    return needExp
end


function PetkaPaiManager:GetPetLvGrowAttr(id, star)
    -- body
    if id == nil or star == nil then
        return nil
    end
    local basePetData = LDataConstMgr:GetPetData(id)
    if basePetData == nil then
        return nil
    end


    local starConfig = JsonConfig.m_star.getDefByID(star)
    if starConfig == nil then
        return nil
    end
    local data = {}
    for k,v in pairs(basePetData.growAttrs) do
        if k and v then
            data[k] = math.floor(v * (starConfig.attr_ratio / 10000) + 0.5)
        end
    end
    return data
end


--升星属性加成
function PetkaPaiManager:GetPetStarGrowAttr( PetData )
    -- body
    basePetData = PetData.baseData
    if basePetData == nil then
        return nil
    end

    local data = {}
    if PetData.star >= AppDef.Pet.MaxStar then
        for i=1, AppDef.Pet.MaxStar do
            self:getPetStarGrowAttrByStar(data, PetData, i)
        end
    else
        self:getPetStarGrowAttrByStar(data, PetData, PetData.star + 1)
    end
    return data
end

function PetkaPaiManager:getPetStarGrowAttrByStar( data, PetData, star)
    -- body
    local attr_add = 0
    for i=1, star do
        local starConfig = JsonConfig.m_star.getDefByID(i)
        if starConfig then
            attr_add = attr_add + starConfig.attr_add
        end
    end

    -- --print("GetPetStarGrowAttr ==>", PetData.star, attr_add)

    local curStarConfig = JsonConfig.m_star.getDefByID(star)
    for k,v in pairs(PetData.baseData.growAttrs) do
        if k and v then
            data[k] = math.floor(v * (curStarConfig.attr_ratio / 10000) * PetData.level  + v * attr_add )
        end
    end
end

function PetkaPaiManager:getPetStarUpCost( petData )
    -- body
    -- --print("getPetStarUpCost ===>", petData.star)
    local starConfig = JsonConfig.m_star.getDefByID(petData.star + 1)
    if starConfig == nil then
        return 0
    end
    for i=1, #starConfig.cost do
        local costItem = starConfig.cost[i]
        -- --print("getPetStarUpCost ==>", petData.baseData.quality, costItem[1])
        if petData.baseData.quality == tonumber(costItem[1]) then
            return tonumber(costItem[2])
        end
    end
    return 0
end

function PetkaPaiManager:getPetStarUpCostInfo( petData )
    -- body
    -- --print("getPetStarUpCost ===>", petData.star)
    local starConfig = JsonConfig.m_star.getDefByID(petData.star + 1)
    if starConfig == nil then
        return nil
    end
    for i=1, #starConfig.cost do
        local costItem = starConfig.cost[i]
        -- --print("getPetStarUpCost ==>", petData.baseData.quality, costItem[1])
        if petData.baseData.quality == tonumber(costItem[1]) then
            return costItem
        end
    end
    return nil
end

--宠物的技能等级根据星级得到
function PetkaPaiManager:GetPetSkillLvByStar( star )
    -- body
    local starConfig = JsonConfig.m_star.getDefByID(star)
    if starConfig == nil then
        return 0
    end
    return starConfig.skill_level
end

-------------------------------------------------------------------------------
function PetkaPaiManager:ShowStars(starLayout, star)
    --print("PetkaPaiManager ShowStars ==>", star)
    local panelSize = starLayout:getContentSize()
    local pStarImg = starLayout:getChildByName("Star")
    --重置
    for i=1, AppDef.Pet.MaxStar + 1 do
        local lastStar = starLayout:getChildByTag(i)
        if lastStar then
            starLayout:removeChildByTag(i)
        end
    end
    pStarImg:setVisible(false)
    local size = pStarImg:getContentSize()
    local sizeWith =size.width
    if star>6 then
     sizeWith =size.width-5
    end
    local width = sizeWith*star
    local sx = (panelSize.width - width)/2 + sizeWith/2
    local sy = size.height/2
    for i = 1, star do
        local starImg = pStarImg:clone()
        starImg:setVisible(true)
        starLayout:addChild(starImg)
        starImg:setTag(i)
        starImg:setPosition(cc.p(sx, sy))
        sx = sx + sizeWith
        --print("ShowStars ===>", i)
    end
end

function PetkaPaiManager:ShowStarsVertical(starLayout, star)
    local panelSize = starLayout:getContentSize()
    local pStarImg = starLayout:getChildByName("Star")
    
    --重置
    for i=1, 7 do
        local lastStar = starLayout:getChildByTag(i)
        if lastStar then
            starLayout:removeChildByTag(i)
        end
    end
    pStarImg:setVisible(false)
    local size = pStarImg:getContentSize()
    local sizeHight =size.height
    if star>6 then
     sizeHight =size.height-5
    end
    local height = sizeHight*star
    local sx = panelSize.width / 2
    local sy = panelSize.height
    for i = 1, star do
        local starImg = pStarImg:clone()
        starImg:setVisible(true)
        starLayout:addChild(starImg)
        starImg:setTag(i)
        starImg:setPosition(cc.p(sx, sy))
        -- sx = sx + sizeWith
        sy = sy - sizeHight
    end
end

function PetkaPaiManager:getPetIdByItemId( itemId )
    -- body
    local heroList =  JsonConfig.m_heroCfg.getList()
    if heroList == nil then
        return 0
    end
    for i=1, #heroList do
        if heroList[i].itemId == itemId then
            return heroList[i].id
        end
    end
    return 0
end

function PetkaPaiManager:getPetIdByItem( itemData )
    -- body
    if itemData.m_type ~= AppDef.ItemType.PetFrag then
        return 0
    end
    local hechengConfig =  JsonConfig.GetHeChengCfg(AppDef.ItemType.PetFrag, itemData.m_id)
    if hechengConfig == nil then
        return 0
    end
    return hechengConfig.target[2]
end

function PetkaPaiManager:getHeChengConfigData(id, type)
    -- body
    local heChengList = JsonConfig.m_HeCheng.getList()
    for i=1, #heChengList do
        if heChengList[i].type == type then
            local items = heChengList[i].item
            for j=1, #items do
                local itemData = items[j]
                -- --print("itemData ===>", itemData[1])
                if itemData[1] == id then
                    return heChengList[i]
                end
            end
        end
    end
    return nil
end


function PetkaPaiManager:isPetCanHeCheng( itemData )
    -- body
    if itemData == nil then
        return false
    end
    local hechengConfig = self:getHeChengConfigData(itemData.m_id, AppDef.HeChengType.Cop_Pet)
    -- --print("isPetCanHeCheng = itemData.m_id", itemData.m_id)
    if hechengConfig == nil then
        return false
    end
    local isOwn = LRoleDataMgr.Pet:IsOwnPetById(hechengConfig.target[2])
    return itemData.m_num >= hechengConfig.item[1][3] and not isOwn
end

function PetkaPaiManager:isPetCanStarUp( petData )
    -- body

    if Utils:CheckModelNotOpened(AppDef.EModuleID.EMID_KAPAI_SJSHENGXING, true) then
        return false
    end

    if petData == nil or petData.baseData == nil then
        return false
    end

    if petData.star >= AppDef.Pet.MaxStar then
        return false
    end

    local cost = self:getPetStarUpCost(petData)
    local fragNum = LRoleDataMgr.Equip:CountItemNumById(petData.baseData.itemId)
    --print("isPetCanStarUp cost ==>", cost, fragNum)
    return fragNum >= cost and cost > 0
end


function PetkaPaiManager:isHasPetTianMingJH()
    -- body
    for k,v in pairs(LRoleDataMgr.Pet.petlist) do
        if v.fightPos > 0 then
            local isCanJH = self:isPetCanTianMingJH(v)
            if isCanJH then
                return true
            end
        end
    end
    return false
end

function PetkaPaiManager:isPetCanTianMingJH( petData )
    -- body
    if petData == nil then
        return false
    end
    local xlLv = petData.XLLv + 1
    local xiulian = JsonConfig.m_xiuLianConfig.getDefByID(xlLv)
    if xiulian == nil then
        return false
    end

    --判断材料
    local num = LRoleDataMgr.Equip:CountItemNumById(853)
    if num < xiulian.cost_xiulian[1][3] then
        return false
    end

    --判断是否修炼满
    for i=1, #petData.XLInfo do
        if petData.XLInfo[i] < xiulian.cost_type then
            return false
        end
    end
    return true
end

function PetkaPaiManager:isPetCanStarUpByItemID( itemId )
    -- body
    --通过合成表找petID
    local hechengConfig = JsonConfig.GetHeChengCfg(AppDef.ItemType.PetFrag, itemId)
    if hechengConfig == nil then
        --print("isPetCanStarUpByItemID itemId not exit", itemId)
        return false
    end
    local petId = hechengConfig.target[2]
    local curPet = LRoleDataMgr.Pet:GetPetById(petId)
    if curPet == nil then
        return false
    end
    local isCanStarUp = PetkaPaiManager:isPetCanStarUp(curPet)
    return isCanStarUp
end

function PetkaPaiManager:isPetCanBreakUp( petData )
    -- body

    if Utils:CheckModelNotOpened(AppDef.EModuleID.EMID_KAPAI_SJXIULIAN, true) then
        return false
    end

    if petData == nil then
        return false
    end

    local breakLevel = petData.breakLevel + 1
    if petData.breakLevel >= AppDef.Pet_MaxBreakLv then
        breakLevel = AppDef.Pet_MaxBreakLv
    end

    local breakdata = JsonConfig.m_petBreakCost.getDefByID(breakLevel)
    local moneyCostData
    local itemCostData
    local itemCostType

    self.heroCfg = JsonConfig.m_heroCfg.getDefByID(petData.id)
    self.costList = {}

    local quelityCfg = JsonConfig.m_quality.getDefByID(self.heroCfg.quality)
    local quelityRate = 1
    if quelityCfg ~= nil then
        quelityRate = quelityCfg.break_ratio / 10000
    end

    for i=1, #breakdata.cost do
        local rewardData = breakdata.cost[i]
        local cost = {}
        cost.id = rewardData[1]
        cost.petID = rewardData[2]
        cost.num = rewardData[3]

        if cost.id == AppDef.EMoneyType.EMT_Gold then
            moneyCostData = cost.num * quelityRate
        else
            itemCostData = cost.num * quelityRate
            itemCostType = cost.id
        end
    end

    local myMoney = LRoleDataMgr.MyHeroInfo.DetailData:getMoney()
    if myMoney < moneyCostData then
        return false
    end

    if LRoleDataMgr.Equip:CountItemNumById(itemCostType) < itemCostData then
        return false
    end

    if petData.level < breakdata.level then
        return false
    end

    return true

end

function PetkaPaiManager:getBreakAttrStr( petData )
    -- body
    return self:getBreakAttrStrByLv(petData, petData.breakLevel + 1)
end

function PetkaPaiManager:getBreakAttrStrByLv( petData , breakLv)
    -- body
    local strTips = {
        "",
        GUITips.RSI_ZQX_TUPO_TIANFU6,
        "",
    }

    local heroCfg = JsonConfig.m_heroCfg.getDefByID(petData.id)
    -- --print("getBreakAttrStrByLv ==>", breakLv)
    local breakAttr = heroCfg.breakattr[breakLv]
    -- dump(breakAttr, "getBreakAttrStrByLv ==>")
    local breakStr = GUITips.RSI_ZQX_TUPO_TIANFU1

    if breakAttr == nil then
        return breakStr
    end

    local breakdata = JsonConfig.m_petBreakCost.getDefByID(breakLv)
    local skillLevel = 1
    if breakdata then
        skillLevel = breakdata.level
    end
    for i=1, #breakAttr do
        local attr = {}
        attr.kind = breakAttr[i][1]
        attr.type = breakAttr[i][2]
        attr.value = breakAttr[i][3]
        local str = ""
        if attr.kind == 3 then
            local skillData = LSkillMgr:getSkillById(attr.type)
            str = strTips[attr.kind] .. LDataConstMgr:GetHeroSkillDesc(attr.type,  attr.value)
            str = string.gsub(str, "%[c3%]", "")
            str = string.gsub(str, "%[/c3%]", "")
        else
            local showValue = attr.value
            if attr.type >= 10 then
                showValue = showValue / 100 .. "%"
            end
            str = strTips[attr.kind] .. self:getAttrName(attr.type) .."+".. tostring(showValue)
        end
        
        breakStr = breakStr .. str .. ""
    end

    -- --print("getBreakAttrStrByLv ==>", breakStr)
    return breakStr
end

function PetkaPaiManager:getAttrName(attrType)
    -- body
    local attrConfig = JsonConfig.m_AttrType.getDefByID(attrType)
    return attrConfig.attrName
end

------------------------------------------------------------------------
function PetkaPaiManager:GetCV(petData)
    if petData.cv == nil or string.len(petData.cv) == 0 then
        return ""
    end
    local soundStr = petData.cv
    local arr = string.split(soundStr,"|")
    local num = #arr
    local playFile = arr[math.random(1,num)]
    return playFile
end

function PetkaPaiManager:GetSkillBgm(petData, skillId)
    -- --print("GetSkillBgm",skillId)
    -- dump(petData,"---->petData")
    local ind = 0
    for i = 1, #petData.skills do
        if skillId == petData.skills[i] then
            ind = i
            break
        end
    end
    if ind == 0 then
        return nil
    end
    if ind > #petData.skillBgms then
        return nil
    end
    local soundArr = petData.skillBgms[ind]
    local num = #soundArr
    local soundId = soundArr[math.random(1,num)]
    return soundId
end

function PetkaPaiManager:IsShiny(petData)
    if petData == nil then
        return false
    end
    return petData.initstar > 7
end

function PetkaPaiManager:ShowEquipImg(node, eid, showEquip, showQuality)
    if showEquip == nil then
        showEquip = ItemCellUI:New(node)
        showEquip.m_pUILayer:setAnchorPoint(cc.p(0, 0))
    end
    if eid == 0 then
        showEquip:UpdateItem(nil)
        return
    end
    local info = LRoleDataMgr.Pet.equipList.m_petEquips[eid]
    if info == nil or info.m_id == 0 then
        self.showEquip:UpdateItem(nil)
        return
    end
    local cfg = JsonConfig.m_equipConfig.getDefByID(info.m_id)
    if cfg == nil then
        return
    end
    local itemValue = {
		isShowQualityBg = showQuality
	}
    local petEquipData = {
        id = info.m_id,
        star = info.cultivateLevel[AppDef.PetEquipLevelType.JueXing] or 0,
        qhLv = info.cultivateLevel[AppDef.PetEquipLevelType.QiangHua] or 0,
        jlLv = info.cultivateLevel[AppDef.PetEquipLevelType.JingLian] or 0,
        szLv = info.cultivateLevel[AppDef.PetEquipLevelType.ShenZhu] or 0,
    }
    itemValue.petEquipData = petEquipData
    showEquip:UpdateItem(itemValue)
    return showEquip
end


---------------------抽卡-------------------------------------
function PetkaPaiManager:getObtainDrawShenHun( ... )
    -- body
    if self.m_DrawResult == nil or self.m_DrawResult.mustBeList == nil then
        return 0
    end

    for i=1, #self.m_DrawResult.mustBeList do
        local itemData = self.m_DrawResult.mustBeList[i]
        --if itemData.mustBeType == AppDef.AwrdItem.AWRD_ITEM_SHENPO then
        if itemData[1] == AppDef.AwrdItem.AWRD_ITEM_SHENPO then
            return itemData[3]
        end
    end

    return 0
end

---------------------商城------------------------------------
function PetkaPaiManager:InitShopData(type, data)
    self.m_AllShopData[type] = data
end

--次数更新
function PetkaPaiManager:SetShopCnt(type,itemId,index,cnt)
    if self.m_AllShopData[type] == nil then
        return
    end
    local data = self.m_AllShopData[type]
    if data.itemList == nil then
        return
    end
    for k,v in pairs(data.itemList) do
        if v.index == index then
            local cfg = JsonConfig.m_ShopInfo.getDefByID(v.id)
            if cfg ~= nil and cfg.itemid[1] == itemId then
                v.buyTimes = cnt
            end
        end
    end
    
end

function PetkaPaiManager:getShopConditionIsDone( condition )
    -- body
    --无条件
    -- dump(condition, "----------------------------")
    if condition == nil then
        return true
    end

    for i=1, #condition do
        local con = condition[i]
        local isDone = self:IsShopConditionDone(con)
        if not isDone then
            return false
        end
    end

    return true

end

function PetkaPaiManager:IsShopConditionDone( condition )
    -- dump(condition, "==========================>")
    --print("IsShopConditionDone 111 ==>", condition[1], LRoleDataMgr.m_activityInfo.arenaMaxRank, condition[2])
    if condition[1] == ShopDef.KP_CDNTYPE.LM_LEVEL then
        local level = LRoleDataMgr.MyHeroInfo.level  --声音冲突，等级语音不说
        return level >= condition[2]
    elseif condition[1] == ShopDef.KP_CDNTYPE.LM_VIP then
        local myVipLevel = LRoleDataMgr.MyHeroInfo.vipLevel
        return myVipLevel >= condition[2]
    elseif condition[1] == ShopDef.KP_CDNTYPE.LM_XUEZHAN then
        return LRoleDataMgr.m_activityInfo ~= nil and LRoleDataMgr.m_activityInfo.xzMaxNum >= condition[2]
    elseif condition[1] == ShopDef.KP_CDNTYPE.LM_XUEZHAN_HARD then
        return LRoleDataMgr.m_activityInfo.xzHardModelMaxNum > condition[2]
    elseif condition[1] == ShopDef.KP_CDNTYPE.LM_AC_SCORE then
    elseif condition[1] == ShopDef.KP_CDNTYPE.LM_RANK then
        return LRoleDataMgr.m_activityInfo.arenaMaxRank <= condition[2]
    elseif condition[1] == ShopDef.KP_CDNTYPE.LM_WULIN then
    end
    return false
end

function PetkaPaiManager:getAllShopConditionStr( condition )
    -- body
    if condition == nil then
        -- return GUITips.UI_QiRi_Shop_tips10
        return ""
    end

    local finalResult = ""
    for i=1, #condition do
        local con = condition[i]
        finalResult = finalResult .. self:getPreShopConditionStr(con)
    end

    -- --print("getAllShopConditionStr ===>", finalResult)
    return finalResult
end

function PetkaPaiManager:getPreShopConditionStr( condition )
    -- body
    -- dump(condition, "getPreShopConditionStr ==>")
    if condition[1] == ShopDef.KP_CDNTYPE.LM_LEVEL then
        return string.format(GUITips.UI_QiRi_Shop_tips11, condition[2])
    elseif condition[1] == ShopDef.KP_CDNTYPE.LM_VIP then
        return string.format(GUITips.UI_QiRi_Shop_tips12, condition[2])
    elseif condition[1] == ShopDef.KP_CDNTYPE.LM_XUEZHAN then
        return string.format(GUITips.UI_QiRi_Shop_tips13, condition[2])
    elseif condition[1] == ShopDef.KP_CDNTYPE.LM_XUEZHAN_HARD then
        return string.format(GUITips.UI_QiRi_Shop_tips14, condition[2])
    elseif condition[1] == ShopDef.KP_CDNTYPE.LM_AC_SCORE then
        return string.format(GUITips.UI_QiRi_Shop_tips15, condition[2])
    elseif condition[1] == ShopDef.KP_CDNTYPE.LM_RANK then
        return string.format(GUITips.UI_QiRi_Shop_tips16, condition[2])
    elseif condition[1] == ShopDef.KP_CDNTYPE.LM_WULIN then
        return string.format(GUITips.UI_QiRi_Shop_tips17, condition[2])
    end
end

------------------------------------------------------------------------
--副本相关
function PetkaPaiManager:getFuBenAchievementsData( Achdata )
    -- body
    local curType = Achdata.orderType
    --print("PetkaPaiManager:getFuBenAchievementsData ==>", curType, Achdata.bitMap)
    if curType < 1 then
        return nil
    end
    local achList = JsonConfig.m_mapAchievement.getList()
    local curAchiList = {}
    local index = 0
    for i=1, #achList do
        local data = achList[i]
        if data.type == curType then
            index = index + 1
            data.isFinish = self:getIsAchiAlreadyFinishByBit(Achdata.bitMap, index)
            table.insert(curAchiList, data)
        end
    end
    -- dump(curAchiList, "getFuBenAchievementsData ===>")
    return curAchiList
end

function PetkaPaiManager:getMapNumByType( type )
    -- body
    local list = JsonConfig.m_FuBenMapConfig.getList()
    local result = 0
    for i=1, #list do
        if list[i].MapType == type then
            result = result + 1
        end
    end
    return result
end

function PetkaPaiManager:getIsAchiAlreadyFinishByBit( bitMap, i )
    -- body
    --从第二位开始，服务器定的
    local bitNum = AppDef.BitMapIndex[i + 1]
    --print("getIsAchiAlreadyFinishByBit bitMap", bitMap, bitNum)
    return bit.band(bitMap, bitNum) > 0
end


function PetkaPaiManager:getCurAchievementType( ... )
    -- body
    local achList = JsonConfig.m_mapAchievement.getList()
    for i=1, #achList do
        local data = achList[i]
        local isFinish = self:getIsAchiAlreadyFinish(data.id)
        if not isFinish then
            return data.type
        end
    end
    return 0
end

function PetkaPaiManager:getTaskDataById(id)
    -- body
    local taskgot = LRoleDataMgr.Task:GetTaskTrackData()
    -- dump(taskgot, "getTaskDataById === 111>")
    -- --print("getTaskDataById num ==", #taskgot)

    for k,v in pairs(taskgot) do
        if v.task_id == id  then
            return v
        end
    end

    return nil
end

function PetkaPaiManager:getFinishTaskNum(id)
    -- body
    local taskgot = LRoleDataMgr.Task:GetTaskTrackData()
    -- dump(taskgot, "getTaskDataById === 111>")
    -- --print("getTaskDataById num ==", #taskgot
    local num = 0
    for k,v in pairs(taskgot) do
        local configData = JsonConfig.m_sevendays.getDefByID(v.task_id)
        --5的任务不计入数目，已完成
        if v.state > 1 and configData.type ~= 5 then
            num = num + 1
        end
    end
    return num
end

function PetkaPaiManager:getLastAchievementCondition(type)
    -- body
    if type < 2 then
        return 0
    end

    type = type - 1
    local achList = JsonConfig.m_mapAchievement.getList()
    for i=1, #achList do
        local data = achList[i]
        if data.type > type then
            return achList[i - 1].condition
        end
    end

    return 0

end

function PetkaPaiManager:getPetCanChange( quality )
    -- body
    for k,v in pairs(LRoleDataMgr.Pet.petlist) do
        if v.fightPos <= 0 and v.baseData.quality > quality then
            return true
        end
    end
    return false
end

function PetkaPaiManager:getPetCanLevelUp(pet)

    if Utils:CheckModelNotOpened(AppDef.EModuleID.EMID_KAPAI_SJJINENG, true) then
        return false
    end

    if pet == nil then
        return false
    end
    
    local curPetLv = pet.level
    local mylevel = LRoleDataMgr.MyHeroInfo.level

    if curPetLv >= mylevel then
        return false
    end

    local resultLv = self:getCanToLvByExp(pet, self:getItemMaxExp())
    return  resultLv > 0
end

function PetkaPaiManager:getPetCangeStrengthUp( pet )
    -- body
    if pet == nil then
        return false
    end
    local isCanLvUp = self:getPetCanLevelUp(pet)
    local isPetCanBreakUp = self:isPetCanBreakUp(pet)
    local isPetCanStarUp = self:isPetCanStarUp( pet )
    local isPetCanTianMingJH = self:isPetCanTianMingJH( pet )
    return isCanLvUp or isPetCanStarUp or isPetCanBreakUp or isPetCanTianMingJH
end

function PetkaPaiManager:getPetStrengthUpCost( configData )
    -- body
    if configData == nil then
        return 0
    end
    
    local hechengConfig = JsonConfig.GetHeChengCfg(AppDef.HeChengType.Cop_Pet, configData.itemid[1])

    --神将装备碎片
    if hechengConfig == nil then
        hechengConfig = JsonConfig.GetHeChengCfg(AppDef.HeChengType.Cop_Equip, configData.itemid[1])
    end

    if hechengConfig == nil then
        return 0
    end

    if hechengConfig.target[1] == AppDef.AwrdItem.AWRD_ITEM_PET then
        local PetId = hechengConfig.target[2]
        local petData = LRoleDataMgr.Pet:GetPetById(PetId)
        -- print("getPetStrengthUpCost =========== PetId>", PetId)
        if petData == nil then
            return hechengConfig.item[1][3]
        end
        return self:getPetStarUpCost(petData)
    else
        return hechengConfig.item[1][3]
    end
    return 0
end

function PetkaPaiManager:getXLAttrStr( petData )
    -- body
    if petData == nil then
        return ""
    end
    local xiulian = JsonConfig.m_xiuLianConfig.getDefByID(petData.XLLv)
    if xiulian == nil then
        return ""
    end
    local size = #xiulian.attr
    local addAttrStr = ""
    for i=1, 4 do
        local attrName = Utils:getAttrName(xiulian.attr[i][2])
        addAttrStr = addAttrStr .. attrName .. "、"
    end
    local addStr = "+" .. (xiulian.attr[1][3]/ 100) .. "%"
    addAttrStr = addAttrStr .. addStr
    return addAttrStr
end

function PetkaPaiManager:getXLExtraAttrStr( petData )
    -- body
    if petData == nil then
        return ""
    end
    return self:getXLExtraAttrStr(petData.XLLv)
end

function PetkaPaiManager:getXLExtraAttrStr(xlLv)
    -- body
    local xiulian = JsonConfig.m_xiuLianConfig.getDefByID(xlLv)
    if xiulian == nil then
        return ""
    end
    local size = #xiulian.attr
    if size < 5 then
        return ""
    end
    local attrStr = LDataConstMgr:GetHeroSkillDesc(xiulian.attr[5][2], xiulian.attr[5][3])
    return attrStr
end


function PetkaPaiManager:getMaxXiuLianNum( petData )
    -- body
    if petData == nil then
        return 0
    end

    local xiulian = JsonConfig.m_xiuLianConfig.getDefByID(petData.XLLv + 1)
    if xiulian == nil then
        return 0
    end

    local minNum = LRoleDataMgr.Equip:CountItemNumById(852)

    local leftMaxNum = 0
    for i=1, #petData.XLInfo do
        local num = xiulian.cost_type - petData.XLInfo[i]
        leftMaxNum = num + leftMaxNum
    end

    if leftMaxNum < minNum then
        minNum = leftMaxNum
    end

    return minNum
end

function PetkaPaiManager:CreatEffect(parent, name, time, func)
    local bgAnim = "res2/animation/"..name
    local _pBgAni = ImodAnim:create()
    _pBgAni:initAnimWithNameSync(bgAnim)
    _pBgAni:PlayAction(0, time)
    _pBgAni:setScale(1)
    parent:addChild(_pBgAni)
    performWithDelay(AppDef.CurScene, function()
        _pBgAni:removeFromParent()
        func()
    end, time)
        
    return _pBgAni
  
end

return PetkaPaiManager:Awake()