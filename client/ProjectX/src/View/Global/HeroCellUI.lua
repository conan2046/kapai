HeroCellUI = {}
HeroCellUI.__index = HeroCellUI

function HeroCellUI:New(parent, itemValues)
	local o = {}
	setmetatable(o,HeroCellUI)	
    o:Init(parent, itemValues)
	return o
end

function HeroCellUI:onNodeEvent(event)       
    if "exit" == event then
        self:onExit(false)
    end
end


function HeroCellUI:Init(parent, heroValues)
	self.m_pNode = parent
	self.m_bCanClick = false
	self.m_pUILayer = self.m_pNode:getChildByName("HeroHeadLayer.csb")
	if self.m_pUILayer == nil then
    	self.m_pUILayer = cc.CSLoader:createNode("csd/common/CommonHeroHead.csb")
    	self.m_pUILayer:setName("HeroHeadLayer.csb")
    	self.m_pNode:addChild(self.m_pUILayer)
        self.heroValues= heroValues
    	if heroValues and heroValues.isChangeSize then
    		local pSize = self.m_pNode:getContentSize()
    		local cSize = self.m_pUILayer:getContentSize()
    		local xScale = pSize.width/cSize.width
    		local yScale = pSize.height/cSize.height
    		self.m_pUILayer:setScale(math.min(xScale, yScale))
    	end
        
        self.m_pUILayer:registerScriptHandler(handler(self,HeroCellUI.onNodeEvent))

        self.touchLayer = self.m_pUILayer:getChildByName("Touch")
        self.touchLayer:setSwallowTouches(false)
        self.touchLayer:addClickEventListener(handler(self, HeroCellUI.ClickCallback))
    end
   	
    local lvLabel = self.m_pUILayer:getChildByName("Level")
    lvLabel:setVisible(false)
    self:UpdateItem(heroValues)
end

function HeroCellUI:UpdateItem(heroValues)
	if heroValues == nil then
		self.m_pUILayer:setVisible(false)
		return
	end
	self.m_pUILayer:setVisible(true)

	self.m_pHero = heroValues["heroData"]
	self.m_isShowQuityBg = heroValues["m_isShowQuityBg"]
	if self.m_isShowQuityBg == nil then
		self.m_isShowQuityBg = false
	end
	self.m_isSelect = heroValues["isSelect"]
	if self.m_isSelect == nil then
        self.m_isSelect = false
    end
	if self.m_pHero ~= nil then
		self:ShowHero()
	end
end

function HeroCellUI:ShowHero()
	local herodata = self.m_pHero
	local basedata = herodata.baseData
	local qualityImg = self.m_pUILayer:getChildByName("Quality")
	qualityImg:setVisible(self.m_isShowQuityBg)
	local iconImg = self.m_pUILayer:getChildByName("Icon")	
	iconImg:setVisible(true)
	Utils:ShowPetHeadImg(iconImg,basedata.pic,qualityImg,basedata.quality,herodata:IsShiny()) 
	local selectImg = self.m_pUILayer:getChildByName("Select")
	if self.m_isSelect == true  then
        selectImg:setVisible(true)
    else
        selectImg:setVisible(false)
    end
	local level = self.m_pUILayer:getChildByName("Level")
	level:setVisible(false)
	if herodata.level > 0 then
		level:setVisible(true)
		level:setString(herodata.level)
	end
	local startlist = self.m_pUILayer:getChildByName("StarList")
	startlist:setVisible(false)
	local starImg = startlist:getChildByName("Star")
	local star = herodata.star
	if star > 0 then
        startlist:setVisible(true)
		startlist:setContentSize(cc.size(30*star, 30))
        for i=2,star do
            local starP = startlist:getChildByTag(i)
            if starP == nil then
                starP = starImg:clone()
                starP:setTag(i)
                startlist:pushBackCustomItem(starP)
            end 
        end
        for i=star+1,6 do
            local starP = startlist:getChildByTag(i)
            if starP ~= nil then
                starP:removeFromParent()
            end
        end
    end
end

function HeroCellUI:ClickCallback(sender)

end

function HeroCellUI:SetCanClick(canClick)
	self.m_bCanClick = canClick
	if self.touchLayer ~= nil then
		self.touchLayer:setVisible(canClick)
	end
end

function HeroCellUI:onNodeEvent(event)       
    if "exit" == event then
        self:onExit(false)
    end
end

function HeroCellUI:onExit(isNonAuto)
    self:Destory()
end

function HeroCellUI:Destory()
	self.m_pUILayer = nil
	self.m_pNode = nil
	self.m_pHero = nil
	self.m_isShowQuityBg = nil
	self.m_bCanClick = nil
end