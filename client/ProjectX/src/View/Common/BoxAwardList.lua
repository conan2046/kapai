
local BoxAwardList = LUIBase:New()
BoxAwardList.__index = BoxAwardList
--local this = LTcpSocket
function BoxAwardList:New(boxInfo)
	local o = LUIBase:New()
	setmetatable(o,BoxAwardList)	
    o:Init(boxInfo)
	return o
end

--注册事件
-- -----------------------------------
function BoxAwardList:RegistMsgs()
    self.msgIds = 
    {
    }
    self:RegistSelf(self,self.msgIds)
end

-- -----------------------------------
function BoxAwardList:ProcessEvent(msg)

end

function BoxAwardList:Init(boxInfo)

    self.m_pUILayer = cc.CSLoader:createNode("csd/guaiwubaoxiangLayer.csb")
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)

   local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
    self._boxInfo = boxInfo
    self:initItemData()
    self:initControlUI()
    self:RefrashUI()
end

function BoxAwardList:initItemData( ... )
    -- body
    local data = JsonConfig.m_BoxReward.getDefByID(self._boxInfo.boxId)
    -- print("initItemData === 11111 >", self._boxInfo)
    -- dump(data, "initItemData   ==>")
    self._itemList = {}
    for i=1, #data.reward do
        local rewardData = data.reward[i]
        local itemData = {}
        itemData.id = rewardData[1]
        itemData.petID = rewardData[2]
        itemData.num = rewardData[3]
        table.insert(self._itemList, itemData)
    end
end

function BoxAwardList:initControlUI( ... )
    -- body
    self._IconColor = self.m_pUILayer:getChildByName("IconColor")
    self._IconColor:retain()
    self._IconColor:removeFromParent()

    local touchBg = self.m_pUILayer:getChildByName("Panel_1")
    touchBg:setVisible(true)
    touchBg:setSwallowTouches(true)

    local panel = self.m_pUILayer:getChildByName("Cangbaotu")
    local bg = panel:getChildByName("bg")
    local ImageList = bg:getChildByName("Image_bg"):getChildByName("IconList")
    self._iconNode = {}
    self._chooseNode = {}
    for i=1, 4 do
        local str = string.format("Icon_Bg%d", i)
        local node = ImageList:getChildByName(str)
        node:setVisible(false)
        table.insert(self._iconNode, node)
        local choose = node:getChildByName("Choose")
        choose:setVisible(false)
        table.insert(self._chooseNode, choose)
    end

    local Text_2 = bg:getChildByName("Image_bg"):getChildByName("Text_2")
    Text_2:setVisible(self._boxInfo.boxState == 0)
    if self._boxInfo.isStarType then
        Text_2:setString(string.format(GUITips.RSI_FUBENMAP_RES13, self._boxInfo.needStarNum))
    else
        local configData = JsonConfig.m_stageNodeConfig.getDefByID(self._boxInfo.stageId)
        -- dump(configData, "configData ====>")
        if configData then
            Text_2:setString(string.format(GUITips.RSI_FUBENMAP_RES14, configData.Name))
        end
    end

    local bgImage = bg:getChildByName("BgImage")
    bgImage:setVisible(false)

    self._btn = bg:getChildByName("ButtonOwn")
    local function OKEvent( sender )
        -- body
        self:closeUI()
    end
    self._btn:addClickEventListener(OKEvent)
    self:MarkIntaractCObj(self._btn)
    self._btn:setVisible(self._boxInfo.boxState ~= 1)
    if self._boxInfo.boxState == 0 then
        self._btn:getChildByName("Text"):setString(GUITips.RSI_FUBENMAP_RES10)
    end

    self._getAwardBtn = bg:getChildByName("Button")
    local function GetAwardEvent( sender )
        --领取宝箱

        if self._boxInfo.boxState == 0 then
            Utils:ShowScrollTips(GUITips.RSI_FUBENMAP_RES7)
            return
        end

        if self._boxInfo.boxState == 2 then
            Utils:ShowScrollTips(GUITips.RSI_FUBENMAP_RES8)
            return
        end

        LuaNetSendMsg:QueryGetBoxReward(4, self._boxInfo.type, self._boxInfo.chapterId, self._boxInfo.boxId)

        self:closeUI()
        
    end
    self:MarkIntaractCObj(self._getAwardBtn)
    self._getAwardBtn:addClickEventListener(GetAwardEvent)
    self._getAwardBtn:setVisible(self._boxInfo.boxState == 1)

    local title = bg:getChildByName("Title")
    local button = title:getChildByName("Button_1")
    local function closeEvent( sender )
        -- body
        self:closeUI()
    end
    button:addClickEventListener(closeEvent)
    self:MarkIntaractCObj(button)

end

function BoxAwardList:RefrashUI( ... )
    -- body
    -- dump(self._itemList, "RefrashUI =====================>")
    for i=1, #self._itemList do
        --test code
        if i > 4 then
            break
        end

        local data = self._itemList[i]
        self._iconNode[i]:setVisible(true)
        local grid = self._iconNode[i]:getChildByName("IconBg")
        local name = self._iconNode[i]:getChildByName("Name")
        if data.id ==  AppDef.AwrdItem.AWRD_ITEM_PET then
            local petIcon = self._IconColor:clone()
            grid:addChild(petIcon)
            -- print("data.num ==", data.petID)
            Utils:ShowPet(data.petID, grid, petIcon, true)
            local nameStr = LDataConstMgr:GetPetData(data.petID).name
            name:setString(nameStr)
        else
            local item = Utils:GetItemCellValue(grid, 0, data.id, true, true, data.num, nil, false)
            local nameStr = Utils:getItemNameByID(data.id)
            name:setString(nameStr)
        end
    end

end

function BoxAwardList:closeUI(  )
    -- body
    Utils:DeleteUI("Common.BoxAwardList")
end

function BoxAwardList:onExit()
    self.m_pUILayer = nil
    self:Destory()
end

return BoxAwardList