LBaseAttr = {}
LBaseAttr.__index = LBaseAttr
function LBaseAttr:New()
	local o = {}
	setmetatable(o,LBaseAttr)	
	o:ctor()
	return o
end

function LBaseAttr:ctor()
	self.id = 0--id
	self.value = 0--属性值
	self.valueType = 0--取值类型
end

function LBaseAttr:Copy()
	local attrs = LBaseAttr:New()
	attrs.id = self.id--id
	attrs.value = self.value--属性值
	attrs.valueType = self.valueType--取值类型
	return attrs
end

--[[
炼化属性生成条目结构
]]
LBaseEquipRefineAttrNum = {}
LBaseEquipRefineAttrNum.__index = LBaseEquipRefineAttrNum
function LBaseEquipRefineAttrNum:New()
	local o = {}
	setmetatable(o,LBaseEquipRefineAttrNum)	
	o:ctor()
	return o
end

function LBaseEquipRefineAttrNum:ctor()
	self.num = 0--数量
	self.weight = 0--权重
end

--[[
炼化属性生成结构
]]
LBaseEquipRefineAttr = {}
LBaseEquipRefineAttr.__index = LBaseEquipRefineAttr
function LBaseEquipRefineAttr:New()
	local o = {}
	setmetatable(o,LBaseEquipRefineAttr)	
	o:ctor()
	return o
end

function LBaseEquipRefineAttr:ctor()
	self.id = 0 --属性id
    self.minV = 0
    self.maxV = 0
    
    --取值数类型：1=整数，2=小数点后1位小数，带%
    self.valueType = 0

    --可重复数量
    self.repeatNum = 0
    
    --权重
    self.weight = 0
end

--[[
装备特技生成结构
]]
LBaseEquipSkill = {}
LBaseEquipSkill.__index = LBaseEquipSkill
function LBaseEquipSkill:New()
	local o = {}
	setmetatable(o,LBaseEquipSkill)	
	o:ctor()
	return o
end

function LBaseEquipSkill:ctor()
	self.id = 0 --技能id
    --权重
    self.weight = 0
end

LItemResData = {}
LItemResData.__index = LItemResData
LBItemType = {}
LBItemType.RoleExp = 1
LBItemType.PetExp = 2
LBItemType.Sliver = 3
LBItemType.BindSliver = 4
LBItemType.Diamond = 5
LBItemType.Equip = 6
LBItemType.Dress = 7
LBItemType.Drug = 8
LBItemType.stone = 11
LBItemType.PetSkillBook = 12
LBItemType.QinMinDu = 14
LBItemType.DaoHeng = 18
LBItemType.BaoTu = 19
LBItemType.Rune = 20
LBItemType.JingJiBi = 21
LBItemType.BangGong = 22
function LItemResData:New()
	local o = {}
	setmetatable(o,LItemResData)	
	o:ctor()
	return o
end

function LItemResData:ctor()
	self.m_iId = 0
	self.m_iNameId = 0
	self.m_eType = 0
	self.m_iTypeNameId = 0
	self.m_iIcon = 0
end

LItemData = LItemResData:New()
LItemData.__index = LItemData
function LItemData:New()
	local o = {}
	setmetatable(o,LItemData)	
	o:ctor()
	return o
end

function LItemData:ctor()
	self.m_iID = 0
	self.m_iDescId = 0
	self.m_byLv = 0
	self.m_wActArr = {}
	self.m_iSellPrice = 0
	self.m_iObtain = {}
	self.m_UseType = 0
	self.m_byColor = 0
	self.m_byMaxStack = 0
	self.m_iPrice = 0
	self.m_byDealType = 0
end

--[[
克隆装备表里面的数据
]]
function LItemData:ClonePackData(packItem)
    self.m_iDescId = packItem.m_iDescId
    self.m_byLv = packItem.m_byLv
    self.m_iSellPrice = packItem.m_iSellPrice
    self.m_wActArr = packItem.m_wActArr
    self.m_byColor = packItem.m_byColor
    self.m_byMaxStack = packItem.m_byMaxStack
    self.m_iPrice = packItem.m_iPrice
    self.m_byDealType = packItem.m_byDealType
end

--[[宝石属性结构]]
LJewelData = LItemData:New()
LJewelData.__index = LJewelData
function LJewelData:New()
	local o = LItemData:New()
	setmetatable(o,LJewelData)	
	o:ctor()
	return o
end

function LJewelData:ctor()
	self.m_ijewelType= 0
	self.m_ijewel_lv = 0
	self.m_iTypeNameID = 0
	self.m_pAddAttrs = {}--LBaseAttr结构
	--[[
	可镶嵌该宝石的装备部位
	1=武器
	2=帽子
	3=衣服
	4=鞋子
	5=项链
]]
	self.m_pInlayTypes = {}--可镶嵌的装备部位,对应LEquipType
end

--[[装备属性结构]]
LEquipData = LItemData:New()
LEquipData.__index = LEquipData
LEquipType = {}
LEquipType.Equip_Weapon = 1
LEquipType.Equip_Hat = 2
LEquipType.Equip_Cloth = 3
LEquipType.Eqip_Shoes = 4
LEquipType.Equip_Necklace = 5
LEquipType.Equip_Amulet = 6
LEquipType.Equip_Belt = 7
LEquipType.Equip_Ring = 8
function LEquipData:New()
	local o = LItemData:New()
	setmetatable(o,LEquipData)	
	o:ctor()
	return o
end

function LEquipData:ctor()
	self.m_byType = 0--对应LEquipType
	self.m_byZhongzu= 0--种族
	--[[
	/// <summary>
    ///装备要求的加点属性类型：
    ///1.体质
    ///2.力量
    ///3.灵力
    ///4.敏捷
    /// </summary>
    ]]
	self.m_byAttrType = 0
	self.m_iAttrV = 0
	self.m_wNaijiu = 0
	self.m_byQuality = 0
	self.m_pBaseAttr = {}--装备属性生成,对应LBaseEquipAttr
	self.m_pRefineNum = {}--对应LBaseEquipRefineAttrNum
	self.m_pRefineAttr = {}--对应LBaseEquipRefineAttr
	self.m_pSkills = {}--对应--BaseEquipSkill
	self.m_wActOnArr = {}--装备操作
	self.m_iModule = 0--模型id
	self.m_iNextId = 0--升级后对应的装备id
end



LItemUseInfo = {}
LItemUseInfo.__index = LItemUseInfo
function LItemUseInfo:New(id)
	local o = {}
	setmetatable(o,LItemUseInfo)	
	o:ctor()
	return o
end

function LItemUseInfo:ctor(id)
	self.m_iId= id
	self.m_byType = 0
end

--[[道具管理]]
LItemManager = LDataBase:New()
LItemManager.__index = LItemManager
function LItemManager:New()
	local o = LDataBase:New()
	setmetatable(o,LItemManager)	
	o:Awake()
	return o
end

function LItemManager:Awake()
	self.m_bIsLoaded = false
	--物品资源总表
	self.m_pItemResDict = {}
	--物品总表
	self.m_pItemDict = {}
	--装备总表
	self.m_pEquipDict = {}
	--宝石表
	self.m_pJewelDataBuff = {}
	--道具使用相关信息
	self.m_pItemUseBuff = {}
	--符文总表
	self.m_pRuneDict = {}
end


function LItemManager:ProcessEvent(msg)
	if msg.msgId == 0 then
	end
end

function LItemManager:Instance()
	if self.m_bIsLoaded == false then
		self:ReadItemResData()
		self:ReadItemData()
		self:ReadEquipData()
		self:ReadJewelData()
		self:ReadItemUseData()
		self.m_bIsLoaded = true
	end
	return self
end

function LItemManager:GetItemResData(id)
    return self.m_pItemResDict[id]
end

function LItemManager:GetItemData(id)
    return self.m_pItemDict[id]
end

function LItemManager:GetEquipData(id)
    return self.m_pEquipDict[id]
end

function LItemManager:GetJewelData(id)
    return self.m_pJewelDataBuff[id]
end

function LItemManager:AllJewelData()
    return self.m_pJewelDataBuff
end

function LItemManager:GetItemUseData(id)
    return self.m_pItemUseBuff[id]
end

function LItemManager:GetRuneData(id)
    return self.m_pRuneDict[id]
end

function LItemManager:ReadItemResData()
	local xml = LXMLCenter:GetXML("Assets/GameRes/xml/resource.xml")
	local xmlInfo = xml.RECORDS
	local rec = xmlInfo.RECORD
	for i = 1, #rec do
		local v = rec[i]
		local itemResData = LItemResData:New()
		itemResData.m_iId = tonumber(v["@id"])
		itemResData.m_eType = tonumber(v["@type"])
		itemResData.m_iNameId = tonumber(v["@name_id"])
		itemResData.m_iIcon = tonumber(v["@icon"])
		itemResData.m_iTypeNameId = tonumber(v["@type_name_id"])
		self.m_pItemResDict[itemResData.m_iId] = itemResData
	end
end

function LItemManager:ReadItemData()
	local xml = LXMLCenter:GetXML("Assets/GameRes/xml/item.xml")
	local xmlInfo = xml.RECORDS
	local rec = xmlInfo.RECORD
	for i = 1, #rec do
		local v = rec[i]
		local itemdata = LItemData:New()
		itemdata.m_iId = tonumber(v["@id"])
		itemdata.m_iDescId = tonumber(v["@describe_id"])
		itemdata.m_byColor = tonumber(v["@color"])
		itemdata.m_byLv = tonumber(v["@use_level"])
		itemdata.m_byMaxStack = tonumber(v["@stack_max"])
		itemdata.m_iPrice = tonumber(v["@price"])
		itemdata.m_byDealType = tonumber(v["@deal_type"])
		itemdata.m_UseType = tonumber(v["@use"])
		local cc = string.split(v["@get_type"], "|")
		itemdata.m_iObtain = {}
		for i = 1, #cc do
			table.insert(itemdata.m_iObtain, tonumber(cc[i]))
		end
        local ss = string.split( v["@act"], "|")
        itemdata.m_wActArr = {}
        for i = 1, #ss do
        	table.insert(itemdata.m_wActArr, tonumber(ss[i]))
        end
        itemdata.m_eType = self.m_pItemResDict[itemdata.m_iId].m_eType
	    itemdata.m_iNameId = self.m_pItemResDict[itemdata.m_iId].m_iNameId
	    itemdata.m_iIcon = self.m_pItemResDict[itemdata.m_iId].m_iIcon
	    itemdata.m_iTypeNameId = self.m_pItemResDict[itemdata.m_iId].m_iTypeNameId
        self.m_pItemDict[itemdata.m_iId] = itemdata
	end
end

function LItemManager:ReadJewelData()
	local xml = LXMLCenter:GetXML("Assets/GameRes/xml/jewel.xml")
	local xmlInfo = xml.RECORDS
	local rec = xmlInfo.RECORD
	self.m_pJewelDataBuff = {}
	for i = 1, #rec do
		local v = rec[i]
		local jewelData = LJewelData:New()
		jewelData.m_iId = tonumber(v["@id"])
		local item = self:GetItem(jewelData.m_iId)
        jewelData:ClonePackData(item)


		jewelData.m_ijewelType = tonumber(v["@jewel_type"])
		jewelData.m_ijewel_lv = tonumber(v["@jewel_lv"])
		jewelData.m_iTypeNameID = tonumber(v["@type_name_id"])
		local cc = string.split(v["@mountable_equiptype"], "|")
		for i = 1, #cc do
			jewelData.m_pInlayTypes[i] = tonumber(cc[i])
		end
        local ss = string.split( v["@add_attr"], "|")
        jewelData.m_pAddAttrs = {}
        for i = 1, #ss do
        	local ss2 = string.split(ss[i], "-")
        	local attrData = LBaseAttr:New()
        	attrData.id = tonumber(ss2[1])
        	attrData.value = tonumber(ss2[2])
        	table.insert(jewelData.m_pAddAttrs, attrData)
        end
        self.m_pJewelDataBuff[jewelData.m_iId] = jewelData
	end
end

function LItemManager:ReadItemUseData()
	local xml = LXMLCenter:GetXML("Assets/GameRes/xml/use_item.xml")
	local xmlInfo = xml.RECORDS
	local rec = xmlInfo.RECORD
	self.m_pItemUseBuff = {}
	for i = 1, #rec do
		local v = rec[i]
		local itemUseInfo = LItemUseInfo:New()
		itemUseInfo.m_iId = tonumber(v["@id"])
		itemUseInfo.m_descid = tonumber(v["@item_tips"])
		itemUseInfo.m_effect = v["@use_effect"]
        self.m_pItemUseBuff[itemUseInfo.m_iId] = itemUseInfo
	end
end

function LItemManager:GetItem(mid)
	return self.m_pItemDict[mid]
end

function LItemManager:ReadEquipData()
	local xml = LXMLCenter:GetXML("Assets/GameRes/xml/equipment.xml")
	local xmlInfo = xml.RECORDS
	local rec = xmlInfo.RECORD
	self.m_pEquipDict = {}
	for i = 1, #rec do
		local v = rec[i]
		local equipData = LEquipData:New()
		equipData.m_iId = tonumber(v["@id"])
		local item = self:GetItem(equipData.m_iId)
        equipData:ClonePackData(item)
		
		equipData.m_byType = tonumber(v["@type2"])
		equipData.m_byZhongzu = tonumber(v["@req_zhongzu"])
		equipData.m_byAttrType = tonumber(v["@req_attr_type"])
		equipData.m_iAttrV = tonumber(v["@req_attr_val"])
		equipData.m_wNaijiu = tonumber(v["@naijiu"])
		equipData.m_byQuality = tonumber(v["@quality"])
		equipData.m_iNextId = tonumber(v["@next_equip_id"])
		equipData.m_iModule = tonumber(v["@model"])
		local cc = string.split(v["@basic_attr"], "|")
		equipData.m_pBaseAttr = {}
		if cc ~= "0" then
			for i = 1, #cc do
				local cc1 = string.split(cc[i], "-")
				local attrData = LBaseAttr:New()
	        	attrData.id = tonumber(cc1[1])
	        	attrData.minV = tonumber(cc1[2])
	        	attrData.maxV = tonumber(cc1[3])
	        	table.insert(equipData.m_pBaseAttr, attrData)
			end
		end

		local cc = string.split(v["@refining_attr_num"], "|")
		equipData.m_pRefineNum = {}
		if cc ~= "0" then
			for i = 1, #cc do
				local cc1 = string.split(cc[i], "-")
				local attrData = LBaseEquipRefineAttrNum:New()
	        	attrData.num = tonumber(cc1[1])
	        	attrData.weight = tonumber(cc1[2])
	        	table.insert(equipData.m_pRefineNum, attrData)
			end
		end

		local cc = string.split(v["@refining_attr"], "|")
		equipData.m_pRefineAttr = {}
		if cc ~= "0" then
			for i = 1, #cc do
				local cc1 = string.split(cc[i], "-")
				local attrData = LBaseEquipRefineAttr:New()
	        	attrData.id = tonumber(cc1[1])
	        	attrData.minV = tonumber(cc1[2])
	        	attrData.maxV = tonumber(cc1[3])
	        	attrData.repeatNum = tonumber(cc1[4])
	        	attrData.weight = tonumber(cc1[5])
	        	table.insert(equipData.m_pRefineAttr, attrData)
			end
		end

		local cc = string.split(v["@special_skill"], "|")
		equipData.m_pSkills = {}
		if cc ~= "0" then
			for i = 1, #cc do
				local cc1 = string.split(cc[i], "-")
				local attrData = LBaseEquipSkill:New()
	        	attrData.id = tonumber(cc1[1])
	        	attrData.weight = tonumber(cc1[2])
	        	table.insert(equipData.m_pSkills, attrData)
			end
		end

		local cc = string.split(v["@act_on"], "|")
		equipData.m_wActOnArr = {}
		if cc ~= "0" then
			for i = 1, #cc do
				table.insert(equipData.m_wActOnArr, tonumber(cc[i]))
			end
		end
        self.m_pEquipDict[equipData.m_iId] = equipData
	end
end



return LItemManager:Awake()