PetCellUI = {}
PetCellUI.__index = PetCellUI

--local this = LTcpSocket
--[[
itemValues数据结构：
{
	（二选一）itemData:PItem
	（二选一）userDefine:{picFilePath, quality, num, level(Pet), star(Pet,PetEquip),career(Pet),strengthenLv(PetEquip),suitId(PetEquip)}
	（可选）isShowQualityBg:true,false,默认false
	（可选）isShowNum:是否显示道具数量：true,false,默认false
	（可选）isChangeSize:是否缩放已匹配父节点大小
}
]]
function PetCellUI:New(parent, itemValues)
	local o = {}
	setmetatable(o,PetCellUI)	
    o:Init(parent, itemValues)
	return o
end

function PetCellUI:onNodeEvent(event)       
    if "exit" == event then
        self:onExit(false)
    end
end


function PetCellUI:Init(parent, itemValues)
    --self.m_pNode = cc.Node:create()
    self.m_pNode = parent
    self.m_bCanClick = false
    self.m_isShowFrom = true
    self.m_pUILayer = self.m_pNode:getChildByName("PetCell.csb")
    if self.m_pUILayer == nil then
    	self.m_pUILayer = cc.CSLoader:createNode("csd/common/PetCell.csb")
    	self.m_pUILayer:setName("PetCell.csb")
    	self.m_pNode:addChild(self.m_pUILayer)
        self.itemValues= itemValues
    	if itemValues and itemValues.isChangeSize then
    		local pSize = self.m_pNode:getContentSize()
    		local cSize = self.m_pUILayer:getContentSize()
    		local xScale = pSize.width/cSize.width
    		local yScale = pSize.height/cSize.height
    		self.m_pUILayer:setScale(math.min(xScale, yScale))
    	end

        
        self.m_pUILayer:registerScriptHandler(handler(self,PetCellUI.onNodeEvent))

        local iconImg = self.m_pUILayer:getChildByName("Touch")
        iconImg:setSwallowTouches(false)
        iconImg:addClickEventListener(handler(self, PetCellUI.ClickCallback))
    end
    self:UpdateItem(itemValues)
	
end

function PetCellUI:setTag(tag)
    -- body
    self.m_pUILayer:setTag(tag)
end

function PetCellUI:setSwallowTouches(isSwallow)
    -- body
    local iconImg = self.m_pUILayer:getChildByName("Touch")
    iconImg:setSwallowTouches(isSwallow)
end

function PetCellUI:setNumTextColor( color )
    -- body
    local numLabel = self.m_pUILayer:getChildByName("ItemNum")
    numLabel:setTextColor(color)
end

function PetCellUI:setNumTextScale( scale )
    -- body
    local numLabel = self.m_pUILayer:getChildByName("ItemNum")
    numLabel:setScale(scale)
end

function PetCellUI:setPosition( pos )
    -- body
    self.m_pUILayer:setPosition(pos)
end

function PetCellUI:adjustPostion( ... )
    -- body
    local size = self.m_pUILayer:getContentSize()
    local x, y = self.m_pUILayer:getPosition()
    self.m_pUILayer:setPosition(cc.p(x - size.height / 2 , y - size.width / 2))
end

function PetCellUI:onExit(isNonAuto)
    -- self:UnbindAsyncImg()
    -- self:UnbindAsyncImg2()
    self:Destory()
    self.m_suitImg = nil
    self.m_pUILayer = nil
    self.m_pNode = nil
    self.m_bCanClick = nil
    self.m_pItem = nil
    self.m_pUserDefine = nil
    self.m_isShowQuityBg = nil
    self.m_isShowNum = nil
    self.m_pUserDefine = nil
end

--设置是否主动释放
function PetCellUI:SetIsNonAutoFree(IsNonAutoFree)
	self.m_isNonAutoFree = IsNonAutoFree
end

--[[
itemValues数据结构：
{
	（二选一）itemData:PItem
	（二选一）userDefine:{picFilePath, num}
	（可选）isShowQualityBg:true,false,默认false
	（可选）isShowNum:是否显示道具数量：true,false,默认false
}
]]
function PetCellUI:UpdateItem(itemValues)
	-- print("UpdateItem")
	if itemValues == nil then
		self.m_pUILayer:setVisible(false)
		return
	end
	self.m_pUILayer:setVisible(true)
	if self.m_pItem ~= nil then
		self.m_pItem = nil
	end
    if itemValues.isChangeSize then
        local pSize = self.m_pNode:getContentSize()
        local cSize = self.m_pUILayer:getContentSize()
        local xScale = pSize.width/cSize.width
        local yScale = pSize.height/cSize.height
        self.m_pUILayer:setScale(math.min(xScale, yScale))
    end
    local info = LPetDataMgr:FindPetDataById(itemValues[1])

	local icon = self.m_pUILayer:getChildByName("Icon")
    --icon
    Utils:ShowPetHeadImg(icon,info.pic,nil,info.quality,info:IsShiny())
    --评分
    local scoreImage = self.m_pUILayer:getChildByName("Quality")
    AppDef:GetPetQualityScore(scoreImage,info.quality)
    --神将类型
    local typeImage = self.m_pUILayer:getChildByName("Career")
    if typeImage then
        AppDef:ShowPetType(typeImage,info.petType)
    end
    --数量
    local label = self.m_pUILayer:getChildByName("Text")
    label:setString("")
    --星级
    local list = self.m_pUILayer:getChildByName("StarsList") 
    list:setSwallowTouches(false)
    local star = list:getChildByName("Star")

    for i=2,info.initstar do
        local starP = star:clone()
        list:pushBackCustomItem(starP)
    end
end

function PetCellUI:ClickCallback(sender)
    -- print("ClickCallback ************************************************* 1111111111", self.m_bCanClick)
	if not self.m_bCanClick then
		return
	end

    Utils:SendMsg(LUILogicEvent.ShowPetInfo, {self.itemValues[1]})
	-- local id = sender.userObject
 --     if Petstar ~=nil then
 --        LGameMsg.m_baseMsgWithOne:Change(LUILogicEvent.ShowPetInfo, {id,nil,Petstar})
 --        LUIManager:SendMsg(LGameMsg.m_baseMsgWithOne)
 --    else
 --        LGameMsg.m_baseMsgWithOne:Change(LUILogicEvent.ShowPetInfo, {id})
 --        LUIManager:SendMsg(LGameMsg.m_baseMsgWithOne)  
 --    end
end

function PetCellUI:Destory()
	self.m_pUILayer = nil
	self.m_pNode = nil
	self.m_pItem = nil
	self.m_pUserDefine = nil
	self.m_isShowQuityBg = nil
	self.m_isShowNum = nil
	self.m_isNonAutoFree = nil
	self.m_bCanClick = nil
end

-- --[[
-- 设置是否能点击显示详情
-- ]]
-- function PetCellUI:SetCanClick(canClick)
-- 	self.m_bCanClick = canClick
--     local touchPanel = self.m_pUILayer:getChildByName("Touch")
--     touchPanel:setVisible(canClick)
-- end

-- --[[
-- 设置点击是否显示来源
-- ]]
-- function PetCellUI:SetShowFrom(sign)
--     self.m_isShowFrom = sign
-- end

-- function PetCellUI:GetCanClick()
--     return self.m_bCanClick
-- end