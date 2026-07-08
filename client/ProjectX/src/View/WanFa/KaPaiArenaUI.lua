--[[
lua里面的游戏逻辑控制
竞技场挑战界面
]]
--local ShopDef = require("View.Shop.ShopDef")

local KaPaiArenaUI = LUIBase:New()
KaPaiArenaUI.__index = KaPaiArenaUI
KaPaiArenaUI.IsHideInBattle = true
--local this = LTcpSocket
function KaPaiArenaUI:New()
	local o = LUIBase:New()
	setmetatable(o,KaPaiArenaUI)	
    o:Init()
	return o
end

local SPEED = 300--/秒

function KaPaiArenaUI:Init()
    --self.m_pGuideBtn = nil
    self.m_pUILayer = cc.CSLoader:createNode("csd/common/JingjiLayer.csb")
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)

   local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
    self:RegistMsgs()
    self:InitData()
    self:ShowList()
    self:ShowMyRole()
    self:ShowInfo()
    self:ShowBgMoney(1)
    self:InitRedDot()
    --LuaNetSendMsg:QueryArenaInfo(2)
    --LuaNetSendMsg:QueryArenaList(2)
    --请求竞技场数据
    LuaNetSendMsg:QueryArenaInfo(1)
    LArenaDataMgr:InitRankInfo()
    --请求竞技场战报
    LuaNetSendMsg:QueryArenaList(3)
    
    --LuaNetSendMsg:QueryGotTaskList(1)
end

function KaPaiArenaUI:onExit()
    LRedDotCheckMgr:CloseCheckBtn("btn_arena_reward")
    LRedDotCheckMgr:CloseCheckBtn("btn_arena_report")
   
    Utils:SendMsg(LUIGuideEvent.UnRegisterStep,GuideDef.StepId.Guide_Arena_Finish)
    LArenaDataMgr:Init()
    self:Destory()
    self.m_pUILayer = nil
    self._innerContentSize = nil
    self.m_pRoleModels = nil
    self.m_rankLabels = nil
    self.m_nameBgImgs = nil
    self.m_nameLabels = nil
    self.m_powerLabels = nil
    self.m_selfImgs = nil
    self.m_myModel = nil
    self.m_runSign = nil
    self.m_sweepBtns = nil
    self.m_cntLabels = nil
    self.m_drawImgs = nil
    self.m_drawBtns = nil
    self.m_datas = nil
    self.m_fightBtns = nil
    self.m_curData = nil
end

--[[
注册UI消息
]]
function KaPaiArenaUI:RegistMsgs()
    self.msgIds = 
    {
        LUIArenaEvent.UpdateTime,           --更新次数
        LUIArenaEvent.UpdateArenaWarInfo,   --更新排名战信息
        LUIArenaEvent.UpdateHeroListInfo,   --打开排行榜界面
        LUIArenaEvent.OpenRecordUI,         --打开战报界面
        LUIArenaEvent.OpenRewardUI,         --打开奖励界面
        LUIRoleDataChangeEvent.MoneyChanged,
        LUIRoleDataChangeEvent.TongBaoChanged,
        LUIRoleDataChangeEvent.TiliChanged,
        LUIRoleDataChangeEvent.ArenaSorceChanged,--竞技场积分改变
        LUITaskDataEvent.WanFaDailyTaskInfo,
        LUITaskDataEvent.WanFaDailyTaskReward,
        LUIRedDotEvent.UpdateRedDotState,
        LUIKunLunEvent.GetRobotZhenFaInfo,
    }
    self:RegistSelf(self,self.msgIds)
end

function KaPaiArenaUI:ProcessEvent(msg)
    if msg.msgId == LUIArenaEvent.UpdateArenaWarInfo then
        self:UpdateInfo()
        self:RegisterGuide()
    elseif msg.msgId == LUIArenaEvent.UpdateHeroListInfo then
        Utils:OpenRankUI(AppDef.EModuleID.EMID_RANK_JinhJi)
    elseif msg.msgId == LUIArenaEvent.UpdateTime then
        self:ShowTime()
        self:UpdateSweepCnt()
    elseif msg.msgId == LUIArenaEvent.OpenRecordUI then
        self:OpenZhanBaoPanel()
    elseif msg.msgId == LUIArenaEvent.OpenRewardUI then
        self:OpenRewardPanel()
    elseif msg.msgId == LUIRoleDataChangeEvent.MoneyChanged 
        or msg.msgId == LUIRoleDataChangeEvent.TongBaoChanged 
        or msg.msgId == LUIRoleDataChangeEvent.TiliChanged then
        self:ShowBgMoney()
    elseif msg.msgId == LUIRoleDataChangeEvent.ArenaSorceChanged then
        --LArenaDataMgr.m_score = LRoleDataMgr.MyHeroInfo:GetArenaSorce() or 0
        self:ShowMoney()
    elseif msg.msgId == LUITaskDataEvent.WanFaDailyTaskInfo then
        local value = msg.value
        if #value ~= 2 or value[1] ~= 1 then
            return
        end
        self.m_datas = value[2]
        self:ShowRewardList()
    elseif msg.msgId == LUITaskDataEvent.WanFaDailyTaskReward then
        local value = msg.value
        if #value ~= 3 or value[1] ~= 1 then
            return
        end
        self:SetTaskState(value[2],2)
        self:ShowRewardList()
        self:TaskRedCheck()
    elseif msg.msgId == LUIRedDotEvent.UpdateRedDotState then
        if msg.value ~= nil and msg.value.id == RedDotDef.ID.ShopWanFaJingji then
            self:UpdateShopRedDot()
        end
    elseif msg.msgId == LUIKunLunEvent.GetRobotZhenFaInfo then
        if not self.m_pUILayer:isVisible() then
            return
        end
        self:OpenFormationUI(msg.value)
    end
end


function KaPaiArenaUI:InitData()
    --panel:setTouchEnabled(false)
    --信息界面
    local panel = self.m_pUILayer:getChildByName("Panel")
    panel:setVisible(true)
    closeBtn = panel:getChildByName("Title"):getChildByName("CloseBtn")
    closeBtn:addClickEventListener(handler(self, KaPaiArenaUI.CloseUI))
    local infoPanel = panel:getChildByName("JingjiBg")
    infoPanel:setTouchEnabled(false)
    local tipsPanel = infoPanel:getChildByName("Tips")
    self.m_myRankLabel = tipsPanel:getChildByName("MyRanking"):getChildByName("Text")
    self.m_myRewardPanel = tipsPanel:getChildByName("RankingReward")
    local cntPanel = infoPanel:getChildByName("TimesBg")
    self.m_cntLabel = cntPanel:getChildByName("Icon"):getChildByName("Num")
    self.m_moneyLabel = infoPanel:getChildByName("ShengwangBg"):getChildByName("Icon"):getChildByName("Num")
    local addCntBtn =  cntPanel:getChildByName("AddBtn")--加次数按钮
    addCntBtn:addClickEventListener(handler(self, KaPaiArenaUI.OnAddCntBtnClick))
    local zhenBtn = infoPanel:getChildByName("ArrayBtn")--打开阵容界面
    zhenBtn:addClickEventListener(handler(self, KaPaiArenaUI.OnZhenBtnClick))
    for i=1,4 do
        local btn = infoPanel:getChildByName("Btn_"..i)
        btn.userObject = i
        btn:addClickEventListener(handler(self, KaPaiArenaUI.OnBottomRightBtnClick)) 
        if i == 1 then
            self.m_shopRedDot = btn:getChildByName("Prompt_0")
        end
    end
    --金钱
    local moneyPanel = panel:getChildByName("GoldCheck")
    local money1 = moneyPanel:getChildByName("GoldIcon1")
    self.m_tiliImg = money1:getChildByName("Icon")--体力
    self.m_tiliLabel = money1:getChildByName("GoldNumBg"):getChildByName("Num")
    local tiliAddBtn = money1:getChildByName("AddBtn")
    tiliAddBtn:addClickEventListener(function ( sender )
        Utils:OpenUseUI(500,1)
    end)
    local money2 = moneyPanel:getChildByName("GoldIcon3")
    self.m_goldImg = money2:getChildByName("Icon")--金币
    self.m_goldLabel = money2:getChildByName("GoldNumBg"):getChildByName("Num")
    local goldAddBtn = money2:getChildByName("AddBtn")
    goldAddBtn:addClickEventListener(function ( sender )
        Utils:OpenFunction(AppDef.EModuleID.EMID_SCCHANGYONG)
    end)
    local money3 = moneyPanel:getChildByName("GoldIcon4")
    self.m_cashImg = money3:getChildByName("Icon")--元宝
    self.m_cashLabel = money3:getChildByName("GoldNumBg"):getChildByName("Num")
    local cashAddBtn = money3:getChildByName("AddBtn")
    cashAddBtn:setVisible(false)

    --背景
    -- local strPath = "res/UI/ui_bg/bg_Jingji.png"
    -- self.m_bgImg = cc.Sprite:create(strPath)
    -- if self.m_bgImg == nil then--再创建一次
    --     self.m_bgImg = cc.Sprite:createWithSpriteFrameName(strPath)
    -- end
    -- self.m_bgImg:setAnchorPoint(cc.p(0,0))

    --scrollView
    self.m_scrollView = self.m_pUILayer:getChildByName("ScrollView")
    self.m_scrollView:setScrollBarEnabled(false)
    self.m_scrollView:setBounceEnabled(false)
    --self.m_scrollView:addEventListenerScrollView(handler(self, KaPaiArenaUI.ScrollEvent))
    --self.m_scrollView:addTouchEventListener(handler(self, KaPaiArenaUI.OnTouched))
    --self.m_scrollView:addChild(self.m_bgImg)
    --self.m_bgImg:setPosition(cc.p(0,0))
    self.m_bgImg = self.m_scrollView:getChildByName("Bg2")
    self.m_bgImg:retain()
    self.m_bgImg:removeFromParent()
    self.m_bgImg:setAnchorPoint(cc.p(0,0))

    self.m_pCell = self.m_pUILayer:getChildByName("ImageBg")
    self.m_pCell:retain()
    self.m_pCell:removeFromParent()
    self.m_pCell1 = self.m_pUILayer:getChildByName("ImageBg_1")
    self.m_pCell1:retain()
    self.m_pCell1:removeFromParent()
    self.m_pCell2 = self.m_pUILayer:getChildByName("ImageBg_2")
    self.m_pCell2:retain()
    self.m_pCell2:removeFromParent()
    self.m_cellNodes = {}
    self.m_cellTexts = {}
    local size = self.m_scrollView:getInnerContainerSize()
    local width = self.m_pCell:getContentSize().width+self.m_pCell1:getContentSize().width *7
    if width > size.width then
        self._innerContentSize = cc.size(width, AppDef.frameSize.height)
        self.m_scrollView:setInnerContainerSize(self._innerContentSize)
    end
    --local width = self.m_bgImg:getContentSize().width
    --self.m_bgImg:setScale(self._innerContentSize.width/width)--临时处理

    --功能面板
    --战报
    self.m_zhanBaoPanel = self.m_pUILayer:getChildByName("Zhanbao")
    self.m_zhanBaoPanel:setVisible(false)
    local popupPanel1 = self.m_zhanBaoPanel:getChildByName("Popup")
    self.m_zhbaoCell = popupPanel1:getChildByName("Item")
    local bg1 = popupPanel1:getChildByName("bg")
    self.m_zhbaoListView = bg1:getChildByName("Image2"):getChildByName("ListView")
    local list1 =  bg1:getChildByName("CheckList")
    self.m_zhbaoCheckBoxs = {}
    self.m_zhbaoCbLabels = {}
    for i=1,2 do
        self.m_zhbaoCheckBoxs[i] = list1:getChildByName("CheckBox_"..i)
        self.m_zhbaoCheckBoxs[i].userObject = i
        self.m_zhbaoCheckBoxs[i]:addEventListener(handler(self,KaPaiArenaUI.ZhBaoCheckBoxCallBack))
        for k=1,2 do
            local idx = (i-1)*2+k
            self.m_zhbaoCbLabels[idx] = self.m_zhbaoCheckBoxs[i]:getChildByName("Text_"..k)
        end
    end
    self.m_zbRedPoint = self.m_zhbaoCheckBoxs[2]:getChildByName("Prompt")

    local closeBtn1 = popupPanel1:getChildByName("Btn_close")
    closeBtn1:addClickEventListener(function(sender)
        self:OpenZhanBaoPanel(1)
    end)
    --排行榜
    self.m_rankPanel = self.m_pUILayer:getChildByName("Ranking")
    self.m_rankPanel:setVisible(false)
    -- local popupPanel2 = self.m_rankPanel:getChildByName("Popup")
    -- self.m_rankCell = popupPanel2:getChildByName("Item")--排行榜cell
    -- self.m_rankRewardCell = popupPanel2:getChildByName("Reward")--排行榜奖励页签cell
    -- self.m_rankRewardIcon = popupPanel2:getChildByName("IconBg")
    -- local bg2 = popupPanel2:getChildByName("bg")
    -- self.m_rankListView = bg2:getChildByName("Image2"):getChildByName("ListView")
    -- local list2 =  bg2:getChildByName("CheckList")
    -- self.m_rankCheckBoxs = {}
    -- self.m_rankCbLabels = {}
    -- for i=1,2 do
    --     self.m_rankCheckBoxs[i] = list2:getChildByName("CheckBox_"..i)
    --     self.m_rankCheckBoxs[i].userObject = i
    --     self.m_rankCheckBoxs[i]:addEventListener(handler(self,KaPaiArenaUI.RankCheckBoxCallBack))
    --     for k=1,2 do
    --         local idx = (i-1)*2+k
    --         self.m_rankCbLabels[idx] = self.m_rankCheckBoxs[i]:getChildByName("Text_"..k)
    --     end
    -- end
    -- self.m_myRankLabel1 = bg2:getChildByName("MyRanking"):getChildByName("Text")
    -- self.m_myRewardPanel1 = bg2:getChildByName("RankingReward")
    -- local closeBtn2 = popupPanel2:getChildByName("Btn_close")
    -- closeBtn2:addClickEventListener(function(sender)
    --     self:OpenRankPanel(1)
    -- end)
    --奖励
    self.m_rewardPanel = self.m_pUILayer:getChildByName("Rewards")
    self.m_rewardPanel:setVisible(false)
    local popupPanel3 = self.m_rewardPanel:getChildByName("Popup")
    self.m_rewardCell = popupPanel3:getChildByName("Reward")
    self.m_rewardIcon = popupPanel3:getChildByName("IconBg")
    local bg3 = popupPanel3:getChildByName("bg")
    self.m_rewardListView = bg3:getChildByName("Image2"):getChildByName("ListView")
    self.m_tzCntLabel = bg3:getChildByName("Times"):getChildByName("Text")
    local closeBtn3 = popupPanel3:getChildByName("Btn_close")
    closeBtn3:addClickEventListener(function(sender)
        self:OpenRewardPanel(1)
    end)
    

    --角色模型
    self.m_pRoleModels = {}
    self.m_rankLabels = {}
    self.m_nameBgImgs = {}
    self.m_nameLabels = {}
    self.m_powerLabels = {}
    self.m_selfImgs = {}
    self.m_sweepBtns = {}
    self.m_myModel = nil
    self.m_runSign = false

    self.m_cntLabels = {}
    self.m_drawImgs = {}
    self.m_drawBtns = {}
    self.m_fightBtns = {}
    --self.m_init = false
    --dump(self.m_scrollView:getInnerContainerSize(), "initControlUI ======>")
    self.m_guideBtn = nil
    self.m_curData = nil

	local helpBtn = panel:getChildByName("Title"):getChildByName("TitleName"):getChildByName("btn_help")
    helpBtn:addClickEventListener(function ( sender )
        self:HelpClicked()
    end)
end

function KaPaiArenaUI:HelpClicked(sender) 
    Utils:ShowDialogOKCancel(GUITips.JingJi)
end

function KaPaiArenaUI:SortItem()
    local data = LArenaDataMgr.m_modelInfos
    if data == nil then
        return
    end
    if #data == 0 then
        return
    end
    local function sortFuc(m1, m2)
        return m1.slotIndex < m2.slotIndex
    end
    table.sort(data, sortFuc)
    --dump(data,"KaPaiArenaUI:SortItem =>")
end


function KaPaiArenaUI:UpdateInfo()
    self:SortItem()
    local num = 0
    if LArenaDataMgr.m_modelInfos ~= nil then
        num = num +#LArenaDataMgr.m_modelInfos
    end
    local size = self.m_scrollView:getInnerContainerSize()
    local width = self.m_pCell:getContentSize().width+self.m_pCell1:getContentSize().width *7+self.m_pCell2:getContentSize().width*num
    if width ~= size.width then
        self._innerContentSize = cc.size(width, AppDef.frameSize.height)
        self.m_scrollView:setInnerContainerSize(self._innerContentSize)
    end
    local bgWidth = self.m_bgImg:getContentSize().width
    local num = math.ceil(width/bgWidth)
    for i=1,num do
        local bg = self.m_scrollView:getChildByTag(i)
        if bg == nil then
            bg = self.m_bgImg:clone()
            self.m_scrollView:addChild(bg)
            bg:setTag(i)
            bg:setName("bg"..i)
            local x = 0+bgWidth*(i-1)
            bg:setPosition(cc.p(x,0))
            bg:setLocalZOrder(-1)
        end
    end
    for i=num+1,20 do
        local bg = self.m_scrollView:getChildByTag(i)
        if bg ~= nil then
            bg:removeFromParent()
        end
    end
    --local width = self.m_bgImg:getContentSize().width
    --self.m_bgImg:setScale(self._innerContentSize.width/width)--临时处理

    self:ShowList()
    self:ShowInfo()
end

function KaPaiArenaUI:ShowBgMoney(init)
    init = init or 0
    local value1 = Utils:getTiliStr(LRoleDataMgr.MyHeroInfo.DetailData:getTili())
    self.m_tiliLabel:setString(value1)
    local value2 = Utils:getGoldStr()
    self.m_goldLabel:setString(""..value2)
    local value3 =  LRoleDataMgr.MyHeroInfo.DetailData:GetTongBao()
    self.m_cashLabel:setString(""..value3)
    --print("showmoney",value1,value2,value3)

    if init == 1 then
        local imgPath1 = "res/UI/Icon/ui_huobi_icon/huobi_"..LRoleDataMgr.GetItemPicId(AppDef.SpecialItemId.Tili)..".png"
        Utils:SafeLoadTexture(self.m_tiliImg,imgPath1,ccui.TextureResType.plistType)
        local imgPath2 = "res/UI/Icon/ui_huobi_icon/huobi_"..LRoleDataMgr.GetItemPicId(AppDef.SpecialItemId.Gold)..".png"
        Utils:SafeLoadTexture(self.m_goldImg,imgPath2,ccui.TextureResType.plistType)
        local imgPath3 = "res/UI/Icon/ui_huobi_icon/huobi_"..LRoleDataMgr.GetItemPicId(AppDef.SpecialItemId.Cash)..".png"
        Utils:SafeLoadTexture(self.m_cashImg,imgPath3,ccui.TextureResType.plistType)
    end
end

function KaPaiArenaUI:ShowInfo()
    self:ShowMyRank(self.m_myRankLabel,self.m_myRewardPanel)
    self:ShowTime()
    self:ShowMoney()
end

function KaPaiArenaUI:ShowList()
    local height = self.m_pCell:getContentSize().height
    local width = self.m_pCell:getContentSize().width
    local h = AppDef.frameSize.height
    --print("KaPaiArenaUI:ShowList h w maxH",height,width,h)
    local nodePanel = self.m_pCell1:getChildByName("Bg"):getChildByName("Node")
    local nameBgImg = nodePanel:getChildByName("NameBg")
    local nameLabel = nodePanel:getChildByName("Name")
    local powerLabel = nodePanel:getChildByName("Power")
    --前三名
    if self.m_cellNodes[1] == nil then
        local cell = self.m_pCell:clone()
        cell:setAnchorPoint(cc.p(0,0))
        self.m_scrollView:addChild(cell)
        cell:setPosition(cc.p(0,h-height))
        local node = cell:getChildByName("Bg")
        for i=1,3 do
            self.m_cellNodes[i] = cc.Node:create()
            self.m_cellNodes[i].userObject = i
            node:addChild(self.m_cellNodes[i],AppDef.GameZOrder.UILayer)
            local pos = cc.p(self.m_pCell:getChildByName("Bg"):getChildByName("Node"..i):getPosition())
            self.m_cellNodes[i]:setPosition(cc.p(pos.x,pos.y))
            self.m_rankLabels[i] = node:getChildByName("RankingBg"..i):getChildByName("Num")
            self.m_nameBgImgs[i] = nameBgImg:clone()
            self.m_nameLabels[i] = nameLabel:clone()
            self.m_powerLabels[i] = powerLabel:clone()
            self.m_cellNodes[i]:addChild(self.m_nameBgImgs[i])
            self.m_cellNodes[i]:addChild(self.m_nameLabels[i])
            self.m_cellNodes[i]:addChild(self.m_powerLabels[i])
            self.m_nameBgImgs[i]:setPosition(cc.p(0,nameBgImg:getPositionY()))
            self.m_nameLabels[i]:setPosition(cc.p(0,nameLabel:getPositionY()))
            self.m_powerLabels[i]:setPosition(cc.p(0,powerLabel:getPositionY()))
            local btn = cell:getChildByName("Panel_"..i)
            btn.userObject = i
            btn:addClickEventListener(handler(self,KaPaiArenaUI.OnFightClick))
            self.m_fightBtns[i] = btn
            self.m_selfImgs[i] = node:getChildByName("Type"..i)
            self.m_sweepBtns[i] = node:getChildByName("Btn_"..i)
            self.m_sweepBtns[i].userObject = i
            self.m_sweepBtns[i]:addClickEventListener(handler(self,KaPaiArenaUI.OnSweepClick))
        end
        --4-10
        for i=4,10 do
            local w = self.m_pCell1:getContentSize().width
            local cell1 = self.m_pCell1:clone()
            cell1:setAnchorPoint(cc.p(0,0))
            self.m_scrollView:addChild(cell1)
            cell1:setPosition(cc.p(width+(i-4)*w,h-height))
            self.m_cellNodes[i] = cc.Node:create()
            self.m_cellNodes[i].userObject = i
            self.m_cellNodes[i]:setScale(1.15)
            cell1:getChildByName("Bg"):addChild(self.m_cellNodes[i],AppDef.GameZOrder.UILayer)
            local pos = cc.p(self.m_pCell1:getChildByName("Bg"):getChildByName("Node"):getPosition())
            self.m_cellNodes[i]:setPosition(pos)
            self.m_rankLabels[i] = cell1:getChildByName("RankingBg"):getChildByName("Num")
            self.m_nameBgImgs[i] = nameBgImg:clone()
            self.m_nameLabels[i] = nameLabel:clone()
            self.m_powerLabels[i] = powerLabel:clone()
            self.m_cellNodes[i]:addChild(self.m_nameBgImgs[i])
            self.m_cellNodes[i]:addChild(self.m_nameLabels[i])
            self.m_cellNodes[i]:addChild(self.m_powerLabels[i])
            self.m_nameBgImgs[i]:setPosition(cc.p(0,nameBgImg:getPositionY()*1.032))
            self.m_nameLabels[i]:setPosition(cc.p(0,nameLabel:getPositionY()*1.032))
            self.m_powerLabels[i]:setPosition(cc.p(0,powerLabel:getPositionY()*1.032))
			
            local btn = cell1:getChildByName("Panel")
            btn.userObject = i
            btn:addClickEventListener(handler(self,KaPaiArenaUI.OnFightClick))
            self.m_fightBtns[i] = btn
            self.m_selfImgs[i] = cell1:getChildByName("Type")
            self.m_sweepBtns[i] = cell1:getChildByName("Btn")
            self.m_sweepBtns[i].userObject = i
            self.m_sweepBtns[i]:addClickEventListener(handler(self,KaPaiArenaUI.OnSweepClick))
        end
    end
    for i=1,10 do
        self:ShowOneItem(self.m_cellNodes[i],LArenaDataMgr.m_toptenModelInfos[i])
    end
    if #LArenaDataMgr.m_modelInfos == 0 then
        return
    end
    local min = 11
    local max = math.max(#LArenaDataMgr.m_modelInfos+10,self.m_scrollView:getChildrenCount()-10)
    for i = min,max do
        if i > #LArenaDataMgr.m_modelInfos+10 then
            if self.m_cellNodes[i] ~= nil then
                self.m_scrollView:removeChild(self.m_cellNodes[i]:getParent(), true)
                self.m_cellNodes[i] = nil
                self.m_rankLabels[i] = nil
                self.m_nameBgImgs[i] = nil
                self.m_nameLabels[i] = nil
                self.m_powerLabels[i] = nil
                self.m_selfImgs[i] = nil
                self.m_sweepBtns[i] = nil
            end
        elseif self.m_cellNodes[i] == nil then
            local w = self.m_pCell2:getContentSize().width
            local cell2 = self.m_pCell2:clone()
            cell2:setAnchorPoint(cc.p(0,0))
            self.m_scrollView:addChild(cell2)
            cell2:setPosition(cc.p(width+(i-4)*w,h-height))
            self.m_cellNodes[i] = cc.Node:create()
            self.m_cellNodes[i].userObject = i
            self.m_cellNodes[i]:setScale(1.15)
            cell2:getChildByName("Bg"):addChild(self.m_cellNodes[i],AppDef.GameZOrder.UILayer)
            local pos = cc.p(self.m_pCell2:getChildByName("Bg"):getChildByName("Node"):getPosition())
            self.m_cellNodes[i]:setPosition(pos)
            self.m_rankLabels[i] = cell2:getChildByName("RankingBg"):getChildByName("Num")
            self.m_nameBgImgs[i] = nameBgImg:clone()
            self.m_nameLabels[i] = nameLabel:clone()
            self.m_powerLabels[i] = powerLabel:clone()
            self.m_cellNodes[i]:addChild(self.m_nameBgImgs[i])
            self.m_cellNodes[i]:addChild(self.m_nameLabels[i])
            self.m_cellNodes[i]:addChild(self.m_powerLabels[i])
            self.m_nameBgImgs[i]:setPosition(cc.p(0,nameBgImg:getPositionY()*1.032))
            self.m_nameLabels[i]:setPosition(cc.p(0,nameLabel:getPositionY()*1.032))
            self.m_powerLabels[i]:setPosition(cc.p(0,powerLabel:getPositionY()*1.032))
			
            local btn = cell2:getChildByName("Panel")
            btn.userObject = i
            btn:addClickEventListener(handler(self,KaPaiArenaUI.OnFightClick))
            self.m_fightBtns[i] = btn
            self.m_selfImgs[i] = cell2:getChildByName("Type")
            self.m_sweepBtns[i] = cell2:getChildByName("Btn")
            self.m_sweepBtns[i].userObject = i
            self.m_sweepBtns[i]:addClickEventListener(handler(self,KaPaiArenaUI.OnSweepClick))
        end
    end
    local num = #LArenaDataMgr.m_modelInfos
    for i= 1,num do
        self:ShowOneItem(self.m_cellNodes[i+10],LArenaDataMgr.m_modelInfos[i])
    end
    --self.m_scrollView:jumpToPercentHorizontal(0)  
    self:UpdateRolePos()
end

function KaPaiArenaUI:UpdateRolePos()
    self.m_selfIdx = self.m_selfIdx or 1
    local posX = 100
    if self.m_selfIdx < 4 then
        posX = self.m_pCell:getContentSize().width/3*(self.m_selfIdx-0.5)
    elseif self.m_selfIdx < 11 then
        posX = self.m_pCell:getContentSize().width+self.m_pCell1:getContentSize().width*(self.m_selfIdx-3-0.5)
    else
        posX = self.m_pCell:getContentSize().width+self.m_pCell1:getContentSize().width*7+self.m_pCell1:getContentSize().width*(self.m_selfIdx-10-0.5)
    end
    local target = cc.p(posX,self._innerContentSize.height/5)
    --dump(target,"KaPaiArenaUI:UpdateRolePos")
    self.m_myModelNode:setPosition(target)
    self:scrollToAimPos(true)
    --self.m_scrollView:jumpToPercentHorizontal(0)   
end

function KaPaiArenaUI:ShowOneItem(sender,data)
    if sender == nil then
        return
    end
    if data ~= nil then
        if data.IdType == 1 then
            local cfg = JsonConfig.m_robotConfig.getDefByID(data.Id)
            if cfg ~= nil then
                data.name = cfg.name
                data.fightpower = cfg.zhanli
                data.model = cfg.mod
            end
        elseif data.IdType == 0 then
            data.model = Utils:CheckModelId(data.model)
        end
    end
    local idx = sender.userObject
    self:ShowRoleModel(sender,idx,data)
    self.m_selfImgs[idx]:setVisible(false)
    self.m_sweepBtns[idx]:setVisible(false)
    --local data = LArenaDataMgr.m_modelInfos[idx]
    if data == nil then
        return
    end 
    self.m_rankLabels[idx]:setString(""..data.slotIndex)
    self.m_nameLabels[idx]:setString(data.name)
    self.m_powerLabels[idx]:setString(GUITips.Item_Power..":"..Utils:getPowerStr(data.fightpower))
    if data.Id == LRoleDataMgr.MyHeroInfo.id then
        self.m_selfImgs[idx]:setVisible(true)
        self.m_selfIdx = idx
    elseif data.slotIndex > LArenaDataMgr.m_myRank then
        self.m_sweepBtns[idx]:setVisible(true)
    end
end

function KaPaiArenaUI:OnTouched(pTouch, pEvent)
    if pEvent == ccui.TouchEventType.ended
            or pEvent == ccui.TouchEventType.canceled then
        if self.m_runSign then
            return
        end
        local start = cc.p(pTouch:getTouchBeganPosition())
        local pos = cc.p(pTouch:getTouchEndPosition())
        local dis = cc.pGetDistance(pos, start)
        if dis < 0.1 and pos.y < 300 then
            local offset = self.m_scrollView:getInnerContainerPosition()
            print("KaPaiArenaUI:OnTouched",dis,start.y,pos.y)
            self:RoleMove(cc.p(pos.x-offset.x,pos.y))
        end
    end
end

function KaPaiArenaUI:OpenFormationUI(zhenfaData)
    local value = {}
    value.enemyZhenfaId = zhenfaData.zhengfaId
    value.enemyInfos = zhenfaData.zhengfaData

    local fun = function()
        if self.m_curData == nil or self.m_curData.Id == nil or self.m_curData.Id < 1 then
            return
        end
        LuaNetSendMsg:QueryArenaChallenge(5,self.m_curData.Id,self.m_curData.IdType,0,self.m_curData.slotIndex)
        self.m_curData = nil
    end
    value.callback = fun
    value.isrole = zhenfaData.isRole
    Utils:InitUI("Common.PetFormationUI",AppDef.UIType.FirstClassLayer,value)
end

function KaPaiArenaUI:OnFightClick(sender)
    local idx = sender.userObject
    if idx < 1 then
        return
    end
    local data = nil
    if idx < 11 then
        data = LArenaDataMgr.m_toptenModelInfos[idx]
    else
        data = LArenaDataMgr.m_modelInfos[idx-10]
    end
    if data == nil or data.Id == 0 or data.Id == LRoleDataMgr.MyHeroInfo.id then
        return
    end
    local cnt = LArenaDataMgr.m_cnt or 0
    if cnt == 0 then
        Utils:ShowDialogOKCancel(GUITips.UI_Arena_Tip11,handler(self,KaPaiArenaUI.OnAddCntBtnClick))
        return
    end
    --LuaNetSendMsg:QueryArenaChallenge(5,data.Id,data.IdType,0,data.slotIndex)
    self.m_curData = {}
    self.m_curData.Id = data.Id
    self.m_curData.IdType = data.IdType
    self.m_curData.slotIndex = data.slotIndex
    if data.IdType == 0 then
        LuaNetSendMsg:QueryOtherPlayerInfo(data.Id,1)
    else
        LuaNetSendMsg:QueryArenaRobotInfo(data.Id)
    end
end

function KaPaiArenaUI:OnSweepClick(sender)
    local idx = sender.userObject
    if idx < 1 then
        return
    end
    local data = nil
    if idx < 11 then
        data = LArenaDataMgr.m_toptenModelInfos[idx]
    else
        data = LArenaDataMgr.m_modelInfos[idx-10]
    end
    if data == nil or data.Id == 0 or data.Id == LRoleDataMgr.MyHeroInfo.id then
        return
    end
    if data.slotIndex < LArenaDataMgr.m_myRank then
        return
    end
    local cnt = LArenaDataMgr.m_cnt or 0
    if cnt == 0 then
        Utils:ShowDialogOKCancel(GUITips.UI_Arena_Tip11,handler(self,KaPaiArenaUI.OnAddCntBtnClick))
        return
    end
    LuaNetSendMsg:SendArenaSweepReq(data.Id)
    --print("OnSweepClick",idx,data.name,data.Id)
end



--模型显示
function KaPaiArenaUI:ShowRoleModel(roleModelNode,idx,data)
    if data == nil or roleModelNode == nil then
         return
    end
   -- print("KaPaiArenaUI:ShowRoleModel idx",idx)
    --dump(data)
    if data.IdType == 0 then
        if self.m_pRoleModels[idx] == nil then
            self.m_pRoleModels[idx] = ModelAniNode:create(AppDef.CEnum.ModelAniType.Hero,data.model,0,0,0,0,0)
            roleModelNode:addChild(self.m_pRoleModels[idx])
        else
            self.m_pRoleModels[idx]:InitAni(AppDef.CEnum.ModelAniType.Hero,data.model,0,0,0,0,0)
        end
    elseif data.model > 0 then
        if self.m_pRoleModels[idx] == nil then
            self.m_pRoleModels[idx] = ModelAniNode:create(AppDef.CEnum.ModelAniType.Monster,data.model)
            roleModelNode:addChild(self.m_pRoleModels[idx])
        else
            self.m_pRoleModels[idx]:InitAni(AppDef.CEnum.ModelAniType.Monster,data.model)
        end
    end
    self.m_pRoleModels[idx]:PlayStand(0)
end

function KaPaiArenaUI:ShowMyRole(posX,posY)
    if self.m_myModelNode == nil then
        self.m_myModelNode = cc.Node:create()
        self.m_scrollView:addChild( self.m_myModelNode)
        self.m_myModelNode:setPosition(cc.p(100,50))
        self.m_myModelNode:setLocalZOrder(999)
    end
    if posX ~= nil and posY ~= nil and posY > 50 and posY < 190 and posX < self._innerContentSize.width-100 and posX > 50 then
        self.m_myModelNode:setPosition(cc.p(posX,posY))
    end 
    -- local data = LRoleDataMgr.MyHeroInfo
    -- local bodyId = data:GetModel()
    -- --print("model",bodyId)
    -- if self.m_myModel == nil then
    --     self.m_myModel = ModelAniNode:create(AppDef.CEnum.ModelAniType.Hero, 
    --                                         bodyId, 
    --                                         0, 
    --                                         0,
    --                                         data.WingsId,
    --                                         0,
    --                                         data:GetShenQiId())
    --     self.m_myModelNode:addChild(self.m_myModel)
    -- end
    -- self.m_myModel:PlayStand(0)
end

function KaPaiArenaUI:RoleMove(target)
    local pos = cc.p(self.m_myModelNode:getPosition())
    local dis = cc.pGetDistance(pos, target)
    if dis < 0.1 then
        return
    end
    self.m_runSign = true
    local offset = self.m_scrollView:getInnerContainerPosition()
    local width = AppDef.frameSize.width

    local face = self:getRoldDir(pos, target)
    --print("KaPaiArenaUI:RoleMove",face)
    self.m_myModel:PlayRun(face)
    local time = dis/SPEED
    local moveAc = cc.MoveTo:create(time, target)
    local moveEnd = cc.CallFunc:create(function()
        self.m_runSign = false
        local tmp = 7
        if face >= 2 and face <= 4 then
            tmp = 3
        end
        self.m_myModel:PlayStand(tmp)
        --人物移动完再移动镜头
        self:scrollToAimPos()
    end)
    self.m_myModelNode:runAction(cc.Sequence:create(moveAc, moveEnd)) 

end

function KaPaiArenaUI:getRoldDir(pos, targetPos)
    if targetPos == nil then
        return 0
    end
    --print("targetPos.y - pos.y",targetPos.y - pos.y)
    if  math.abs(targetPos.x - pos.x) <= 10 then
        if  targetPos.y > pos.y then
            return 5
        elseif targetPos.y < pos.y then
            return 1
        end
    elseif math.abs(targetPos.y - pos.y) <= 10 then
        if  targetPos.x > pos.x then
            return 7
        elseif targetPos.x < pos.x then
            return 3
        end
    elseif targetPos.x > pos.x and targetPos.y < pos.y then
        return 0
    elseif targetPos.x < pos.x and targetPos.y < pos.y then
        return 2
    elseif targetPos.x < pos.x and targetPos.y > pos.y then
        return 4
    elseif targetPos.x > pos.x and targetPos.y > pos.y then
        return 6
    end
    return 0
end

function KaPaiArenaUI:scrollToAimPos(isJump)
    local width = self._innerContentSize.width-AppDef.frameSize.width
    local dis = self.m_myModelNode:getPositionX() - AppDef.frameSize.width/2
    local  percent  = dis/width*100
    if percent < 0 then
        percent = 0
    end
    if percent > 100 then
        percent = 100
    end
    if isJump == nil then
        isJump = false
    end
    
    if isJump then
        self.m_scrollView:jumpToPercentHorizontal(percent)
    else
        local offset = self.m_scrollView:getInnerContainerPosition()
        local cnt = dis+offset.x
        local time = math.abs(cnt/(AppDef.frameSize.width/2))
        self.m_scrollView:scrollToPercentHorizontal(percent, time, false)
    end
end

function KaPaiArenaUI:ShowMyRank(rankLabel,rewardPanel)
    if rankLabel == nil or rewardPanel == nil then
        return
    end
    local myRank = LArenaDataMgr.m_myRank or 0
    rankLabel:setString(""..myRank)
    local cfg = JsonConfig.GetRewardRankCfg(999,myRank)
    if cfg == nil then
        rewardPanel:setVisible(false)
        return
    end
    rewardPanel:setVisible(true)
    local rewards = cfg.reward or {}
    for i=1,3 do
        local value = rewards[i]
        local iconImg = rewardPanel:getChildByName("Icon"..i)
        local numLabel = iconImg:getChildByName("Value")
        if value == nil or #value < 3 then
            iconImg:setVisible(false)
        else
            iconImg:setVisible(true)
            local imgPath = "item/equip"..LRoleDataMgr.GetItemPicId(value[1])..".png"
            Utils:SafeLoadTexture(iconImg,imgPath,ccui.TextureResType.localType)
            numLabel:setString(value[3])
        end
    end
end

--够买次数
function KaPaiArenaUI:OnAddCntBtnClick(sender)
    local cnt = LArenaDataMgr.m_buyCnt or 0
    Utils:OpenUseUI(401,1)
end

--打开阵容界面
function KaPaiArenaUI:OnZhenBtnClick(sender)
    Utils:OpenFunction(AppDef.EModuleID.EMID_SJBUZHEN)
    -- LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "Common.PetFormationUI",AppDef.UIType.FirstClassLayer,{})
    -- self:SendMsg(LGameMsg.m_initUIMsg)
end

--右下按钮
function KaPaiArenaUI:OnBottomRightBtnClick(sender)
    local idx = sender.userObject
    --print("OnBottomRightBtnClick",idx)
    if idx == 1 then
        --玩法商店（竞技场）
        --Utils:InitUI("Shop.WanFaShopMainUI", AppDef.UIType.PopFirstClassLayer, 1)
        Utils:OpenFunction(AppDef.EModuleID.EMID_SHOP_JINGJI)
    elseif idx == 2 then
        --挑战奖励面板
        self:OpenRewardPanel()
    elseif idx == 3 then
        --打开排行榜
        --self:OpenRankPanel()
        LuaNetSendMsg:QueryArenaList(2)
    else
        --打开战报
        --self:OpenZhanBaoPanel()
        LuaNetSendMsg:QueryArenaList(3)
        LuaNetSendMsg:QueryArenaList(16)
    end
end

--显示挑战次数
function KaPaiArenaUI:ShowTime()
    --print("ShowTime",LArenaDataMgr.m_cnt)
    self.m_cntLabel:setString(""..LArenaDataMgr.m_cnt)
end

--更新竞技场货币信息
function KaPaiArenaUI:ShowMoney()
    local score = LRoleDataMgr.MyHeroInfo.DetailData:GetArenaSorce() or 0
    self.m_moneyLabel:setString(""..score)
end

--更新扫荡次数
function KaPaiArenaUI:UpdateSweepCnt()
    local cnt = LArenaDataMgr.m_cnt or 0
    if cnt < 0 then cnt = 0 end
    if cnt == 0 or cnt >= 5 then
        cnt = 5
    end
    for k,v in pairs(self.m_sweepBtns) do
        local Cntlabel = v:getChildByName("Text")
        if Cntlabel ~= nil then
            Cntlabel:setString(string.format(GUITips.UI_Arena_Tip15,cnt))
        end
    end
end

-------------------------------------------------------------排行榜---------------------------------------------------
-- function KaPaiArenaUI:OpenRankPanel(isHide)
--     isHide = isHide or 0
--     self.m_rankPanel:setVisible(isHide == 0)
--     if isHide == 1 then
--         return
--     end
--     --默认选中排行榜页签
--     --临时初始化
--     --LArenaDataMgr:InitRankList()
--     self.m_rankCheckBoxs[1]:setSelected(true)
--     self:RankCheckBoxCallBack(self.m_rankCheckBoxs[1],CHECKBOX_STATE_EVENT_SELECTED)
--     self:ShowMyRank(self.m_myRankLabel1,self.m_myRewardPanel1)
-- end

-- --排行榜，切换页签
-- function KaPaiArenaUI:RankCheckBoxCallBack(sender,evnetType)
--     local idx = sender.userObject
--     --print("KaPaiArenaUI:RankCheckBoxCallBack",idx)
--     local otherIdx = 1
--     if idx == 1 then
--         otherIdx = 2 
--     end
--     if evnetType == CHECKBOX_STATE_EVENT_SELECTED then
--         self.m_rankCheckBoxs[idx]:setTouchEnabled(false)
--         self.m_rankCheckBoxs[otherIdx]:setTouchEnabled(true)
--         self.m_rankCheckBoxs[otherIdx]:setSelected(false)
--         self.m_rankCbLabels[(idx-1)*2+1]:setVisible(true)
--         self.m_rankCbLabels[(idx-1)*2+2]:setVisible(false)
--         self.m_rankCbLabels[(otherIdx-1)*2+1]:setVisible(false)
--         self.m_rankCbLabels[(otherIdx-1)*2+2]:setVisible(true)
--         if idx == 1 then
--             self:ShowRankList()
--         else
--             self:ShowRankRewardList()
--         end
--     end
-- end

-- function KaPaiArenaUI:ShowRankList()
--     self.m_rankListView:removeAllItems()
--     for i=1,#LArenaDataMgr.m_rankList do
--         local cell = self.m_rankCell:clone()
--         cell.userObject = i
--         self.m_rankListView:pushBackCustomItem(cell)
--         self:ShowOneRank(cell)
--     end
-- end

-- function KaPaiArenaUI:ShowRankRewardList()
--     self.m_rankListView:removeAllItems()
--     local cfgDatas = JsonConfig.m_mapRewardRank[1]
--     for i=1,#cfgDatas do
--         local cell = self.m_rankRewardCell:clone()
--         cell.userObject = i
--         self.m_rankListView:pushBackCustomItem(cell)
--         self:ShowOneRankReward(cell,cfgDatas[i].id)
--     end
-- end

-- function KaPaiArenaUI:ShowOneRank(sender)
--     local idx = sender.userObject
--     local data = LArenaDataMgr.m_rankList[idx]
--     local numLabel = sender:getChildByName("Num_2")
--     local powerLabel = sender:getChildByName("Power"):getChildByName("Value")
--     local bangLabel = sender:getChildByName("Gangs"):getChildByName("Value")
--     local iconImg = sender:getChildByName("Icon_1")
--     local nameLabel = iconImg:getChildByName("Name")
--     local mySignImg = sender:getChildByName("Lable")

--     mySignImg:setVisible(false)
--     if data.Id == LRoleDataMgr.MyHeroInfo.id then
--         mySignImg:setVisible(true)
--     end
--     numLabel:setString(""..idx)
--     powerLabel:setString(""..data.fightpower)
--     nameLabel:setString(""..data.name)
--     local bangName = data.bangName
--     if #bangName == 0 then
--         bangName = GUITips.Common_None
--     end
--     bangLabel:setString(""..bangName)
--     local head = 5
--     if info.sex == 1 then
--         head = 4
--     end
--     local str = AppDef:GetHeroPicFileName(head,AppDef.HeadType.HERO_IMAGE_HEAD_ROUND)
--     iconImg:loadTexture(str,ccui.TextureResType.localType)
--     iconImg.userObject = {data.Id,data.IdType}
--     iconImg:setTouchEnabled(true)
--     iconImg:addClickEventListener(function(sender)
--         local value = sender.userObject
--         if value == nil or #value ~= 2 or value[2] ~= 0 then
--             Utils:ShowScrollTips(GUITips.UI_Arena_Tip12)
--             return
--         end
--         if value[1] == LRoleDataMgr.MyHeroInfo.id then
--             return
--         end
--         LuaNetSendMsg:QueryOtherPlayerInfo(value[1])
--     end)
-- end

-- function KaPaiArenaUI:ShowOneRankReward(sender,id)
--     local cfgData = JsonConfig.m_rewardRank.getDefByID(id)
--     local idx = sender.userObject
--     local numLabel = sender:getChildByName("Num")
--     local number = ""..cfgData.rank[1]
--     if cfgData.rank[2] ~= cfgData.rank[1] then
--         number = number.."-"..cfgData.rank[2]
--     end
--     numLabel:setString(string.format(GUITips.UI_Arena_Msg9,number))
--     local listView = sender:getChildByName("ListView")
--     listView:setTouchEnabled(false)
--     listView:removeAllItems()
--     for i=1,#cfgData.reward do
--         local value = cfgData.reward[i]
--         local cell = self.m_rankRewardIcon:clone()
--         local iconImg = cell:getChildByName("Icon")
--         local cntLabel = cell:getChildByName("Text_5")
--         local imgPath = "item/equip"..LRoleDataMgr.GetItemPicId(value[1])..".png"
--         Utils:SafeLoadTexture(iconImg,imgPath,ccui.TextureResType.localType)
--         cntLabel:setString(""..value[3])
--         listView:pushBackCustomItem(cell)
--     end
-- end
-------------------------------------------------------------排行榜-end--------------------------------------------------
-------------------------------------------------------------战报--------------------------------------------------------
function KaPaiArenaUI:OpenZhanBaoPanel(isHide)
    isHide = isHide or 0
    self.m_zhanBaoPanel:setVisible(isHide == 0)
    if isHide == 1 then
        return
    end
    --默认选中排行榜页签
    --临时初始化
    --LArenaDataMgr:InitRecordList()
    self.m_zhbaoCheckBoxs[1]:setSelected(true)
    self:ZhBaoCheckBoxCallBack(self.m_zhbaoCheckBoxs[1],CHECKBOX_STATE_EVENT_SELECTED)
end

--排行榜，切换页签
function KaPaiArenaUI:ZhBaoCheckBoxCallBack(sender,evnetType)
    local idx = sender.userObject
    local otherIdx = 1
    if idx == 1 then
        otherIdx = 2 
    end
    --print("KaPaiArenaUI:RankCheckBoxCallBack",idx)
    if evnetType == CHECKBOX_STATE_EVENT_SELECTED then
        self.m_zhbaoCheckBoxs[idx]:setTouchEnabled(false)
        self.m_zhbaoCheckBoxs[otherIdx]:setTouchEnabled(true)
        self.m_zhbaoCheckBoxs[otherIdx]:setSelected(false)
        self.m_zhbaoCbLabels[(idx-1)*2+1]:setVisible(true)
        self.m_zhbaoCbLabels[(idx-1)*2+2]:setVisible(false)
        self.m_zhbaoCbLabels[(otherIdx-1)*2+1]:setVisible(false)
        self.m_zhbaoCbLabels[(otherIdx-1)*2+2]:setVisible(true)
        self:ShowRecordList(idx)
    end
end

function KaPaiArenaUI:ShowRecordList(tab)
    --print("KaPaiArenaUI:ShowRecordList",tab)
    self.m_zhbaoListView:removeAllItems()
    local data = LArenaDataMgr.m_records
    if tab == 2 then
        data = LArenaDataMgr.m_myrecords
        Utils:SetRedDotState(RedDotDef.ID.AreanReport, false)
    end
    local isShow = Utils:GetRedDotState(RedDotDef.ID.AreanReport)
    self.m_zbRedPoint:setVisible(isShow)
    for i=1,#data do
        local cell = self.m_zhbaoCell:clone()
        cell.userObject = i
        self.m_zhbaoListView:pushBackCustomItem(cell)
        self:ShowOneRecord(cell,tab,data[i])
    end
end

function KaPaiArenaUI:ShowOneRecord(sender,tab,data)
    local function showHero(heroImg,info)
        local nameLabel = heroImg:getChildByName("Name")
        local powerLabel = heroImg:getChildByName("Power"):getChildByName("Value")
        local imgPath = ""
        if info.IdType == 0 then
            info.head = Utils:CheckHeadId(info.head) 
            imgPath = AppDef:GetHeroPicFileName(info.head,AppDef.HeadType.HERO_IMAGE_HEAD_ROUND)
        else
            local cfg = JsonConfig.m_robotConfig.getDefByID(info.Id)
            if cfg ~= nil then
                info.head = cfg.mod
                info.name = cfg.name
                info.fightpower = cfg.zhanli
                imgPath = "res2/Monster_Bust/"..info.head.."_tou.png"
            end
        end
        nameLabel:setString(info.name)
        powerLabel:setString(Utils:getPowerStr(info.fightpower))
        --print("info.head1",info.head)
        if #imgPath > 0 then
            Utils:SafeLoadTexture(heroImg,imgPath,ccui.TextureResType.localType)
        end
    end
    local idx = sender.userObject
    local tipLabel = sender:getChildByName("Tips")
    local heroImg1 = sender:getChildByName("Icon_1")
    local heroImg2 = sender:getChildByName("Icon_2")
    local btn = sender:getChildByName("PlayBtn")--战斗回放
    btn.userObject = data.replayId
    btn:addClickEventListener(function(sender)
        local id = sender.userObject
        LuaNetSendMsg:SendReplayBattle(id)
    end)

    showHero(heroImg1,data.attackerInfo)
    showHero(heroImg2,data.victimInfo)
    --print("showOnerecord data.win",data.win)
    local str = ""
    if tab == 1 then
        if data.win == 0 then
            str = string.format(GUITips.UI_Arena_Tip5,data.attackerInfo.name,data.victimInfo.name)
            if data.rank < data.oldRank then
                str = str.."，"..string.format(GUITips.UI_Arena_Tip13,data.rank)
            end
        else
            --攻击方失败
            str = string.format(GUITips.UI_Arena_Tip10,data.attackerInfo.name,data.victimInfo.name)
        end
    elseif tab == 2 then
        local myId = LRoleDataMgr.MyHeroInfo.id
        if data.win == 0 then
            if myId == data.attackerInfo.Id then
                str = string.format(GUITips.UI_Arena_Tip8,data.victimInfo.name)
                if data.rank < data.oldRank then
                    str = str.."，"..string.format(GUITips.UI_Arena_Tip13,data.rank)
                end
            else
                str = string.format(GUITips.UI_Arena_Tip7,data.attackerInfo.name)
                if data.rank < data.oldRank then
                    str = str.."，"..string.format(GUITips.UI_Arena_Tip14,data.oldRank)
                end
            end
        else
            --攻击方失败
            if myId == data.attackerInfo.Id then
                str = string.format(GUITips.UI_Arena_Tip9,data.victimInfo.name)
            else
                str = string.format(GUITips.UI_Arena_Tip6,data.attackerInfo.name)
            end
        end
    end
    tipLabel:setString(str)
end
-------------------------------------------------------------战报-end----------------------------------------------------
-------------------------------------------------------------奖励--------------------------------------------------------
function KaPaiArenaUI:OpenRewardPanel(isHide)
    --print("KaPaiArenaUI:OpenRewardPanel",isHide)
    isHide = isHide or 0
    self.m_rewardPanel:setVisible(isHide == 0)
    if isHide == 1 then
        return
    end
    --LArenaDataMgr:InitRankReward()
    LuaNetSendMsg:QueryGotTaskList(1)
    --self:ShowRewardList()
end
function KaPaiArenaUI:ShowRewardList()
    --print("KaPaiArenaUI:ShowRecordList",tab)
    self:SortData()
    self.m_rewardListView:removeAllItems()
    local id = self:GetLastId()
    local cnt = 0
    --local datas = self.m_datas--LRoleDataMgr.Task:GetTaskDataByType(1)
    for i=1,#self.m_showIds do
        local cell = self.m_rewardCell:clone()
        cell.userObject = i
        self.m_rewardListView:pushBackCustomItem(cell)
        local data = self:GetTaskData(self.m_showIds[i].id)
        self:ShowOneReward(cell,data)
        if data.task_id == id then
            cnt = data.taskActiveNum
        end
    end
    self.m_tzCntLabel:setString(""..cnt)
end

function KaPaiArenaUI:SortData()
    self.m_showIds = {}
    if self.m_datas == nil then
        return
    end
    local dels = {}
    for i=1,#self.m_datas do
        local cfg = JsonConfig.m_dailyConfig.getDefByID(self.m_datas[i].task_id)
        if cfg ~= nil and (cfg.show == 0 or self:GetTaskState(cfg.show) == 2) then
            if cfg.show > 0 then
                table.insert(dels,cfg.show)
            end
            local value = {}
            value.id = cfg.id
            value.state = self:GetTaskState(cfg.id)
            if value.state == 0 then
                value.state = 1 
            elseif value.state == 1 then
                value.state = 0
            end
            table.insert(self.m_showIds,value)
        end
    end
    for i=1,#dels do
        for k=1,#self.m_showIds do
            if self.m_showIds[k].id == dels[i] then
                table.remove(self.m_showIds,k)
                break
            end
        end
    end

    local function sortFuc(m1, m2)
        if m1.state == m2.state then
            return m1.id < m2.id
        end
        return m1.state < m2.state
    end
    table.sort(self.m_showIds, sortFuc)
end

function KaPaiArenaUI:GetLastId()
    local id = 0
    local cfgs = JsonConfig.GetDailyByType(1)
    for i=1,#cfgs do
        if cfgs[i].daily == 1 and cfgs[i].condition[1] == 9 then
            id = cfgs[i].id
        end
    end
    return id
end

function KaPaiArenaUI:GetTaskData(id)
    if id == nil then
        return nil
    end
    for i=1,#self.m_datas do
        local data = self.m_datas[i]
        if data.task_id == id then
            return data
        end
    end
    return nil
end

function KaPaiArenaUI:GetTaskState(id)
    if id == nil then
        return 0
    end
    for i=1,#self.m_datas do
        local data = self.m_datas[i]
        if data.task_id == id then
            return data.state
        end
    end
    return 2
end

function KaPaiArenaUI:SetTaskState(id,state)
    if id == nil or self.m_datas == nil then
        return
    end
    for i=1,#self.m_datas do
        local data = self.m_datas[i]
        if data.task_id == id then
            data.state = state
            break
        end
    end
end

function KaPaiArenaUI:ShowOneReward(sender,data)
    local idx = sender.userObject
    local tipLabel = sender:getChildByName("Num")
    self.m_cntLabels[idx] = sender:getChildByName("Value")

    local listView = sender:getChildByName("ListView")
    self.m_drawImgs[idx] = sender:getChildByName("Get")
    self.m_drawBtns[idx] = sender:getChildByName("Btn")
    self.m_drawBtns[idx].userObject = data.task_id
    self.m_drawBtns[idx]:addClickEventListener(function(sender)--领取奖励
        local id = sender.userObject
        LuaNetSendMsg:QueryGotTaskAward(1, id)
    end)
    
    self.m_drawBtns[idx]:setVisible(true)
    self.m_drawImgs[idx]:setVisible(false)
    self.m_drawBtns[idx]:setEnabled(false)
    
    listView:setTouchEnabled(false)
    listView:removeAllItems()
    local cfgData = JsonConfig.m_dailyConfig.getDefByID(data.task_id)
    if cfgData == nil then
        return
    end
    for i=1,#cfgData.reward do
        local value = cfgData.reward[i]
        local cell = self.m_rewardIcon:clone()
        local iconImg = cell:getChildByName("Icon")
        local cntLabel = cell:getChildByName("Text_5")
        cntLabel:setString("")
        Utils:ShowItemByConfigData(value, iconImg, nil, true, true)
        listView:pushBackCustomItem(cell)
    end
    local max = cfgData.condition[2]
    tipLabel:setString(cfgData.des)
    --curCnt = 0
    local cnt  = 0
    -- if cfgData.daily == 1 then
    --     curCnt = data.taskActiveNum
    -- end
    cnt  = data.taskActiveNum
    if cnt > max then
        cnt = max
    end
    if cnt == max then
        if data.state == 1 then
            self.m_drawBtns[idx]:setEnabled(true)
        elseif data.state == 2 then
            self.m_drawBtns[idx]:setVisible(false)
            self.m_drawImgs[idx]:setVisible(true)
        end
    end  
    
    self.m_cntLabels[idx]:setString(""..cnt.."/"..max) 
end
-------------------------------------------------------------奖励-end----------------------------------------------------

function KaPaiArenaUI:CloseUI()
    LGameMsg.m_deleteUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "WanFa.KaPaiArenaUI")
    self:SendMsg(LGameMsg.m_deleteUIMsg)
end

function KaPaiArenaUI:RegisterGuide()
    local data = LArenaDataMgr.m_modelInfos
    local sign = false
    for i= #data,1,-1 do
        if sign then
            self.m_guideBtn = self.m_fightBtns[i+10]
            break
        end
        if data[i].Id == LRoleDataMgr.MyHeroInfo.id then
            sign = true
        end
    end
    if self.m_guideBtn then
        Utils:RegisterGuide(GuideDef.StepId.Guide_Arena_Finish, self.m_guideBtn ,function()
             self:OnFightClick(self.m_guideBtn)
        end, nil, true)
    end
end 

function KaPaiArenaUI:InitRedDot()
    LRedDotCheckMgr:AddCheckBtn(self.m_pUILayer:findChildByName("Panel/JingjiBg/Btn_2"), "btn_arena_reward")
    LRedDotCheckMgr:AddCheckBtn(self.m_pUILayer:findChildByName("Panel/JingjiBg/Btn_4"), "btn_arena_report")
    --Utils:SendMsg(LUILogicEvent.RedDotCheck, "btn_arena_report")
    self:UpdateShopRedDot()
end 

function KaPaiArenaUI:UpdateShopRedDot()
    if self.m_shopRedDot ~= nil then
        local show = Utils:GetRedDotState(RedDotDef.ID.ShopWanFaJingji)
        self.m_shopRedDot:setVisible(show)
    end
end

--每日任务-竞技场
function KaPaiArenaUI:TaskRedCheck(value)
    local show = false
    for i=1,#self.m_datas do
        local data = self.m_datas[i]
        if data.state == 1 then
            show = true
            break
        end
    end
    Utils:SetRedDotState(RedDotDef.ID.ArenaTask, show)
end
return KaPaiArenaUI