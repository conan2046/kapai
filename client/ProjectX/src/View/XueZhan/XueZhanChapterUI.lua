local XueZhanChapterUI = LUIBase:New()
XueZhanChapterUI.__index = XueZhanChapterUI
XueZhanChapterUI.IsHideInBattle = true
function XueZhanChapterUI:New()
    local o = LUIBase:New()
    setmetatable(o,XueZhanChapterUI) 
    o:Init()
    return o
end

--[[
注册消息
]]
function XueZhanChapterUI:RegistMsgs()
    self.msgIds = 
    {
         LUIXueZhanEvent.UpdateChapterInfo,
         LUIRoleDataChangeEvent.XinXiuJingHuaChanged,--血战货币更新
         LUIXueZhanEvent.RefreshChapterBuffUI,
         LUIXueZhanEvent.RefreshChapterSweepUI,
         LUIRedDotEvent.UpdateRedDotState,
         LUIXueZhanEvent.RefreshBtnState,
    }
    self:RegistSelf(self,self.msgIds)
end

function XueZhanChapterUI:ProcessEvent(msg)
    if msg.msgId == LUIXueZhanEvent.UpdateChapterInfo then
        self:ShowChapter()
        self:ShowStar()
        self:ShowUnLockTips()
        self:CheckSaoDangShow()
    elseif msg.msgId == LUIRoleDataChangeEvent.XinXiuJingHuaChanged then
        self:ShowMoney()
    elseif msg.msgId == LUIXueZhanEvent.RefreshChapterBuffUI then
        self:ShowStar()
        self:ShowAttrInfo()
    elseif msg.msgId == LUIXueZhanEvent.RefreshChapterSweepUI then
        self:ShowSweep()
    elseif msg.msgId == LUIRedDotEvent.UpdateRedDotState then
        if msg.value ~= nil and msg.value.id == RedDotDef.ID.ShopWanFaXueZhan then
            self:UpdateRedDot()
        end
    elseif msg.msgId == LUIXueZhanEvent.RefreshBtnState then
        self:ShowItemNum()
    end
end


function XueZhanChapterUI:Init()
    self.Script = "XueZhan.XueZhanChapterUI"
    self.m_pUILayer = cc.CSLoader:createNode("csd/xuezhan/XuezhanLevel.csb")
    local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
    self:RegistMsgs()
    self:InitData()
    self:UpdateUI()

    Utils:SendMsg(LUIFClassBgEvent.SetTitle, GUITips.UI_Title_XueZhan)
    Utils:SendMsg(LUIRoleDataChangeEvent.BGVisible, false)
    Utils:SendMsg(LUIFClassBgEvent.SetCloseCallback,handler(self,XueZhanChapterUI.CloseUI))

    Utils:QueryXueCurRank()
    self:UpdateRedDot()
    
    if self:CheckRevive() then
        return
    end
    local data = LActivityManager:GetXueZhanData()
    --dump(data.m_sweepInfo)
    --print("state,buff num",data.m_state,#data.m_sweepInfo.bufs)
    if data.m_state == 7 then
        if data.m_sweepInfo.bufs ~= nil and #data.m_sweepInfo.bufs > 0 then
            Utils:InitUI("XueZhan.XueZhanAttrSelectUI",AppDef.UIType.PopWindow,14)
        end
    else
        Utils:OpenXueZhanReward()
    end
end

--重置or复活
function XueZhanChapterUI:CheckRevive()
    local data = LActivityManager:GetXueZhanData()
    if data.m_state == 2 then
        if data.m_reviveCnt > 0 then
            LuaNetSendMsg:SendXueZhanReviveReq(1)
        elseif data.m_cnt > 0 then
            LuaNetSendMsg:QueryXueZhanInfo(6)
            return true
        end
    end
    return false
end

function XueZhanChapterUI:InitData()
    local panel = self.m_pUILayer:getChildByName("Panel_xuezhan")
    panel:setTouchEnabled(false)
    self.m_sweepBtn = panel:getChildByName("saodang")
    self.m_sweepBtn:addClickEventListener(handler(self, XueZhanChapterUI.SweepCallBack))

    --self.m_autoSelect = false--自动选择星星消耗多的属性（扫荡用）
    self.m_checkBox = self.m_sweepBtn:getChildByName("CheckBox")
    self.m_checkBox:addEventListener(handler(self, XueZhanChapterUI.CheckBoxCallback))
    self.m_checkBox:setSelected(false)

    self.m_checkBox1 = self.m_sweepBtn:getChildByName("CheckBox_1")
    self.m_checkBox1:addEventListener(handler(self, XueZhanChapterUI.CheckBox1Callback))
    self.m_checkBox1:setSelected(false)

    self.m_attrValueLabel = {}
    local attrPanel = panel:getChildByName("Info")
    self.m_totalStarLabel = attrPanel:getChildByName("Star1"):getChildByName("Num")
    self.m_curStarLabel = attrPanel:getChildByName("Star2"):getChildByName("Num")
    self.m_maxStarLabel = attrPanel:getChildByName("Star3"):getChildByName("Num")
    local jichuPanel = attrPanel:getChildByName("jichu")
    self.m_types = {10,11,12,13,15,16,17,18,19,22}
    for i= 1,#self.m_types do
        local typeLabel = jichuPanel:getChildByName("Attribute_"..i)
        if typeLabel ~= nil then
            self.m_attrValueLabel[self.m_types[i]] = typeLabel:getChildByName("Value")
        end
    end

    self.m_levelLabels = {}
    local levelPanel = panel:getChildByName("Slider_Bg")
    for i=1,5 do
        local levelImg = levelPanel:getChildByName("level"..i)
        self.m_levelLabels[i] = levelImg:getChildByName("Text")
    end
    self.m_chapterLabel = levelPanel:getChildByName("chapter")
    self.m_loadingBar = levelPanel:getChildByName("LoadingBar")
    self.m_fightImg = levelPanel:getChildByName("fight")
    self.m_bufImg = levelPanel:getChildByName("buff")
    self.m_bufImgPosX = self.m_bufImg:getPositionX()
    --self.m_conditionNode = levelPanel:getChildByName("condition")
    --self.m_conditionLabel = self.m_conditionNode:getChildByName("Text")
    local boxBtn = levelPanel:getChildByName("Button_Reward")
    boxBtn:addClickEventListener(function (sender)
        --宝箱
        LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "XueZhan.XueZhanGiftBoxUI",AppDef.UIType.PopWindow)
        self:SendMsg(LGameMsg.m_initUIMsg)
    end)

    self.m_bossNameLabels = {}
    self.m_bossStarLabels = {}
    self.m_bossParentNodes = {}
    self.m_bossModelNodes = {}
    --挑战
    local bossPanel = panel:getChildByName("ItemCell")
    for i=1,3 do
        local bossItem = bossPanel:getChildByName("Item"..i)
        self.m_bossNameLabels[i] = bossItem:getChildByName("Name")
        self.m_bossStarLabels[i] = bossItem:getChildByName("Star"):getChildByName("Num")
        self.m_bossParentNodes[i] = bossItem:getChildByName("Node")
        local btn = bossItem:getChildByName("Button")
        btn.userObject = i
        btn:addClickEventListener(handler(self, XueZhanChapterUI.FightCallBack))
    end

    local rightBottom = panel:getChildByName("youxia")
    local shopBtn = rightBottom:getChildByName("btn_shangdian")
    local rankBtn = rightBottom:getChildByName("btn_paihangbang")
    self.m_shopPrompt = shopBtn:getChildByName("Prompt")
    rankBtn:getChildByName("Prompt"):setVisible(false)
    shopBtn:addClickEventListener(function (sender)
        --Utils:InitUI("Shop.WanFaShopMainUI", AppDef.UIType.PopFirstClassLayer, 1)
        Utils:OpenFunction(AppDef.EModuleID.EMID_SHOP_XUEZHAN)
    end)
    rankBtn:addClickEventListener(function (sender)
        Utils:OpenRankUI(AppDef.EModuleID.EMID_RANK_XueZhan)
    end)

    self.m_itemNumImg = shopBtn:getChildByName("Icon")
    local str = "res/UI/Icon/ui_huobi_icon/huobi_"..LRoleDataMgr.GetItemPicId(AppDef.SpecialItemId.StarExp)..".png"
    Utils:SafeLoadTexture(self.m_itemNumImg,str,ccui.TextureResType.plistType)
    self.m_itemNumLabel = self.m_itemNumImg:getChildByName("Text")
    self.m_forecastRankLabel1 = rankBtn:getChildByName("base"):getChildByName("Text")

    self.m_setBtn = panel:getChildByName("set")
    self.m_setBtn:addClickEventListener(function (sender)
        Utils:InitUI("XueZhan.XueZhanSetUI",AppDef.UIType.PopWindow)
    end)

    panel:getChildByName("ItemIcon_bg"):setVisible(false)
    self.m_unLockImg = panel:getChildByName("ItemIcon")
    self.m_unLockImg:setVisible(false)
    self.m_unLockLabel = self.m_unLockImg:getChildByName("Text")
    self.m_unLockNumLabel = self.m_unLockImg:getChildByName("num")
end

function XueZhanChapterUI:CheckBoxCallback(sender,eventType)
    if eventType == ccui.CheckBoxEventType.selected then
        LuaNetSendMsg:SendXueZhanSweepSetting(0)
        self.m_checkBox1:setSelected(false)
    elseif eventType == ccui.CheckBoxEventType.unselected then
        LuaNetSendMsg:SendXueZhanSweepSetting(0xffffffff)
    end
end

function XueZhanChapterUI:CheckBox1Callback(sender,eventType)
    if eventType == ccui.CheckBoxEventType.selected then
        local sType = LUserConfigMgr:GetXueZhanSType()
        --print("LUserConfigMgr:GetXueZhanSType",sType)
        if sType == 0 then
            LUserConfigMgr:SetXueZhanSType(0x400)
            LuaNetSendMsg:SendXueZhanSweepSetting(0x400)
            Utils:InitUI("XueZhan.XueZhanSetUI",AppDef.UIType.PopWindow)
        else
            LuaNetSendMsg:SendXueZhanSweepSetting(sType)
        end
        self.m_checkBox:setSelected(false)
    elseif eventType == ccui.CheckBoxEventType.unselected then
        LuaNetSendMsg:SendXueZhanSweepSetting(0xffffffff)
    end
end

function XueZhanChapterUI:SweepCallBack(sender)
    local data = LActivityManager:GetXueZhanData()
    if data.m_sweepLevelId +1 <= data.m_levelId then
        Utils:ShowScrollTips(GUITips.RSI_XUEZHAN_TIP25)
        return
    end
    LuaNetSendMsg:QueryXueZhanInfo(9)
end

function XueZhanChapterUI:FightCallBack(sender)
    --挑战
    local idx = sender.userObject
    --print("XueZhanChapterUI:FightCallBack",idx)
    if idx == nil or idx < 1 or idx > 3 then
        return
    end
    local data = LActivityManager:GetXueZhanData()
    --print("XueZhanChapterUI:FightCallBack arraysId",data.m_enemyZhenId[idx])
    if data.m_enemyZhenId[idx] == 0 then
        return
    end
    local arrayCfg = JsonConfig.m_bloodArrays.getDefByID(data.m_enemyZhenId[idx])
    if arrayCfg == nil then
        return
    end
    data.m_difficulty = idx

    --阵容选择界面
    local value = {}
    value.type = AppDef.FormationType.XueZhan
    value.enemyZhenfaId = arrayCfg.zhenfa
    value.enemyInfos = {}
    local max = AppDef.Formation.MaxFightNum
    for i = 1,max do
        value.enemyInfos[i] = arrayCfg["index"..i]
    end

    local fun = function()
        LuaNetSendMsg:SendXueZhanFightReq(LActivityManager:GetXueZhanData().m_difficulty or 1)
    end
    value.callback = fun
    value.hideLevel=true
    LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "Common.PetFormationUI",AppDef.UIType.FirstClassLayer,value)
    self:SendMsg(LGameMsg.m_initUIMsg)
end

function XueZhanChapterUI:UpdateUI()
    self:ShowAttrInfo()
    self:ShowItemNum()
    self:ShowChapter()
    self:ShowStar()
    self:ShowUnLockTips()
    self:CheckSaoDangShow()
end

function XueZhanChapterUI:CheckSaoDangShow()
    self.m_setBtn:setVisible(false)
    self.m_sweepBtn:setVisible(false)
    local config = LDataConstMgr:GetFunctionLevelData(AppDef.EModuleID.EMID_KAPAI_XZ_SAODANG)
    if config == nil or #config.open_condition == 0 then
        return
    end
    local value = config.open_condition[1]
    local sign = false
    local cType = value[1] or 0
    local cVal = value[2] or 0
    --print("CheckSaoDangShow",cType,cVal)
    if cType == 1 then
        if LRoleDataMgr.MyHeroInfo.level >= cVal then
            sign = true
        end
    elseif cType == 3 then
        local data = LActivityManager:GetXueZhanData()
        --print("m_firstLevelId",data.m_firstLevelId)
        if data.m_firstLevelId >= cVal then
            sign = true
        end
    end
    if sign then
        self.m_setBtn:setVisible(true)
        self.m_sweepBtn:setVisible(true)
        self:ShowSweep()
    end
end

function XueZhanChapterUI:ShowSweep()
    self.m_checkBox:setSelected(false)
    self.m_checkBox1:setSelected(false)
    local data = LActivityManager:GetXueZhanData()
    if data.m_sweepInfo == nil or data.m_sweepInfo.sType == nil then
        return
    end
    --print("XueZhanChapterUI:ShowSweep",data.m_sweepInfo.sType)
    if data.m_sweepInfo.sType == 0 then
        self.m_checkBox:setSelected(true)
    elseif data.m_sweepInfo.sType ~= 0xffffffff then
        self.m_checkBox1:setSelected(true)
    else
        if LUserConfigMgr:GetXueZhanSType() == 0 then
            LUserConfigMgr:SetXueZhanSType(data.m_sweepInfo.sType)
        end
    end
end

function XueZhanChapterUI:ClearAttrShow()
    for i=1,#self.m_types do
        local label = self.m_attrValueLabel[self.m_types[i]] 
        if label ~= nil then
            label:setString("+0%")
        end
    end
end

function XueZhanChapterUI:ShowAttrInfo()
    self:ClearAttrShow()
    local data = LActivityManager:GetXueZhanData()
    if data.m_attrs == nil then
        return
    end
    for i=1,#data.m_attrs do
        local attrtype = data.m_attrs[i].type
        --print("XueZhanChapterUI:ShowAttrInfo",i,attrtype)
        local attrVal = data.m_attrs[i].val or 0
        local label = self.m_attrValueLabel[attrtype] 
        if label ~= nil then
            local str = "+"..attrVal
            if attrtype > AppDef.EAttrType.EAT_RESISIT_CRIT and attrVal > 0 then
                local val = string.format("%.1f", attrVal/100)
                str = "+"..val.."%"
            end
            label:setString(str)
        end
    end
end

function XueZhanChapterUI:ShowStar()
    local data = LActivityManager:GetXueZhanData()
    self.m_totalStarLabel:setString(""..(data.m_totalStar or 0))
    self.m_curStarLabel:setString(""..(data.m_curStar or 0))
    self.m_maxStarLabel:setString(""..(data.m_maxStar or 0))
end

function XueZhanChapterUI:ShowChapter()
    local data = LActivityManager:GetXueZhanData()
    if data.m_chapterId == 0 then
        data.m_chapterId = 1
    end
    if data.m_levelId == 0 then
        data.m_levelId = 1
    end
    local idx = (data.m_levelId-1)%5
    self.m_chapterLabel:setString(string.format(GUITips.RSI_XUEZHAN_TIP7,GUINumUper[data.m_chapterId]))
    self.m_loadingBar:setPercent(idx*25)
    self.m_fightImg:setPosition(cc.p(150*idx, self.m_fightImg:getPositionY()))
    --self.m_conditionNode:setPosition(cc.p(150*idx, self.m_conditionNode:getPositionY()))
    local bufNumber = 0
    local configData = JsonConfig.m_config.getDefByID(3)
    if configData ~= nil then
        bufNumber = tonumber(configData.value)
    end
    self.m_oneLevel = math.floor((data.m_levelId-1)/5)*5--data.m_levelId - data.m_levelId%5
    local sign = 0
    for i=1,5 do
        local level = self.m_oneLevel+i
        local tmp = (level-1)%100+1
        self.m_levelLabels[i]:setString(string.format(GUITips.RSI_XUEZHAN_TIP11,level))
        if bufNumber > 0 and tmp%bufNumber == 0 then
            local ind = (level-1)%5 
            if sign > 0 then
                if self.m_bufImg1 == nil then
                    self.m_bufImg1 = self.m_bufImg:clone()
                    self.m_bufImg:getParent():addChild(self.m_bufImg1)
                end
                self.m_bufImg1:setVisible(true)
                self.m_bufImg1:setPosition(cc.p(self.m_bufImgPosX +150*ind, self.m_bufImg:getPositionY()))
            else
                self.m_bufImg:setPosition(cc.p(self.m_bufImgPosX +150*ind, self.m_bufImg:getPositionY()))
            end
            sign = sign+1
        end
    end
    if sign == 1 and self.m_bufImg1 ~= nil then
        self.m_bufImg1:setVisible(false)
    end
    local cfg = JsonConfig.m_bloodBattle.getDefByID(data.m_levelId)
    if cfg == nil then
        return
    end
    local str = ""
    for i=1,#cfg.condition do
        local value = cfg.condition[i]
        local tmp = string.format(GUITips["RSI_XUEZHAN_TIPC"..value[1]],value[2])
        str = str..tmp..","
    end
    str = string.sub(str,1,-2)
    str = str..GUITips.RSI_XUEZHAN_TIP8
    --print("m_conditionLabel",str)
    --self.m_conditionLabel:setString(str)
    --self.m_conditionLabel:setTextAreaSize(cc.size(self.m_conditionLabel:getAutoRenderSize().width+30, self.m_conditionLabel:getContentSize().height))
    --self.m_conditionLabel:setPosition(cc.p(self.m_conditionLabel:getContentSize().width/2,self.m_conditionLabel:getPositionY()))
    --local conParent = self.m_conditionLabel:getParent()
    --conParent:setContentSize(cc.size(self.m_conditionLabel:getContentSize().width, conParent:getContentSize().height))

    --boss
    local stars = {}
    configData = JsonConfig.m_config.getDefByID(2)
    if configData ~= nil then
        stars = json.decode(configData.value)
    end
    for i=1,3 do
        local name = ""
        local pic = ""
        local arrayCfg = JsonConfig.m_bloodArrays.getDefByID(data.m_enemyZhenId[i])
        if arrayCfg ~= nil then
            local monsterCfg = LDataConstMgr:GetMonsterData(arrayCfg.show) 
            if monsterCfg ~= nil then
                name = monsterCfg.name
                pic = ""..monsterCfg.pic
            end
        end
        local star = 0   
        if stars[i] ~= nil then
            star = stars[i]
        end
        self.m_bossNameLabels[i]:setString(name)
        self.m_bossStarLabels[i]:setString("x"..star)
        if #pic > 0 then
            self:ShowModel(i,self.m_bossParentNodes[i],pic)
        end
    end
end

--[[
显示模型
]]
function XueZhanChapterUI:ShowModel(idx,parent,pic)
    if idx == nil or idx == 0 or parent == nil or pic == nil or pic == 0 then
        return
    end
    if self.m_bossModelNodes[idx] == nil then
        self.m_bossModelNodes[idx] = ModelAniNode:create(AppDef.CEnum.ModelAniType.MonsterBig, 0)
        parent:addChild(self.m_bossModelNodes[idx])
        parent:setScale(0.46)
    end
    self.m_bossModelNodes[idx]:InitAni(AppDef.CEnum.ModelAniType.MonsterBig, pic)
    self.m_bossModelNodes[idx]:PlayStand(0)
end

function XueZhanChapterUI:ShowItemNum()
    local data =  LActivityManager:GetXueZhanData()
    local str = ""
    if data.m_forecastRankId > 0 then
        str = string.format(GUITips.RSI_XUEZHAN_TIP3,data.m_forecastRankId)
    end
    self.m_forecastRankLabel1:setString(str)
    self:ShowMoney()
end

function XueZhanChapterUI:ShowMoney()
    local myJingHua = LRoleDataMgr.MyHeroInfo:GetDetailData():GetXinXiuJingHua() or 0
    self.m_itemNumLabel:setString(""..myJingHua)--代币道具数量
end

--
function XueZhanChapterUI:ShowUnLockTips()
    self.m_unLockImg:setVisible(false)
    local data =  LActivityManager:GetXueZhanData()
    --print("m_nextLevelId",data.m_nextLevelId)
    local info = JsonConfig.GetXueZhanRewardInfo(data.m_firstLevelId or 0)
    --dump(info,"XueZhanChapterUI:ShowUnLockTips info=>")
    if info == nil then
        return
    end
    --self.m_unLockImg:setVisible(true)
    self.m_unLockLabel:setString(GUITips.RSI_XUEZHAN_TIP16)
    self.m_unLockNumLabel:setString(string.format(GUITips.RSI_XUEZHAN_TIP17,info.level))
    self.m_item = Utils:GetItemCellValue(self.m_unLockImg, 0, info.id, true, true, info.num, self.m_item, true, true)
end

function XueZhanChapterUI:CloseUI()
    LGameMsg.m_deleteUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "XueZhan.XueZhanChapterUI")
    self:SendMsg(LGameMsg.m_deleteUIMsg)
end

function XueZhanChapterUI:onExit()
    self:Destory()
    self.m_pUILayer = nil
    self.Script  = nil
    Utils:SendMsg(LUIRoleDataChangeEvent.BGVisible, true)
end

function XueZhanChapterUI:OnEnter()
    Utils:SendMsg(LUIRoleDataChangeEvent.BGVisible, false)
end

function XueZhanChapterUI:UpdateUserData()
    self:ShowChapter()
    self:ShowStar()
    self:ShowUnLockTips()
    self:CheckSaoDangShow()
end

function XueZhanChapterUI:UpdateRedDot()
    local show = Utils:GetRedDotState(RedDotDef.ID.ShopWanFaXueZhan)
    self.m_shopPrompt:setVisible(show)
end

return XueZhanChapterUI