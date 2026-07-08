
local SaoDangResultUI = LUIBase:New()
SaoDangResultUI.__index = SaoDangResultUI
--local this = LTcpSocket
function SaoDangResultUI:New(saoDangData)
	local o = LUIBase:New()
	setmetatable(o,SaoDangResultUI)	
    o:Init(saoDangData)
	return o
end

--注册事件
-- -----------------------------------
function SaoDangResultUI:RegistMsgs()
    self.msgIds = 
    {
        LUIPetEvent.ChangePetLv,
    }
    self:RegistSelf(self,self.msgIds)
end

-- -----------------------------------
function SaoDangResultUI:ProcessEvent(msg)
    if msg.msgId == LUIPetEvent.ChangePetLv then
        self:RecvPetUp(msg.value)
    end
end

function SaoDangResultUI:RecvPetUp(data)
    self._petUpArr[data.pid] = true
end

function SaoDangResultUI:Init(saoDangData)

    self.m_pUILayer = cc.CSLoader:createNode("csd/fuben/saodangLayer.csb")
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)

   local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self._petUpArr = {}
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
    self:RegistMsgs()
    self:initData(saoDangData)
    self:initControlUI()
    self:updateUI()
end

function SaoDangResultUI:initData( data )
    -- body
    self._showType = data.showType or 0--0-道具、神将经验都显示，1-只显示道具
    self._resultData = data.result or {}
    self._callback = data.callback or nil --多次扫荡
    print("SaoDangResultUI:initData",self._showType)
end

function SaoDangResultUI:initControlUI( ... )
    -- body
    local bg = self.m_pUILayer:getChildByName("bg")
    bg:addClickEventListener(function( sender )
        -- self:colseUI()
    end)

    local closeBtn = bg:getChildByName("Btn_close")
    closeBtn:addClickEventListener(function( sender )
        -- body
        self:colseUI()
    end)

    self._listView =  bg:getChildByName("ListView_2")
    self._listView:setLocalZOrder(9)
    self._pCellItem = self.m_pUILayer:getChildByName("Panel")
    for i=1, 5 do
        self._pCellItem:getChildByName("Icon_Bg"..i):setVisible(false)
    end
    self._pCellPet = self.m_pUILayer:getChildByName("Panel1")
    for i=1, 5 do
        local petIcon = self._pCellPet:getChildByName("IconColor"..i)
        if petIcon ~= nil then
            petIcon:setVisible(false)
        end
        -- local nameStr = LDataConstMgr:GetPetData(petID).name
        -- name:setString(nameStr)
    end
    -----------------------------------------------------------------------
    local image = bg:getChildByName("Image")
    local saoDngOver = image:getChildByName("Button")
    saoDngOver:addClickEventListener(function( ... )
        -- body
        self:colseUI()
    end)

    local saoDngFiveTimes = image:getChildByName("Button1")
    if self._callback == nil then
        saoDngFiveTimes:setVisible(false)
    end
    saoDngFiveTimes:addClickEventListener(function ( sender )
        -- body
        if self._callback ~= nil then
            self._callback()
        end
        self:colseUI()
    end)
    self.m_btnLabel = saoDngFiveTimes:getChildByName("Text")
end

function SaoDangResultUI:updateUI( ... )
    self._curAddNum = 1
    local data = self._resultData[self._curAddNum]
    self.m_addSign = 0
    if data ~= nil and data.fightIndex == 0 then
        self.m_addSign = 1
    end
    self.m_btnLabel:setString(string.format(GUITips.RSI_FUBENMAP_RES6,#self._resultData))
    self:AddSchedule()
end


function SaoDangResultUI:addResult( ... )
    -- body
    local itemData = self._resultData[self._curAddNum]
    local pItem = self._pCellItem:clone()
    local times = pItem:getChildByName("Image3"):getChildByName("Text_9")
    print("itemData.fightIndex ========================>", itemData.fightIndex)
    local str = ""
    if itemData.fightIndex ~= nil then
        local idx = itemData.fightIndex
        if self.m_addSign == 1 then
            idx = idx +1
        end
        str = string.format(GUITips.RSI_FUBENMAP_RES16,idx)
    elseif itemData.levelId ~= nil then
        str = string.format(GUITips.RSI_XUEZHAN_TIP11, itemData.levelId)
    end
    times:setString(str)
    local itemList = {}
    local moneyList = {}
    for i=1, #itemData.itemList do
        local aData = itemData.itemList[i]
        -- if aData.itemNum < 1 then
        --     aData.itemNum = 1
        -- end
        if Utils:CheckIsMoney(aData[1]) then
            table.insert( moneyList, aData )
        else
            table.insert( itemList, aData )
        end
    end
    local moneyImgs = {}
    table.insert(moneyImgs,pItem:getChildByName("GoldIcon1"))
    table.insert(moneyImgs,pItem:getChildByName("GoldIcon4"))
    for i=1,2 do
        local iconImg = moneyImgs[i]
        if #moneyList < i then
            iconImg:setVisible(false)
        else
            local aData = moneyList[i]
            local imgPath = "item/equip"..LRoleDataMgr.GetItemPicId(aData[1])..".png"
            Utils:SafeLoadTexture(iconImg,imgPath,ccui.TextureResType.localType)
            local numLabel = iconImg:getChildByName("GoldNumBg"):getChildByName("Num")
            numLabel:setString(""..aData[3])
        end
    end
    for i=1, #itemList do
        local aData = itemList[i]
        local Icon_Bg = pItem:getChildByName("Icon_Bg"..i)
        local name = Icon_Bg:getChildByName("Name")
        name:setVisible(false)
        Icon_Bg:setVisible(true)
        local  Icon = Icon_Bg:getChildByName("IconBg")
        -- if aData.itemNum < 1 then
        --     aData.itemNum = 1
        -- end
        -- print("SaoDangResultUI:updateUI  ===== 222222222222222 >", aData.itemId, aData.itemNum)
        -- local item = Utils:GetItemCellValue(Icon, 0, aData.itemId, true, true, aData.itemNum, nil, true)
        item = Utils:ShowItemByConfigData(aData, Icon, nil, false, true)
        -- local nameStr = Utils:getItemNameByID(aData.itemId)
        -- name:setString(nameStr)
    end
    self._listView:pushBackCustomItem(pItem)
    self._listView:jumpToBottom()
end



function SaoDangResultUI:addPetResult( ... )
    -- body
    


    local ind = 0;
    local exp = 0;
    for i=1,#self._resultData do
        for j = 1, #self._resultData[i].itemList do
            local itemId = tonumber(self._resultData[i].itemList[j][1])
            if itemId == AppDef.SpecialItemId.PetExp then
                exp = exp + self._resultData[i].itemList[j][3];
            end
        end
    end
    if exp == 0 then 
        return;
    end
    local pCellPet = self._pCellPet:clone()
    self._listView:pushBackCustomItem(pCellPet)
    self._listView:jumpToBottom()
    local i = 0
    for j=1, #LRoleDataMgr.Pet.petlist do
        local petData = LRoleDataMgr.Pet.petlist[j]
        if petData.fightPos > 0 then
            i = i + 1
            local petIcon = pCellPet:getChildByName("IconColor"..i)
            petIcon:setVisible(true)
            local petID = LRoleDataMgr.Pet.petlist[i].id
            Utils:ShowPetOnItem(petID, petIcon, true)
            petIcon:getChildByName("Text_jiang1"):setString(string.format(GUITips.RSI_ZQX_HERO_LV_UP,exp))
            petIcon:getChildByName("Text"):setString(petData.level)


            local configData = JsonConfig.m_petLvUpExp.getDefByID(petData.level)
            local rate = math.floor(petData.exp * 100 / configData.exp_hero)
            local bar = petIcon:getChildByName("LoadingBar_2");
            bar:setPercent(rate)
            if self._petUpArr[petID] then
                petIcon:getChildByName("Image_27_0"):setVisible(true);
            else
                petIcon:getChildByName("Image_27_0"):setVisible(false);
            end

        end
    end
end

function SaoDangResultUI:DeleteSchedule()
    if self.m_refreshHandler ~= nil then
        Utils:unschedule(nil, self.m_refreshHandler)
        self.m_refreshHandler = nil
    end
end

function SaoDangResultUI:AddSchedule()
    self:DeleteSchedule()
    local function RefreshCallback(dt)
        if self._showType < 0 or self._showType > 1 then
            self:DeleteSchedule()
            return
        end
        if self._curAddNum <= #self._resultData then
            self:addResult()
            self._curAddNum = self._curAddNum + 1
        elseif self._curAddNum == #self._resultData + 1 then
            self:DeleteSchedule()
            if self._showType == 0 then
                self:addPetResult()
                self._curAddNum = self._curAddNum + 1
            end    
        end
    end
    self.m_refreshHandler = Utils:schedule(nil, RefreshCallback, 0.3, false)
end

function SaoDangResultUI:colseUI( ... )
    -- body
    Utils:DeleteUI("FuBenMap.SaoDangResultUI")
end


function SaoDangResultUI:onExit()
    self.m_pUILayer = nil
    self:DeleteSchedule()
    self:Destory()
end

return SaoDangResultUI