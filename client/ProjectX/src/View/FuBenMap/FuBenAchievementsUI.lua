
local FuBenAchievementsUI = LUIBase:New()
FuBenAchievementsUI.__index = FuBenAchievementsUI
--local this = LTcpSocket
function FuBenAchievementsUI:New(StarNum)
	local o = LUIBase:New()
	setmetatable(o,FuBenAchievementsUI)	
    o:Init(StarNum)
	return o
end

--注册事件
-- -----------------------------------
function FuBenAchievementsUI:RegistMsgs()
    self.msgIds = 
    {
        LUIFuBenMapEvent.updateFuBenAchievement,
    }
    self:RegistSelf(self,self.msgIds)
end

-- -----------------------------------
function FuBenAchievementsUI:ProcessEvent(msg)
    local msgId = msg:GetMsgId()
    if msgId == LUIFuBenMapEvent.updateFuBenAchievement then
        self:updateData(msg.value)
    end
end

function FuBenAchievementsUI:Init(StarNum)

    self.m_pUILayer = cc.CSLoader:createNode("csd/fuben/zhuxianchengjiu.csb")
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)

   local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
    self:RegistMsgs()
    self:initData(StarNum)
    self:initControlUI()
    --查询
    LuaNetSendMsg:QueryFuBenAchievement()
end

function FuBenAchievementsUI:initData ( StarNum )
    -- body
    self._totalStarNum = StarNum
    self._isHaveRedDot = false
    -- self._achievementsData = PetkaPaiManager:getFuBenAchievementsData()
end

function FuBenAchievementsUI:updateData( data )
    -- body
    dump(data, "FuBenAchievementsUI:updateData ===>")
    self._isHaveRedDot = false
    self._achievementsData = PetkaPaiManager:getFuBenAchievementsData(data)

    
    if #self._achievementsData < 1 then
        --所有奖励已经领取完,停留在上一个界面
        data.orderType = data.orderType - 1
        self._achievementsData = PetkaPaiManager:getFuBenAchievementsData(data)
        for k,v in pairs(self._achievementsData) do
            v.isFinish = true
        end
    end
    -- dump(self._achievementsData, "FuBenAchievementsUI:initControlUI 222222 ==>")

    self:updateUI()
    print("FuBenAchievementsUI:updateData == 11111111111>", self._isHaveRedDot)
    Utils:SetRedDotState(RedDotDef.ID.FuBenAchievement, self._isHaveRedDot)

end

function FuBenAchievementsUI:initControlUI( ... )
    -- body
    local Mask = self.m_pUILayer:getChildByName("Mask")
    Mask:addClickEventListener(function ( sender )
        -- body
        if not self._opened then
            return
        end
        self.m_timeline = cc.CSLoader:createTimeline("csd/fuben/zhuxianchengjiu.csb")
        self.m_pUILayer:runAction(self.m_timeline)
        self.m_timeline:gotoFrameAndPlay(50, 65, false)

        local function onCloseFrame()
            print("initControlUI overAction ==== 1111111111111 >")
            self:CloseUI()
        end
        self.m_timeline:setAnimationEndCallFunc("animation0", onCloseFrame)

    end)
    ------------------------------------------------------
    local zhuxianchengjiu_layer = self.m_pUILayer:getChildByName("zhuxianchengjiu_layer")
    local jiangli_layer = zhuxianchengjiu_layer:getChildByName("jiangli_layer")
    local Item_layer = jiangli_layer:getChildByName("Item_layer")
    self._itemList = {}
    for i=1, 6 do
        local Item = Item_layer:getChildByName("Item"..i)
        table.insert(self._itemList, Item)
        Item:addClickEventListener(handler(self, FuBenAchievementsUI.getAwardEvent))
    end

    local bar_layer = jiangli_layer:getChildByName("bar_layer")
    self._EXPBar = bar_layer:getChildByName("EXPBar")
    self._goalTxt = jiangli_layer:getChildByName("yilingqu_0")
    self._xingNum = jiangli_layer:getChildByName("xing"):getChildByName("xing_num")

    self.m_timeline = cc.CSLoader:createTimeline("csd/fuben/zhuxianchengjiu.csb")
    self.m_pUILayer:runAction(self.m_timeline)
    self.m_timeline:gotoFrameAndPlay(0, 50, false)
    self._opened = false
    local function onOpenEnd()
        self._opened = true
    end
    self.m_timeline:setAnimationEndCallFunc("animation1", onOpenEnd)

end


function FuBenAchievementsUI:updateUI( ... )
    -- body
    if self._achievementsData == nil or #self._achievementsData < 1 then
        return
    end
    for i=1, #self._itemList do
        local item = self._itemList[i]
        local data = self._achievementsData[i]
        local bg_icon = item:getChildByName("bg_icon")

        local canGet = not data.isFinish and self._totalStarNum >= data.condition

        if not self._isHaveRedDot and canGet then
            self._isHaveRedDot = true
        end

        bg_icon:setTouchEnabled(not canGet)
        Utils:GetItemCellValue(bg_icon, 0, data.reward[1], true, true, data.reward[3], nil, not canGet, true)

        local xingshu_layer = item:getChildByName("xingshu_layer")
        local num = xingshu_layer:getChildByName("Num")
        num:setString(tostring(data.condition))

        local FinishIcon = item:getChildByName("yilingqu")
        local prompt = item:getChildByName("Prompt")
        FinishIcon:setVisible(data.isFinish)
        prompt:setVisible(canGet)

        local Particle = item:getChildByName("Particle_1")
        Particle:setVisible(canGet)
        item:setTouchEnabled(canGet)
        -- item.userObject = data
        item:setTag(i)
    end

    local beginStar = PetkaPaiManager:getLastAchievementCondition(self._achievementsData[1].type)
    local rate = (self._totalStarNum - beginStar) / (self._achievementsData[6].condition - beginStar)
    self._EXPBar:setPercent(rate * 100)
    
    self._xingNum:setString(string.format("%d/%d", self._totalStarNum, self._achievementsData[6].condition))

    if self._totalStarNum < self._achievementsData[6].condition then
        local needStar = self._achievementsData[6].condition - self._totalStarNum
        local tipsStr = string.format(GUITips.RSI_FUBEN_ACHIEVEMENT, needStar)
        self._goalTxt:setString(tipsStr)
    else
        self._goalTxt:setVisible(false)
    end
    
end

function FuBenAchievementsUI:getAwardEvent( sender )
    -- body
    -- local data = sender.userObject
    -- print("FuBenAchievementsUI:getAwardEvent === 1111 >", data.id)
    local tag = sender:getTag()
    print("FuBenAchievementsUI:getAwardEvent ===>", tag)
    LuaNetSendMsg:QueryFuBenAchievementAward(tag)
end

function FuBenAchievementsUI:CloseUI( ... )
    -- body
    Utils:DeleteUI("FuBenMap.FuBenAchievementsUI")
end

function FuBenAchievementsUI:onExit()
    self.m_pUILayer = nil
    self:Destory()
end

return FuBenAchievementsUI