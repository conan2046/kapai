local XueZhanMainUI = LUIBase:New()
XueZhanMainUI.__index = XueZhanMainUI
XueZhanMainUI.IsHideInBattle = true
function XueZhanMainUI:New()
    local o = LUIBase:New()
    setmetatable(o,XueZhanMainUI) 
    o:Init()
    return o
end

function XueZhanMainUI:Init()
    self.Script = "XueZhan.XueZhanMainUI"
    self.m_pUILayer = cc.CSLoader:createNode("csd/xuezhan/XuezhanMain.csb")
    local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
    self:RegistMsgs()
    self:InitData()
    self:ShowTodayInfo()
    self:ShowItemNum()
    self:ShowRankInfo()

    Utils:SendMsg(LUIFClassBgEvent.SetTitle, GUITips.UI_Title_XueZhan)
    Utils:SendMsg(LUIRoleDataChangeEvent.BGVisible, false)
    Utils:SendMsg(LUIFClassBgEvent.SetCloseCallback,handler(self,XueZhanMainUI.CloseUI))
    Utils:SendMsg(LUIFClassBgEvent.HelpBtn,AppDef.FCBHelp.XueZhan)
    self.m_rankType = 22
    if LRankDataMgr.m_myInfo[self.m_rankType] ==  nil then
        LuaNetSendMsg:QueryRankList(self.m_rankType)
    end
    Utils:QueryXueCurRank(1)
    self:UpdateRedDot()
end

--[[
注册UI消息
]]
function XueZhanMainUI:RegistMsgs()
    self.msgIds = 
    {
        LUIRankEvent.RankListInfo,
        LUIXueZhanEvent.RefreshBtnState,
        LUIRedDotEvent.UpdateRedDotState,
    }
    self:RegistSelf(self,self.msgIds)
end

function XueZhanMainUI:ProcessEvent(msg)
    if msg.msgId == LUIRankEvent.RankListInfo then
        if msg.value == self.m_rankType then
            self.m_rankSign = true
            self:ShowRankInfo()
            self:ShowTodayInfo()
            --print("1111111111111111")
        end
    elseif msg.msgId == LUIXueZhanEvent.RefreshBtnState then
        self:ShowTodayInfo()
        self:ShowItemNum()
    elseif msg.msgId == LUIRedDotEvent.UpdateRedDotState then
        local data = msg.value
        if data ~= nil and data.id == RedDotDef.ID.ShopWanFaXueZhan then
            self:UpdateRedDot()
        end
    end
end

function XueZhanMainUI:InitData()
    local panel = self.m_pUILayer:getChildByName("Panel_xuezhan")
    panel:setTouchEnabled(false)
    self.m_todaypanel = panel:getChildByName("today")
    self.m_todayLabel = self.m_todaypanel:getChildByName("Text1")
    self.m_forecastRankLabel = self.m_todaypanel:getChildByName("Text2")
    self.m_forecastAwardLabel = self.m_todaypanel:getChildByName("Text3")
    self.m_forecastItems = {}
    self.m_forecastAwardImgs = {}
    for i=1,4 do
        self.m_forecastAwardImgs[i] = self.m_forecastAwardLabel:getChildByName("Icon"..i)
    end
    local startBtn = panel:getChildByName("start"):getChildByName("btn_paihangbang")
    startBtn:addClickEventListener(handler(self, XueZhanMainUI.StartCallBack))
    startBtn.userObject = 0
    self.m_startBtn = startBtn

    self.m_startLabel = startBtn:getChildByName("start")
    self.m_Label = startBtn:getChildByName("Text")
    self.m_drawLabel = startBtn:getChildByName("text_lingqu")

	local effect = startBtn:getChildByName("effect_xuezhan_1")
	local effcet = self:SetEffect()
    effcet:setName("effcet") 
    effect:addChild(effcet)

    local rightBottom = panel:getChildByName("youxia")
    local shopBtn = rightBottom:getChildByName("btn_shangdian")
    local rankBtn = rightBottom:getChildByName("btn_paihangbang")
    shopBtn:addClickEventListener(function (sender)
        Utils:OpenFunction(AppDef.EModuleID.EMID_SHOP_XUEZHAN)
    end)
    rankBtn:addClickEventListener(handler(self, XueZhanMainUI.OpenRankList))
    rankBtn:getChildByName("Prompt"):setVisible(false)
    self.m_shopPrompt = shopBtn:getChildByName("Prompt")

    self.m_itemNumImg = shopBtn:getChildByName("Icon")
    local str = "res/UI/Icon/ui_huobi_icon/huobi_"..LRoleDataMgr.GetItemPicId(AppDef.SpecialItemId.StarExp)..".png"
    Utils:SafeLoadTexture(self.m_itemNumImg,str,ccui.TextureResType.plistType)
    self.m_itemNumLabel = self.m_itemNumImg:getChildByName("Text")
    self.m_forecastRankLabel1 = rankBtn:getChildByName("base"):getChildByName("Text")

    --排行榜
    local rankPanel = panel:getChildByName("Popup")
    self.m_ayerRankLabel = rankPanel:getChildByName("MyRank")
    self.m_listView = rankPanel:getChildByName("ListView")
    self.m_itemCell = rankPanel:getChildByName("txtlayer")
    self.m_itemCell:retain()
    self.m_itemCell:removeFromParent()
    local btn = rankPanel:getChildByName("btn_Upgrade")
    btn:addClickEventListener(handler(self, XueZhanMainUI.OpenRankList))
    self.m_xuezhanLabel = rankPanel:getChildByName("firstDay_tips")
    self.m_xuezhanLabel:setVisible(false)

    self.m_myRank = 0
    self.m_rankSign = false
end

function XueZhanMainUI:SetEffect()
    local bgAnim = "res2/animation/effect_xuezhan_1"
    local m_pBgAni = ImodAnim:create()
    m_pBgAni:initAnimWithNameSync(bgAnim)
    m_pBgAni:PlayActionRepeat(0)
    m_pBgAni:setScale(scale or 1)
    return m_pBgAni
end

-- function XueZhanMainUI:QueryXueCurRank()
--     local data = LActivityManager:GetXueZhanData()
--     local sign = false
--     if data.m_state == 1 then
--         sign = true
--     elseif data.m_cnt == 0 and data.m_state == 3 then
--         local time = os.time()
--         if data.m_forecastTime == 0 or time - data.m_forecastTime > 600 then
--             data.m_forecastTime = os.time()
--             sign = true
--         end
--     end
--     if sign then
--         LuaNetSendMsg:QueryXueZhanInfo(17)
--     end
-- end

function XueZhanMainUI:OpenRankList()
    Utils:OpenRankUI(AppDef.EModuleID.EMID_RANK_XueZhan)
end

--开始按钮
function XueZhanMainUI:StartCallBack(sender)
    sender.userObject = sender.userObject or 0
    if sender.userObject == 0 then
        return
    end
    local data = LActivityManager:GetXueZhanData()
    if data.m_cnt == 0 and data.m_state == 3 then
        Utils:ShowScrollTips(GUITips.RSI_XUEZHAN_TIP15)
        return
    end
    if sender.userObject == 1 then
        LuaNetSendMsg:QueryXueZhanInfo(16)
        return
    end
    if data.m_enemyZhenId[1] == 0 then
        LuaNetSendMsg:QueryXueZhanInfo(2)
        self:CloseUI()
    else
        self:CloseUI()
        LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "XueZhan.XueZhanChapterUI",AppDef.UIType.FirstClassLayer)
        self:SendMsg(LGameMsg.m_initUIMsg)
    end
end

function XueZhanMainUI:ShowTodayInfo()
    local data = LActivityManager:GetXueZhanData()
    --self.m_startLabel:setString(GUITips.RSI_XUEZHAN_TIP4)
    self.m_Label:setString("")
    --print(data.m_state,data.m_cnt)
    if data.m_maxCnt > 0 then
        local curCnt = data.m_cnt
        -- if data.m_cnt < data.m_maxCnt and data.m_state ~= 3 then
        --     curCnt = data.m_cnt + 1
        -- end
        local cnt = data.m_maxCnt-curCnt
        self.m_Label:setString(string.format(GUITips.RSI_XUEZHAN_TIP10,cnt,curCnt))
    end
    
    self.m_drawLabel:setVisible(false)
    self.m_startLabel:setVisible(false)
    if data.m_rewardState == 1 then
        self.m_startLabel:setVisible(true)
        self.m_startBtn.userObject = 2
    else
        if self.m_rankSign then
            local sign = true
            if self.m_myRank > 0 then
                local cfg = JsonConfig.GetRewardRankCfg(self.m_rankType,self.m_myRank)
                if cfg ~= nil then
                    self.m_drawLabel:setVisible(true)
                    self.m_startBtn.userObject = 1
                    sign = false
                end
            end
            if sign then
                self.m_startLabel:setVisible(true)
                self.m_startBtn.userObject = 2
            end
        end
    end
    if data.m_maxLevelId == nil or data.m_maxLevelId == 0 then
        self.m_todaypanel:setVisible(false)
        return
    end
    data.m_maxLevelStar = data.m_maxLevelStar or 1
    self.m_todayLabel:setString(string.format(GUITips.RSI_XUEZHAN_TIP1,data.m_maxChapterId,data.m_maxLevelId,data.m_maxLevelStar))
    self.m_forecastRankLabel:setString(string.format(GUITips.RSI_XUEZHAN_TIP2,data.m_forecastRankId))
    if data.m_forecastRankId > 0 then
        self.m_forecastAwardLabel:setVisible(true)
        for i=1,4 do
            local value = data.m_forecastAwards[i]
            if value == nil then
                self.m_forecastAwardImgs[i]:setVisible(false)
            else
                self.m_forecastAwardImgs[i]:setVisible(true)
                self.m_forecastItems[i] = Utils:GetItemCellValue(self.m_forecastAwardImgs[i], 0, value.id, true, true, value.num, self.m_forecastItems[i],false,true)
            end
        end
    else
        self.m_forecastAwardLabel:setVisible(false)
    end
end

function XueZhanMainUI:ShowItemNum()
    local data =  LActivityManager:GetXueZhanData()
    self.m_forecastRankLabel1:setString(string.format(GUITips.RSI_XUEZHAN_TIP3,data.m_forecastRankId))

    local myJingHua = LRoleDataMgr.MyHeroInfo:GetDetailData():GetXinXiuJingHua() or 0
    self.m_itemNumLabel:setString(myJingHua)--代币道具数量
end

function XueZhanMainUI:ShowMyRank()
    self.m_myRank = 0
    local data = LRankDataMgr.m_myInfo[self.m_rankType]
    if data ~= nil then
        self.m_myRank = LRankDataMgr.m_myInfo[self.m_rankType].slotIndex or 0
    end
    local str = GUITips.RSI_XUEZHAN_TIP22..":"
    if self.m_myRank == 0 then
        str = str..GUITips.RSI_XUEZHAN_TIP6
    else
        str = str..string.format(GUITips.RSI_XUEZHAN_TIP23,self.m_myRank)
    end
    self.m_ayerRankLabel:setString(str)
end

function XueZhanMainUI:ShowRankInfo()
    self:ShowMyRank()
    self:ShowRankList()
end

function XueZhanMainUI:ShowRankList()
    if LRankDataMgr.m_ranks[self.m_rankType] == nil then
        return
    end
    self.m_listView:removeAllItems()
    local list = LRankDataMgr.m_ranks[self.m_rankType]
    for i=1,#list do
        local cell = self.m_itemCell:clone()
        cell.userObject = i
        self.m_listView:pushBackCustomItem(cell)
        self:ShowOneRank(cell,list[i])
    end
    if #list == 0 then
        self.m_xuezhanLabel:setVisible(true)
    else
        self.m_xuezhanLabel:setVisible(false)
    end
end

function XueZhanMainUI:ShowOneRank(sender,data)
    if data == nil then
        return
    end
    local nameLabel = sender:getChildByName("name")
    local chapterLabel = sender:getChildByName("score")
    local starLabel = sender:getChildByName("starnum")
    local rankPanel = sender:getChildByName("Panel_rank")
    local rankLabel = rankPanel:getChildByName("rank")
    rankLabel:setString("")
    local rankImgs = {}
    for i=1,3 do
        rankImgs[i] = rankPanel:getChildByName("Image_no"..i)
        rankImgs[i]:setVisible(false)
    end
    --排名
    if data.slotIndex < 1 then
        data.slotIndex = sender.userObject
    end
    if data.slotIndex < 4 then
        rankImgs[data.slotIndex]:setVisible(true)
    else 
        rankLabel:setString(data.slotIndex)
    end
    --名字
    nameLabel:setString(data.name)
    --星数
    starLabel:setString(data.data)
    --关卡
    local str = ""
    local cfg = JsonConfig.m_bloodBattle.getDefByID(data.value)
    if cfg ~= nil then
        str = string.format(GUITips.RSI_XUEZHAN_TIP7,""..cfg.chapter)..string.format(GUITips.RSI_XUEZHAN_TIP11,data.value)
    end
    chapterLabel:setString(str)
end

function XueZhanMainUI:CloseUI()
    LGameMsg.m_deleteUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "XueZhan.XueZhanMainUI")
    self:SendMsg(LGameMsg.m_deleteUIMsg)
end

function XueZhanMainUI:onExit()
    self:Destory()
    self.m_pUILayer = nil
    self.m_pNode = nil
    self.m_id = nil
    self.Script  = nil
    Utils:SendMsg(LUIRoleDataChangeEvent.BGVisible, true)
    LRankDataMgr:Delete(self.m_rankType)
end

function XueZhanMainUI:OnEnter()
    Utils:SendMsg(LUIRoleDataChangeEvent.BGVisible, false)
end

function XueZhanMainUI:UpdateRedDot()
    local show = Utils:GetRedDotState(RedDotDef.ID.ShopWanFaXueZhan)
    self.m_shopPrompt:setVisible(show)
end

return XueZhanMainUI