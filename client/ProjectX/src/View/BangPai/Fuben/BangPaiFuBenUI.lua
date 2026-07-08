local BangPaiFuBenUI = LUIBase:New()
BangPaiFuBenUI.__index = BangPaiFuBenUI
BangPaiFuBenUI.IsHideInBattle = true
local BangPaiDef = require("View.BangPai.BangPaiDef")
local ShopDef = require("View.Shop.ShopDef")
local BPBuffs = require("ConfigData.guild_buff_dat")

local ListCtrl = require("View.BangPai.Fuben.BangPaiFuBenListCtrl");
local InfoCtrl = require("View.BangPai.Fuben.BangPaiFuBenInfoCtrl");
-- -----------------------------------
function BangPaiFuBenUI:New()
    local o = {}
    setmetatable(o, BangPaiFuBenUI)
    o:Init()
    return o
end

-- -----------------------------------
function BangPaiFuBenUI:Init()
    self.Script = "BangPai.Fuben.BangPaiFuBenUI"

    self._listCtrl = nil
    self._infoCtrl = nil

    self:RegistMsgs()
    self:InitViewSize()
    self:InitUIControl()
    self:setCloseCallback()
    self:ShowMoney();
    self:ShowTongbao();
    self:ShowTili();
    self:ShowChapterInfo();
    self:OnEnter();
    LuaNetSendMsg:QueryBangPaiBuff();
    -- LuaNetSendMsg:QueryFactionList()
    -- LuaNetSendMsg:QueryFactionInfo()
    -- LuaNetSendMsg:QueryFactionZoneInfo()
    -- LuaNetSendMsg:QueryFactionActivityList()
end

function BangPaiFuBenUI:OnEnter()
    local function initRedDotState(id)
        local isShow = Utils:GetRedDotState(id)
        self:DealUpdateRedDotState({id=id, isShow=isShow})
    end
    initRedDotState(RedDotDef.ID.BPSkillUpgrade);
end

function BangPaiFuBenUI:DealUpdateRedDotState(data)
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
    if data.id == RedDotDef.ID.BPSkillUpgrade then
        self.m_pUILayer:findChildByName("Panel/FubenBg/DescBg/Btn/Prompt"):setVisible(data.isShow);
        self.m_pUILayer:findChildByName("Panel/FubenBg/Btn_2/Prompt"):setVisible(data.isShow);
    end
    -- if ind > 0 then
    --     Utils:SendMsg(LUIFClassBgEvent.RedDotState, {ind, data.isShow})
    -- end
end


function BangPaiFuBenUI:ShowTili()
    local moneyLabel = self.m_pUILayer:findChildByName("Panel/GoldCheck/GoldIcon1/GoldNumBg/Num");
    local myTili = LRoleDataMgr.MyHeroInfo:GetDetailData():getTili()
    moneyLabel:setString(Utils:getTiliStr(myTili))
end

function BangPaiFuBenUI:ShowTongbao()
    local moneyLabel = self.m_pUILayer:findChildByName("Panel/GoldCheck/GoldIcon4/GoldNumBg/Num");
    local myGold = LRoleDataMgr.MyHeroInfo.DetailData:GetTongBao()
    moneyLabel:setString(myGold)
end

function BangPaiFuBenUI:ShowMoney()
    local moneyLabel = self.m_pUILayer:findChildByName("Panel/GoldCheck/GoldIcon3/GoldNumBg/Num");
    local myMoney = Utils:getGoldStr()
    moneyLabel:setString(myMoney)
end

-- -----------------------------------
function BangPaiFuBenUI:onExit()
    self:Destory()
    if self.m_schedule ~= nil then
        self.m_pTablePanel:stopAction(self.m_schedule)
        self.m_schedule = nil
    end
    self.m_pUILayer = nil
    -- self.m_bpUI = nil
    -- self.m_pMessageBoxUI = nil
    -- self.m_pBasicNews = nil
    -- --self.m_pDetailedNews = nil
    -- self.m_pHuoyueNode = nil
    -- self.m_pFubenNode = nil
    -- Utils:FreeTable(self.m_pGongGaoButtons)
    -- self.m_pGongGaoButtons = nil

    -- --table view相关
    -- self.m_pGridCell = nil
    -- self.m_pTablePanel = nil
    -- self.m_datas = nil
end

-- -----------------------------------
function BangPaiFuBenUI:RegistMsgs()
    self.msgIds = {
        LUIBangPaiEvent.GotCopyData,
        LUIBangPaiEvent.GotBuffData,
        LUIBangPaiEvent.UpdateCopyData,
        LUIBangPaiEvent.UpdateFightTimes,
        LUIBangPaiEvent.UpdateChapterData,
        LUIRedDotEvent.UpdateRedDotState,
        LUIBangPaiEvent.GotChapterData,
    }
    self:RegistSelf(self, self.msgIds)
end

-- -----------------------------------
function BangPaiFuBenUI:ProcessEvent(msg)
    if msg.msgId == LUIBangPaiEvent.GotCopyData then
        self:EnterFight(msg.value)
        self:ShowFightTimes();
    elseif msg.msgId == LUIBangPaiEvent.GotChapterData then
        self:ShowChapterInfo();
    elseif msg.msgId == LUIBangPaiEvent.GotBuffData then
        self:OnGetBuffData()
        self:ShowFightTimes();
    elseif msg.msgId == LUIBangPaiEvent.UpdateCopyData then
        self:OnUpdateBuffData(msg.value)
        self:ShowFightTimes();
    elseif msg.msgId == LUIBangPaiEvent.UpdateChapterData then
        self:OnUpdateChapterData(msg.value)
    elseif msg.msgId == LUIBangPaiEvent.UpdateFightTimes then
        self:ShowFightTimes()
    elseif msg.msgId == LUIRedDotEvent.UpdateRedDotState then
        self:DealUpdateRedDotState(msg.value)
    end
    -- elseif msg.msgId == LUIBangPaiEvent.UpdateGongGao then
    --     self:UpdateGongGao()
    -- elseif msg.msgId == LUIBangPaiEvent.UpdateNameShow then
    --     self:updateBPNameVisible(msg.value)
    -- elseif msg.msgId == LUIBangPaiEvent.UpdateManorInfo then
    --     self:setDetailUI()
    -- elseif msg.msgId == LUIBangPaiEvent.ReloadFactionActivityList then
    --     self:ReloadActivityData(msg.value)
    -- elseif msg.msgId == LUIBangPaiEvent.FlushFactionActivity then
    --     self:SetActivity(LRoleDataMgr.Faction.Info.totalActivity)
    -- elseif msg.msgId == LUIRedDotEvent.UpdateRedDotState then
    --     self:UpdateRedDot(msg.value)
    -- elseif msg.msgId == LUILogicEvent.changeBpNameSuc then
    --     self:setBpName()
    -- end
end

function BangPaiFuBenUI:OnUpdateChapterData(chId)
    if self._listCtrl ~= nil then
        self._listCtrl:UpdateChapterData(chId);
    end
end

function BangPaiFuBenUI:ShowChapterInfo()
    local curChapter = LRoleDataMgr.Faction:GetCurChapter();
    if curChapter == nil then
        LuaNetSendMsg:QueryBangPaiFubenList()
        return
    end
    if self._listCtrl == nil then
        self._listCtrl = ListCtrl:New(self, self.m_pUILayer:getChildByName("ScrollView"))
    end
    if self._infoCtrl == nil then
        self._infoCtrl = InfoCtrl:New(self, self.m_pUILayer:getChildByName("Guanqia"))
        self._infoCtrl:setVisible(false)
    end
    local chapterConfig = JsonConfig.m_FuBenMapConfig.getDefByID(curChapter.id)
    local nameLabel = self.m_pUILayer:findChildByName("Panel/FubenBg/Tips/MyRanking");
    nameLabel:setString(chapterConfig.Name);

    self:ShowChapterProgress();
    self:ShowFightTimes();
end

function BangPaiFuBenUI:ShowChapterProgress()
    local curChapter = LRoleDataMgr.Faction:GetCurChapter();
    local progress = curChapter:GetProgress();
    local str = string.format(GUITips.SI_BP_TIP57,progress);
    local label = self.m_pUILayer:findChildByName("Panel/FubenBg/Tips/MyRanking/Text");
    label:setString(str);
end

function BangPaiFuBenUI:OnUpdateBuffData(copyData)
    if self._infoCtrl ~= nil then
        self._infoCtrl:UpdateCopy(copyData);
    end

    if self._listCtrl ~= nil then
        self._listCtrl:UpdateCopy(copyData);
    end
    self:ShowChapterInfo();
end

function BangPaiFuBenUI:OnGetBuffData()
    local skills = LRoleDataMgr.Faction.buffList;
    local curItemPanel;
    local listView = self.m_pUILayer:findChildByName("Panel/FubenBg/DescBg/Bg/ListView");
    listView:removeAllItems();
    for i = 1, #skills do
        if i % 2 == 1 then
            curItemPanel = self._baseSkillPanel:clone();
            curItemPanel:setVisible(true);
            listView:pushBackCustomItem(curItemPanel);
        end
        local ind = (i - 1) % 2 + 1;
        local attrLabel = curItemPanel:getChildByName("Name_" .. ind);
        attrLabel:setVisible(true)

        
        local baseInfo = BPBuffs[skills[i].buffId]
        local attrData = LDataConstMgr:GetAttrConfigData(baseInfo.buff[1]);
        attrLabel:setString(attrData.attrName .. ":");
        local valueLabel = attrLabel:getChildByName("Text");
        valueLabel:setString(skills[i].level * baseInfo.buff[2]);
    end
end

function BangPaiFuBenUI:EnterFight(copyData)
    if self._infoCtrl == nil or self._infoCtrl.m_pUILayer:isVisible() == false then
        return
    end
    self._infoCtrl:EnterFight(copyData)
end

function BangPaiFuBenUI:setCloseCallback()
    local function onNodeEvent(event)
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
end

function BangPaiFuBenUI:ShowFightTimes()
    local label = self.m_pUILayer:findChildByName("Panel/FubenBg/TimesBg/Icon/Num");
    label:setString(LRoleDataMgr.Faction.canFightNum)
end

-- -----------------------------------
function BangPaiFuBenUI:InitViewSize()
    self:CreateUINode("csd/bangpai/GangsFubenLayer.csb");
end

-- -----------------------------------
function BangPaiFuBenUI:InitUIControl()
print("------------------------------------------------------")
    local closeBtn = self.m_pUILayer:findChildByName("Panel/Title/CloseBtn");
    closeBtn:addClickEventListener(function(sender)
        self:onCloseClicked()
    end)

    local buffBtn = self.m_pUILayer:findChildByName("Panel/FubenBg/DescBg/Btn");
    buffBtn:addClickEventListener(function(sender)
        self:onBuffClicked();
    end)

    local btn = self.m_pUILayer:findChildByName("Panel/GoldCheck/GoldIcon1/AddBtn");
    btn:addClickEventListener(function(sender)
        self:onTiliClicked();
    end)

    btn = self.m_pUILayer:findChildByName("Panel/GoldCheck/GoldIcon3/AddBtn");
    btn:addClickEventListener(function(sender)
        self:onMoneyClicked();
    end)

    btn = self.m_pUILayer:findChildByName("Panel/GoldCheck/GoldIcon4/AddBtn");
    btn:setEnabled(false)
    -- btn:addClickEventListener(function(sender)
    --     self:onYuanbaoClicked();
    -- end)

    local shopBtn = self.m_pUILayer:findChildByName("Panel/FubenBg/Btn_1");
    shopBtn:addClickEventListener(function(sender)
        Utils:OpenFunction(AppDef.EModuleID.EMID_SHOP_BANGPAI)
    end)
    local skillBtn = self.m_pUILayer:findChildByName("Panel/FubenBg/Btn_2");
    skillBtn:addClickEventListener(function(sender)
        self:onBuffClicked();
    end)
    skillBtn:setVisible(true)

    self._titleNode = self.m_pUILayer:getChildByName("Panel");
    

    self._baseSkillPanel = self.m_pUILayer:findChildByName("Panel/FubenBg/DescBg/Bg/Panel");
    self._baseSkillPanel:getChildByName("Name_1"):setVisible(false);
    self._baseSkillPanel:getChildByName("Name_2"):setVisible(false);
    self._baseSkillPanel:setVisible(false);

	local goldcheck = self._titleNode:getChildByName("GoldCheck")
	goldcheck:setTouchEnabled(false)
	
	local helpBtn = self._titleNode:getChildByName("Title"):getChildByName("TitleName"):getChildByName("btn_help")
    helpBtn:addClickEventListener(function ( sender )
        self:HelpClicked()
    end)
end

function BangPaiFuBenUI:HelpClicked(sender) 
    Utils:ShowDialogOKCancel(GUITips.BangPaiFuBen)
end

function BangPaiFuBenUI:onTiliClicked()
    print("onTiliClicked")
    Utils:OpenUseUI(500,1)
end

function BangPaiFuBenUI:onMoneyClicked()
    print("onMoneyClicked")
    Utils:OpenFunction(AppDef.EModuleID.EMID_SCCHANGYONG)
end

function BangPaiFuBenUI:onYuanbaoClicked()
    print("onYuanbaoClicked")
end

function BangPaiFuBenUI:onBuffClicked()
    Utils:OpenFunction(AppDef.EModuleID.EMID_BPSKILL);
end

function BangPaiFuBenUI:EnterFuben(fid)

    self._listCtrl:setVisible(false)
    self._infoCtrl:setVisible(true)
    local myData = LRoleDataMgr:GetBPChapterData(fid);
    self._infoCtrl:SetData(myData)
end

function BangPaiFuBenUI:onCloseClicked()
    if self._infoCtrl:isVisible() then
        self._listCtrl:setVisible(true)
        self._infoCtrl:setVisible(false)
        return
    end
    self._listCtrl:setVisible(false)
    self._infoCtrl:setVisible(true)
    self:RemoveUI()
end

function BangPaiFuBenUI:initGongGaoPanel()
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

function BangPaiFuBenUI:helpButtonCallback()
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

function BangPaiFuBenUI:setBPNameVisible(bShow)
    local isShow = Utils:three(LRoleDataMgr.Faction.Info.isShowBPName, 0, 1)
    LuaNetSendMsg:QueryIsShowBPName(isShow)
    LuaNetSendMsg:DealHeroTitleShow(0, isShow)
end

function BangPaiFuBenUI:updateBPNameVisible( bShow )
    bShow = Utils:ToBool(bShow)
    self.m_pGongGaoButtons[1]:setVisible(bShow)
    self.m_pGongGaoButtons[2]:setVisible(not bShow)
end

function BangPaiFuBenUI:showGongGaoPanel(bShow)
    if self.m_pMessageBoxUI ~= nil then
        self.m_pMessageBoxUI:setVisible(bShow)
    end
end

function BangPaiFuBenUI:setBasicUI()
    local bangPai = LRoleDataMgr.Faction.Info

    if bangPai.id == 0 or self.m_pBasicNews == nil then
        return
    end

    local pTitleBg = self.m_pBasicNews:getChildByName("TitleBg")
    local pTitleName = pTitleBg:getChildByName("TitleName")
    self._pTitleName = pTitleName
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

function BangPaiFuBenUI:setBpName( ... )
    -- body
    local bangPai = LRoleDataMgr.Faction.Info
    self._pTitleName:setString(string.format("%sLV%d", bangPai.name, bangPai.level))
end

function BangPaiFuBenUI:setDetailUI()
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

function BangPaiFuBenUI:InitLogList()
    self.m_pTablePanel:removeAllItems()
    for i=1,#self.m_datas do
        local pCell = self.m_pGridCell:clone()
        pCell:setVisible(true)
        self:updateItem(pCell, self.m_datas[i])
        self.m_pTablePanel:pushBackCustomItem(pCell)
    end
end

function BangPaiFuBenUI:updateItem(cell, info)
    local pText = cell:getChildByName("Text")
    pText:setString(info.treeName)

    if bit.band(info.state, 0x01) == 0x01 then
        self:setItemTime(cell, nil, GUITips.RSI_FACTION_MSG11)
    else
        self:setItemTime(cell, info.leftTimes)
    end
end

function BangPaiFuBenUI:setItemTime(cell, leftTimes, str)
    local pText_0 = cell:getChildByName("Text_0")
    if str ~= nil then
        pText_0:setString(str)
    else
        pText_0:setString(self:getTimeString(leftTimes))
    end
end

function BangPaiFuBenUI:UpdateGongGao()
    local pTextField = self.m_pBasicNews:getChildByName("TextField")
    pTextField:setTouchEnabled(false)
    pTextField:setString(LRoleDataMgr.Faction.Info.gongGao)

    local pMessageBoxUI = self.m_pMessageBoxUI:getChildByName("MessageBoxUI")
    local pDesBg1 = pMessageBoxUI:getChildByName("DesBg1")
    local pTextField = pDesBg1:getChildByName("TextField")
    pTextField:setString(LRoleDataMgr.Faction.Info.gongGao)
end

function BangPaiFuBenUI:upButtonCallback()
end

function BangPaiFuBenUI:getTimeString(leftTimes)
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

function BangPaiFuBenUI:updateTime()
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

function BangPaiFuBenUI:flushCellTimer()
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

function BangPaiFuBenUI:JuanXian()
    -- LuaNetSendMsg:QueryFactionGodTreeDetail(LRoleDataMgr.Faction.Info.id)
    if LRoleDataMgr.m_bIsCrossServer then
        Utils:ShowScrollTips(GUITips.RSI_FACTION_MSG119)
        return
    end
    LuaNetSendMsg:QueryFactionJuanXianMsg()
end

function BangPaiFuBenUI:ShiJian()
    Utils:InitUI("BangPai.BangPaiEventPopup", AppDef.UIType.SecondClassLayer)
end

function BangPaiFuBenUI:LingDi()
    if LRoleDataMgr.m_bIsCrossServer then
        Utils:ShowScrollTips(GUITips.RSI_CS_TIP2)
        return
    end
    LuaNetSendMsg:QueryBangPaiEnterZone(LRoleDataMgr.Faction.Info.id)
end

function BangPaiFuBenUI:InitSetPanel()
    local pBg = self.m_pSetLevel:getChildByName("bg")
    local pImageBg = pBg:getChildByName("Image_Bg")
    
    local config = LDataConstMgr:GetFunctionLevelData(AppDef.EModuleID.EMID_BANGPAI)
    local limitValue = 32
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
        LuaNetSendMsg:QuerySetBPApply(level)
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

function BangPaiFuBenUI:initActivity()
    if self.m_pHuoyueNode == nil then
        return
    end
    local pLoadingBg = self.m_pHuoyueNode:getChildByName("LoadingBg")
    self.m_pLoadingBar = pLoadingBg:getChildByName("LoadingBar")
    self.m_pEquip = pLoadingBg:getChildByName("Equip")
    self.m_pEquip:setTouchEnabled(true)
    self.m_pEquip:addClickEventListener(handler(self, self.EquipClick))

    self.m_pActivityNum = pLoadingBg:getChildByName("ValueBg"):getChildByName("Value")

    self.m_pNeedActivityNum = pLoadingBg:getChildByName("Bg"):getChildByName("Value")
    self.m_pNeedActivityNum:setString("0")

    local btn = pLoadingBg:getChildByName("HelpBtn")
    local function helpBtn( sender )
        -- body
        local function OnOk()
        end
        Utils:ShowDialogOKCancel(GUITips.RSI_BP_DES_TIPS1, OnOk)
    end
    btn:addClickEventListener(helpBtn)

end

function BangPaiFuBenUI:EquipClick(sender)
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

function BangPaiFuBenUI:SetActivity(act)
    --print("SetActivity act ===>", act, self.m_maxAct)
    if self.m_maxAct == nil then
        return
    end
    act = act or 0
    local max = self.m_maxAct
    local pro = act/max
    self.m_pLoadingBar:setPercent(pro*100)
    self.m_pActivityNum:setString(string.format("%d/%d", act, max))
    if self.m_curAct then
        self.m_pNeedActivityNum:setString(tostring(self.m_curAct.activity or 0))
    end
end

function BangPaiFuBenUI:FlushCurrent()
    if self.m_activityList == nil or #self.m_activityList < 1 then
        return
    end

    self.m_curAct = self.m_activityList[#self.m_activityList]
    self.m_maxAct = self.m_curAct.activity
    for i=1,#self.m_activityList do
        local item = self.m_activityList[i]
        if item and item.state == 0 then
            self.m_maxAct = item.activity
            self.m_curAct = item
            break
        end
    end
--    dump(self.m_curAct, "self.m_curAct--->")
--    dump(LRoleDataMgr.Faction.Info.totalActivity, "LRoleDataMgr.Faction.Info.totalActivity--->")
    self:SetActivity(LRoleDataMgr.Faction.Info.totalActivity)
    self:SetOneReward(self.m_pEquip, self.m_curAct)
end

function BangPaiFuBenUI:ReloadActivityData(datas)
    if datas == nil or datas[2] == nil then
        return
    end
    if datas[2].activityList == nil then
        return
    end
    self.m_activityList = datas[2].activityList
    self:FlushCurrent()
end

function BangPaiFuBenUI:SetOneReward(pNode, pData)
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

function BangPaiFuBenUI:UpdateRedDot(data)
    if data.id == RedDotDef.ID.BPKeji then
        local _ = self._kejiRedDot and self._kejiRedDot:setVisible(data.isShow)
    end
end

return BangPaiFuBenUI