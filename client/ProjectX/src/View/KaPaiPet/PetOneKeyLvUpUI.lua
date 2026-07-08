
local PetOneKeyLvUpUI = LUIBase:New()
PetOneKeyLvUpUI.__index = PetOneKeyLvUpUI
--local this = LTcpSocket
function PetOneKeyLvUpUI:New(data)
	local o = LUIBase:New()
	setmetatable(o,PetOneKeyLvUpUI)	
    o:Init(data)
	return o
end

local ITEMINDEXBEGIN = 833
local ADDTYPE = 1
local MINUSTYPE = 2
--注册事件
-- -----------------------------------
function PetOneKeyLvUpUI:RegistMsgs()
    self.msgIds = 
    {
    }
    self:RegistSelf(self,self.msgIds)
end

-- -----------------------------------
function PetOneKeyLvUpUI:ProcessEvent(msg)

end

function PetOneKeyLvUpUI:Init(data)

    self.m_pUILayer = cc.CSLoader:createNode("csd/shenjiangyangcheng/yingxiongshengjiScene1.csb")
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)

   local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
    self:initData(data)
    self:initControlUI()
end

function PetOneKeyLvUpUI:initData( data )
    -- body
    self._petData = data
    self._itemList = {}
end

function PetOneKeyLvUpUI:initControlUI( ... )
    -- body
    local bg = self.m_pUILayer:getChildByName("bg")
    local close = bg:getChildByName("Btn_close")
    close:addClickEventListener(function ( sneder )
        -- body
        self:closeUI()
    end)

    local image = bg:getChildByName("Image")
    self._valueText = bg:getChildByName("Image_19"):getChildByName("TextField_1")
    self._value = 0
    self._oldValue = 0
    self._ToLevel = bg:getChildByName("Text_3_")

    self._maxLevel = bg:getChildByName("cailiao_0"):getChildByName("value")
    self._maxLevel:setString( string.format("%d", LRoleDataMgr.MyHeroInfo.level))
    
    local OnBtn = bg:getChildByName("Button")
    OnBtn:addClickEventListener(handler(self, PetOneKeyLvUpUI.shengJiEvent))

    local cancelBtn = bg:getChildByName("Button1")
    cancelBtn:addClickEventListener(function(sender)
        -- body
        self:closeUI()
    end)

    local ButtonP10 = bg:getChildByName("Button_+10")
    ButtonP10:addClickEventListener(function( sender )
        -- body
        self._oldValue = self._value
        self._value = self._value + 10

        if self._value > LRoleDataMgr.MyHeroInfo.level - self._petData.level then
            self._value = LRoleDataMgr.MyHeroInfo.level - self._petData.level
        end

        if self._value > AppDef.Pet.MaxLevel - self._petData.level then
            self._value = AppDef.Pet.MaxLevel - self._petData.level
        end

        self:setAmountValue(ADDTYPE)
    end)

    local ButtonM10 = bg:getChildByName("Button_-10")
    ButtonM10:addClickEventListener(function( sender )
        -- body
        self._oldValue = self._value
        self._value = self._value - 10
        if self._value < 0 then
            self._value = 0
        end
        self:setAmountValue(MINUSTYPE)
    end)

    local Button_add = bg:getChildByName("Button_+")
    Button_add:addClickEventListener(function( sender )
        -- body
        self._oldValue = self._value
        self._value = self._value + 1

        if self._value > LRoleDataMgr.MyHeroInfo.level - self._petData.level then
            self._value = LRoleDataMgr.MyHeroInfo.level - self._petData.level
        end

        if self._value > AppDef.Pet.MaxLevel - self._petData.level then
            self._value = AppDef.Pet.MaxLevel - self._petData.level
        end

        self:setAmountValue(ADDTYPE)
    end)

    local Button_mun =  bg:getChildByName("Button_-")
    Button_mun:addClickEventListener(function( ... )
        -- body
        self._oldValue = self._value
        self._value = self._value - 1
        if self._value < 0 then
            self._value = 0
        end
        self:setAmountValue(MINUSTYPE)
    end)

    self._textList = {}
    for i=1, 4 do
        local itemId = ITEMINDEXBEGIN + i
        local num = LRoleDataMgr.Equip:CountItemNumById(itemId)

        local btn_Item = self.m_pUILayer:getChildByName("btn_Item_"..i)

        local text = btn_Item:getChildByName("Text_23")
        text:setString(string.format("%d/%d", 0, num))

        local Item = btn_Item:getChildByName("Item")
        Utils:GetItemCellValue(Item, 0 , itemId, true, false, 0 , nil, true, true)
        table.insert(self._textList, text)
    end

    self:setAmountValue(ADDTYPE)
    -- JsonConfig.m_petLvUpExp

    self._petName = bg:getChildByName("Text_3")
    self._petName:setString(self._petData.name)

    self._level = bg:getChildByName("Text_3_0_0")
    self._level:setString(self._petData.level)

    self._IconColor = self.m_pUILayer:getChildByName("IconColor")
    Utils:ShowPetOnItem(self._petData.id, self._IconColor)


end

function PetOneKeyLvUpUI:setAmountValue(calcType)
    -- body
    --获得需要的物品和能升到的等级
    if self._value <= 0 then
        self._valueText:setString(tostring(self._value))
        self._ToLevel:setString(tostring(self._petData.level))
        self:resetCostStr()
        return
    end

    local addItemLis, addValue  = PetkaPaiManager:getPetCanUpToLV(self._petData, self._value, calcType, self._oldValue)
    self._value = addValue
    --不能升级则不增加消耗
    if addValue <= 0 or addValue == self._oldValue then
        if self._petData.level+ self._value>=LRoleDataMgr.MyHeroInfo.level then
            Utils:ShowScrollTips(GUITips.UI_QiRi_Shop_tips22)
        else
            Utils:ShowScrollTips(GUITips.UI_QiRi_Shop_tips19)
        end    
       
        return
    end
    self._itemList = addItemLis
    

    self._valueText:setString(tostring(self._value))
    local goalValue = self._petData.level + self._value
    local goalLevel = tostring(goalValue)
    self._ToLevel:setString(goalLevel)
    for i=1, #self._itemList do
        self:setCostStr(self._itemList[i])
    end
end

function PetOneKeyLvUpUI:resetCostStr( ... )
    -- body
    for i=1, #self._itemList do
        self._itemList[i].itemNum = 0
        self:setCostStr(self._itemList[i])
    end
end

function PetOneKeyLvUpUI:setCostStr(itemData)
    -- body
    local index = itemData.itemId - ITEMINDEXBEGIN
    if index > 4 or index < 1 then
        return
    end
    local totalNum = LRoleDataMgr.Equip:CountItemNumById(itemData.itemId)
    self._textList[index]:setString(string.format("%d/%d", itemData.itemNum, totalNum))

end

function PetOneKeyLvUpUI:shengJiEvent( sender )
    -- body

    if self._petData.level >= LRoleDataMgr.MyHeroInfo.level then
        Utils:ShowScrollTips(GUITips.RSI_GS_TIP17)
        return
    end

    local toLevel =  self._value + self._petData.level
    if toLevel > LRoleDataMgr.MyHeroInfo.level then
        toLevel = LRoleDataMgr.MyHeroInfo.level
    end

    if self._value  <= 0 or #self._itemList < 1 then
        Utils:ShowScrollTips(GUITips.UI_QiRi_Shop_tips19)
        return
    end
    
    LuaNetSendMsg:QueryOneKeyPetLvUp(self._petData.id, toLevel, self._itemList)
    Utils:SendMsg(LUIKaPaiPetEvent.updatePetLvUp, self._itemList)
    self:closeUI()
    
end

function PetOneKeyLvUpUI:closeUI( ... )
    -- body
    Utils:DeleteUI("KaPaiPet.PetOneKeyLvUpUI")
end

function PetOneKeyLvUpUI:onExit()
    self.m_pUILayer = nil
    self:Destory()
end

return PetOneKeyLvUpUI