--[[
luaÃ€Ã¯ÃƒÃ¦ÂµÃ„Ã“ÃŽÃÂ·Ã‚ÃŸÂ¼Â­Â¿Ã˜Ã–Ã†
]]

local RoleCreateUI = LUIBase:New()
RoleCreateUI.__index = RoleCreateUI

function RoleCreateUI:New()
	local o = LUIBase:New()
	setmetatable(o,RoleCreateUI)	
    o:Init()
	return o
end

--[[
Ã—Â¢Â²Ã¡UIÃÃ»ÃÂ¢
]]
function RoleCreateUI:RegistMsgs()
    self.msgIds = 
    {
        LUILoginEvent.RecvCheckHeroName,
        -- LUILoginEvent.RecvServerList,
        -- LUILoginEvent.RecvRoleServerList,
        -- LUILoginEvent.LoginSuccess,
    }
    self:RegistSelf(self,self.msgIds)
end

function RoleCreateUI:ProcessEvent(msg)
    if msg.msgId == LUILoginEvent.RecvCheckHeroName then
        self:SaveRandomName(msg.value)
    end
end

function RoleCreateUI:Init()
    self:RegistMsgs()
    self:CreateUINode("csd/Login/RoleCreateLayer.csb")
    -- self.m_pUILayer = cc.CSLoader:createNode("csd/Login/RoleCreateLayer.csb")
    -- self.m_pUILayer:setContentSize(AppDef.frameSize)
    -- ccui.Helper:doLayout(self.m_pUILayer)
    local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
    
    self:InitData()
    self:AddTouchEvt()
    if AppDef.LOCAL_TEST == true and AppDef.LOCAL_TEST_ROLE_NAME_PRESET ~= nil and AppDef.LOCAL_TEST_ROLE_NAME_PRESET ~= "" then
        self.m_pName:setString(AppDef.LOCAL_TEST_ROLE_NAME_PRESET)
        return
    end
    if AppDef.LOCAL_TEST == true and AppDef.LOCAL_TEST_AUTO_CREATE_ROLE == true then
        local roleName = AppDef.LOCAL_TEST_ROLE_NAME or "Test01"
        self.m_pName:setString(roleName)
        performWithDelay(self.m_pUILayer, function()
            LRoleDataMgr.m_strCreateName = roleName
            LuaNetSendMsg:QueryCreateHero(roleName, 0, 5, 5, GameSdk.ChannelId)
        end, 0.5)
        return
    end
    local isUpdate = self:UpdateHeroName()
    if not isUpdate then
        local sex = self.m_sex - 1
        LuaNetSendMsg:QueryCheckHeroName(2, sex, nil)
    end
end

function RoleCreateUI:InitData()
    local panel = self.m_pUILayer:getChildByName("RoleCreateUI")
    self.m_pCreateBg = panel:getChildByName("RoleCreateBg"):getChildByName("role_bg1_1")
    self.m_pImodNode = panel:getChildByName("Role")
    self.m_pExitBtn = panel:getChildByName("Image"):getChildByName("btn_Exit")
    
        
	local effect = panel:getChildByName("effect_chuangjue_1")
	local effcet = self:SetEffect()
    effcet:setName("effcet") 
    effect:addChild(effcet)

    self.m_pStartBtn = panel:getChildByName("btn_Start")
    local rolePanel = panel:getChildByName("Role_Layout")
    self.m_pName = rolePanel:getChildByName("TextField")
	self.m_pName:setCursorEnabled(true)
    self.m_pRandomBtn = rolePanel:getChildByName("btn_Random")
    self.m_pSexArray = {}--
    self.m_sex = 1--(0男1女)+1
    self.m_mHeroNames = {}
    self.m_mIdx = 0
    self.m_fHeroNames = {}
    self.m_fIdx = 0
    self.m_pSexArray[1] = panel:getChildByName("man")
    self.m_pSexArray[1]:setSelected(true)
    self.m_pSexArray[1]:setTouchEnabled(false)
    self.m_pSexArray[2] = panel:getChildByName("woman")
    self.m_pSexArray[2]:setSelected(false)
    for i=1,2 do
        local function SexChangeCallBack(sender,evnetType)
            --self:ShowRoleBgAndImod(pSender)
            if evnetType == ccui.CheckBoxEventType.selected then
                self.m_sex = sender.userObject
                self.m_pSexArray[self.m_sex]:setTouchEnabled(false)
                local idx = 1
                if self.m_sex == 1 then
                    idx = 2
                end
                self.m_pSexArray[idx]:setSelected(false)
                self.m_pSexArray[idx]:setTouchEnabled(true)
                self:ShowRoleBgAndImod()
            end
        end
        self.m_pSexArray[i].userObject = i
        self.m_pSexArray[i]:addEventListener(SexChangeCallBack)
    end
    self.m_pCreateImod = ImodAnim:create()
    -- self.m_pCreateImod:setScale(0.8)
    local size = self.m_pImodNode:getContentSize()
    self.m_pCreateImod:setPosition(cc.p(size.width/2, size.height/2))
    self.m_pImodNode:addChild(self.m_pCreateImod,5,666)
    self:ShowRoleBgAndImod()
end

function RoleCreateUI:SetEffect()
    local bgAnim = "res2/animation/effect_chuangjue_1"
    local m_pBgAni = ImodAnim:create()
    m_pBgAni:initAnimWithNameSync(bgAnim)
    m_pBgAni:PlayActionRepeat(0)
    m_pBgAni:setScale(scale or 1)
    return m_pBgAni
end

--[[
显示背景与东画
]]
function RoleCreateUI:ShowRoleBgAndImod()
    local pngStr = AppDef.GUIRes.Create_Role_Path..AppDef.GUIRes["Create_Role_Imod_"..self.m_sex]
    local aniStr = AppDef.GUIRes.Create_Role_Path..AppDef.GUIRes["Create_Role_Imod_"..self.m_sex]..".ani"
    --local bgStr = AppDef.GUIRes.Create_Role_Path..AppDef.GUIRes["Create_Role_Bg_"..self.m_sex]
    self.m_pCreateImod:initAnimWithNameSync(pngStr)
    self.m_pCreateImod:PlayNewAction(0, true)
    --self.m_pCreateBg:loadTexture(bgStr)
    
    local soundPath = AppDef.HeroBGM[self.m_sex]
    LGameMsg.m_audioMsg:Change(LAudioEvent.PlayEffect, soundPath)
    self:SendMsg(LGameMsg.m_audioMsg)
end

function RoleCreateUI:onExit()
    self:Destory()
    self.m_pExitBtn = nil
    self.m_pRandomBtn = nil
    self.m_pStartBtn = nil    
end

function RoleCreateUI:AddTouchEvt()
    local function ExitCallback(sender)
        
        LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "Login.RoleCreateUI")
        self:SendMsg(LGameMsg.m_initUIMsg)

        LGameMsg.m_baseMsg:ChangeEventId(LGameNetEvent.ConfigDataLoadFinish)
        self:SendMsg(LGameMsg.m_baseMsg)

        -- LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "Login.ServerListUI", AppDef.UIType.Normal)
        -- self:SendMsg(LGameMsg.m_initUIMsg)
    end
    self.m_pExitBtn:addClickEventListener(ExitCallback)
	self:MarkIntaractCObj(self.m_pExitBtn)
    -- Ã‹Ã¦Â¼Â´ÃƒÃ»Â³Ã†
    local function QueryCheckHeroName(sender)
        local isUpdate = self:UpdateHeroName()
        if not isUpdate then
            local sex = self.m_sex - 1
            LuaNetSendMsg:QueryCheckHeroName(2, sex, nil)
        end
    end
    self.m_pRandomBtn:addClickEventListener(QueryCheckHeroName)
	self:MarkIntaractCObj(self.m_pRandomBtn)
    -- 请求创建角色
    local function QueryCreateHero(sender)
        local name = self.m_pName:getString()
        local isOK = self:CheckName(name)
        if not isOK then
            Utils:ShowScrollTips(GUITips.Login_Register_Account_LenMax)
            --print("name is too chang")
            --LGameMsg.m_scrollTipsMsg:ChangeWithMsgId(LUILogicEvent.ShowSrcollTips,GUITips.Login_Register_Account_LenError)
            return
        end

        local isLimited = Utils:IsLimitedMsg(name)
        if isLimited then
            Utils:ShowScrollTips(GUITips.REI_TIPS_LIMITE_WORLD)
            self.m_pName:setString("")
            return
        end

        -- self.ARY_PROF = {5,5,1,1,2,2}
        local sex = self.m_sex-1
        local pro = {5,4}
        LRoleDataMgr.m_strCreateName = name
        LuaNetSendMsg:QueryCreateHero(name,sex,pro[self.m_sex],pro[self.m_sex],GameSdk.ChannelId)
    end
    self.m_pStartBtn:addClickEventListener(QueryCreateHero)
	self:MarkIntaractCObj(self.m_pStartBtn)
end

function RoleCreateUI:CheckName(name)
    if name == nil or string.utf8len(name) > 6 then
        return false
    end
    -- LoginCreateHeroLayer::editBoxReturn(CCEditBox *editText) Ã€ÃÃÃ®Ã„Â¿Ã€Ã¯ÃƒÃ¦Â¼Ã¬Â²Ã©
    return true
end

--Â±Â£Â´Ã¦Ã‹Ã¦Â»ÃºÃƒÃ»Â³Ã†
function RoleCreateUI:SaveRandomName(array)
     print("check hero name")
        -- ÃƒÃ»Ã—Ã–Ã‹Ã¦Â»ÃºÂ·ÂµÂ»Ã˜Â´Â¦Ã€Ã­
        local sex = array[1]
        local nameNum = array[2]
        if sex == 0 then
            for i=1, nameNum do
                self.m_mHeroNames[i] = array[i + 2]
                print("add name ", sex, array[i + 2])
            end
            self.m_mIdx = 0
        else
            for i=1, nameNum do
                self.m_fHeroNames[i] = array[i + 2]
                print("add name ", sex, array[i + 2])
            end
            self.m_fIdx = 0
        end
        print("update hero name")
        self:UpdateHeroName()
end

-- Â¸Ã¼ÃÃ‚Â½Ã‡Ã‰Â«ÃƒÃ»Ã—Ã–
function RoleCreateUI:UpdateHeroName()
    local sex = self.m_sex - 1
    local name = nil
    if sex == 0 then
        self.m_mIdx = self.m_mIdx + 1
        name = self.m_mHeroNames[self.m_mIdx]
        print("update hero name", sex, name)
    else
        self.m_fIdx = self.m_fIdx + 1
        name = self.m_fHeroNames[self.m_fIdx]
     print("update hero name", sex, name)
    end

    if name == nil then
        return false
    end

    self.m_pName:setString(name)
    return true
end

return RoleCreateUI
