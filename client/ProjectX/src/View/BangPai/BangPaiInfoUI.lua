local BangPaiInfoUI = LUIBase:New()
BangPaiInfoUI.__index = BangPaiInfoUI
BangPaiInfoUI.IsHideInBattle = true
local BangPaiDef = require("View.BangPai.BangPaiDef")
local ShopDef = require("View.Shop.ShopDef")

-- -----------------------------------
function BangPaiInfoUI:New(bpUI)
    local o = {}
    setmetatable(o, BangPaiInfoUI)
    o:Init(bpUI)
    return o
end

-- -----------------------------------
function BangPaiInfoUI:Init(bpUI)
    self.Script = "BangPai.BangPaiInfoUI"
    self.m_bpUI = bpUI
    self.m_pMessageBoxUI = nil
    self.m_pBasicNews = nil
    self.m_pDetailedNews = nil
    self.m_pGongGaoButtons = {}
    self.m_schedule = nil

    --table view相关
    self.m_pGridCell = nil
    self.m_pTablePanel = nil
    self.m_datas = {}

    self:RegistMsgs()
    self:InitViewSize()
    self:InitUIControl()
    self:setCloseCallback()
    self:InitData()
    self:ShowMoney();
    self:ShowTongbao();
    self:ShowTili();
    self:setBasicUI();
    self:OnEnter();
    -- LuaNetSendMsg:QueryFactionList()
    -- LuaNetSendMsg:QueryFactionInfo()
    LuaNetSendMsg:QueryFactionZoneInfo()
    -- LuaNetSendMsg:QueryFactionActivityList()
    LuaNetSendMsg:QueryBangPaiHuoyue();
end

function BangPaiInfoUI:OnEnter()
    local function initRedDotState(id)
        local isShow = Utils:GetRedDotState(id)
        self:DealUpdateRedDotState({id=id, isShow=isShow})
    end
    initRedDotState(RedDotDef.ID.BPChengYuan);
    initRedDotState(RedDotDef.ID.BPShiJian);
    initRedDotState(RedDotDef.ID.BPJiangLi);
    initRedDotState(RedDotDef.ID.BPFuben);
    -- initRedDotState(RedDotDef.ID.BPHuoDong)
    -- initRedDotState(RedDotDef.ID.BPXinXi)
    -- initRedDotState(RedDotDef.ID.BPXiuLian)
end

function BangPaiInfoUI:DealUpdateRedDotState(data)
    -- local ind = 0
    -- if data.id == RedDotDef.ID.BPChengYuan or data.id == RedDotDef.ID.BPXinXi then
    --     ind = self:getIndex(AppDef.EModuleID.EMID_BPXINXI)
    -- elseif data.id == RedDotDef.ID.BPHuoDong then
    --     ind = self:getIndex(AppDef.EModuleID.EMID_BPHUODONG)
    -- -- elseif data.id == RedDotDef.ID.BPXiuLian then
    -- --     ind = self:getIndex(AppDef.EModuleID.EMID_BPXIULIAN)
    -- end
    -- if ind > 0 then
    --     Utils:SendMsg(LUIFClassBgEvent.RedDotState, {ind, data.isShow})
    -- end
    local ind = 0
    if data.id == RedDotDef.ID.BPChengYuan then
        self.m_pUILayer:findChildByName("Bangpai/BtnList/Btn3/Prompt"):setVisible(data.isShow);
    elseif data.id == RedDotDef.ID.BPShiJian then
        self.m_pUILayer:findChildByName("Bangpai/BtnList/Btn4/Prompt"):setVisible(data.isShow);
    elseif data.id == RedDotDef.ID.BPJiangLi then
        self.m_pUILayer:findChildByName("Bangpai/Huoyue/LoadingBg/Reward/Prompt"):setVisible(data.isShow);
    elseif data.id == RedDotDef.ID.BPFuben then
        self.m_pUILayer:findChildByName("Bangpai/Panel_1/Btn/Prompt"):setVisible(data.isShow);

    end
    -- if ind > 0 then
    --     Utils:SendMsg(LUIFClassBgEvent.RedDotState, {ind, data.isShow})
    -- end
end

function BangPaiInfoUI:SetRedDotState(value)
    local ind = value[1]
    local show = value[2]
    if self.m_pTabBtns[ind] == nil then return end
    local btn = self.m_pTabBtns[ind]:getChildByName("Button1")
    if btn ~= nil then
        btn:getChildByName("Prompt"):setVisible(show)
    end
end


function BangPaiInfoUI:InitData()
    local datas = require("ConfigData.guild_reward_dat");
    self._maxHuoyue = 0;
    for i = 1, #datas do
        if datas[i].activity > self._maxHuoyue then
            self._maxHuoyue = datas[i].activity
        end
    end

end

function BangPaiInfoUI:ShowTili()
    local moneyLabel = self.m_pUILayer:findChildByName("Panel/GoldCheck/GoldIcon1/GoldNumBg/Num");
    local myTili = LRoleDataMgr.MyHeroInfo:GetDetailData():getTili()
    moneyLabel:setString(Utils:getTiliStr(myTili))
end

function BangPaiInfoUI:ShowTongbao()
    local moneyLabel = self.m_pUILayer:findChildByName("Panel/GoldCheck/GoldIcon4/GoldNumBg/Num");
    local myGold = LRoleDataMgr.MyHeroInfo.DetailData:GetTongBao()
    moneyLabel:setString(myGold)
end

function BangPaiInfoUI:ShowMoney()
    local moneyLabel = self.m_pUILayer:findChildByName("Panel/GoldCheck/GoldIcon3/GoldNumBg/Num");
    local myMoney = Utils:getGoldStr()
    moneyLabel:setString(myMoney)
end

-- -----------------------------------
function BangPaiInfoUI:onExit()
    self:Destory()
    if self.m_schedule ~= nil then
        self.m_pTablePanel:stopAction(self.m_schedule)
        self.m_schedule = nil
    end
    self.m_pUILayer = nil
    self.m_bpUI = nil
    self.m_pMessageBoxUI = nil
    self.m_pBasicNews = nil
    --self.m_pDetailedNews = nil
    self.m_pHuoyueNode = nil
    self.m_pFubenNode = nil
    Utils:FreeTable(self.m_pGongGaoButtons)
    self.m_pGongGaoButtons = nil

    --table view相关
    self.m_pGridCell = nil
    self.m_pTablePanel = nil
    self.m_datas = nil
end

-- -----------------------------------
function BangPaiInfoUI:RegistMsgs()
    self.msgIds = {
        LUIBangPaiEvent.UpdateGongGao,
        LUIBangPaiEvent.UpdateNameShow,
        LUIBangPaiEvent.UpdateManorInfo,
        LUIBangPaiEvent.UpdateMyFactionInfo,
        -- LUIBangPaiEvent.FlushFactionActivity,
        -- LUIBangPaiEvent.ReloadFactionActivityList,
        LUIRedDotEvent.UpdateRedDotState,
        LUILogicEvent.changeBpNameSuc,
        LUIBangPaiEvent.GotChapterData,
        LUIBangPaiEvent.UpdateTodayHuoyue,
    }
    self:RegistSelf(self, self.msgIds)
end

-- -----------------------------------
function BangPaiInfoUI:ProcessEvent(msg)
    if msg.msgId == LUIBangPaiEvent.UpdateMyFactionInfo then
        self:setBasicUI()
    elseif msg.msgId == LUIBangPaiEvent.UpdateGongGao then
        self:UpdateGongGao()
    elseif msg.msgId == LUIBangPaiEvent.UpdateNameShow then
        self:updateBPNameVisible(msg.value)
    elseif msg.msgId == LUIBangPaiEvent.UpdateManorInfo then
        self:setDetailUI()
    -- elseif msg.msgId == LUIBangPaiEvent.ReloadFactionActivityList then
    --     self:ReloadActivityData(msg.value)
    -- elseif msg.msgId == LUIBangPaiEvent.FlushFactionActivity then
    --     self:SetActivity(LRoleDataMgr.Faction.Info.totalActivity)
    elseif msg.msgId == LUIRedDotEvent.UpdateRedDotState then
        self:UpdateRedDot(msg.value)
    elseif msg.msgId == LUILogicEvent.changeBpNameSuc then
        self:setBpName()
    elseif msg.msgId == LUIBangPaiEvent.GotChapterData then
        self:GotChapterData()
    elseif msg.msgId == LUIBangPaiEvent.UpdateTodayHuoyue then
        self:UpdateHuoyue()
    end
end

function BangPaiInfoUI:UpdateHuoyue()
    -- LRoleDataMgr.Faction.todayHuoyue = stream:ReadUInt();
    --     local num = stream:ReadByte();
    --     LRoleDataMgr.Faction.huoyueAward = {};--活跃奖励
    --     for i = 1, num do
    --         local data = {}
    --         data.huoyueId = stream:ReadWord();
    --         data.itemNum = stream:ReadInt();
    --         table.insert(LRoleDataMgr.Faction.huoyueAward, data);
    --     end
    --     Utils:SendMsg(LUIBangPaiEvent.UpdateTodayHuoyue);
    local list = LRoleDataMgr.Faction.huoyueAward
    if #list == 0 then
        return
    end
    self._curHuoyueId = 0;
    local hasReward = false;
    for i = 1, #list do
        if list[i].isGet == 1 then
            self._curHuoyueId = list[i].huoyueId;
            hasReward = true;
            break
        end
    end

    self.m_pUILayer:findChildByName("Bangpai/Huoyue/LoadingBg/Reward"):setVisible(hasReward)

    -- self.m_curAct = self.m_activityList[#self.m_activityList]
    -- self.m_maxAct = self.m_curAct.activity
    -- for i=1,#self.m_activityList do
    --     local item = self.m_activityList[i]
    --     if item and item.state == 0 then
    --         self.m_maxAct = item.activity
    --         self.m_curAct = item
    --         break
    --     end
    -- end
--    dump(self.m_curAct, "self.m_curAct--->")
--    dump(LRoleDataMgr.Faction.Info.totalActivity, "LRoleDataMgr.Faction.Info.totalActivity--->")
    self:SetActivity(LRoleDataMgr.Faction.todayHuoyue)
    -- self:SetOneReward(self.m_pEquip, self.m_curAct)
end

function BangPaiInfoUI:setCloseCallback()
    local function onNodeEvent(event)
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
end

-- -----------------------------------
function BangPaiInfoUI:InitViewSize()
    AppDef.spriteFrameCache:addSpriteFrames("csd/Plist/ui_huobi.plist", "csd/Plist/ui_huobi.png")
    self:CreateUINode("csd/bangpai/GangsLayer.csb");

    self.m_timeline = cc.CSLoader:createTimeline("csd/bangpai/GangsLayer.csb")
    self.m_timeline:pause()
    self.m_pUILayer:runAction(self.m_timeline)
    self.m_timeline:gotoFrameAndPlay(0, true)
end

-- -----------------------------------

function BangPaiInfoUI:IsFuBenLocked()
    if Utils:CheckModelNotOpened(AppDef.EModuleID.EMID_BPFUBEN, false) then
        return true
    end
    return false;
    -- if LRoleDataMgr.MyHeroInfo.level < 30 then
    --     return true
    -- end
    -- return false
end

function BangPaiInfoUI:GotChapterData()
    Utils:OpenFunction(AppDef.EModuleID.EMID_BPFUBEN)
end

function BangPaiInfoUI:OpenFuben()
    if self:IsFuBenLocked() == true then
        -- Utils:ShowScrollTips(string.format(GUITips.RSI_TARGET_RD_TIPS6,30))
        return
    end

    LuaNetSendMsg:QueryBangPaiFubenList()
    
    -- Utils:OpenFunction(AppDef.EModuleID.EMID_BPFUBEN)
end
function BangPaiInfoUI:InitUIControl()

    local panel = self.m_pUILayer:getChildByName("Bangpai")

    local pGuildNews = panel:getChildByName("GuildNews")

    local pBasicNews = pGuildNews:getChildByName("BasicNews")
    self.m_pBasicNews = pBasicNews

    local topNode = self.m_pUILayer:getChildByName("Panel");

    local closeBtn = self.m_pUILayer:findChildByName("Panel/Title/CloseBtn");
    closeBtn:addClickEventListener(function(sender)
        self:onCloseClicked()
    end)

    local fubtnBtn = self.m_pUILayer:findChildByName("Bangpai/Panel_1/Btn");
    fubtnBtn:addClickEventListener(function(sender)
        self:OpenFuben();
        
    end)

    local fubenLockBtn = self.m_pUILayer:findChildByName("Bangpai/Panel_1/Btn/Lock");
    fubenLockBtn:setVisible(self:IsFuBenLocked());

    ---------------------------------------------
    local pHelpBtn = pBasicNews:getChildByName("HelpBtn")
    pHelpBtn:addClickEventListener(function(sender)
        self:helpButtonCallback()
    end)
	self:MarkIntaractCObj(pHelpBtn)
    ---------------------------------------------
    local pGaiMingBtn = pBasicNews:getChildByName("btn_gaiming")
    pGaiMingBtn:addClickEventListener(function(sender)
        local bangPai = LRoleDataMgr.Faction.Info
        if bangPai.selfRank ~= BangPaiDef.BPRT.BANGZHU then
            Utils:ShowScrollTips(GUITips.RSI_BP_CHANGENAME_TIPS2)
            return
        end
        Utils:InitUI("Role.GaiMingUI", AppDef.UIType.PopWindow, 2)
    end)
    self:MarkIntaractCObj(pGaiMingBtn)

    ---------------------------------------------
    local pInformation3 = pBasicNews:getChildByName("Information3")
    local pOpenBtn = pInformation3:getChildByName("OpenBtn")
    pOpenBtn:addClickEventListener(function(sender)
        self:setBPNameVisible(true)
    end)
	self:MarkIntaractCObj(pOpenBtn)
    self.m_pGongGaoButtons[1] = pOpenBtn

    local pCloseBtn = pInformation3:getChildByName("CloseBtn")
    pCloseBtn:addClickEventListener(function(sender)
        self:setBPNameVisible(false)
    end)
	self:MarkIntaractCObj(pCloseBtn)
    pCloseBtn:setVisible(false)
    self.m_pGongGaoButtons[2] = pCloseBtn

    ---------------------------------------------
    local pNoticeBtn = pBasicNews:getChildByName("NoticeBtn")
    pNoticeBtn:addClickEventListener(function(sender)
        local bangPai = LRoleDataMgr.Faction.Info
        if bangPai.selfRank ~= BangPaiDef.BPRT.BANGZHU then
            Utils:ShowScrollTips(GUITips.RSI_BP_TIP3)
            return
        end
        self:showGongGaoPanel(true)
    end)
	self:MarkIntaractCObj(pNoticeBtn)
    ---------------------------------------------

    self.m_pHuoyueNode = panel:getChildByName("Huoyue")
    self.m_pFubenNode = panel:getChildByName("Panel_1")
    -- local pDetailedNews = pGuildNews:getChildByName("DetailedNews")
    -- self.m_pDetailedNews = pDetailedNews

    local pBtnBg = panel:getChildByName("BtnList")
    local pBtn1 = pBtnBg:getChildByName("Btn1")
    pBtn1:addClickEventListener(function(sender)
        --self:JuanXian()
        Utils:OpenFunction(AppDef.EModuleID.EMID_SHOP_BANGPAI)
    end)

    local pBtn2 = pBtnBg:getChildByName("Btn2")
    pBtn2:addClickEventListener(function(sender)
        Utils:OpenFunction(AppDef.EModuleID.EMID_BPLIEBIAO)
    end)

    local pBtn3 = pBtnBg:getChildByName("Btn3")
    pBtn3:addClickEventListener(function(sender)
        Utils:OpenFunction(AppDef.EModuleID.EMID_BPCHENGYUAN)
    end)
	-- self:MarkIntaractCObj(pBtn1)
 --    local pReddot = pBtn1:getChildByName("Reddot")
 --    pReddot:setVisible(false)

    -- local pBtn3 = pBtnBg:getChildByName("Btn3")
    -- pBtn3:addClickEventListener(function(sender)
    --     self:LingDi()
    -- end)

    local pBtn4 = pBtnBg:getChildByName("Btn4")
    pBtn4:addClickEventListener(function(sender)
        self:ShiJian()
    end)
	self:MarkIntaractCObj(pBtn2)
    
    local pBtn5 = pBtnBg:getChildByName("Btn5")
    pBtn5:addClickEventListener(function(sender)
        local rank = LRoleDataMgr.Faction.Info.selfRank
        print("rank",rank)
        if(rank ~= AppDef.FactionInfo.BPRT_BANGZHU and rank ~= AppDef.FactionInfo.BPRT_ZHANGLAO) then
            Utils:ShowScrollTips(GUITips.RSI_BP_TIP52)
            return
        end
        self.m_pSetLevel:setVisible(true)    
    end)
    self:MarkIntaractCObj(pBtn5)
    local pBtn6 = pBtnBg:getChildByName("Btn6")
    pBtn6:addClickEventListener(function(sender)
        self:JuanXian()
    end)
    self:MarkIntaractCObj(pBtn6)
    -- self._kejiRedDot = pBtn6:getChildByName("Reddot")
    -- local curRed = Utils:GetRedDotState(RedDotDef.ID.BPKeji)
    -- self._kejiRedDot:setVisible(curRed)
    ---------------------------------------------
    self.m_pSetLevel = self.m_pUILayer:getChildByName("SetLevel")
    self.m_pSetLevel:setVisible(false)
    self:InitSetPanel()
    ---------------------------------------------
    self.m_pMessageBoxUI = self.m_pUILayer:getChildByName("MessageBoxUI")
    self.m_pMessageBoxUI:setVisible(false)
    ---------------------------------------------
    local moneyPanel = topNode:getChildByName("GoldCheck")
    local money1 = moneyPanel:getChildByName("GoldIcon1")
    self.m_tiliImg = money1:getChildByName("Icon")--体力
    local tiliAddBtn = money1:getChildByName("AddBtn")
    tiliAddBtn:addClickEventListener(function ( sender )
        Utils:OpenUseUI(500,1)
    end)
    local money2 = moneyPanel:getChildByName("GoldIcon3")
    self.m_goldImg = money2:getChildByName("Icon")--金币
    local goldAddBtn = money2:getChildByName("AddBtn")
    goldAddBtn:addClickEventListener(function ( sender )
        Utils:OpenFunction(AppDef.EModuleID.EMID_SCCHANGYONG)
    end)
    local money3 = moneyPanel:getChildByName("GoldIcon4")
    self.m_cashImg = money3:getChildByName("Icon")--元宝
    local cashAddBtn = money3:getChildByName("AddBtn")
    cashAddBtn:setEnabled(false)
    
    local imgPath1 = "res/UI/Icon/ui_huobi_icon/huobi_"..LRoleDataMgr.GetItemPicId(AppDef.SpecialItemId.Tili)..".png"
    Utils:SafeLoadTexture(self.m_tiliImg,imgPath1,ccui.TextureResType.plistType)
    local imgPath2 = "res/UI/Icon/ui_huobi_icon/huobi_"..LRoleDataMgr.GetItemPicId(AppDef.SpecialItemId.Gold)..".png"
    Utils:SafeLoadTexture(self.m_goldImg,imgPath2,ccui.TextureResType.plistType)
    local imgPath3 = "res/UI/Icon/ui_huobi_icon/huobi_"..LRoleDataMgr.GetItemPicId(AppDef.SpecialItemId.Cash)..".png"
    Utils:SafeLoadTexture(self.m_cashImg,imgPath3,ccui.TextureResType.plistType)
    ---------------------------------------------
    self:initGongGaoPanel()
    ---------------------------------------------
    self:initActivity()
    ---------------------------------------------
end

function BangPaiInfoUI:onCloseClicked()
    self:RemoveUI()
end

function BangPaiInfoUI:initGongGaoPanel()
    local pMessageBoxUI = self.m_pMessageBoxUI:getChildByName("MessageBoxUI")
    local pbg = pMessageBoxUI:getChildByName("bg")
    local pBtn_close = pbg:getChildByName("Btn_close")
    pBtn_close:addClickEventListener(function(sender)
        self:showGongGaoPanel(false)
    end)
	self:MarkIntaractCObj(pBtn_close)
    local pDesBg1 = pMessageBoxUI:getChildByName("DesBg1")
    local pTextField = pDesBg1:getChildByName("TextField")
    pTextField:setCursorEnabled(true)

    local pBtn_Confirm = pMessageBoxUI:getChildByName("Btn_Confirm")
    pBtn_Confirm:addClickEventListener(function(sender)
        local str = pTextField:getString()
        if #str == 0 then
            Utils:ShowScrollTips(GUITips.RSI_BP_TIP8)
            return
        end
        if #str > 150 then
            Utils:ShowScrollTips(GUITips.RSI_GM_TIP13)
            return
        end
        str = Utils:FilterLimitedMsg(str)
        LuaNetSendMsg:QueryFactionChangeAnnoucement(str)
        self:showGongGaoPanel(false)
    end)
	self:MarkIntaractCObj(pBtn_Confirm)
end

function BangPaiInfoUI:helpButtonCallback()
    local str = string.format("%s%s%s%s%s", GUITips.RSI_BP_TIP19, GUITips.RSI_BP_TIP20, GUITips.RSI_BP_TIP21, GUITips.RSI_BP_TIP22, GUITips.RSI_BP_TIP23)

    local function OKCallback()
    end
    local msgData = {
        okCallback = OKCallback,
        desc = str
    }
    LGameMsg.m_baseMsgWithOne:Change(LUIMsgBoxEvent.ShowMsgBox, msgData)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)
end

function BangPaiInfoUI:setBPNameVisible(bShow)
    local isShow = Utils:three(LRoleDataMgr.Faction.Info.isShowBPName, 0, 1)
    LuaNetSendMsg:QueryIsShowBPName(isShow)
    LuaNetSendMsg:DealHeroTitleShow(0, isShow)
end

function BangPaiInfoUI:updateBPNameVisible( bShow )
    bShow = Utils:ToBool(bShow)
    self.m_pGongGaoButtons[1]:setVisible(bShow)
    self.m_pGongGaoButtons[2]:setVisible(not bShow)
end

function BangPaiInfoUI:showGongGaoPanel(bShow)
    if self.m_pMessageBoxUI ~= nil then
        self.m_pMessageBoxUI:setVisible(bShow)
    end
end

function BangPaiInfoUI:setBasicUI()
    local bangPai = LRoleDataMgr.Faction.Info

    if bangPai.id == 0 or self.m_pBasicNews == nil then
        return
    end

    local pTitleBg = self.m_pBasicNews:getChildByName("TitleBg")
    local pTitleName = pTitleBg:getChildByName("TitleName")
    self._pTitleName = pTitleName
    self._pTitleLv=self.m_pBasicNews:findChildByName("GuildImageBg/Level")
    self:setBpName()

    local expRatio = (bangPai.Exp/bangPai.MaxExp)*100/10 + 1
    local ratio = expRatio/10
    if bangPai.Exp == 0 then
        ratio = 0
    end

    local pGuildImageBg = self.m_pBasicNews:getChildByName("GuildImageBg")
    
    --TODO:帮派ICON
    local pGuildImage = pGuildImageBg:getChildByName("GuildImage")
    -- pGuildImage:setVisible(false)

    local pLoading = pGuildImageBg:getChildByName("Loading")
    pLoading:setVisible(false)

    local pSp = cc.Sprite:createWithSpriteFrameName("res/UI/ui_bangpai/ui_bangpai_jingyan.png")
    local progressBar = cc.ProgressTimer:create(pSp)
    progressBar:setType(cc.PROGRESS_TIMER_TYPE_RADIAL)
    progressBar:setIgnoreAnchorPointForPosition(true)
    progressBar:setAnchorPoint(pLoading:getAnchorPoint())
    progressBar:setPosition(cc.p(pLoading:getPosition()))
    progressBar:setPercentage(0)
    progressBar:runAction(cc.ProgressTo:create(0.5, ratio*100))
    pGuildImageBg:addChild(progressBar)

    local function setInformation(bg, value)
        if bg == nil then
            return
        end
        local pName = bg:getChildByName("Name")
        local pText = pName:getChildByName("Text")
        pText:setString(tostring(value))
    end

    local pInfo1 = self.m_pBasicNews:getChildByName("Information1")
    local pInfo2 = self.m_pBasicNews:getChildByName("Information2")
    local pInfo3 = self.m_pBasicNews:getChildByName("Information3")
    local pInfo4 = self.m_pBasicNews:getChildByName("Information4")
    local pInfo5 = self.m_pBasicNews:getChildByName("Information5")
    local pInfo6 = self.m_pBasicNews:getChildByName("Information6")
    
    setInformation(pInfo1, bangPai.rank)
    setInformation(pInfo2, string.format("%d/%d", bangPai.memberNum, bangPai.MaxMemberNum))
    setInformation(pInfo3, Utils:getPostName(bangPai.selfRank))
    setInformation(pInfo4, bangPai:GetselfBangGong())
    setInformation(pInfo5, bangPai.bpMoney)
    pInfo6:getChildByName("Name"):setString(string.format("%d/%d", bangPai.Exp, bangPai.MaxExp))

    self:updateBPNameVisible(bangPai.isShowBPName)
    self:UpdateGongGao()
end

function BangPaiInfoUI:setBpName( ... )
    -- body
    local bangPai = LRoleDataMgr.Faction.Info
    self._pTitleName:setString(bangPai.name)
    self._pTitleLv:setString(string.format("LV%d",bangPai.level))
end

function BangPaiInfoUI:setDetailUI()
 --    local info = LRoleDataMgr.Faction:GetManorInfo()
 --    self.m_datas = info.VecFileds

 --    local pTreeNews = self.m_pDetailedNews:getChildByName("TreeNews")

 --    local function setInformation(bg, value)
 --        if bg == nil then
 --            return
 --        end
 --        local pName = bg:getChildByName("Name")
 --        local pText = pName:getChildByName("Text")
 --        pText:setString(tostring(value))
 --    end

 --    local pInformation1 = pTreeNews:getChildByName("Information1")
 --    local pInformation2 = pTreeNews:getChildByName("Information2")
 --    local pInformation2_0 = pTreeNews:getChildByName("Information2_0")
 --    local pInformation2_1 = pTreeNews:getChildByName("Information2_1")
 --    local pInformation2_2 = pTreeNews:getChildByName("Information2_2")

 --    setInformation(pInformation1, "LV"..info.GodTreeLevel)
 --    setInformation(pInformation2, info.PrayTimes)
 --    setInformation(pInformation2_0, info.GuardNums)
 --    setInformation(pInformation2_1, info.MaxFields-info.LeftFields)
 --    setInformation(pInformation2_2, info.LeftFields)

 --    local pDecBg = self.m_pDetailedNews:getChildByName("DecBg")
 --    local pViewBg = pDecBg:getChildByName("ViewBg")
 --    local pUpBtn = pViewBg:getChildByName("UpBtn")
 --    pUpBtn:addClickEventListener(function(sender)
 --        self:upButtonCallback()
 --    end)
	-- self:MarkIntaractCObj(pUpBtn)
 --    local pList = pDecBg:getChildByName("List")
 --    self.m_pTablePanel = pList

 --    local pDecRow = pDecBg:getChildByName("DecRow")
 --    pDecRow:setVisible(false)
 --    pDecRow:setTouchEnabled(false)
 --    self.m_pGridCell = pDecRow

 --    self:InitLogList()

 --    local function updateTime(sender)
 --        self:updateTime()
 --    end

 --    self.m_schedule = schedule(self.m_pTablePanel, updateTime, 1)
end

function BangPaiInfoUI:InitLogList()
    self.m_pTablePanel:removeAllItems()
    for i=1,#self.m_datas do
        local pCell = self.m_pGridCell:clone()
        pCell:setVisible(true)
        self:updateItem(pCell, self.m_datas[i])
        self.m_pTablePanel:pushBackCustomItem(pCell)
    end
end

function BangPaiInfoUI:updateItem(cell, info)
    local pText = cell:getChildByName("Text")
    pText:setString(info.treeName)

    if bit.band(info.state, 0x01) == 0x01 then
        self:setItemTime(cell, nil, GUITips.RSI_FACTION_MSG11)
    else
        self:setItemTime(cell, info.leftTimes)
    end
end

function BangPaiInfoUI:setItemTime(cell, leftTimes, str)
    local pText_0 = cell:getChildByName("Text_0")
    if str ~= nil then
        pText_0:setString(str)
    else
        pText_0:setString(self:getTimeString(leftTimes))
    end
end

function BangPaiInfoUI:UpdateGongGao()
    local pTextField = self.m_pBasicNews:getChildByName("TextField")
    pTextField:setTouchEnabled(false)
    pTextField:setString(LRoleDataMgr.Faction.Info.gongGao)

    local pMessageBoxUI = self.m_pMessageBoxUI:getChildByName("MessageBoxUI")
    local pDesBg1 = pMessageBoxUI:getChildByName("DesBg1")
    local pTextField = pDesBg1:getChildByName("TextField")
    pTextField:setString(LRoleDataMgr.Faction.Info.gongGao)
end

function BangPaiInfoUI:upButtonCallback()
end

function BangPaiInfoUI:getTimeString(leftTimes)
    if leftTimes == 0 then
        return GUITips.RSI_FACTION_MSG11
    end
    local _h, _m, _s = Utils:getFormatTime(leftTimes)
    local str = GUITips.RSI_FACTION_MSG3
    local timeStr = ""
    if leftTimes >= 3600 then
        timeStr = string.format("%d%s%d%s", _h, GUITips.RSI_MYTEAM_MSG30, _m, GUITips.RSI_MYTEAM_MSG31)
    else
        timeStr = string.format("%d%s%d%s", _m, GUITips.RSI_MYTEAM_MSG31, _s, GUITips.RSI_MYTEAM_MSG32)
    end
    return string.format(str, timeStr)
end

function BangPaiInfoUI:updateTime()
    for i=1,#self.m_datas do
        if self.m_datas[i].leftTimes > 0 then
            self.m_datas[i].leftTimes = math.max(self.m_datas[i].leftTimes - 1, 0)
            if self.m_datas[i].leftTimes == 0 then
                self.m_datas[i].state = 1
            end
        end
    end
    self:flushCellTimer()
end

function BangPaiInfoUI:flushCellTimer()
    for i=1,#self.m_pTablePanel:getItems() do
        local info = self.m_datas[i]
        if info then
            if bit.band(info.state, 0x01) == 0x01 then
                self:setItemTime(self.m_pTablePanel:getItem(i-1), nil, GUITips.RSI_FACTION_MSG11)
            else
                self:setItemTime(self.m_pTablePanel:getItem(i-1), info.leftTimes)
            end
        end
    end
end

function BangPaiInfoUI:JuanXian()
    LuaNetSendMsg:QueryFactionJuanXianMsg()
end

function BangPaiInfoUI:ShiJian()
    Utils:InitUI("BangPai.BangPaiEventPopup", AppDef.UIType.SecondClassLayer)
end

function BangPaiInfoUI:LingDi()
    if LRoleDataMgr.m_bIsCrossServer then
        Utils:ShowScrollTips(GUITips.RSI_CS_TIP2)
        return
    end
    LuaNetSendMsg:QueryBangPaiEnterZone(LRoleDataMgr.Faction.Info.id)
end

function BangPaiInfoUI:InitSetPanel()
    local pBg = self.m_pSetLevel:getChildByName("Bg")
    local pImageBg = pBg:getChildByName("Image_Bg")
    
    local config = LDataConstMgr:GetFunctionLevelData(AppDef.EModuleID.EMID_BANGPAI)
    local limitValue = 20
    if config and config.open_condition and #config.open_condition > 0 then
        if config.open_condition[1].cType == 1 then
            limitValue = config.open_condition[1].cValue
        end
    end

    local pSlider = pImageBg:getChildByName("Bg"):getChildByName("Slider_1")
    local pText = pSlider:getChildByName("Text")

    local maxLevel = 100-limitValue+1

    local function SetLevel(level)
        local Showlevel = level
        if level > 0 then
            Showlevel = level + limitValue - 1
        end
        pSlider:setPercent(level)
        pText:setString(tostring(Showlevel))
        local pro = level/maxLevel
        pText:setPositionX(pro*pSlider:getContentSize().width)
    end
    
    pSlider:setMaxPercent(maxLevel)
    if LRoleDataMgr.Faction.Info.limitLevel > 0 then
        SetLevel(LRoleDataMgr.Faction.Info.limitLevel - limitValue + 1)
    else
        SetLevel(1)
    end
    pSlider:addEventListener(function(sender, event)
        local persent = sender:getPercent()
        -- print("persent =========>", persent)
        if persent <= 0 then
            persent = 1
        end
        SetLevel(persent)
    end)

    local pBtnConfirm = pBg:getChildByName("Btn_Confirm2")
    pBtnConfirm:addClickEventListener(function(sender)
        local level = pSlider:getPercent()
        if level > 0 then
            level = level + limitValue - 1
        end
        local isLevelLimit = (level > 0)
        if isLevelLimit then
            local info = LDataConstMgr:GetFunctionLevelData(AppDef.EModuleID.EMID_BANGPAI)
            if limitValue then
                if level < limitValue then
                    Utils:ShowScrollTips(string.format(GUITips.RSI_BP_TIP48, limitValue))
                    return
                end
                if level > 100 then
                    Utils:ShowScrollTips(string.format(GUITips.RSI_BP_TIP51, 100))
                    return
                end
            end
        end
        local checkBox = pBg:getChildByName("CheckBox_1")
        local isSelect = checkBox:isSelected()
        if not isSelect then
            SetLevel(1)
            LuaNetSendMsg:QuerySetBPApply(0)
        else
            LuaNetSendMsg:QuerySetBPApply(level)
        end
        
        self.m_pSetLevel:setVisible(false)
    end)

    local pBtnClose = pBg:getChildByName("Btn_close")
    pBtnClose:addClickEventListener(function(sender)
        if LRoleDataMgr.Faction.Info.limitLevel > 0 then
            SetLevel(LRoleDataMgr.Faction.Info.limitLevel - limitValue + 1)
        else
            SetLevel(1)
        end
        self.m_pSetLevel:setVisible(false)
    end)

    local checkBox = pBg:getChildByName("CheckBox_1")
    local function autoIntoBPEvent( sender )
        -- body
        local isSelect = sender:isSelected()
        if isSelect then
            SetLevel(1)
            LuaNetSendMsg:QuerySetBPApply(0)
        end
    end
    checkBox:addClickEventListener(autoIntoBPEvent)
    local isSelect = checkBox:isSelected()
    if not isSelect then
        SetLevel(1)
    end
end
-- function BangPaiInfoUI:SetRewardVisiable(isV)
--     local reward = self.m_pHuoyueNode:findChildByName("LoadingBg/Reward")
--     Reward 
--     -- body
-- end

function BangPaiInfoUI:initActivity()
    if self.m_pHuoyueNode == nil then
        return
    end
    local pLoadingBg = self.m_pHuoyueNode:getChildByName("LoadingBg")
    self.m_pLoadingBar = pLoadingBg:getChildByName("LoadingBar")
    self.m_pEquip = self.m_pHuoyueNode:getChildByName("Equip")
    self.m_pEquip:setTouchEnabled(true)
    self.m_pEquip:addClickEventListener(handler(self, self.EquipClick))

    self.m_pActivityNum = pLoadingBg:getChildByName("ValueBg"):getChildByName("Value")

    self.m_pNeedActivityNum = self.m_pHuoyueNode:findChildByName("Bg/Value")
    self.m_pNeedActivityNum:setString("0")

    local btn = self.m_pHuoyueNode:getChildByName("HelpBtn")
    local function helpBtn( sender )
        -- body
        local function OnOk()
        end
        Utils:ShowDialogOKCancel(GUITips.RSI_BP_DES_TIPS1, OnOk)
    end
    btn:addClickEventListener(helpBtn)


    local function getBtn( sender )
        self:HandleGetHuoyueReward();
    end
    self.m_pHuoyueNode:addClickEventListener(getBtn)

end

function BangPaiInfoUI:HandleGetHuoyueReward()
    Utils:OpenFunction(AppDef.EModuleID.EMID_BPHYREWARDPREVIEW)
end

function BangPaiInfoUI:EquipClick(sender)
    if sender == nil then
        return
    end
    local actData = self.m_curAct
    if actData == nil then
        return
    end
    local info = LRoleDataMgr.Faction.Info
    if info.totalActivity >= actData.activity and actData.state == 0 then
        LuaNetSendMsg:QueryGetFactionActivity(2, actData.activity)
    else
        if actData.rewards and #actData.rewards > 0 then
            local itemId = actData.rewards[1].id
            if itemId < AppDef.AwrdItem.AWRD_ITEM_COIN then
                Utils:ShowItemTips(itemId)
            else--if itemId == AppDef.AwrdItem.AWRD_ITEM_COIN then
                Utils:ShowGoldTips(itemId)
            end
        end
    end
end

function BangPaiInfoUI:SetActivity(act)
    --print("SetActivity act ===>", act, self.m_maxAct)
    act = act or 0
    local max = self._maxHuoyue
    local pro = act/max
    self.m_pLoadingBar:setPercent(100 - pro*100)
    self.m_pActivityNum:setString(string.format("%d/%d", act, max))
    if self.m_curAct then
        self.m_pNeedActivityNum:setString(tostring(self.m_curAct.activity or 0))
    end
end

-- function BangPaiInfoUI:FlushCurrent()
--     if self.m_activityList == nil or #self.m_activityList < 1 then
--         return
--     end

--     self.m_curAct = self.m_activityList[#self.m_activityList]
--     self.m_maxAct = self.m_curAct.activity
--     for i=1,#self.m_activityList do
--         local item = self.m_activityList[i]
--         if item and item.state == 0 then
--             self.m_maxAct = item.activity
--             self.m_curAct = item
--             break
--         end
--     end
-- --    dump(self.m_curAct, "self.m_curAct--->")
-- --    dump(LRoleDataMgr.Faction.Info.totalActivity, "LRoleDataMgr.Faction.Info.totalActivity--->")
--     self:SetActivity(LRoleDataMgr.Faction.Info.totalActivity)
--     self:SetOneReward(self.m_pEquip, self.m_curAct)
-- end

-- function BangPaiInfoUI:ReloadActivityData(datas)
--     if datas == nil or datas[2] == nil then
--         return
--     end
--     if datas[2].activityList == nil then
--         return
--     end
--     self.m_activityList = datas[2].activityList
--     self:FlushCurrent()
-- end

function BangPaiInfoUI:SetOneReward(pNode, pData)
    if pNode == nil or pData == nil or pData.rewards == nil or #pData.rewards == 0 then
        return
    end
    
    local info = LRoleDataMgr.Faction.Info

    local reward = pData.rewards[1]
    local itemId = reward.id
    local num = reward.num

    self.m_item = Utils:GetItemCellValue(pNode, 0, itemId, true, true, num, self.m_item, nil, true)
    self.m_item.m_pUILayer:setLocalZOrder(1)

    local pMark = pNode:getChildByName("Mark")
    pMark:setVisible(pData.state == 1)

    local pEffect = pNode:getChildByName("Effect")
    if info.totalActivity >= pData.activity and pData.state == 0 then
        if pEffect == nil then
            local size = pNode:getContentSize()
            pEffect = Utils:createAnimEffect(pNode, cc.p(size.width/2+2, size.height/2), "res2/fx/huoyuedujiangli")
            pEffect:setName("Effect")
            pEffect:setLocalZOrder(0)
        else
            pEffect:setVisible(true)
        end
    else
        if pEffect then
            pEffect:setVisible(false)
        end
    end
end

function BangPaiInfoUI:UpdateRedDot(data)

    self:DealUpdateRedDotState(data);
    -- if data.id == RedDotDef.ID.BPKeji then
    --     local _ = self._kejiRedDot and self._kejiRedDot:setVisible(data.isShow)
    -- end
end

return BangPaiInfoUI