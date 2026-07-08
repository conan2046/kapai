--[[
]]
fairData = {}
fairData.__index = fairData
function fairData:New(id)
	local o = {}
	setmetatable(o,fairData)
	o:ctor(id)
	return o
end

function fairData:ctor(id)
	self.m_iId = 0
	self.m_iItemId = 0
	self.m_iPage = 0
	self.m_iPrice = 0
	self.m_iMin_price = 0
	self.m_iSign_copy = 0 
	self.m_iRare = 0 
end

PageData = {}
PageData.__index = PageData
function PageData:New(id)
	local o = {}
	setmetatable(o,PageData)
	o:ctor(id)
	return o
end

function PageData:ctor(id)
	self.m_iId = 0
	self.m_iName = 0
	self.m_iPage = {}
	self.m_iNum = 0
	self.m_iIcon = 0
	self.m_iGongShi = 0 
end

LFairDataManager = LDataBase:New()
LFairDataManager.__index = LFairDataManager
function LFairDataManager:New()
	local o = LUIBase:New()
	setmetatable(o,LFairDataManager)	
	o:Awake()
	return o
end

function LFairDataManager:Awake()
	self.m_bIsLoaded = false
	self.m_pfairData = {}
	self.m_pPageOnefairData = {}
	self.m_pPageTowfairData = {}
end

function LFairDataManager:Instance()
	if self.m_bIsLoaded == false then
		self:ReadFairData()
		self:ReadPageOnefairData()
		self:ReadPageTowfairData()
		self.m_bIsLoaded = true
	end
	return self
end

function LFairDataManager:GetfairData(id)
    return self.m_pfairData[id]
end

function LFairDataManager:GetPageOneData(id)
    return self.m_pPageOnefairData[id]
end

function LFairDataManager:GetPageTwoData(id)
    return self.m_pPageTowfairData[id]
end

function LFairDataManager:GetFairCount()
    return #self.m_LFairDataManagerBuff
end


function LFairDataManager:ReadFairData()
	local xml = LXMLCenter:GetXML("Assets/GameRes/xml/jishi_goods.xml")
	local xmlInfo = xml.RECORDS
	local rec = xmlInfo.RECORD
	for i = 1, #rec do
		local v = rec[i]
		local Fairdata = fairData:New()
		Fairdata.m_iId = tonumber(v["@id"])
		Fairdata.m_iItemId = tonumber(v["@item"])
		Fairdata.m_iPage = tonumber(v["@page"])
		Fairdata.m_iPrice = tonumber(v["@price"])
		Fairdata.m_iMin_price = tonumber(v["@min_price"])
		Fairdata.m_iSign_copy = tonumber(v["@sign_copy"])
		Fairdata.m_iRare = tonumber(v["@rare"])
        self.m_pfairData[Fairdata.m_iId] = Fairdata
	end
end

function LFairDataManager:ReadPageOnefairData()
	local xml = LXMLCenter:GetXML("Assets/GameRes/xml/jishi_firstpage.xml")
		-- body
	local xmlInfo = xml.RECORDS
	local rec = xmlInfo.RECORD
	for i = 1, #rec do
		local v = rec[i]
		local Fairdata = PageData:New()
		Fairdata.m_iId = tonumber(v["@id"])
		Fairdata.m_iName = tonumber(v["@name"])
		Fairdata.m_iGongShi = tonumber(v["@gongshi"])
		local cc = string.split( v["@page"], "|")
		for i = 1, #cc do
			table.insert(Fairdata.m_iPage, tonumber(cc[i]))
		end
        self.m_pPageOnefairData[Fairdata.m_iId] = Fairdata
	end
end

function LFairDataManager:ReadPageTowfairData()
	local xml = LXMLCenter:GetXML("Assets/GameRes/xml/jishi_secondpage.xml")
		-- body
	local xmlInfo = xml.RECORDS
	local rec = xmlInfo.RECORD
	for i = 1, #rec do
		local v = rec[i]
		local Fairdata = PageData:New()
		Fairdata.m_iId = tonumber(v["@id"])
		Fairdata.m_iName = tonumber(v["@name"])
		Fairdata.m_iIcon = tonumber(v["@icon"])
		Fairdata.m_iNum = tonumber(v["@num"])
		Fairdata.m_iGongShi = tonumber(v["@gongshi"])
		local cc = string.split( v["@page"], "|")
		for i = 1, #cc do
			table.insert(Fairdata.m_iPage, tonumber(cc[i]))
		end
        self.m_pPageTowfairData[Fairdata.m_iId] = Fairdata
	end
end




return LFairDataManager:Awake()