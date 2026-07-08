local ShenshouUI = LUIBase:New()
ShenshouUI.__index = ShenshouUI

function ShenshouUI:New()
    local o = LUIBase:New()
    setmetatable(o,ShenshouUI)  
    o:Init()
    return o
end

--[[
注册UI消息
]]
function ShenshouUI:RegistMsgs()
    self.msgIds = 
    {
        LUIActivityEvent.ShenshouResult,
    }
    self:RegistSelf(self,self.msgIds)
end

function ShenshouUI:ProcessEvent(msg)
    if msg.msgId == LUIActivityEvent.ShenshouResult then
        self:ShowCurQuality()
    end
end

function ShenshouUI:Init()
    cc.SpriteFrameCache:getInstance():addSpriteFrames("res/UI/csd/Plist/ui_commonPlist_PList.plist","res/UI/csd/Plist/ui_commonPlist_PList.png")
    self:RegistMsgs()
    self.m_pUILayer = cc.CSLoader:createNode("csd/ShenshouLayer.csb")
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)
    local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
    self:InitData()
    self:AddTouchEvt()
    self:InitListView()
    self:ShowCurQuality()
end

function ShenshouUI:onExit()
    self:Destory()
end

function ShenshouUI:InitData()
    self.m_panelUI = self.m_pUILayer:getChildByName("Panel")
    self.m_functionBg = self.m_panelUI:getChildByName("Function")
    self.m_autoRefreshBg = self.m_functionBg:getChildByName("Check")
    self.m_listBg = self.m_panelUI:getChildByName("List")
    -- self.m_panelUI:setSwallowTouches(false) -- 拦截点击
    -- 下边信息部分
    -- 刷新按钮
    self.m_pRefreshBtn = self.m_functionBg:getChildByName("Button1")
    -- 护送按钮
    self.m_pStartBtn = self.m_functionBg:getChildByName("Button2")
    -- 刷新消耗
    self.m_RefreshMoney = self.m_functionBg:getChildByName("Tips"):getChildByName("Refresh"):getChildByName("Text_38")
    -- 当前品质
    self.m_curQualityBg = self.m_functionBg:getChildByName("Quality")
    self.m_curQuality = self.m_curQualityBg:getChildByName("Name")
    self.m_qualityText = Utils:CreateColorText(self.m_curQualityBg, self.m_curQuality, "Quality1")
    -- 刷新前品质
    self.m_preQuality = nil
    -- 次数
    self.m_curTimesBg = self.m_functionBg:getChildByName("Times")
    self.m_curTimes = self.m_curTimesBg:getChildByName("Num")
     -- self.m_TimesText = Utils:CreateColorText(self.m_curTimesBg, self.m_curTimes, "Num1")
    -- 奖励
    self.m_curReward = self.m_functionBg:getChildByName("EXP"):getChildByName("Num")
    -- 刷新选择
    self.m_autoRefreshBtn = self.m_autoRefreshBg:getChildByName("CheckBox")
    -- 刷新列表
    self.m_refreshList = self.m_autoRefreshBg:getChildByName("BtnList")
    self.m_refreshList:setVisible(false)
    self.m_refreshList:setTouchEnabled(false)
    -- 选择按键
    self.m_pQualityBtn = {}
    -- 选择刷新品质
    self.m_refreshQuality = self.m_autoRefreshBg:getChildByName("Num")
    self.m_refreshQuality = Utils:CreateColorText2(self.m_refreshQuality, self.m_refreshQuality, self.m_refreshQuality:getContentSize())
    -- self.m_refreshQuality:setString(GUITips["RSI_Shenshou_Color"..self.m_selectIdx])
    self.m_refreshQuality:setString(GUITips.RSI_Shenshou_Color4)
    -- 品质选择展开按钮
    self.m_spreadBtn = self.m_autoRefreshBg:getChildByName("Button")
    -- 选择刷新品质
    self.m_refreshUp = self.m_spreadBtn:getChildByName("Up")
    -- 选择刷新品质
    self.m_refreshDown = self.m_spreadBtn:getChildByName("Down")
    self.m_isSpread = false
    self.m_refreshDown:setVisible(false)

    -- list部分
    -- 左移
    self.m_pLeftArrow = self.m_listBg:getChildByName("LeftArrow")
    self.m_pLeftArrow:setTouchEnabled(true)
    -- 右移
    self.m_pRightArrow = self.m_listBg:getChildByName("RightArrow")
    self.m_pRightArrow:setTouchEnabled(true)
    -- 列表
    self.m_pListView = self.m_listBg:getChildByName("ListView")
    -- cell
    self.m_pCell = self.m_listBg:getChildByName("BossBg")
    self.m_pCell:getChildByName("ChooseBg"):setVisible(false)
    -- star
    self.m_pStar = self.m_listBg:getChildByName("StarBg")
    self.m_selectIdx = 4
end

--[[
显示刷新信息
]]
function ShenshouUI:ShowRefreshInfo()
    if self.m_isSpread then -- 已经展开
        self.m_refreshList:setVisible(false)
        self.m_isSpread = false
        self.m_refreshUp:setVisible(true)
        self.m_refreshDown:setVisible(false)
    else -- 还没有展开
        self.m_refreshList:setVisible(true)
        self.m_isSpread = true
        self.m_refreshUp:setVisible(false)
        self.m_refreshDown:setVisible(true)
    end
end

function ShenshouUI:AddTouchEvt()
    -- 左移
    local function LeftArrowCallback(pSender, inputType)
        self.m_pListView:jumpToLeft()
    end
    self.m_pLeftArrow:addClickEventListener(LeftArrowCallback)
	self:MarkIntaractCObj(self.m_pLeftArrow)

    -- 右移
    local function RightArrowCallback(pSender, inputType)
        self.m_pListView:jumpToRight()
    end
    self.m_pRightArrow:addClickEventListener(RightArrowCallback)
	self:MarkIntaractCObj(self.m_pRightArrow)

    -- 展开
    local function SpreadCallback(pSender, inputType)
        self:ShowRefreshInfo()
    end
    self.m_spreadBtn:addClickEventListener(SpreadCallback)
	self:MarkIntaractCObj(self.m_spreadBtn)

    -- 选择刷新品质
    local function SelectCallback(pSender, inputType)
        self.m_selectIdx = pSender:getTag()
        self.m_refreshQuality:setString(GUITips["RSI_Shenshou_Color"..self.m_selectIdx])
        self:ShowRefreshInfo()
    end
    for i=1,4 do
        self.m_pQualityBtn[i] = self.m_refreshList:getChildByName("Button_"..i)
        self.m_pQualityBtn[i]:setTag(i)
        self.m_pQualityBtn[i]:addClickEventListener(SelectCallback)
		self:MarkIntaractCObj(self.m_pQualityBtn[i])
    end

    -- 刷新
    local function RefreshCallback(pSender, inputType)
		local Data = LRoleDataMgr.MyHeroInfo.m_Convoy
		if LRoleDataMgr.MyHeroInfo:GetDetailData().Money < Data.useMoney then
			Utils:ShowGoldTips(AppDef.AwrdItem.AWRD_ITEM_COIN)
			return
		end
        if self.m_autoRefreshBtn:isSelected() then
            LuaNetSendMsg:QueryConvoyQuality(self.m_selectIdx)
        else
            LuaNetSendMsg:QueryConvoyQuality(0)
        end
    end
    self.m_pRefreshBtn:addClickEventListener(RefreshCallback)
	self:MarkIntaractCObj(self.m_pRefreshBtn)
    -- 开始护送
    local function StartCallback(pSender, inputType)
        LuaNetSendMsg:QueryConvoyTaskRecv()
    end
    self.m_pStartBtn:addClickEventListener(StartCallback)
	self:MarkIntaractCObj(self.m_pStartBtn)
end

function ShenshouUI:InitListView()
    local gText = self.m_pCell:getChildByName("BossName"):getChildByName("Name")
    local pFontSize = gText:getFontSize()
    local cellSize = gText:getContentSize()
    local color = gText:getTextColor()
    local monserId = AppDef.HusongMonserPics
    for i=1,5 do
        local cell = self.m_pCell:clone()
        cell:setTag(i)
        local listBg = cell:getChildByName("List")
        local list = listBg:getChildByName("StarsList")
        local curSize = self.m_pStar:getContentSize()
        local Quality = GUITips["RSI_Shenshou_Quality"..i-1]
        local nameText = cell:getChildByName("BossName"):getChildByName("Name")
        list:setTouchEnabled(false)
        curSize.width = curSize.width * i
        listBg:setContentSize(curSize)

        local bg = cell:getChildByName("BossName")
        local text = bg:getChildByName("Name")
        local colorText = Utils:CreateColorText(bg, text, "Name1")
        colorText:triggleInit(Quality, colorText.cellSize, -132,
            colorText.color, colorText.pFontSize,false,0,0,0,true,false)
        colorText:setPositionX(text:getPositionX() - colorText.cellSize.width/2)
        colorText:setPositionY(text:getPositionY() + colorText.cellSize.height / 2)
        for j=1,i do
            local star = self.m_pStar:clone()
            list:pushBackCustomItem(star)
        end
        self.m_pListView:pushBackCustomItem(cell)
        local size = cell:getChildByName("ImageBase"):getContentSize()
        local imod = Utils:CreateImod("Monster/btm"..monserId[i].."_zd",cc.p(size.width/2, size.height*3/4),cell:getChildByName("ImageBase"),1)
        imod:PlayActionRepeat(1)
    end
end

--[[
显示当前品质
]]
function ShenshouUI:ShowCurQuality()
    local Data = LRoleDataMgr.MyHeroInfo.m_Convoy
    local cell = self.m_pListView:getItem(Data.Quality)
    local Quality = GUITips["RSI_Shenshou_Quality"..Data.Quality]
    local useMoney = string.format(GUITips.RSI_Shenshou_Use_Money, Data.useMoney)
    if Data.Quality == 4 then
        self.m_pRefreshBtn:setTouchEnabled(false)
        self.m_pRefreshBtn:setBright(false)
    else
        self.m_pRefreshBtn:setTouchEnabled(true)
        self.m_pRefreshBtn:setBright(true)
    end
    -- 取消刷新前的选择
    if self.m_preQuality ~= nil then
        local preCell = self.m_pListView:getItem(self.m_preQuality)
        preCell:getChildByName("ChooseBg"):setVisible(false)
    end
    self.m_preQuality = Data.Quality
    if self.m_preQuality >= 4 then
        self.m_pListView:jumpToRight()
    end
    cell:getChildByName("ChooseBg"):setVisible(true)
    -- 刷新消耗
    self.m_RefreshMoney:setString(useMoney)
    -- 品质
    self.m_curReward:setString(Quality)
    local cellSize = self.m_curReward:getContentSize()
    self.m_qualityText:triggleInit(Quality, cellSize, -132,self.m_qualityText.color, self.m_qualityText.pFontSize,false,0,0,0,true,false)
    self.m_qualityText:setPositionX(self.m_qualityText.oldX - (self.m_curQualityBg:getContentSize().width - self.m_qualityText.cellSize.width)/2-10)
    self.m_qualityText:setPositionY(self.m_qualityText.oldY + self.m_qualityText.cellSize.height / 2)
    -- 次数
    local times = string.format(GUITips.RSI_Shenshou_Times, Data.AvaNum, Data.MaxNum)
    self.m_curTimes:setString(times)
    -- self.m_TimesText:triggleInit(times, self.m_TimesText.cellSize, -132,
    --     self.m_TimesText.color, self.m_TimesText.pFontSize,false,0,0,0,true,false)
    -- self.m_TimesText:setPositionX(self.m_TimesText.oldX - self.m_TimesText.cellSize.width/2)
    -- self.m_TimesText:setPositionY(self.m_TimesText.oldY + self.m_TimesText.cellSize.height / 2)
    -- 奖励
    self.m_curReward:setString(tostring(Data.Exp))
end

return ShenshouUI
