--商城数据结构
LMarketGoodsInfo = {}
LMarketGoodsInfo.__index = LMarketGoodsInfo
function LMarketGoodsInfo:New()
	local o = {}
	setmetatable(o,LMarketGoodsInfo)	
	o:Init()
	return o
end

function LMarketGoodsInfo:Init()
	self.id = 0 --物品ID
	self.price = 0  --价格
	self.coupon = 0 --特价
    self.label = 0  --标签
	self.num = 0   --剩余数量
	self.leftTime = 0 --剩余时间
	self.petEquipId = 0--宠物装备ID
	self.petEquipStar = 0--宠物装备星级
	self.buyTimes = 0 --购买次数
	self.m_index = 0
end

function LMarketGoodsInfo:Delete()
	self.id = nil
	self.price = nil
	self.coupon = nil
    self.label = nil
	self.num = nil
	self.leftTime = nil
	self.petEquipId = nil
	self.petEquipStar = nil
	self.buyTimes = nil --购买次数
	self.m_index = nil
end

--神秘商店物品信息
LSMItemInfo = {}
LSMItemInfo.__index = LSMItemInfo
function LSMItemInfo:New()
	local o = {}
	setmetatable(o,LSMItemInfo)	
	o:Init()
	return o
end

function LSMItemInfo:Init()
	self.id = -1
	self.price = 0
	self.itemId = -1
    self.itemNum = 0
	self.vipLimit = 0   --开启所需vip等级等于0已开启
	self.petEquipId = 0--宠物装备Id
	self.petEquipStar = 0--宠物装备星级
end

function LSMItemInfo:Delete()
	self.id = nil
	self.price = nil
	self.itemId = nil
	self.itemNum = nil
    self.vipLimit = nil
    self.petEquipId = nil
	self.petEquipStar = nil
end

--神秘商店信息
LShopMysteryInfo = {}
LShopMysteryInfo.__index = LShopMysteryInfo
function LShopMysteryInfo:New()
	local o = {}
	setmetatable(o,LShopMysteryInfo)	
	o:Init()
	return o
end

function LShopMysteryInfo:Init()
	self.time = 0
	self.num = 0
	self.ItemData = {}
    self.logMegNum = 0
	self.logMeg = {}
end

function LShopMysteryInfo:Delete()
	self.time = nil
	self.num = nil
	self.ItemData = nil
	self.logMegNum = nil
    self.logMeg = nil
end

--商店Item选中数据结构
ShopSelectInfo = {}
ShopSelectInfo.__index = ShopSelectInfo
function ShopSelectInfo:New()
	local o = {}
	setmetatable(o,ShopSelectInfo)	
	o:Init()
	return o
end

function ShopSelectInfo:Init()
	self.m_name = nil
	self.m_desc = nil
	self.m_id = 0
	self.m_count = 0
	self.m_unitCount = 0
	self.m_price = 0
	self.m_priceType = 0
	self.m_isShowHave = true
	self.m_isChangeCount = true
	self.m_maxCount = 0
	self.m_pid = 0
	self.m_pstar = 0
end

function ShopSelectInfo:Delete()
	self.m_name = nil
	self.m_desc = nil
	self.m_id = nil
	self.m_count = nil
	self.m_unitCount = nil
	self.m_price = nil
	self.m_priceType = nil
	self.m_isShowHave = nil
	self.m_isChangeCount = nil
	self.m_maxCount = nil
	self.m_pid = nil
	self.m_pstar = nil
end