
local HeroBookSingleUI = LUIBase:New()
HeroBookSingleUI.__index = HeroBookSingleUI
--local this = LTcpSocket
function HeroBookSingleUI:New(heroId)
    local o = LUIBase:New()
    setmetatable(o,HeroBookSingleUI)    
    o:Init(heroId)
    return o
end

--注册事件
-- -----------------------------------
function HeroBookSingleUI:RegistMsgs()
    self.msgIds = 
    {
        LUIKaPaiPetEvent.BookLevelUpSuc,
        LUIKaPaiPetEvent.UpdateHeroBookUI,
    }
    self:RegistSelf(self,self.msgIds)
end

-- -----------------------------------
function HeroBookSingleUI:ProcessEvent(msg)
    if msg.msgId == LUIKaPaiPetEvent.BookLevelUpSuc then
    elseif msg.msgId == LUIKaPaiPetEvent.UpdateHeroBookUI then
        self:ShowData()
    end
end

function HeroBookSingleUI:Init(heroId)
    self:RegistMsgs()
    self:InitMembers(heroId)
    self:ShowData()
    self:AddTouchEvt()
    local function onNodeEvent(event)
        if "exit" == event then
            self:onExit()
        end
    end

    self.m_pUILayer:registerScriptHandler(onNodeEvent)
end

function HeroBookSingleUI:InitMembers(heroId)
    self.m_pUILayer = cc.CSLoader:createNode("csd/shenjiangyangcheng/yingxiongtujianupLayer.csb")
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)
    local popup = self.m_pUILayer:getChildByName("Popup")
    local attrBg = popup:getChildByName("shuxing")
    
    self.m_heroId = heroId
    self.m_blackBg = self.m_pUILayer:getChildByName("Mask")
    self.m_headColor = popup:getChildByName("IconColor")
    self.m_headIcon = self.m_headColor:getChildByName("Icon")
    self.m_nameText = self.m_headColor:getChildByName("Name")
    self.m_closeBtn = popup:getChildByName("Btn_close")
    self.m_levelCondText = popup:getChildByName("tiaojian"):getChildByName("Value")
    self.m_levelUpBtn = popup:getChildByName("Btn_shengji")
    self.m_costBg = popup:getChildByName("xiaohao"):getChildByName("Icon")
    self.m_costText = popup:getChildByName("xiaohao"):getChildByName("Value")
    self.m_curInfo = {}
    self.m_curInfo.attr = {}
    self.m_nextInfo = {}
    self.m_nextInfo.attr = {}

    self.m_curInfo.level = attrBg:getChildByName("Level_1")
    self.m_curInfo.score = attrBg:getChildByName("tujianzhi_1")
    self.m_nextInfo.level = attrBg:getChildByName("Level_2")
    self.m_nextInfo.score = attrBg:getChildByName("tujianzhi_2")
    for i=1,4 do
        self.m_curInfo.attr[i] = attrBg:getChildByName("Attribute_"..i)
        self.m_nextInfo.attr[i] = attrBg:getChildByName("Attribute_"..i+4)
        self.m_curInfo.attr[i]:setVisible(false)
        self.m_nextInfo.attr[i]:setVisible(false)
    end
    self.m_blackBg:setTouchEnabled(true)
    self.m_blackBg:setSwallowTouches(true)
end

function HeroBookSingleUI:onExit()
    self.m_pUILayer = nil
    self.m_heroId = nil
    self.m_blackBg = nil
    self.m_headColor = nil
    self.m_headIcon = nil
    self.m_nameText = nil
    self.m_closeBtn = nil
    self.m_levelCondText = nil
    self.m_levelUpBtn = nil
    self.m_costBg = nil
    self.m_costText = nil
    self.m_curInfo = nil
    self.m_nextInfo = nil
    self:Destory()
end

function HeroBookSingleUI:AddTouchEvt()
    local function ClickCallback(sender)
        LGameMsg.m_deleteUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "HeroBook.HeroBookSingleUI")
        LUIManager:SendMsg(LGameMsg.m_deleteUIMsg)
    end
    -- self.m_blackBg:addTouchEventListener(ClickCallback)
    -- self:MarkIntaractCObj(self.m_blackBg)
    self.m_closeBtn:addClickEventListener(ClickCallback)
    self:MarkIntaractCObj(self.m_closeBtn)

    function LevelUpCallBack(sender)
        LuaNetSendMsg:LevelUpHeroBook(self.m_heroId)
    end
    self.m_levelUpBtn:addClickEventListener(LevelUpCallBack)
    self:MarkIntaractCObj(self.m_levelUpBtn)
end

function HeroBookSingleUI:ShowData()
    local herostar = LRoleDataMgr.m_book.bookStar[self.m_heroId]
    local heroCfg = JsonConfig.m_heroCfg.getDefByID(self.m_heroId)
    if heroCfg == nil then return end
    local quelityCfg = JsonConfig.m_quality.getDefByID(heroCfg.quality)
    if quelityCfg == nil then return end
    local heroData = LRoleDataMgr.Pet:GetPetById(self.m_heroId)
    local curHeroStar = 0
    if heroData ~= nil then curHeroStar = heroData.star end
    local star = 1
    local score = 0
    local addValue = 0
    if herostar ~= nil then
        star = herostar.star
        score = herostar.score
    end

    local starCfg = JsonConfig.m_star.getDefByID(star)
    for i=1,#starCfg.handbook_value do
        local value = starCfg.handbook_value[i]
        if value[1] == quelityCfg.quality then
            addValue = value[2]
            break
        end
    end

    local starCost = {}
  
    local nextStarCfg = JsonConfig.m_star.getDefByID(star + 1)
    for i=1,#nextStarCfg.handbook_cost do
        local value = nextStarCfg.handbook_cost[i]
        if value[1] == heroCfg.quality then
            starCost.type = value[2]
            starCost.value = value[3]
            break
        end
    end
    starCost.hasCnt = LRoleDataMgr.Equip:CountItemNumById(starCost.type) or 0

    local curAttr = {}
    local nextAttr = {}
    for i=1,4 do
        curAttr[i] = 0
    end
    for i=1,star do
        local curStarCfg = JsonConfig.m_star.getDefByID(i)
        curAttr[1] = curAttr[1] + curStarCfg.handbook * heroCfg.gongji_lv * quelityCfg.handbook_ratio / 10000
        curAttr[2] = curAttr[2] + curStarCfg.handbook * heroCfg.wufang_lv * quelityCfg.handbook_ratio / 10000
        curAttr[3] = curAttr[3] + curStarCfg.handbook * heroCfg.fafang_lv * quelityCfg.handbook_ratio / 10000
        curAttr[4] = curAttr[4] + curStarCfg.handbook * heroCfg.qixue_lv * quelityCfg.handbook_ratio / 10000
    end
    for i=1,4 do
        nextAttr[i] = curAttr[i]
    end

    if star < 7 then
        local curStarCfg = JsonConfig.m_star.getDefByID(star + 1)
        nextAttr[1] = nextAttr[1] + curStarCfg.handbook * heroCfg.gongji_lv * quelityCfg.handbook_ratio / 10000
        nextAttr[2] = nextAttr[2] + curStarCfg.handbook * heroCfg.wufang_lv * quelityCfg.handbook_ratio / 10000
        nextAttr[3] = nextAttr[3] + curStarCfg.handbook * heroCfg.fafang_lv * quelityCfg.handbook_ratio / 10000
        nextAttr[4] = nextAttr[4] + curStarCfg.handbook * heroCfg.qixue_lv * quelityCfg.handbook_ratio / 10000
    end

    for i=1,4 do
        self.m_curInfo.attr[i]:setString(string.format(GUITips.RSI_ZQX_HERO_BOOK9,
            AppDef.EAttrTypeName[i], curAttr[i]))
        self.m_curInfo.attr[i]:setVisible(true)
        self.m_nextInfo.attr[i]:setString(string.format(GUITips.RSI_ZQX_HERO_BOOK9,
            AppDef.EAttrTypeName[i], nextAttr[i]))
        self.m_nextInfo.attr[i]:setVisible(true)
    end

    Utils:ShowPetHeadImg(self.m_headIcon, heroCfg.pic, self.m_headColor, heroCfg.quality, false)
    self.m_curInfo.score:setString(string.format(GUITips.RSI_ZQX_HERO_BOOK4, score))
    self.m_nextInfo.score:setString(string.format(GUITips.RSI_ZQX_HERO_BOOK4, score + addValue))
    self.m_curInfo.level:setString(string.format(GUITips.RSI_ZQX_HERO_BOOK2, star))
    self.m_nextInfo.level:setString(string.format(GUITips.RSI_ZQX_HERO_BOOK2, star + 1))

    self.m_levelCondText:setString(string.format(GUITips.RSI_ZQX_HERO_BOOK11,
        curHeroStar, nextStarCfg.handbook_condition))
    self.m_nameText:setString(heroCfg.name)
    self.m_costBg:loadTexture("item/equip"..LRoleDataMgr.GetItemPicId(starCost.type)..".png")
    self.m_costText:setString(string.format(GUITips.RSI_ZQX_HERO_BOOK10, starCost.hasCnt, starCost.value))
end

return HeroBookSingleUI