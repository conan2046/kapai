local SkillOpenUI = LUIBase:New()
SkillOpenUI.__index = SkillOpenUI

SkillOpenUI.IsHideInBattle = true

-------------------------------------
function SkillOpenUI:New(id)
    local o = {}
    setmetatable(o, SkillOpenUI)
    o:Init(id)
    return o
end
-------------------------------------
function SkillOpenUI:Init(id)
    self.Script = "ImproveUI.SkillOpenUI"
    ------------------------------------------------
    self.m_index = 1
    self.m_datas = {}
    ------------------------------------------------
    self.m_pBg = nil
    self.m_pLight = nil
    self.m_pIcon = nil
    self.m_pText = nil
    self.m_canClick = false
    ------------------------------------------------
    self:InitViewSize()
    self:InitUIControl()
    self:setCloseCallback()
    if id then
        self:UpdateData(id)
        self:CheckNext()
    end
end

--------------------------------- ----
function SkillOpenUI:onExit()
    self:Destory()
    self.m_pUILayer = nil
    self.m_pBg = nil
    self.m_pLight = nil
    self.m_pIcon = nil
    self.m_pText = nil
    self.m_canClick = nil
end
-------------------------------------
function SkillOpenUI:InitUIControl()
    local pPanel = self.m_pUILayer:getChildByName("Panel")
    -----------------------------------------------------------
    local pPanel_1 = self.m_pUILayer:getChildByName("Panel_1")
    pPanel_1:addClickEventListener(handler(self, SkillOpenUI.CloseUI))
	self:MarkIntaractCObj(pPanel_1)
    -----------------------------------------------------------
    local pBg = pPanel:getChildByName("Bg")
    self.m_pBg = pBg
    -----------------------------------------------------------
    self.m_pLight = pBg
    -----------------------------------------------------------
    local pIconBg = pBg:getChildByName("IconBg")
    local pIcon = pIconBg:getChildByName("Icon")
    pIcon:setVisible(false)
    self.m_pIcon = pIconBg:getChildByName("SkillIcon")
    self.m_pIcon:setVisible(true)
    self.m_pText = self.m_pIcon:getChildByName("Text")
    -----------------------------------------------------------
    local pTitle = pBg:getChildByName("Title")
    local _ = pTitle and pTitle:setVisible(false)
    local pSkillTitle = pBg:getChildByName("SkillTitle")
    local _ = pSkillTitle and pSkillTitle:setVisible(true)
    -----------------------------------------------------------
    local pTextBg = pBg:getChildByName("TextBg")
    pTextBg:setVisible(false)
end

function SkillOpenUI:setCloseCallback()
    local function onNodeEvent(event)
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
end

-------------------------------------
function SkillOpenUI:InitViewSize()
    self:CreateUINode("csd/NewFunctionLayer.csb")
    self.m_pUILayer:setVisible(true)
end

function SkillOpenUI:CloseUI(sender)
    self.m_pUILayer:stopAllActions()
    if not self.m_canClick then
        return
    end
    self:RemoveUI()
end

function SkillOpenUI:UpdateUserData(id)
    self:UpdateData(id)
end

function SkillOpenUI:UpdateData(id)
    if id == nil then
        return
    end
    if not Utils:containValue(self.m_datas, id) then
        table.insert(self.m_datas, id)
    end
    if #self.m_datas <= 0 then
        self:RemoveUI()
        return
    end
end

function SkillOpenUI:ShowStartAnim()
    self.m_pBg:stopAllActions()
    self.m_pBg:setScale(0)

    local pScaleAc = cc.EaseBackOut:create(cc.ScaleTo:create(0.25, 1))
    local pCallback = cc.CallFunc:create(function()
        self.m_canClick = true
    end)
    self.m_canClick = false
    self.m_pBg:runAction(cc.Sequence:create(pScaleAc, pCallback))
    self.m_pBg:setVisible(true)
end

function SkillOpenUI:CheckNext()
    if self.m_pIcon == nil then
        return false
    end
    if self.m_index > #self.m_datas then
        return false
    end

    local skiiId = self.m_datas[self.m_index]
    local skillData = LRoleDataMgr:GetSkillDetailById(skiiId)
    if skillData == nil then
        return
    end
    self.m_index = self.m_index + 1
    local str = string.format("Skill/UI/skill_%d.png", skiiId)
    if str then
        self.loadImageKey[str] = true
        Utils:AsyncLoadImg(self.m_pIcon, str, function(pTexture)
            self.loadImageKey[str] = nil
            self.m_pIcon:loadTexture(str, UI_TEX_TYPE_LOCAL)
        end)
    end

    self.m_pText:setString(skillData.name)

    self:ShowStartAnim()

    -- LGameMsg.m_cBaseMsg:ChangeEventId(CEnum.AutoPathEvent.PauseAutoPath)
    -- self:SendMsg(LGameMsg.m_cBaseMsg)

    Utils:PlayEffect("GuideBGM", "id", 6, nil, true)

    self.m_pUILayer:stopAllActions()
    performWithDelay(self.m_pUILayer, function(sender)
        self:CloseUI()
    end, 3)

    return true
end

return SkillOpenUI