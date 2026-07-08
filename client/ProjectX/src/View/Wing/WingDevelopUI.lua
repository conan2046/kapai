local WingDevelopUI = LUIBase:New()
WingDevelopUI.__index = WingDevelopUI

function WingDevelopUI:New()
    local o = LUIBase:New()
    setmetatable(o,WingDevelopUI)   
    o:Init()
    return o
end

--[[
注册UI消息
]]
function WingDevelopUI:RegistMsgs()
    self.msgIds = 
    {
        LUIWingDataEvent.UpgradWing,
        LUIRedDotEvent.UpdateRedDotState,
        LUIWingDataEvent.UpgradEnd
        --LUIItemListUIEvent.SelectItem,
    }
    self:RegistSelf(self,self.msgIds)
end

function WingDevelopUI:ProcessEvent(msg)
    if msg.msgId == LUIWingDataEvent.UpgradWing then
        self:AutoPutIn()
        self:UpdateView()
    elseif msg.msgId == LUIRedDotEvent.UpdateRedDotState then
        self:DealUpdateRedDotState(msg.value)
    elseif msg.msgId == LUIItemListUIEvent.SelectItem then
        local itemInfo = msg.value
        if itemInfo == nil then
            return
        end
        self.m_itemId = itemInfo["id"]
        self.m_itemNum = itemInfo["num"]
        self:ShowExp()
    elseif msg.msgId == LUIWingDataEvent.UpgradEnd then
        self.m_pUpgradBtn:setEnabled(true)
    end
end

function WingDevelopUI:Init()
    self:RegistMsgs()
    self.m_pUILayer = cc.CSLoader:createNode("csd/WingDevelopLayer.csb")
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
    self:UpdateView()
    self:AutoPutIn()
end

function WingDevelopUI:onExit()
    self:Destory()
    --self.m_pButton = nil    
end

function WingDevelopUI:AddTouchEvt()
    local function MoneyCheckCallback(sender)
        self:ShowExp()
    end
    self.m_pAutoMoney:addEventListener(MoneyCheckCallback)
    
    local function AutoAddCallback(sender)
        self.m_itemId = 2538
        self.m_itemNum = LRoleDataMgr.Equip:CountItemNumById(self.m_itemId)
        if self.m_itemNum == 0 then
            self.m_itemId = 0
        end
        self:ShowExp()
    end
    self.m_pAutoAdd:addClickEventListener(AutoAddCallback)
	self:MarkIntaractCObj(self.m_pAutoAdd)
--    local function MaterialCallback(sender)
--        LGameMsg.m_baseMsgWithOne:Change(LUILogicEvent.ShowItemListUI, {AppDef.EItemListType.EILTYuyiStone})
--        self:SendMsg(LGameMsg.m_baseMsgWithOne)
--    end
--    self.m_pMaterial:addClickEventListener(MaterialCallback)

    local function UpgradCallback(sender)
        -- if not self.m_pAutoMoney:isSelected() and self.m_itemNum == 0 then
        --     Utils:ShowScrollTips(GUITips.Wing_Tips_Error3)
        --     return
        -- end

        if not self.m_pAutoMoney:isSelected() and self.m_itemNum < 1 then
            --若没有材料,则显示来源
            local num = LRoleDataMgr:getLowMatrialNumByType(AppDef.EItemListType.EILTYuyiStone)
            local id = LRoleDataMgr:getLowMatrialIdByType(AppDef.EItemListType.EILTYuyiStone)
            item = 
            {
                itemType = "CItem",
                itemData = LItemMgr:getItem(id)
            }
            LGameMsg.m_baseMsgWithOne:Change(LUILogicEvent.ShowItemInfo, item)
            self:SendMsg(LGameMsg.m_baseMsgWithOne)
            return
        else
            local itemId = self.m_itemId
            if self.m_itemNum == 0 then 
                itemId = 0
            end
            LuaNetSendMsg:QueryChiBangInfo(2, itemId, self.m_itemNum)
            self.m_pUpgradBtn:setEnabled(false)
        end
    end
    self.m_pUpgradBtn:addClickEventListener(UpgradCallback)
	self:MarkIntaractCObj(self.m_pUpgradBtn)
    local function QuestionCallBack()
        self:ShowHelp()
    end
    self.m_pHelpBtn:addClickEventListener(QuestionCallBack)
	self:MarkIntaractCObj(self.m_pHelpBtn)
end

function WingDevelopUI:InitData()
    local developUI = self.m_pUILayer:getChildByName("WingDevelopUI")
    local panel = developUI:getChildByName("Panel")
    local panel0 = developUI:getChildByName("Panel_0")
    self.m_pCurAttrs = {}   -- ÃƒÂ¥Ã‚Â±Ã…Â¾ÃƒÂ¦Ã¢â€?
    for i=1,4 do
        self.m_pCurAttrs[i] = developUI:getChildByName("Attribute_"..i)
    end
    self.m_pHelpBtn = panel0:getChildByName("btn_help")

    self.m_pStars = developUI:getChildByName("Star")
    self.m_pStarIcons = {}   -- ÃƒÂ¦Ã‹Å“?
    for i=1,5 do
        self.m_pStars[i] = self.m_pStars:getChildByName("Image_"..i)
    end
    self.m_pExp = developUI:getChildByName("bg_xianling"):getChildByName("Value")
    self.m_pHExp = developUI:getChildByName("bg_xianling"):getChildByName("LoadingBar_1")   --ÃƒÂ§Ã‚ÂºÃ‚Â¢ÃƒÂ§Ã‚Â»Ã‚ÂÃƒÂ©Ã‚ÂªÃ…â€™ÃƒÂ¦Ã‚ÂÃ‚Â?
    self.m_pLExp = developUI:getChildByName("bg_xianling"):getChildByName("LoadingBar_2")   --ÃƒÂ§Ã‚Â»Ã‚Â¿ÃƒÂ§Ã‚Â»Ã‚ÂÃƒÂ©Ã‚ÂªÃ…â€™ÃƒÂ¦Ã‚ÂÃ‚Â?

    self.m_pAutoAdd = developUI:getChildByName("btn_Add")
    self.m_pAutoAdd:setVisible(false)
    self.m_pUpgradBtn = developUI:getChildByName("btn_Upgrad")
    self.m_pUpgradBtn:getChildByName("Prompt"):setVisible(false)
    
    self.m_pMaterial = developUI:getChildByName("btn_Material")
    self.m_pMaterial:setTitleText("")
    self.m_iconImage = self.m_pMaterial:getChildByName("Icon")
    self.m_addImage = self.m_pMaterial:getChildByName("Image")
    self.m_pItemNum = self.m_pMaterial:getChildByName("Value")
    self.m_pItemNameLabel = developUI:getChildByName("Name")

    self.m_pAutoMoney = developUI:getChildByName("CheckBox")
    self.m_pCurStage = panel:getChildByName("bg_Class"):getChildByName("Text")
    self.m_pNextStage = panel0:getChildByName("bg_Class"):getChildByName("Text")
    self.m_pCurName = panel:getChildByName("bg_Name"):getChildByName("Text")
    self.m_pNextName = panel0:getChildByName("bg_Name"):getChildByName("Text")
    self.m_pAutoMoney:setSelected(false)
    self.m_itemId = 0
    self.m_itemNum = 0
    self.m_curAni = panel:getChildByName("RolePoint")
    self.m_nextAni = panel0:getChildByName("RolePoint")

    local data = LRoleDataMgr.MyHeroInfo
    self.m_curRoleModel = ModelAniNode:create(AppDef.CEnum.ModelAniType.Hero, 
            data.professional, data:GetWeaponId(), data.LightEffect,
            data.WingsId, 0, 0) 
    self.m_curAni:addChild(self.m_curRoleModel)
    self.m_nextRoleModel = ModelAniNode:create(AppDef.CEnum.ModelAniType.Hero, 
            data.professional, data:GetWeaponId(), data.LightEffect,
            data.WingsId, 0, 0) 
    self.m_nextAni:addChild(self.m_nextRoleModel)
end

function WingDevelopUI:UpdateView()
    local OtInfo = LRoleDataMgr.MyHeroInfo.ChiBangExInfo
    local stage = OtInfo.Level + 1-- 阶段是从0 - 8 对应id 1 - 9
    local nextStage = stage + 1
    local curWing
    if stage < 8 then
        curWing = LDataConstMgr:GetWingConfigData(stage)
    else
        curWing = LDataConstMgr:GetWingConfigData(7)
    end
    local nextWing
    if OtInfo.Star == 10 and stage == 9 then -- 满级
        nextWing = curWing
        self.m_pNextStage:setString(GUITips["Wing_Stage_Text"..nextStage])
    else -- 没有满级
        if stage >= 7 then -- 超过7阶 翅膀模型不变
            nextWing = curWing
        else
            nextWing = LDataConstMgr:GetWingConfigData(nextStage)
        end
        self.m_pNextStage:setString(GUITips.Wing_Stage_Next..GUITips["Wing_Stage_Text"..nextStage])
    end

    self.m_pCurStage:setString(GUITips.Wing_Stage_Cur..GUITips["Wing_Stage_Text"..stage])
    if curWing ~= nil then
        self.m_pCurName:setString(curWing.name)
        self.m_pNextName:setString(nextWing.name)
    end
    local curStar = LDataConstMgr:GetWingDevelopStar(OtInfo.Level, OtInfo.Star)
    local nextStar = LDataConstMgr:GetNextWingDevelopStar(OtInfo.Level, OtInfo.Star)
    if nextStar == nil then nextStar = curStar end
    for i=1,4 do
        local attr = curStar.attrs[i]
        local nattr = nextStar.attrs[i]
        local acfg = LDataConstMgr:GetAttrConfigData(tonumber(attr[1]))
        self.m_pCurAttrs[i]:setString(acfg.attrName.." :")
        self.m_pCurAttrs[i]:getChildByName("Value"):setString(attr[2])
        self.m_pCurAttrs[i]:getChildByName("Value_0"):setString("+"..tonumber(nattr[2])-tonumber(attr[2]))
    end
    
    self:ShowExp()
    
    self:UpdateAni(self.m_curRoleModel, self.m_curAni, curWing.id)
    self:UpdateAni(self.m_nextRoleModel, self.m_nextAni, nextWing.id)

    local xingNum = OtInfo.Star / 2
    local halfXing = OtInfo.Star % 2 ~= 0
    local curIdx = 0 -- 
    for i=1, xingNum do
        self.m_pStars[i]:loadTexture("res/UI/ui_common/ui_zuoqi_xing_01.png", ccui.TextureResType.plistType)
        curIdx = i
    end
    if halfXing then
        curIdx = curIdx + 1
        self.m_pStars[curIdx]:loadTexture("res/UI/ui_common/ui_zuoqi_xing_03.png", ccui.TextureResType.plistType)
    end

    for i=curIdx+1, 5 do
        self.m_pStars[i]:loadTexture("res/UI/ui_common/ui_zuoqi_xing_02.png", ccui.TextureResType.plistType)
        halfIdx = i + 1
    end
end

function WingDevelopUI:UpdateAni(model, ani, wingId)
    local data = LRoleDataMgr.MyHeroInfo
    model:InitAni(AppDef.CEnum.ModelAniType.Hero,  
        data.professional, data:GetWeaponId(), data.LightEffect,
        wingId, 0, 0)
    model:PlayStand(0)
    --model:setPositionY(-60)
end

function WingDevelopUI:ShowExp()
    self.m_addImage:setVisible(false)
    self.m_iconImage:setVisible(false)
    local isOpenTpuch = false
    if self.m_itemNum == 0 then 
        isOpenTpuch = true
    end
    if self.m_itemId > 0 then
        local itemData = LItemMgr:getItem(self.m_itemId)
        if itemData ~= nil then
            self.m_pItemCell = Utils:GetItemCellValue(self.m_pMaterial, 0, self.m_itemId, true, true, self.m_itemNum, self.m_pItemCell, isOpenTpuch, true)
            self.m_pItemNameLabel:setString(itemData.m_name)
        end
    end
    
--    self.m_pItemNum:setString(self.m_itemNum)
    self.m_pItemNum:setVisible(false)
--    if self.m_itemNum > 0 then
--        self.m_pItemNum:setColor(AppDef.UIColor.WHITE)
--    else
--        self.m_pItemNum:setColor(AppDef.UIColor.RED)
--    end

    local add = 0
    local OtInfo = LRoleDataMgr.MyHeroInfo.ChiBangExInfo
    if self.m_pAutoMoney:isSelected() then
        add = 2000
    else
        add = self.m_itemNum * 10
    end
    local midStr = ""
    if add ~= 0 then
        midStr = "(+"..add..")/"
    else
        midStr = "/"
    end

    local curStar = LDataConstMgr:GetWingDevelopStar(OtInfo.Level, OtInfo.Star)
    local exp = OtInfo.Exp..midStr..curStar.needExp
    self.m_pLExp:setVisible(true)
    self.m_pHExp:setVisible(true)
    self.m_pHExp:setPercent((OtInfo.Exp + add) * 100 / curStar.needExp)
    self.m_pLExp:setPercent((OtInfo.Exp * 100)/curStar.needExp)
    self.m_pExp:setString(exp)
end

function WingDevelopUI:ShowHelp()
    local function closeMsgBox()
    end
    local userData =
    {
        loseCallback = closeMsgBox,
        okCallback = closeMsgBox,
        title = GUITips.RSI_WELFARE_MSG38,
        desc = GUITips.RSI_Help_Str3..GUITips.RSI_Help_Str4..GUITips.RSI_Help_Str5
    }
    LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "Common.MsgBoxUI",AppDef.UIType.PopWindow, userData)
    LUIManager:SendMsg(LGameMsg.m_initUIMsg)
end

function WingDevelopUI:AutoPutIn()
    self.m_itemId = 0
    self.m_itemNum = 0
    for i= #AppDef.YuyiStoneIds, 1, -1 do
        local itemId = AppDef.YuyiStoneIds[i]
        local itemNum = LRoleDataMgr.Equip:CountItemNumById(itemId)
        if itemNum > 0 then
            self.m_itemId = itemId
            self.m_itemNum = itemNum
            break
        end
    end
    if self.m_itemId == 0 then
        self.m_itemId = AppDef.YuyiStoneIds[1]
    end
    self:ShowExp()

    local isFullLevel = LRoleDataMgr:IsMyYuYiFullLevel()
    local isShow = self.m_itemNum > 0 and not isFullLevel
    Utils:SetRedDotState(RedDotDef.ID.YuYiJJPeiYang, isShow)
end

function WingDevelopUI:DealUpdateRedDotState(data)
    if data == nil or data.id == nil then
        return
    end
    if data.id == RedDotDef.ID.YuYiJJPeiYang then
        self.m_pUpgradBtn:getChildByName("Prompt"):setVisible(data.isShow)
    end
end

return WingDevelopUI