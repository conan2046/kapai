
local TreasureMapAwardUI = LUIBase:New()
TreasureMapAwardUI.__index = TreasureMapAwardUI
--local this = LTcpSocket
function TreasureMapAwardUI:New(recData)
	local o = LUIBase:New()
	setmetatable(o,TreasureMapAwardUI)	
    o:Init(recData)
	return o
end

--[[
注册UI消息
]]
function TreasureMapAwardUI:RegistMsgs()
    self.msgIds = 
    {
        LUIGetPetWingEvent.ShowFlyItems
    }
    self:RegistSelf(self, self.msgIds)
end


function TreasureMapAwardUI:ProcessEvent(msg)
    if msg.msgId == LUIGetPetWingEvent.ShowFlyItems then
        self._strTips = msg.value
    end
end

function TreasureMapAwardUI:Init(recData)

    self._data = recData
    self._curIndex = 1
    self._curCircle = 1
    self._isClosing = false
--测试代码
--    self:loadData()
--    dump(self._data, "TreasureMapAwardUI")
    self.m_pUILayer = cc.CSLoader:createNode("csd/CangbaotuLayer.csb")
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)

   local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)

    self:RegistMsgs()

    local panel = self.m_pUILayer:getChildByName("Cangbaotu")
    local bg = panel:getChildByName("bg")
    local ImageList = bg:getChildByName("Image_bg"):getChildByName("IconList")
    self._iconNode = {}
    self._chooseNode = {}
    for i=1, 15 do
        local str = string.format("Icon_Bg%d", i)
        local node = ImageList:getChildByName(str)
        table.insert(self._iconNode, node)
        local choose = node:getChildByName("Choose")
        choose:setVisible(false)
        table.insert(self._chooseNode, choose)
    end

    local bgImage = bg:getChildByName("BgImage")
    bgImage:setVisible(false)

    self._btn = bg:getChildByName("Button")
    local function OKEvent( sender )
        -- body
        self._btn:setTouchEnabled(false)
        self._btn:setBright(false)

        if self._curCircle <= 1 then
            self._curCircle = self._curCircle + 1
        end
    end
    self._btn:addClickEventListener(OKEvent)
	self:MarkIntaractCObj(self._btn)

    local title = bg:getChildByName("Title")
    local button = title:getChildByName("Button_1")
    local function closeEvent( sender )
        -- body
--        self:closeUI()
        if self._isClosing then
            return
        end
        self._isClosing = true
        self:ActEndEvent()
    end
    button:addClickEventListener(closeEvent)
	self:MarkIntaractCObj(button)

    self:loadUI()

    performWithDelay(AppDef.CurScene, function(sender)
            --开始播放
        self:TimerCallBack()

        end, 0.5)
end

function TreasureMapAwardUI:closeUI( ... )
    -- body
--    print("closeUI ===========================")
    LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "Activity.TreasureMapAwardUI")
    self:SendMsg(LGameMsg.m_initUIMsg)
end

function TreasureMapAwardUI:loadData()
    -- body
    local info = {}
    info.idx = 3
    info.num = 15
    info.awardInfo = {}
    for i = 1, info.num do
        local awardSt = {}
        local id = 835
        local num = 1
        awardSt.id = id
        awardSt.num = num
        table.insert(info.awardInfo, awardSt)
    end
    self._data = info

    self._curIndex = 1
    self._curCircle = 1
end

function TreasureMapAwardUI:loadUI()
    -- body
    for i = 1, #self._data.awardInfo do
        local data = self._data.awardInfo[i]
        local grid = self._iconNode[i]:getChildByName("IconBg")
        local item = Utils:GetItemCellValue(grid, 0, data.id, true, true, data.num, nil, false)
        local itemName = self._iconNode[i]:getChildByName("Name")
--        dump(item, "+++++++++++++++++++++++++++++++++++++++++")
--        print("TreasureMapAwardUI:loadUI itemName", item.m_pItem.m_name)
        
        local nameStr = Utils:getNameByItem(item)
        itemName:setString(nameStr)
        
    end
end

function TreasureMapAwardUI:TimerCallBack()
    local scheduler =  AppDef.Director:getScheduler()
    local function UpdateCD()
        self._curIndex = self._curIndex + 1
        if self:getLeftNum() <= 3  then

            self:UnRoundSchedule()
            self.m_schedulerID = scheduler:scheduleScriptFunc(UpdateCD, 0.5, false)
        elseif self:getLeftNum() <= 7 then
            --最后7步
            self:UnRoundSchedule()
            self.m_schedulerID = scheduler:scheduleScriptFunc(UpdateCD, 0.3, false)
        end

        if self._curIndex > 15 then
            self._curIndex = 1
            self._chooseNode[self._curIndex]:setVisible(true)
            self._chooseNode[15]:setVisible(false)
            self._curCircle = self._curCircle + 1
        else
            self._chooseNode[self._curIndex]:setVisible(true)
            self._chooseNode[self._curIndex - 1]:setVisible(false)
        end

        if self:isToEnd() then
            self:ActEndEvent()
        end

    end
    self:UnRoundSchedule()
    self._chooseNode[self._curIndex]:setVisible(true)
    self.m_schedulerID = scheduler:scheduleScriptFunc(UpdateCD, 0.1, false)
    
end

function TreasureMapAwardUI:UnRoundSchedule()
    if self.m_schedulerID then
        AppDef.Director:getScheduler():unscheduleScriptEntry(self.m_schedulerID)
        self.m_schedulerID = nil
    end
end

function TreasureMapAwardUI:getLeftNum()
    -- body
    local tocalNum = 30 + self._data.idx + 1
    local curNum = self._curIndex + (self._curCircle - 1) * 15
    return tocalNum - curNum
end

function TreasureMapAwardUI:isToEnd()
    -- body
    return  self._curCircle == 3 and self._curIndex >= self._data.idx + 1
end

function TreasureMapAwardUI:ActEndEvent( ... )
    -- body
    self:UnRoundSchedule()
    self._curIndex = 1
    self._curCircle = 1

    performWithDelay(AppDef.CurScene, function(sender)
    --开始播放
        local data = self._data.awardInfo[self._data.idx + 1]
--        dump(self._data, "=============")
--        print("getItem *******************************************", self._data.idx)

        local flyItem
        if self:isMoney(data.id) then
            flyItem = LFlyItem:New(LFlyItem.FlyType.Money, data.id)
        elseif data.id == AppDef.AwrdItem.AWRD_ITEM_POTEN then    -- 潜能
            flyItem = LFlyItem:New(LFlyItem.FlyType.Qianneng, data.id)
        else
            flyItem = LFlyItem:New(LFlyItem.FlyType.Item, data.id)
        end
        
        Utils:SendMsg(LUILogicEvent.ShowFlyItems,flyItem)


        LGameMsg.m_scrollTipsMsg:ChangeWithMsgId(LUILogicEvent.ShowSrcollTipsAtferBattle, LRoleDataMgr.IsHighTreasuerMsg)
        self:SendMsg(LGameMsg.m_scrollTipsMsg)

        self._isClosing = false
--使用藏宝图
        local pos = LRoleDataMgr:FindCangbaotuPos()
        if pos > 0 then
            performWithDelay(AppDef.CurScene, function(sender)
                LRoleDataMgr:useCangbaotu(pos)
                self:closeUI()
            end, 1)
        else
            self:closeUI()
        end

    end, 0.5)
end

function TreasureMapAwardUI:isMoney( itemId )
    -- body
        if itemId == AppDef.AwrdItem.AWRD_ITEM_COIN     -- 金币
            or itemId == AppDef.AwrdItem.AWRD_ITEM_BDYB     -- 绑定元宝
            or itemId == AppDef.AwrdItem.AWRD_ITEM_YUANBAO  -- 元宝
            or itemId == AppDef.AwrdItem.AWRD_ITEM_EXP      -- 经验
            or itemId == AppDef.AwrdItem.AWRD_ITEM_SHENPO   then --神魄
            return true
        end

        return false
end

function TreasureMapAwardUI:onExit()
    self.m_pUILayer = nil
    LRoleDataMgr.IsInHighTreasuer = false
    LRoleDataMgr.IsHighTreasuerMsg = ""
    self._isClosing = nil
    self:UnRoundSchedule()
    self:Destory()
end

return TreasureMapAwardUI