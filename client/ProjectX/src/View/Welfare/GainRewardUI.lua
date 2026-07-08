
local GainRewardUI = LUIBase:New()
GainRewardUI.__index = GainRewardUI
--local this = LTcpSocket
function GainRewardUI:New(awardInfo)
	local o = LUIBase:New()
	setmetatable(o,GainRewardUI)	
    o:Init(awardInfo)
	return o
end

--注册事件
-- -----------------------------------
function GainRewardUI:RegistMsgs()
    self.msgIds = 
    {
        LUIResRecoveryEvent.showAwardLayer,
        LUIResRecoveryEvent.changeTitleTxt,
    }
    self:RegistSelf(self,self.msgIds)
end

-- -----------------------------------
function GainRewardUI:ProcessEvent(msg)
    if msg.msgId == LUIResRecoveryEvent.showAwardLayer then
        self:ShowAward(msg.value)
    end

    if msg.msgId == LUIResRecoveryEvent.changeTitleTxt then
        self:setTitleText(msg.value)
    end
        
end

function GainRewardUI:Init(awardInfo)
    self.m_pUILayer = cc.CSLoader:createNode("csd/FirstRewardLayer.csb")
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)

    local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)

    self:RegistMsgs()

    self._awardInfo = awardInfo
    self:initUI()
    self:ShowAward(awardInfo)
end

function GainRewardUI:initUI( ... )
    -- body
    local reword = self.m_pUILayer:getChildByName("Reward")
    local bg = reword:getChildByName("bg")
    local titleBg = bg:getChildByName("Title"):getChildByName("TitleBg")
    self._titleTxt = titleBg:getChildByName("Text")
    self._titleTxt:setString(GUITips.RSI_GS_TIP_RECOVERY_GAIN)

    local tipsText = reword:getChildByName("TipsText")
    tipsText:setVisible(false)
    local text = reword:getChildByName("Text")
    self._IconBg =  reword:getChildByName("IconBg")
    self._IconBg:setVisible(true)

    self._awardList = self._IconBg:getChildByName("List")
    self._awardList:getChildByName("IconBtn1"):setVisible(false)
    self._awardList:getChildByName("IconBtn2"):setVisible(false)
    self._awardList:getChildByName("IconBtn3"):setVisible(false)
    self._awardCell = self._awardList:getChildByName("IconBtn1")

    local btnConfirm = reword:getChildByName("Btn_Confirm")
    local text = btnConfirm:getChildByName("Text")
    text:setString(GUITips.RSI_GS_TIP_RECOVERY_SURE)
    local function confirmEvent( ... )
        -- body
        self:closeDialog()
    end
    btnConfirm:addClickEventListener(confirmEvent)
	self:MarkIntaractCObj(btnConfirm)
    local starsList = reword:getChildByName("StarsList")
    starsList:setVisible(false)

    local TextBg = reword:getChildByName("TextBg")
    TextBg:setVisible(false)



end

function GainRewardUI:closeDialog( ... )
    -- body
    LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "Welfare.GainRewardUI")
    self:SendMsg(LGameMsg.m_initUIMsg)
end

function GainRewardUI:ShowAward(awardList)
    -- body
    local btns = {}
    self._awardList:removeAllChildren()
--    print("awardInfo ***********", #awardList)

    if #awardList > 4 then
        local listView  = self._awardList:getChildByTag(100106)
        if listView == nil then
            listView = ccui.ListView:create()
            listView:setDirection(LISTVIEW_DIR_HORIZONTAL)
            listView:setContentSize(self._awardList:getContentSize())
            listView:setAnchorPoint(cc.p(0, 0))
            listView:setPosition(cc.p(0, 0))
            -- 关闭惯性滑动
            listView:setBounceEnabled(false)
            listView:setSwallowTouches(false)
            -- 隐藏滚动条
            listView:setScrollBarEnabled(false)
            self._awardList:addChild(listView, 5)
            listView:setTag(100106)
        end

        for i = 1, #awardList do
            local data = awardList[i]
            -- local awardui = cc.Sprite:create()
            -- awardui:setContentSize(cc.size(88, 88))
            local awardui = self._awardCell:clone()
            awardui:setVisible(true)
            Utils:GetItemCellValue(awardui, 0, data.awardType, true, true, data.awardValue, nil, true)
            local name = awardui:getChildByName("Name")
            local nameStr = Utils:getItemNameByID(data.awardType)
            name:setVisible(true)
            name:setString(nameStr)
            awardui:setAnchorPoint(cc.p(0.5, 0.5))
            awardui:setTag(i)
            listView:pushBackCustomItem(awardui)
        end

    else
        for i = 1, #awardList do
            local data = awardList[i]
            -- local awardui = cc.Sprite:create()
            -- awardui:setContentSize(cc.size(88, 88))
            local awardui = self._awardCell:clone()
            awardui:setVisible(true)
            Utils:GetItemCellValue(awardui, 0, data.awardType, true, true, data.awardValue, nil, true)
            local name = awardui:getChildByName("Name")
            local nameStr = Utils:getItemNameByID(data.awardType)
            name:setVisible(true)
            name:setString(nameStr)
            self._awardList:addChild(awardui)
            awardui:setAnchorPoint(cc.p(0.5, 0.5))
            awardui:setPositionY(self._awardList:getContentSize().height / 2)
            awardui:setTag(i)
            table.insert(btns, awardui)
        end
        Utils:AlignNodes(self._awardList, btns, {30}, 3, false)
    end

end

function GainRewardUI:setTitleText( txt )
    -- body
    self._titleTxt:setString(txt)
end

function GainRewardUI:onExit()
    self:Destory()
    self.m_pUILayer = nil
    self._awardCell = nil
end

return GainRewardUI