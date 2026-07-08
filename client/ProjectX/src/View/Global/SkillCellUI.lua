SkillCellUI = {}
SkillCellUI.__index = SkillCellUI

--local this = LTcpSocket
--[[
itemValues数据结构：
{
    （二选一）itemData:PItem
    （二选一）userDefine:{picFilePath, quality, num}
    （可选）isShowQualityBg:true,false,默认false
    （可选）isShowNum:是否显示道具数量：true,false,默认false
}
]]
function SkillCellUI:New(parent, skData, quality,isBronSkill, showLv, scale)
    local o = {}
    setmetatable(o,SkillCellUI)  
    o:Init(parent, skData, quality,isBronSkill, showLv, scale)
    return o
end

function SkillCellUI:SetClickCallback(func, tag)
    local panel = self.m_pUILayer:getChildByName("btn_skill")
    if tag ~= nil then
        panel:setTag(tag)
    end
    panel:addClickEventListener(func)
end


function SkillCellUI:Init(parent, skData, quality, isBronSkill, showLv, scale)
    --self.m_pNode = cc.Node:create()
    self.m_pNode = parent
    self.m_pUILayer = cc.CSLoader:createNode("csd/SkillIconLayer.csb")
    self.m_pNode:addChild(self.m_pUILayer)
   -- self:addChild(self.m_pUILayer)
   scale = scale or 1.0
   showLv = showLv or false
   isBronSkill = isBronSkill or false
   self.m_pUILayer:setScale(scale)
    local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit(false)
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
    self:UpdateItem(skData,quality,isBronSkill, showLv, scale)
end

function SkillCellUI:onExit(isNonAuto)
    if isNonAuto or self.m_isNonAutoFree == nil then
        Utils:UnbindAsyncImg(self.m_filepathKey)
        self.m_pUILayer = nil
        self.m_pNode = nil
        self.m_pItem = nil
        self.m_pUserDefine = nil
        self.m_isShowQuityBg = nil
        self.m_isShowNum = nil
        self.m_isNonAutoFree = nil
    end
end

function SkillCellUI:UpdateItem(skData, quality,isBronSkill, showLv, scale)
    -- print("UpdateItem")
    local panel = self.m_pUILayer:getChildByName("btn_skill")
    local bornImg = panel:getChildByName("Mark")
    local maskImg = panel:getChildByName("Mask")
    local lockImg = panel:getChildByName("Lock")
    local addImg = panel:getChildByName("Icon")
    --local skIconImg = panel:getChildByName("SkillImage")
    local lvLabel = panel:getChildByName("Level")
    local iconImg = panel:getChildByName("SkillIcon")
    lvLabel:setVisible(showLv)
    lvLabel:setString(skData.level)

    if skData.skDetail ~= nil then
        if skData.level == 0 then
            --未开启，等级0
            lockImg:setVisible(true)
            maskImg:setVisible(true)
            lvLabel:setVisible(false)
            --skIconImg:setVisible(false)
            addImg:setVisible(true)
        else
            lockImg:setVisible(false)
            maskImg:setVisible(false)
            addImg:setVisible(false)
            lvLabel:setVisible(true)
        end

        iconImg:setVisible(true)
        local str = string.format("Skill/UI/skill_%d.png", skData.skDetail.id)
        Utils:AsyncLoadImg(iconImg,str)
        --skIconImg:loadTexture(string.format("Skill/UI/skill_%d.png", skData.skDetail.id), ccui.TextureResType.localType)
        --skIconImg:setScale(0.88)
    else
        iconImg:setVisible(false)
        lockImg:setVisible(true)
        maskImg:setVisible(false)
        lvLabel:setVisible(false)
        addImg:setVisible(false)
    end
    bornImg:setVisible(isBronSkill)
end

function SkillCellUI:ShowUserDefineData()
    --local item = self.m_pItem

    self.m_pUserDefine.num = self.m_pUserDefine.num or 0
    self.m_pUserDefine.quality = self.m_pUserDefine.quality or 0
    local qualityImg = self.m_pUILayer:getChildByName("ItemQuality")
    --local itemImg = self.m_pUILayer:getChildByName("ItemIcon")
    local numLabel = self.m_pUILayer:getChildByName("ItemNum")
    local stateImg = self.m_pUILayer:getChildByName("ItemState")
    local iconImg = self.m_pUILayer:getChildByName("Icon")
    iconImg:setVisible(true)
    stateImg:setVisible(false)
    if self.m_isShowNum == true and self.m_pUserDefine.num >= 0 then
        numLabel:setVisible(true)
        numLabel:setString(tostring(self.m_pUserDefine.num))
    else
        numLabel:setVisible(false)
    end
    if self.m_pUserDefine.quality > 0 then  -- 装备
        local str = AppDef.ColorKuangArr[self.m_pUserDefine.quality]
        if str ~= nil then
            qualityImg:loadTexture(str,ccui.TextureResType.plistType)
            qualityImg:setVisible(true)
        end
    else
        qualityImg:setVisible(false)
    end
    str = self.m_pUserDefine.picFilePath
    local size = qualityImg:getContentSize()
    iconImg:setTextureRect(cc.rect(0,0,size.width,size.height))
    Utils:AsyncLoadImg(iconImg,str)
    self.m_filepathKey = str
--    itemImg:loadTexture(str,ccui.TextureResType.localType)
--    itemImg:setContentSize(self.m_pNode:getContentSize())
end

function SkillCellUI:ShowItem()
    local item = self.m_pItem
    local qualityImg = self.m_pUILayer:getChildByName("ItemQuality")
    --local itemImg = self.m_pUILayer:getChildByName("ItemIcon")
    local numLabel = self.m_pUILayer:getChildByName("ItemNum")
    local stateImg = self.m_pUILayer:getChildByName("ItemState")
    local iconImg = self.m_pUILayer:getChildByName("Icon")
    iconImg:setVisible(true)
    stateImg:setVisible(false)
    local size = qualityImg:getContentSize()
    iconImg:setTextureRect(cc.rect(0,0,size.width,size.height))
    if self.m_isShowNum == true and item.m_num >= 0 then
        numLabel:setVisible(true)
        numLabel:setString(tostring(item.m_num))
    else
        numLabel:setVisible(false)
    end
    if item:IsEquip() == true then  -- 装备
        
        local colorIdx = math.floor(item.m_roleLevel/10)
        if colorIdx > 8 then
            colorIdx = 9
        end
        if self.m_isShowQuityBg == true then
            local str = AppDef.ColorKuangArr[colorIdx + 1]
            qualityImg:loadTexture(str,ccui.TextureResType.plistType)
            qualityImg:setVisible(true)
        end

        str = "item/equip" .. item.m_item.pic .. ".png"
        Utils:AsyncLoadImg(iconImg,str)
        --itemImg:loadTexture(str,ccui.TextureResType.localType)
        if colorIdx > 8 then
            local imod = ImodAnim:createWithFileSync("item/equipLight")
            imod:PlayActionRepeat(0,0.1)
            size = itemImg:getContentSize()
            imod:setPosition(cc.p(size.width/2, size.height/2))
            itemImg:addChild(imod,5,666)
        else 
            local imod = itemImg:getChildByTag(666)
            if imod ~= nil then
                imod:removeFromParent()
            end
        end
    else
        qualityImg:setVisible(false)
        str = "item/equip" .. item.m_item.pic .. ".png"
        --itemImg:loadTexture(str,ccui.TextureResType.localType)
        Utils:AsyncLoadImg(iconImg,str)
    end
    --itemImg:setContentSize(self.m_pNode:getContentSize())
end