

--------------------------------------------------------------------------
--- LCItem - 物品基本配置属性
--------------------------------------------------------------------------

LCItem = {}
LCItem.__index = LCItem
function LCItem:New(id )
	local o = {}
	setmetatable(o,LCItem )	
	o:ctor(id )
	return o
end

function LCItem:ctor(id )
	self.m_id = id or 0
	self.m_type = 0
	self.m_level = 0
	self.m_pic = 0
	self.m_sex = 0
    self.m_quality = 0
    self.m_priority = 0
    self.m_pos = 0 --装备用:部位（从1开始）
	self.additionalValue = 0--额外参数(原来的耐久字段)
    self.m_price = 0
	self.m_name = ""
	self.m_desc = ""
	self.m_from = ""
    self.m_baseAttrTypes = {}
    self.m_baseAttrValues = {}
    self.m_sell = 0
end

function LCItem:Delete(id )
	self.m_id = nil
	self.m_type = nil
	self.m_level = nil
	self.m_pic = nil
	self.m_sex = nil
    self.m_quality = nil
	self.m_priority = nil
    self.m_pos = nil
    self.additionalValue = nil
    self.m_price = nil
	self.m_name = nil
	self.m_desc = nil
	self.m_from = nil
    self.m_baseAttrTypes = nil
    self.m_baseAttrValues = nil
    self.m_sell = nil
end

function LCItem:copy(it )
	self.m_id = it.m_id
	self.m_name = it.m_name
	self.m_priority = it.m_priority
end

--function LCItem:isOK( )
--	return self.m_ok
--end

--[[
是否装备
]]
-- function LCItem:IsEquip()
--     local typeLabel = {}
--     for i=1,6 do
--         local key = AppDef.EItemType["EIT_WuQi_"..i]
--         typeLabel[key] = 1
--         key = AppDef.EItemType["EITTouKui"..i]
--         typeLabel[key] = 1
--         key = AppDef.EItemType["EITKuiJia_"..i]
--         typeLabel[key] = 1
--         key = AppDef.EItemType["EITYaoDai_"..i]
--         typeLabel[key] = 1
--         key = AppDef.EItemType["EITXieZi_"..i]
--         typeLabel[key] = 1
--         key = AppDef.EItemType["EITXiangLian_"..i]
--         typeLabel[key] = 1
--         key = AppDef.EItemType["EITHuWan_"..i]
--         typeLabel[key] = 1
--         key = AppDef.EItemType["EITJieZhi_"..i]
--         typeLabel[key] = 1
--     end
-- 	return (self.m_id > 0) and ( typeLabel[self.m_type] == 1)
-- end

--[[
是否装备
]]
--现在没有装备物品了
function LCItem:IsEquip()
	return false
end

function LCItem:Getm_id( ) return self.m_id  end
function LCItem:Getm_type( ) return self.m_type  end
function LCItem:Getm_level( ) return self.m_level  end
function LCItem:Getm_pic( ) return self.m_pic  end
function LCItem:Getm_sex( )   return  self.m_sex  end
--function LCItem:GetAttack( )   return self.attack  end               --攻击
--function LCItem:GetRecovery( )   return self.recovery  end           --防御
--function LCItem:GetAddHp( )   return self.addHp end             --气血
function LCItem:Getm_name( ) return self.m_name  end
function LCItem:Getm_desc( ) return self.m_desc  end
function LCItem:Getm_from( )   return self.m_from  end
--function LCItem:Getm_ok( )   return self.m_ok end              --收到了相关信息
--function LCItem:GetNeedRemake( )   return needRemake  end


function LCItem:Setm_id(value_ ) self.m_id = value_  end
function LCItem:Setm_level(value_ ) self.m_level = value_  end
function LCItem:Setm_type(value_ ) self.m_type = value_  end
function LCItem:Setm_pic(value_ ) self.m_pic = value_  end
function LCItem:Setm_name(value_ ) self.m_name = value_  end
function LCItem:Setm_desc(value_ ) self.m_desc = value_  end

	


LPItem = {}
LPItem.__index = LPItem

function LPItem:New(id )
	local o = {}
	setmetatable(o,LPItem )	
	o:ctor(id )
	return o
end

function LPItem:ctor(id )
	self.m_pos = 0--位置(在背包、装备栏中位置)
	self.m_type = 0--物品类型(EItemType )
	self.m_id = id or 0          --物品id              
	self.m_num = 0                          --堆叠数量
	
	self.m_locked = false                       --是否锁定
	self.m_roleLevel = 0                    --角色等级需求
	self.m_qhLevel = 0                      --强化等级(当前 )
	self.m_quality = 0	                    --品质分数(0-8 

	--淬炼属性加成
    self.addCuiLianAttrNum = 0							   --附加属性数量
    self.addCuiLianAttrType = {}--附加属性类型
    self.addCuiLianAttrVal = {}--附加属性值
    self.addCuiLianAttrStar = {} --附加属性星级

	--洗炼属性

	self.addXiLianAttrNum = 0--附加属性数量
	self.addXiLianAttrType = {}--附加属性类型
	self.addXiLianAttrVal = {}--附加属性值
    self.addXiLianAttrStar = {} --附加属性星级
	self.addSaveXiLianAttrType = {}--附加属性类型
	self.addSaveXiLianAttrVal = {}--附加属性值	
    self.addSaveXiLianAttrStar = {} --附加属性星级

	--综合属性（需要计算）
    self.totalAttrType = {}
    self.totalAttrValue = {}

	self.m_price = 0                        --价格
    self.m_priceType = 1                    --价格类型(1-金币 2-元宝 )
	
    --self.m_openKong = 0                     --空是否开启状态(32位-每位代表一个孔是否开启 )
	self.m_name = ""                         --名称
	self.m_mod = 0	                        --模式
	--self.m_kong = {0,0,0}                      --镶嵌3个额外孔的状态
	self.m_item = nil                         --物品基础信息指针
	if self.m_id > 0 then
		self.m_item = LItemMgr:getItem(self.m_id)
	end

	self.m_targetPos = 0   --藏宝图挖宝的目的地, ÷100 是地图ID, %100是坐标ID
end

function LPItem:Delete( )
	self.m_pos = nil
	self.m_type = nil                       --物品类型(EItemType )
	self.m_id = nil
	self.m_num = nil                          --堆叠数量
	
	self.m_locked = nil                       --是否锁定
	self.m_roleLevel = nil                    --角色等级需求
	self.m_qhLevel = nil                      --强化等级(当前 )
	self.m_quality = nil	                    --品质分数(nil-8 )
	
	--淬炼属性加成
    self.addCuiLianAttrNum = nil							   --附加属性数量
    self.addCuiLianAttrType = nil--附加属性类型
    self.addCuiLianAttrVal = nil--附加属性值
    self.addCuiLianAttrStar = nil

	--洗炼属性

	self.addXiLianAttrNum = nil--附加属性数量
	self.addXiLianAttrType = nil--附加属性类型
	self.addXiLianAttrVal = nil--附加属性值
    self.addXiLianAttrStar = nil
	self.addSaveXiLianAttrType = nil--附加属性类型
	self.addSaveXiLianAttrVal = nil--附加属性值	
    self.addSaveXiLianAttrStar = nil
	
    self.totalAttrType = nil
    self.totalAttrValue = nil

	self.m_price = nil                        --价格
    self.m_priceType = nil                   --价格类型(1-金币 2-元宝 )
	
    --self.m_openKong = nil                     --空是否开启状态(32位-每位代表一个孔是否开启 )
	self.m_name = nil                          --名称
	self.m_mod = nil	                        --模式
	--self.m_kong = nil                 --镶嵌3个额外孔的状态
	self.m_item = nil                         --物品基础信息指针
	self.m_targetPos = nil
end

function LPItem:clearData( )
	self.m_id = 0
	self.m_item = nil
end

function LPItem:getID( ) 
	return self.m_id
end

--[[
是否装备
]]
function LPItem:IsEquip( )
	if self.m_id <= 0 then
        return false
    end
	return LItemMgr:IsEquip(self.m_type)
end


	--tolua
function LPItem:Getm_pos( ) return self.m_pos end
function LPItem:Getm_type( ) return self.m_type end
function LPItem:Getm_id( ) return self.m_id end
function LPItem:Getm_num( ) return self.m_num end
function LPItem:Getm_locked( ) return self.m_locked end
function LPItem:Getm_roleLevel( ) return self.m_roleLevel end
function LPItem:Getm_qhLevel( ) return self.m_qhLevel end
--function LPItem:Getm_class( ) return self.m_class end
function LPItem:Getm_quality( ) return self.m_quality end
--function LPItem:Getm_bangding( ) return self.m_bangding end
--function LPItem:GetreqAttrType( ) return self.reqAttrType end
--function LPItem:GetreqAttrVal( ) return self.reqAttrVal end

--function LPItem:Getm_attack( )   return self.m_attack end                 --基础攻击值
--function LPItem:Getm_naijiu( )   return self.m_naijiu end                 --耐久度
--function LPItem:Getm_fangyu( )   return self.m_fangyu end                     --防御
--function LPItem:Getm_addQiXue( )   return self.m_addQiXue end                    --增加气血
--function LPItem:Getm_addFaLi( )   return self.m_addFaLi end                     --增加法力
--function LPItem:Getm_addSpeed( )   return self.m_addSpeed end                    --增加速度
function LPItem:Getm_price( )   return self.m_price end                       --价格
function LPItem:Getm_priceType( )   return self.m_priceType end                   --价格类型(1-金币 2-元宝 )

--淬炼属性加成
function LPItem:Get_addCuiLianAttrNum( )   return self.addCuiLianAttrNum end					   --附加属性数量
function LPItem:Get_addCuiLianAttrTypeByIdx(idx )   return self.addCuiLianAttrType[idx] end     --附加属性类型
function LPItem:Get_addCuiLianAttrValByIdx(idx )   return self.addCuiLianAttrVal[idx] end      --附加属性值
function LPItem:Get_addCuiLianAttrStarByIdx(idx )   return self.addCuiLianAttrStar[idx] end      --附加属性值

--洗炼属性
function LPItem:Get_addXiLianAttrNum( )   return self.addXiLianAttrNum end					--附加属性数量
function LPItem:Get_addXiLianAttrTypeByIdx(idx )   return self.addXiLianAttrType[idx] end		--附加属性类型
function LPItem:Get_addXiLianAttrValByIdx(idx )   return self.addXiLianAttrVal[idx] end		--附加属性值
function LPItem:Get_addSaveXiLianAttrType(idx )   return self.addSaveXiLianAttrType[idx] end	--附加属性类型
function LPItem:Get_addSaveXiLianAttrVal(idx )   return self.addSaveXiLianAttrVal[idx] end	--附加属性值



--set
function LPItem:Setm_pos(value_ )  self.m_pos = value_ end
function LPItem:Setm_id(value_ )  self.m_id = value_ end
function LPItem:Setm_num(value_ )  self.m_num = value_ end	
function LPItem:Setm_locked(value_ )  self.m_locked = value_ end
function LPItem:Setm_roleLevel(value_ )  self.m_roleLevel = value_ end
function LPItem:Setm_qhLevel(value_ )  self.m_qhLevel = value_ end
--function LPItem:Setm_class(value_ )  self.m_class = value_ end
function LPItem:Setm_quality(value_ )  self.m_quality = value_ end
--function LPItem:Setm_bangding(value_ )  self.m_bangding = value_ end	
--function LPItem:SetreqAttrType(value_ )  self.reqAttrType = value_ end
--function LPItem:SetreqAttrVal(value_ )  self.reqAttrVal = value_ end

--function LPItem:Setm_attack(value )   self.m_attack = value end                      --基础攻击值
--function LPItem:Setm_naijiu(value )    self.m_naijiu = value end                        --耐久度
--function LPItem:Setm_fangyu(value )   self.m_fangyu = value end                         --防御
--function LPItem:Setm_addQiXue(value )   self.m_addQiXue = value end                       --增加气血
--function LPItem:Setm_addFaLi(value )   self.m_addFaLi = value end                       --增加法力
--function LPItem:Setm_addSpeed(value )   self.m_addSpeed = value end                       --增加速度


function LPItem:Getm_item( ) return self.m_item end
function LPItem:Setm_item(value_ ) self.m_item = value_ end
function LPItem:Setm_type(value_ ) self.m_type = value_ end
function LPItem:GetIntNum( )   return self.m_num end

LFootItem = {}
LFootItem.__index = LFootItem
function LFootItem:New()
	local o = {}
	setmetatable(o,LFootItem )	
	o:Init(id )
	return o
end

function LFootItem:Init()
	self.id = 0
	self.name = ""
	self.desc = ""
	self.buyType = 0
	self.price = 0
	self.isBuy = 0
	self.time = 0
	self.isEquip = 0
end

function LFootItem:Delete()
	self.id = nil
	self.name = nil
	self.desc = nil
	self.buyType = nil
	self.price = nil
	self.isBuy = nil
	self.time = nil
	self.isEquip = nil
end

--升级缺少物品结构
LUpgradeLackItem = {}
LUpgradeLackItem.__index = LUpgradeLackItem
function LUpgradeLackItem:New()
	local o = {}
	setmetatable(o,LUpgradeLackItem )	
	o:Init(id )
	return o
end

function LUpgradeLackItem:Init()
	self.id = 0
	self.name = ""
	self.num = 0
	self.price = 0
	self.costType = 1
	self.quality = 0
end

function LUpgradeLackItem:Delete()
	self.id = nil
	self.name = nil
	self.num = nil
	self.price = nil
	self.costType = nil
	self.quality = nil
end


LCEquipStrengthen = {}
LCEquipStrengthen.__index = LCEquipStrengthen
function LCEquipStrengthen:New()
	local o = {}
	setmetatable(o,LCEquipStrengthen )	
	o:Init(id )
	return o
end

function LCEquipStrengthen:Init()
	self.m_type = 0
	self.m_level = 0
	self.m_attrTypes = {}
    self.m_attrValues = {}
end

LCEquipStrengthenCost = {}
LCEquipStrengthenCost.__index = LCEquipStrengthenCost
function LCEquipStrengthenCost:New()
	local o = {}
	setmetatable(o,LCEquipStrengthenCost )	
	o:Init(id )
	return o
end

function LCEquipStrengthenCost:Init()
	self.m_pos = 0
	self.m_level = 0
	self.m_itemId = 0
    self.m_itemNum = 0
    self.m_moneyType = 0
    self.m_moneyValue = 0
    self.m_baseRatio = 0   --基础成功率
    self.m_itemRatio = {}   --幸运符加成成功率
end

LCEquipUpgrade = {}
LCEquipUpgrade.__index = LCEquipUpgrade
function LCEquipUpgrade:New()
	local o = {}
	setmetatable(o,LCEquipUpgrade )	
	o:Init(id )
	return o
end

function LCEquipUpgrade:Init()
	self.m_pos = 0
	self.m_level = 0
	self.m_itemId = 0
    self.m_itemNum = 0
    self.m_moneyType = 0
    self.m_moneyValue = 0
end

--淬炼
LCEquipCuiLian = {}
LCEquipCuiLian.__index = LCEquipCuiLian
function LCEquipCuiLian:New()
	local o = {}
	setmetatable(o,LCEquipCuiLian )	
	o:Init(id )
	return o
end

function LCEquipCuiLian:Init()
	self.m_itemType = 0
	self.m_level = {}
	self.m_attrType = {}
    self.m_attrMaxVal = {}
end

--[[
合成数据结构
]]
LItemCpdData = {}
LItemCpdData = {}
LItemCpdData.__index = LItemCpdData
function LItemCpdData:New()
	local o = {}
	setmetatable(o,LItemCpdData)	
	o:ctor()
	return o
end

function LItemCpdData:ctor()
	self.type = 0--类型，1合成道具2合成宠物神将
	self.itemId = 0--需求的道具id
	self.itemNum = 0--需求的道具id数量
	self.targetId = 0--合成出来的id，可能是道具id，宠物id+60002
	self.petId = 0--合成出来的宠物id
	self.petStarLv = 0--合成出来的宠物星级
	self.petLv = 0--合成出来的宠物等级
end
function LItemCpdData:Delete()
	self.type = nil--类型，1合成道具2合成宠物神将
	self.itemId = nil--需求的道具id
	self.itemNum = nil--需求的道具id数量
	self.targetId = nil--合成出来的id，可能是道具id也可能是宠物id
	self.petId = nil
	self.petStarLv = nil--合成出来的宠物星级
	self.petLv = nil--合成出来的宠物等级
end

--[[
飞入背包道具数据结构
]]
LFlyItem = {}
LFlyItem.__index = LFlyItem
LFlyItem.FlyType = {
	Money = 2,
	Item = 3,
	Qianneng = 4,
	XinXiuJingHua = 5,
}
function LFlyItem:New(ftype, value)
	local o = {}
	ftype = ftype or 0
	value = value or 0
	setmetatable(o,LFlyItem)	
	o:Init(ftype, value)
	return o
end

function LFlyItem:Init(ftype, value)
	self.flyType = ftype
	self.flyValue = value
end

function LFlyItem:Delete()
	self.flyType = nil
	self.flyValue = nil
end

LItemMgr= {}
LItemMgr.__index = LItemMgr
function LItemMgr:getItem(id)
    return JsonConfig.m_Item.getDefByID(id)
end

function LItemMgr:findItem(id )
    --二分法查找数据
    local vecItems = LDataConstMgr:GetItemList( )
    local ItemCount = #vecItems
    local MaxItemCount = LDataConstMgr:GetItemMaxNum( )
	local  min = 1
	local  max = ItemCount
	local  ntry
	
    if MaxItemCount == 0 then
		return 0
	end

    while (true )
    do
		ntry = math.floor((max + min ) / 2 )

		if id == vecItems[ntry].m_id then
			return ntry
		end
		
        if min == max then
			return 0
		end
		
        if id < vecItems[ntry].m_id then
			if ntry == min then
				return 0
			end
			max = ntry - 1
		else
			if ntry == max then
				return -0
			end
			min = ntry + 1
		end
	end
	return 0
end

function LItemMgr:GetItemPicFileName(itemId )
    local cItem = self:getItem(itemId )
    if cItem == nil then
    	return "item/equip99999.png"
    else
    	return "item/equip" .. cItem.m_pic .. ".png"
    end
end

function LItemMgr:IsItemCanPile1(itemId )
    local pItem = self:getItem(itemId )
    if pItem == nil then
        return false
    end

    if pItem.m_type == 14 or pItem.m_type == 16 then
        return true
    end
    if pItem.m_type == 13 then
        return true
    end
    if pItem.m_type == 19 then
        if ItemMgr:IsBattleBloodItem(itemId) == true or itemId == 1805 or itemId == 1809 or itemId == 1815 then
            return false
        end
        if itemId == 1822 or itemId == 1823 or itemId == 1824 or itemId == 1825 then
            return false
        end
        if itemId == 1827 or itemId == 1828 or itemId == 1829 then
            return false
        end
        return true
    end
    return false
end

function LItemMgr:IsItemCanPile2(p1, p2 )
    if p2.m_id ~= p1.m_id then
        return false
    end
    if p2.m_num >= AppDef.PItem.MAX_CAN_STACK then
        return false
    end
    if p2.m_bangding ~= p1.m_bangding then
        return true
    end

    if p2.m_id == 611 then -- 炼化石
        if p1.m_qhLevel ~= p2.m_qhLevel then
            return false
        end
    elseif p2.m_id == 615 then -- 蓝水晶
        if p1.addCuiLianAttrNum ~= p2.addCuiLianAttrNum then
            return false
        end
        if p2.addCuiLianAttrNum == 0 then
            return true
        end
        if p1.addCuiLianAttrType[1] ~= p2.addCuiLianAttrType[1]	or p1.addCuiLianAttrVal[1] ~= p2.addCuiLianAttrVal[1] then
            return false
        end
    end
    return true
end

--战斗力计算
--@param it PItem
function LItemMgr:CalcFTP(it)
	it.totalAttrType = {}
    it.totalAttrVaule = {}
    --基础属性
    if it.m_item ~= nil then
        for i=1,#it.m_item.m_baseAttrTypes do
            table.insert(it.totalAttrType,it.m_item.m_baseAttrTypes[i])
            table.insert(it.totalAttrVaule,it.m_item.m_baseAttrValues[i])
        end
    end
    --强化属性
    local dStrengthen = LDataConstMgr:GetEquipStrengthenData(it.m_type,it.m_qhLevel)
    if dStrengthen ~= nil then
        for i=1,#dStrengthen.m_attrTypes do
            table.insert(it.totalAttrType,dStrengthen.m_attrTypes[i])
            table.insert(it.totalAttrVaule,dStrengthen.m_attrValues[i])
        end
    end
    --淬炼属性
    for i=1,it.addCuiLianAttrNum do
        table.insert(it.totalAttrType,it.addCuiLianAttrType[i])
        table.insert(it.totalAttrVaule,it.addCuiLianAttrVal[i])
    end
    --洗炼属性
    for i=1,it.addXiLianAttrNum do
        table.insert(it.totalAttrType,it.addXiLianAttrType[i])
        table.insert(it.totalAttrVaule,it.addXiLianAttrVal[i])
    end
    return LDataConstMgr:GetAttrPower(it.totalAttrType,it.totalAttrVaule)
end

--道具基础战斗力计算
--@param it CItem
function LItemMgr:CalcCItemFTP(it)
	if it == nil then return 0 end
    local totalAttrType = {}
    local totalAttrVaule = {}
    --基础属性
    for i=1,#it.m_baseAttrTypes do
        table.insert(totalAttrType,it.m_baseAttrTypes[i])
        table.insert(totalAttrVaule,it.m_baseAttrValues[i])
    end
 
    return LDataConstMgr:GetAttrPower(totalAttrType,totalAttrVaule)
end

--战斗力计算-装备强化
--@param it PItem
function LItemMgr:CalcEquipStrengthenFTP(it)
	if it == nil or it.m_item == nil or not self:IsEquip(it.m_type) then 
       return 0
    end
    it.totalAttrType = {}
    it.totalAttrVaule = {}
    --基础属性
    if it.m_item ~= nil then
        for i=1,#it.m_item.m_baseAttrTypes do
            table.insert(it.totalAttrType,it.m_item.m_baseAttrTypes[i])
            table.insert(it.totalAttrVaule,it.m_item.m_baseAttrValues[i])
        end
    end
    --强化属性
    local dStrengthen = LDataConstMgr:GetEquipStrengthenData(it.m_type,it.m_qhLevel)
    if dStrengthen ~= nil then
        for i=1,#dStrengthen.m_attrTypes do
            table.insert(it.totalAttrType,dStrengthen.m_attrTypes[i])
            table.insert(it.totalAttrVaule,dStrengthen.m_attrValues[i])
        end
    end
    return LDataConstMgr:GetAttrPower(it.totalAttrType,it.totalAttrVaule)
end

--获取强化属性
function LItemMgr:GetQiangHuaVal(level, itemType,attrType)
  
    if not self:IsEquip(itemType) then
        return 0
    end

    if level == 0 then
        return 0
    end

    if level > AppDef.MAX_EQUIP_STRENGTH_LEVEL then
        level = AppDef.MAX_EQUIP_STRENGTH_LEVEL
    end
    local dStrengthen = LDataConstMgr:GetEquipStrengthenData(itemType,level)
    if dStrengthen == nil then
        return 0
    end
    for i = 1,#dStrengthen.m_attrTypes do
        if dStrengthen.m_attrTypes[i] == attrType then
            return dStrengthen.m_attrValues[i]
        end
    end
    return 0
end

function LItemMgr:IsGreenItem(itemType)
	return false
end

function LItemMgr:IsWeapon(itemType)
    local WeaponAttr =
    {
        AppDef.EquipAttr.EA_LILIANG, AppDef.EquipAttr.EA_LINGLI, AppDef.EquipAttr.EA_SHANGHAI, AppDef.EquipAttr.EA_MINGZHONG, AppDef.EquipAttr.EA_LIANJI,
        AppDef.EquipAttr.EA_BAOJI, AppDef.EquipAttr.EA_FANJI, AppDef.EquipAttr.EA_SXJT, AppDef.EquipAttr.EA_CXJT, AppDef.EquipAttr.EA_DXJT,
        AppDef.EquipAttr.EA_QXJT, AppDef.EquipAttr.EA_LJQH, AppDef.EquipAttr.EA_BJQH, AppDef.EquipAttr.EA_FJQH, AppDef.EquipAttr.EA_QSX1
    }
    local num = math.floor(#WeaponAttr/WeaponAttr[1])
    for i = 1, num do
        if WeaponAttr[i] == itemType then
            return true
        end
    end
    return false
end

function LItemMgr:IsCompoundItem(ID)
    local data = LDataConstMgr:GetItemCpdData(ID)
    if data == nil or data.type ~= 1 then 
        return false 
    end
    return true
end

function LItemMgr:IsResolveItem(ID)
    local data = LDataConstMgr:GetResolveData(ID)
    if data == nil or data.type ~= 3 then 
        return false 
    end
    return true
end

function LItemMgr:GetCompoundItemNum(ID)
    local data = LDataConstMgr:GetItemCpdData(ID)
    if data == nil or data.type ~= 1 then 
        return 0 
    end
    return data.itemNum
end

function LItemMgr:GetCompoundItemTargetId(ID)
    local data = LDataConstMgr:GetItemCpdData(ID)
    if data == nil or data.type ~= 1 then 
        return 0 
    end
    return data.targetId
end

function LItemMgr:IsCanTradeItem(it)
    -- if it.m_id ~= 0 and it.m_bangding == 0 and it.m_type ~= 17 and it.m_type ~= 18 and it.m_type ~= 23 then
    --     return false
    -- end
    -- return false
    return false
end

function LItemMgr:DecideItemClassColor(itemClass)
    if itemClass == 0 then
        return ccColor3B(255,255,255)
    elseif itemClass == 1 then
        return ccColor3B(0,150,255)
    elseif itemClass == 2 then
        return ccColor3B(0,192,18)
    else
        return ccColor3B(255,0,234)
    end
end

-- ItemInfoDialog* ItemMgr::ShowItemInfoLayer(int itemId,PItem& item,CCPoint pos,CCNode* target,int Priority,int zorder then
-- {
--     CItem *citem = ITEM_MGR->getItem(itemId then;
--     if (citem == NULL then
--         return NULL;

--     item.m_id = itemId;
--     item.m_item = citem;
--     item.m_type = citem->m_type;
--     ItemInfoDialog *ItemLayer = ItemInfoDialog::create( then;
--     ItemLayer->setPriority(Priority then;
-- 	ObjectHelper::adaptPosToUIByOffset(ItemLayer,pos then;
--     ItemLayer->reLoadData(item,-1,IDI_NoOption then;
--     target->addChild(ItemLayer,zorder then;

--     return ItemLayer;
-- }

function LItemMgr:IsEquip(itemType)
 --    local typeLabel = {}
 --    for i=1,6 do
 --        local key = AppDef.EItemType["EIT_WuQi_"..i]
 --        typeLabel[key] = 1
 --        key = AppDef.EItemType["EITTouKui_"..i]
 --        typeLabel[key] = 1
 --        key = AppDef.EItemType["EITKuiJia_"..i]
 --        typeLabel[key] = 1
 --        key = AppDef.EItemType["EITYaoDai_"..i]
 --        typeLabel[key] = 1
 --        key = AppDef.EItemType["EITXieZi_"..i]
 --        typeLabel[key] = 1
 --        key = AppDef.EItemType["EITXiangLian_"..i]
 --        typeLabel[key] = 1
 --        key = AppDef.EItemType["EITHuWan_"..i]
 --        typeLabel[key] = 1
 --        key = AppDef.EItemType["EITJieZhi_"..i]
 --        typeLabel[key] = 1
 --    end
	-- return (typeLabel[itemType] ~= nil) and ( typeLabel[itemType] == 1)
    return false
end

function LItemMgr:CanUse(id)
    local cfg = self:getItem(id)
    if cfg == nil or cfg.use_type == 0 then
        return false
    end
    return true
end

function LItemMgr:CanDiscard(Item)
    if self:IsEquip(Item.m_type) then
        return false
    end
    return true
end

function LItemMgr:NewResetBagItem()
	LuaNetSendMsg:QuerySortPackage()
end

function LItemMgr:sortItemList()
	--堆叠背包物品
	-- local packageList = LRoleDataMgr.Equip.PackageList
	-- local openPackageNum = LRoleDataMgr:GetPacSize()
	-- local pi
	-- local pother
	-- local item

	-- for i = 1,openPackageNum do
	-- 	pi = packageList[i]
	-- 	for j=i+1,openPackageNum do
	-- 		pother = packageList[j]
	-- 		if self:isNeedSwapItem(pi,pother) then
	-- 			item = packageList[i]
	-- 			packageList[i] = packageList[j]
	-- 			packageList[j] = item
	-- 			pi = packageList[i]
	-- 		end
	-- 	end
	-- end
end

function LItemMgr:isNeedSwapItem(pItem1,pItem2)
	if pItem1 == nil and pItem2 == nil then
		return false
	end
	if pItem1 ~= nil and pItem2 == nil then
		return false
	end

	if pItem1 == nil and pItem2 ~= nil then
		return true
	end

	if pItem1.m_id == 0 and pItem2.m_id > 0  then
		return true
	end
	if pItem1.m_id == 0 and pItem2.m_id == 0 then
		return false
	end
	if pItem1.m_id > 0 and pItem2.m_id == 0 then
		return false
	end
	if pItem1.m_id > 0 and pItem2.m_id > 0 then
		if pItem1.Getm_item().m_priority > pItem2.Getm_item().m_priority then
			return true
		elseif pItem1.Getm_item().m_priority == pItem2.Getm_item().m_priority then
			if pItem1.Getm_item():Getm_id() > pItem2.Getm_item():Getm_id() then
				return true
			else
				return false
			end
		else
			return false
		end
	end
	return false
end

function LItemMgr:isNeedShowInputNumDialog(itemId)
    local cfg = self:getItem(itemId)
    if cfg == nil or cfg.use_type ~= 2 then
		return false
	end
	return true
end

--[[
是否是坐骑强化宝石
]]
function LItemMgr:IsHorseStrengthStone(itemId)
	for i = 1, #AppDef.Mount.EnforceStoneIds do
		if itemId == AppDef.Mount.EnforceStoneIds[i] then
			return true
		end
	end
	return false
end

--[[
获取坐骑强化宝石对应的经验
]]
function LItemMgr:GetHorseStrengthStoneExp(itemId)
	-- for i = 1, #AppDef.Mount.EnforceStoneIds do
	-- 	if itemId == AppDef.Mount.EnforceStoneIds[i] then
	-- 		return AppDef.Mount.EnforceStoneIdToMoneys[i]
	-- 	end
	-- end
	--坐骑强化不要钱了
	return 0
end

--[[
是否是装备强化石
]]
function LItemMgr:IsQiangHuaStone(itemId)
	for i = 1, #AppDef.Mount.EnforceStoneIds do
		if itemId == AppDef.Mount.EnforceStoneIds[i] then
			return true
		end
	end
	return false
end

--[[
是否是礼盒
]]
function LItemMgr:IsGiftBox(itemId)
	--if itemId == 1100 or itemId == 1105 or itemId == 2497 or itemId == 2498 then
    if itemId == 2497 or itemId == 2498 then
        return true
    end
	return false
end
