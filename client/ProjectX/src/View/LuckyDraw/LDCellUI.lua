local LDCellUI = {}
LDCellUI.__index = LDCellUI
-------------------------------------
function LDCellUI:New(data)
    local o = {}
    setmetatable(o, LDCellUI)
    o:Init(data)
    return o
end
-------------------------------------
function LDCellUI:Init(data)
    self.m_pUILayer = data.sjNode
    ------------------------------------------------
    self.m_petConfig = nil
    ------------------------------------------------
    self.m_pShenJiangRoot = data.sjNode --神将根节点
    self.m_pItemRoot = data.djNode--道具根节点
    self.m_pMark = nil
    self.m_pName = nil
    self.m_pPetModelNode = nil
    self.m_pLevel = nil
    self.m_pbg_Level = data.levelBg--神将品质背景节点
    self.m_pItemNode = nil
    ------------------------------------------------
    self.m_pFinishCallback = nil
    ------------------------------------------------
    self:InitUIControl()
    self:setCloseCallback()
    if data.data then
        self:updateData(data.data)
    end
end
-------------------------------------
function LDCellUI:onExit()
    if self.m_pItemNode then
        self.m_pItemNode:onExit(true)
        self.m_pItemNode = nil
    end
    self.m_pUILayer = nil
    Utils:FreeTable(self.m_data)
    self.m_data = nil
    ------------------------------------------------
    self.m_petConfig = nil
    ------------------------------------------------
    self.m_pShenJiangRoot = nil
    self.m_pItemRoot = nil
    self.m_pMark = nil
    self.m_pName = nil
    self.m_pPetModelNode = nil
    self.m_pLevel = nil
    self.m_pbg_Level = nil
    self.m_pItemNode = nil
    ------------------------------------------------
    self.m_pFinishCallback = nil
    self.m_pItemName = nil
end
-------------------------------------
function LDCellUI:InitUIControl()
    local function addDiZuoAnim(pAnimNode)
        if pAnimNode == nil then
            return
        end
        local pAnim = ImodAnim:createWithFileSync("res2/fx/shenqizhanshi")
        pAnim:setVisible(false)
        pAnim:setName("DiZuo")
        pAnim:setIgnoreAnchorPointForPosition(false)
        pAnim:setAnchorPoint(cc.p(0.5, 0))
        pAnim:PlayActionRepeat(0)
        pAnim:setPosition(cc.p(pAnimNode:getContentSize().width/2, pAnimNode:getContentSize().height/2+20))
        pAnimNode:removeChildByTag(0xf0)
        pAnimNode:addChild(pAnim, 0, 0xf0)
    end
    -------------------------------------------------------
    local pPanel = self.m_pUILayer
    -------------------------------------------------------
    local pshenjiang = self.m_pShenJiangRoot:getParent()

    local pMark = pshenjiang:getChildByName("Mark")
    self.m_pMark = pMark

    self.m_pShenJiangRoot:getParent():setVisible(false)
    self.m_pName = pshenjiang:getChildByName("Name")

    self._shadow = pshenjiang:getChildByName("Shadow")


    addDiZuoAnim(pshenjiang:getChildByName("Image"))
    -------------------------------------------------------
    local pItem = self.m_pItemRoot
    pItem:setVisible(false)

    local pItemName = pItem:getChildByName("Name")
    self.m_pItemName = pItemName

    
    -- addDiZuoAnim(pItem:getChildByName("Image"))
    -------------------------------------------------------
    local pbg_Level = self.m_pbg_Level
    if pbg_Level then
        pbg_Level:setVisible(true)
        local pLevel = pbg_Level:getChildByName("Level")
        self.m_pLevel = pLevel
    end    
end
-------------------------------------
function LDCellUI:setCloseCallback()
    local function onNodeEvent(event)
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
end
--[[
data.itemId
data.itemNum
data.petId
data.petLevel
data.petStar
data.tranItemId
data.tranItemNum
]]
function LDCellUI:updateData(data)
    self:Reset()

    -- dump(data, "SingleDrawResultUI ================================>")

    Utils:FreeTable(self.m_data)
    self.m_data = nil
    self.m_data = data
    self.m_petConfig = nil
    -- print("self.m_data.petId ==========>", self.m_data.petId, self.m_data.tranItemId)
    if self.m_data and self.m_data.petId > 0 then
        self.m_petConfig = LPetDataMgr:FindPetDataById(self.m_data.petId)
        self:updateGetPet()
    else
        self:updateGetItem()
    end
end

function LDCellUI:Reset()
   self.m_pShenJiangRoot:getParent():setVisible(false)

    self.m_pItemRoot:setVisible(false)
    if self.m_pbg_Level then
        self.m_pbg_Level:setVisible(false)
    end 
end

function LDCellUI:updateGetPet()
    self:setNodeVisible(1)
    self:ShowPetModel()
    self:ShowQuality()
    self:ShowName()
    AppDef:ShowProAttrImg(self.m_pMark, self.m_petConfig.petType)
end
--[[
显示宠物模型
]]
function LDCellUI:ShowPetModel()
    if self.m_pPetModelNode == nil then
        -- self.m_pPetModelNode = ModelAniNode:create(AppDef.CEnum.ModelAniType.Monster, 0)
        -- print("LDCellUI:ShowPetModel self.m_data.petId =>", self.m_data.petId)
        if self.m_data.petId > 0 then
            self.m_pPetModelNode = Utils:CreateAnimModel(AppDef.AwrdItem.AWRD_ITEM_PET, self.m_data.petId, nil, true)
            if self.m_pPetModelNode then
                self.m_pShenJiangRoot:removeChildByTag(0xf9)
                self.m_pShenJiangRoot:addChild(self.m_pPetModelNode, 1, 0xf9)
            end 

            if self._shadow then
                -- local _pPetModelNodeTemp = Utils:CreateAnimModel(AppDef.AwrdItem.AWRD_ITEM_PET, self.m_data.petId, nil, true)
                -- self._shadow:removeChildByTag(0xf8)
                -- self._shadow:addChild(_pPetModelNodeTemp, 1, 0xf8)

                -- local function BlackPlayEnd( sender )
                --     -- body
                --     sender:removeFromParent()
                -- end

                -- _pPetModelNodeTemp:setScale(0.1)
                -- _pPetModelNodeTemp:setOpacity(0)

                -- local scaleTo1 = cc.ScaleTo:create(1, 1)
                -- local fade1 = cc.FadeTo:create(1, 255)
                -- local sp1 = cc.Spawn:create(scaleTo1, fade1)

                -- local scaleTo2 = cc.ScaleTo:create(1, 1)
                -- local fade2 = cc.FadeTo:create(1, 0)
                -- local sp2 = cc.Spawn:create(scaleTo2, fade2)

                -- local seqAct = cc.Sequence:create( sp1, sp2, cc.CallFunc:create(BlackPlayEnd))
                -- _pPetModelNodeTemp:runAction(seqAct)

            end

        end
    else
        if self.m_data == nil or self.m_data.petId <= 0 then
            self.m_pPetModelNode:setVisible(false)
            return
        end

        local data = self.m_petConfig
        if data == nil or data.pic <= 0 then
            self.m_pPetModelNode:setVisible(false)
            return
        end
        self.m_pPetModelNode:setVisible(true)
        self.m_pPetModelNode:InitAni(AppDef.CEnum.ModelAniType.MonsterBig, data.pic)
    end
    if self.m_pPetModelNode then
        self.m_pPetModelNode:PlayStand(0)
    end
end
--[[
显示品质评分
]]
function LDCellUI:ShowQuality()
    if self.m_pLevel then
        -- print("self.m_petConfig.quality =============>", self.m_petConfig.quality)
        self.m_pbg_Level:setVisible(true)
        self.m_pLevel:setVisible(true)
        AppDef:GetPetQualityScore(self.m_pLevel, self.m_petConfig.quality)
    end
end
--[[
显示名字
]]
function LDCellUI:ShowName()
    local data = self.m_petConfig
    local color = AppDef:GetPetQualityColor(data.quality)
    self.m_pName:setTextColor(color)
    self.m_pName:setString(data.name)
end

function LDCellUI:setNodeVisible(_t)
    local function checkAndSet(pNode, isVisible)
        if pNode then
            pNode:setVisible(isVisible)
        end
    end
    local showPet = _t == 1
    local showItem = not showPet
    checkAndSet(self.m_pShenJiangRoot:getParent(), showPet)
    checkAndSet(self.m_pItemRoot, showItem)

    --显示转换碎片
    local auto = self.m_pItemRoot:getChildByName("auto")
    local isHasTran = self.m_data.tranItemId and self.m_data.tranItemId > 0
    -- print("LDCellUI:setNodeVisible", isHasTran, self.m_data.tranItemId, showItem, showPet)
    if showItem and isHasTran then
        auto:setVisible(true)
        local num = auto:getChildByName("Num")
        num:setString(self.m_data.tranItemNum)
    else
        auto:setVisible(false)
    end

end

function LDCellUI:updateGetItem()
    self:setNodeVisible(2)
    -- print("self.m_data.itemId ==", self.m_data.itemId, self.m_data.itemNum)
    -- if self.m_pItemNode == nil then
        self.m_pItemRoot:removeChildByTag(0xf8)
        -- self.m_pItemRoot:removeAllChildren()
        self.m_pItemNode = Utils:GetItemCellValue(self.m_pItemRoot, 0, self.m_data.itemId, true, true, self.m_data.itemNum, nil, true)
        self.m_pItemNode:SetIsNonAutoFree(true)
        self.m_pItemNode.m_pUILayer:setTag(0xf8)
    -- end
    local nameStr = Utils:getItemNameByID(self.m_data.itemId)
    self.m_pItemName:setString(nameStr)
end

function LDCellUI:StartAnim()
    if self.m_data.itemId and self.m_data.itemId > 0 then
        self:animFinished()
    else
        local pAni = self.m_pShenJiangRoot:getChildByTag(0xff)
        if pAni == nil then
            pAni = ImodAnim:createWithFileSync("res2/fx/choukashenjiang")
            pAni:setIgnoreAnchorPointForPosition(false)
            pAni:setAnchorPoint(cc.p(0.5,0.5))
            pAni:setPosition(cc.p(0, 0))
            self.m_pShenJiangRoot:addChild(pAni, 2, 0xff)
        end
        pAni:PlayAction(0)
        if self.m_pPetModelNode == nil then
            self:animFinished()
            return
        end
        self.m_pPetModelNode:setPositionY(400)
        self.m_pPetModelNode:setScale(1)
        self.m_pPetModelNode:stopAllActions()
        local funcs = {}
        local moveAc = cc.EaseIn:create(cc.MoveTo:create(pAni:GetCurAniTime()/2, cc.p(0,0)), 5)
        table.insert(funcs, moveAc)
        if self.m_data.tranItemId and self.m_data.tranItemId > 0 then
            table.insert(funcs, cc.ScaleTo:create(0.25, 0))
            table.insert(funcs, cc.CallFunc:create(function()
                self.m_data.itemId = self.m_data.tranItemId
                self.m_data.itemNum = self.m_data.tranItemNum
                self:updateGetItem()
            end))
        else
            table.insert(funcs, cc.CallFunc:create(function()
                local pImage = self.m_pShenJiangRoot:getParent():getChildByName("Image")
                if pImage then
                    local pDiZuo = pImage:getChildByName("DiZuo")
                    if pDiZuo then
                        pDiZuo:setVisible(true)
                    end
                end
            end))    
        end
        table.insert(funcs, cc.CallFunc:create(handler(self, LDCellUI.animFinished)))
        local seq = cc.Sequence:create(funcs)
        self.m_pPetModelNode:runAction(seq)
    end
end

function LDCellUI:animFinished()
    local _ = self.m_pFinishCallback and self.m_pFinishCallback()
end

function LDCellUI:SetAnimFinishCallback(cb)
    self.m_pFinishCallback = cb
end

return LDCellUI