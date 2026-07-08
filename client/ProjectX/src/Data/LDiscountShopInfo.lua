--折扣商店

LDiscountBoxItemsInfo = {}
LDiscountBoxItemsInfo.__index = LDiscountBoxItemsInfo

function LDiscountBoxItemsInfo:New()
	local o = {}
	setmetatable(o,LDiscountBoxItemsInfo)	
	o:Init()
	return o
end

function LDiscountBoxItemsInfo:Init()
	self.awardType = 0
--	itemInfoStr     itemInfo;
	self.itemId = 0
	self.num = 0
	self.petInfo = LPetData:New(1)
	self.quality = 0
	self.skillBook = 0
end

function LDiscountBoxItemsInfo:Delete()
	self.awardType = nil
--	itemInfoStr     itemInfo;
	self.itemId = nil
	self.num = nil
	self.petInfo = nil
	self.quality = nil
	self.skillBook = nil
end





LDiscountShopData = {}
LDiscountShopData.__index = LDiscountShopData


function LDiscountShopData:New()
	local o = {}
	setmetatable(o,LDiscountShopData)	
	o:Init()
	return o
end

function LDiscountShopData:Init()
	self.id = 0
	self.name = ""		  
	self.desc = ""
	self.srcPrice = 0
	self.curPrice = 0
	self.discount = 0
	self.canBuyNum = 0
	self.vip = 0
	self.awardCount = 0
--	vector<LDiscountBoxItemsInfo> itemInfos;
	self.itemInfos = {}
end

function LDiscountShopData:Delete()
	self.id = nil
	self.name = nil		  
	self.desc = nil
	self.srcPrice = nil
	self.curPrice = nil
	self.discount = nil
	self.canBuyNum = nil
	self.vip = nil
	self.awardCount = nil
	self.itemInfos = nil
end




LDiscountShopInfo = {}
LDiscountShopInfo.__index = LDiscountShopInfo

function LDiscountShopInfo:New()
	local o = {}
	setmetatable(o,LDiscountShopInfo)	
	o:Init()
	return o
end

function LDiscountShopInfo:Init()
	self.type = 0
	self.time = 0	    --如果类型为1的时候会读取
	self.num = 0
--	vector<LDiscountShopData> shopdata;
	self.shopdata = {}
end

function LDiscountShopInfo:Delete()
	self.type = nil
	self.time = nil	    --如果类型为1的时候会读取
	self.num = nil
--	vector<LDiscountShopData> shopdata;
	self.shopdata = nil
end



