
local HeroBookLevelEndUI = LUIBase:New()
HeroBookLevelEndUI.__index = HeroBookLevelEndUI
--local this = LTcpSocket
function HeroBookLevelEndUI:New(sucInfo)
    local o = LUIBase:New()
    setmetatable(o, HeroBookLevelEndUI)    
    o:Init(sucInfo)
    return o
end

--注册事件
-- -----------------------------------
function HeroBookLevelEndUI:RegistMsgs()
    self.msgIds = 
    {
        LUIKaPaiPetEvent.ShowPetLeftInfo,
    }
    self:RegistSelf(self,self.msgIds)
end

-- -----------------------------------
function HeroBookLevelEndUI:ProcessEvent(msg)
    if msg.msgId == LUIKaPaiPetEvent.ShowPetLeftInfo then
        
    end
end

function HeroBookLevelEndUI:Init(sucInfo)
    self:RegistMsgs()
    self:InitMembers()
    self:ShowData(sucInfo)
    self:AddTouchEvt()
    local function onNodeEvent(event)
        if "exit" == event then
            self:onExit()
        end
    end

    self.m_pUILayer:registerScriptHandler(onNodeEvent)
end

function HeroBookLevelEndUI:InitMembers(heroId)
    self.m_pUILayer = cc.CSLoader:createNode("csd/shenjiangyangcheng/yingxiongtujianupendLayer.csb")
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)


    local attrBg = self.m_pUILayer:getChildByName("shengjichenggongUI")
    attrBg:addClickEventListener(function ( sender )
        -- body
        if  self.upgradeLevel==true then
            Utils:InitUI("HeroBook.BookActivateUI", AppDef.UIType.PopWindow)
        end  
        Utils:DeleteUI("HeroBook.HeroBookLevelEndUI")
    end)
    local scoreBg = attrBg:getChildByName("tujianzhi")
    
    self.m_blackBg = self.m_pUILayer:getChildByName("Mask")
    self.m_preColor = attrBg:getChildByName("IconColor_1")
    self.m_preIcon = self.m_preColor:getChildByName("Icon")
    self.m_preName = self.m_preColor:getChildByName("Name")
    self.m_curColor = attrBg:getChildByName("IconColor_2")
    self.m_curIcon = self.m_curColor:getChildByName("Icon")
    self.m_curName = self.m_curColor:getChildByName("Name")
    self.m_preScore = scoreBg:getChildByName("Value_1")
    self.m_curScore = scoreBg:getChildByName("Value_2")
    self.m_addScore = scoreBg:getChildByName("Value_3")
    self.m_attrbg = {}
    for i=1,4 do
        local attr = {}
        attr.type = attrBg:getChildByName("Atrribute_"..i)
        attr.pre = attr.type:getChildByName("Value_1")
        attr.cur = attr.type:getChildByName("Value_2")
        attr.add = attr.type:getChildByName("Value_3")
        self.m_attrbg[i] = attr
    end
    -- self.m_blackBg:setTouchEnabled(true)
    -- self.m_blackBg:setSwallowTouches(true)
end

function HeroBookLevelEndUI:onExit()
    self.m_pUILayer = nil
    self.m_heroId = nil
    self.m_blackBg = nil
    self.m_preColor = nil
    self.m_preIcon = nil
    self.m_preName = nil
    self.m_curColor = nil
    self.m_curIcon = nil
    self.m_curName = nil
    self.m_preScore = nil
    self.m_curScore = nil
    self.m_addScore = nil
    self.m_attrbg = nil
    self:Destory()
end

function HeroBookLevelEndUI:AddTouchEvt()
    local function ClickCallback(sender)
        if  self.upgradeLevel==true then
            Utils:InitUI("HeroBook.BookActivateUI", AppDef.UIType.PopWindow)
        end  
        print(self.upgradeLevel,"执行=========》")
        LGameMsg.m_deleteUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "HeroBook.HeroBookLevelEndUI")
        LUIManager:SendMsg(LGameMsg.m_deleteUIMsg)
    end  
    self.m_blackBg:addTouchEventListener(ClickCallback)
    self:MarkIntaractCObj(self.m_blackBg)
end

function HeroBookLevelEndUI:ShowData(sucInfo)
    print("HeroBookLevelEndUI:ShowData ===>", sucInfo.heroId)
    self.m_heroId = sucInfo.heroId
    self.upgradeLevel=sucInfo.upgradeLevel
    local petData = LRoleDataMgr.Pet:GetPetById(sucInfo.heroId)
    if petData == nil then
        return
    end
    Utils:ShowPetHeadImg(self.m_preIcon, petData.baseData.pic,
        self.m_preColor, petData.baseData.quality, petData:IsShiny())
    Utils:ShowPetHeadImg(self.m_curIcon, petData.baseData.pic,
        self.m_curColor, petData.baseData.quality, petData:IsShiny())

    self.m_preName:setString(string.format(GUITips.RSI_ZQX_HERO_BOOK12, petData.baseData.name, sucInfo.star - 1))
    self.m_curName:setString(string.format(GUITips.RSI_ZQX_HERO_BOOK12, petData.baseData.name, sucInfo.star))
    local herostar = LRoleDataMgr.m_book.bookStar[self.m_heroId]
    local bookData = JsonConfig.m_star.getDefByID(sucInfo.star).handbook_value
    local bookvalue = 0

    for i=1,#bookData do
        if petData.baseData.quality==bookData[i][1] then
           bookvalue=bookData[i][2] 
           break
        end
        
    end
                      
   
       
    self.m_preScore:setString(tostring(herostar.score))
    self.m_curScore:setString(tostring(herostar.score +bookvalue))
    self.m_addScore:setString(tostring(bookvalue))

    local quelityCfg = JsonConfig.m_quality.getDefByID(petData.baseData.quality)
    local preAttr = {}
    local curAttr = {}
    for i=1,4 do
        preAttr[i] = 0
    end

    local attrTypeArr = {}
    for i=1,sucInfo.star - 1 do
        local cfg = JsonConfig.m_star.getDefByID(i)
        preAttr[1] = preAttr[1] + cfg.handbook * petData.baseData.gongji_lv * quelityCfg.handbook_ratio / 10000
        preAttr[2] = preAttr[2] + cfg.handbook * petData.baseData.wufang_lv * quelityCfg.handbook_ratio / 10000
        preAttr[3] = preAttr[3] + cfg.handbook * petData.baseData.fafang_lv * quelityCfg.handbook_ratio / 10000
        preAttr[4] = preAttr[4] + cfg.handbook * petData.baseData.qixue_lv * quelityCfg.handbook_ratio / 10000
    end

    local curStarCfg = JsonConfig.m_star.getDefByID(sucInfo.star)
    curAttr[1] = preAttr[1] + curStarCfg.handbook * petData.baseData.gongji_lv * quelityCfg.handbook_ratio / 10000
    curAttr[2] = preAttr[2] + curStarCfg.handbook * petData.baseData.wufang_lv * quelityCfg.handbook_ratio / 10000
    curAttr[3] = preAttr[3] + curStarCfg.handbook * petData.baseData.fafang_lv * quelityCfg.handbook_ratio / 10000
    curAttr[4] = preAttr[4] + curStarCfg.handbook * petData.baseData.qixue_lv * quelityCfg.handbook_ratio / 10000

    for i=1, #self.m_attrbg do
        local attr = self.m_attrbg[i]
        attr.type:setString(string.format(GUITips.RSI_ZQX_HERO_BOOK3,Utils:getAttrName(i)))
        attr.pre:setString(tostring(preAttr[i]))
        attr.cur:setString(tostring(curAttr[i]))
        attr.add:setString(tostring(sucInfo.cardAttr[i].value))
    end
end

return HeroBookLevelEndUI