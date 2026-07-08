local SettingUI = LUIBase:New()
SettingUI.__index = SettingUI

function SettingUI:New()
    local o = LUIBase:New()
    setmetatable(o,SettingUI)  
    o:Init()
    return o
end

--[[
注册UI消息
]]
function SettingUI:RegistMsgs()
    self.msgIds = 
    {
        --LUIWingDataEvent.SetWingState,
    }
    self:RegistSelf(self,self.msgIds)
end

function SettingUI:ProcessEvent(msg)
--    if msg.msgId == LUIWingDataEvent.SetWingState then
--    end
end

function SettingUI:Init()
    self:RegistMsgs()
    self.m_pUILayer = cc.CSLoader:createNode("csd/zhujue/SystemLayer.csb")
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
    self:ShowSetting()
end

function SettingUI:onExit()
    self:Destory()
    self.m_panelUI = nil
    self.m_pSystemBg = nil
    self.m_pBtnList = nil
    -----------------------------------------------------------------------
    -- 角色信息
    self.m_pImageBg = nil
    self.m_pHeadImage = nil
    self.m_pLevel = nil
    self.m_pName = nil
    self.m_pServerName = nil
    -----------------------------------------------------------------------
    -- 设置信息
    self.m_pMusic = nil
    self.m_pMusicSlider = nil
    self.m_pSound = nil
    self.m_pSoundSlider = nil
    -----------------------------------------------------------------------
    -- 按键
    self.m_pGongGaoBtn = nil
    self.m_pChangeAccountBtn = nil
    self.m_pKeyBtn = nil
end

function SettingUI:InitData()
    self.m_panelUI = self.m_pUILayer:getChildByName("Panel")
    self.m_pSystemBg = self.m_panelUI:getChildByName("SystemBg")
    self.m_pBtnList = self.m_panelUI:getChildByName("BtnList")
    self.m_pBtnList:setTouchEnabled(false)

    -----------------------------------------------------------------------
    -- 角色信息
    self.m_pImageBg = self.m_pSystemBg:getChildByName("ImageBg")
    -- 角色头像
    self.m_pHeadImage = self.m_pImageBg:getChildByName("HeadIcon"):getChildByName("HeadImage")
    self.m_pLevel = self.m_pImageBg:getChildByName("HeadIcon"):getChildByName("Text_1")
    -- 角色名
    self.m_pName = self.m_pImageBg:getChildByName("Name")
    -- 服务器名称
    self.m_pServerName = self.m_pImageBg:getChildByName("ServerName")

    -----------------------------------------------------------------------
    -- 设置信息
    -- 音乐
    self.m_pMusic = self.m_pSystemBg:getChildByName("CheckBox_1")
    self.m_pMusicSlider = self.m_pMusic:getChildByName("Slider")
    -- 音效
    self.m_pSound = self.m_pSystemBg:getChildByName("CheckBox_2")
    self.m_pSoundSlider = self.m_pSound:getChildByName("Slider")

    -----------------------------------------------------------------------
    -- 按键
    -- 游戏公告
    self.m_pGongGaoBtn = self.m_pBtnList:getChildByName("Btn_1")
    -- 切换账号
    self.m_pChangeAccountBtn = self.m_pBtnList:getChildByName("Btn_4")
    -- 兑换码
    self.m_pKeyBtn = self.m_pBtnList:getChildByName("Btn_5")

    -----------------------------------------------------------------------
    -- -- 屏蔽设定
    -- --是否屏蔽附近玩家
    -- self.m_pNearRole = self.m_pPopup:getChildByName("CheckBox1")
    -- --是否屏蔽切磋
    -- self.m_pPK = self.m_pPopup:getChildByName("CheckBox2")
    -- --是否屏蔽鲜花特效
    -- self.m_pFlower = self.m_pPopup:getChildByName("CheckBox3")
    -- --是否屏蔽至尊标识
    -- self.m_pVIP = self.m_pPopup:getChildByName("CheckBox4")
    -- --是否屏蔽称号
    -- self.m_pTitle = self.m_pPopup:getChildByName("CheckBox5")
    -- self.m_pCloseBtn = self.m_pPopup:getChildByName("bg"):getChildByName("Btn_close")

end

function SettingUI:AddTouchEvt()
    -- 音乐开关
    local function MusicCallback(sender)
        local isSelect = sender:isSelected()
        if isSelect then
            self.m_pMusicSlider:setPercent(0)
            self.m_pMusicSlider:setTouchEnabled(false)
            LGameMsg.m_scrollTipsMsg:ChangeWithMsgId(LAudioEvent.DisableBgMusic)
            self:SendMsg(LGameMsg.m_scrollTipsMsg)
        else
            self.m_pMusicSlider:setPercent(100)
            self.m_pMusicSlider:setTouchEnabled(true)
            LGameMsg.m_scrollTipsMsg:ChangeWithMsgId(LAudioEvent.EnableBgMusic)
            self:SendMsg(LGameMsg.m_scrollTipsMsg)
        end
        LUserConfigMgr:SetMusicVolume(self.m_pMusicSlider:getPercent()/100)
    end
    self.m_pMusic:addEventListener(MusicCallback)

    -- 音乐大小
    local function MusicSliderCallback(sender)
        LUserConfigMgr:SetMusicVolume(sender:getPercent()/100)
        LGameMsg.m_scrollTipsMsg:ChangeWithMsgId(LAudioEvent.SetMusicVolume)
        self:SendMsg(LGameMsg.m_scrollTipsMsg)
    end
    self.m_pMusicSlider:addEventListener(MusicSliderCallback)

    -- 音效开关
    local function SoundCallback(sender)
        local isSelect = sender:isSelected()
        if isSelect then
            self.m_pSoundSlider:setPercent(0)
            self.m_pSoundSlider:setTouchEnabled(false)
            LGameMsg.m_scrollTipsMsg:ChangeWithMsgId(LAudioEvent.DisableEffects)
            self:SendMsg(LGameMsg.m_scrollTipsMsg)
        else
            self.m_pSoundSlider:setPercent(100)
            self.m_pSoundSlider:setTouchEnabled(true)
            LGameMsg.m_scrollTipsMsg:ChangeWithMsgId(LAudioEvent.EnableEffects)
            self:SendMsg(LGameMsg.m_scrollTipsMsg)
        end
        LUserConfigMgr:SetEffectsVolume(self.m_pSoundSlider:getPercent()/100)
    end
    self.m_pSound:addEventListener(SoundCallback)
    
    -- 音效大小
    local function SoundSliderCallback(sender)
        LUserConfigMgr:SetEffectsVolume(sender:getPercent()/100)
        LGameMsg.m_scrollTipsMsg:ChangeWithMsgId(LAudioEvent.SetEffectVolume)
        self:SendMsg(LGameMsg.m_scrollTipsMsg)
    end
    self.m_pSoundSlider:addEventListener(SoundSliderCallback)

    -- 公告
    local function gongGaoCallback(sender)
        if LRoleDataMgr.MyHeroInfo.level < 2 then
            Utils:ShowScrollTips(GUITips.RSI_GG_TIPS1)
            return
        end
        LuaNetSendMsg:QueryMsgHeader()
    end
    self.m_pGongGaoBtn:addClickEventListener(gongGaoCallback)
    
    -- 切换帐号
    local function changeCallback(sender)
        Utils:SendMsg(LGameEvent.ChangeUser)
    end
    self.m_pChangeAccountBtn:addClickEventListener(changeCallback)

    -- 兑换码
    local function keyCallback(sender)
        LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.InitUI, "Welfare.NewActiveCodeUI",AppDef.UIType.PopWindow)
        self:SendMsg(LGameMsg.m_initUIMsg)
    end
    self.m_pKeyBtn:addClickEventListener(keyCallback)
end

function SettingUI:ShowSetting()
    local heroData = LRoleDataMgr.MyHeroInfo
    local str = AppDef:GetHeroPicFileName(LRoleDataMgr.MyHeroInfo:GetHead(),AppDef.HeadType.HERO_IMAGE_HEAD)
    self.m_pHeadImage:loadTexture(str,ccui.TextureResType.localType)
    self.m_pLevel:setString(tostring(LRoleDataMgr.MyHeroInfo.level))
    self.m_pName:setString(GUITips.UI_Text_Role..GUITips.UI_Text_Maohao..heroData.name)
    self.m_pServerName:setString(GUITips.UI_Text_Server..GUITips.UI_Text_Maohao..LUserConfigMgr:GetLastSelServerName())

    local bMusicMate = LUserConfigMgr:GetIsMusicClosed()
    local bSoundMate = LUserConfigMgr:GetIsEffectClosed()
    
    self.m_pMusic:setSelected(bMusicMate)
    self.m_pSound:setSelected(bSoundMate)
    if bMusicMate then
        self.m_pMusicSlider:setTouchEnabled(false)
        self.m_pMusicSlider:setPercent(0)
    else
        self.m_pMusicSlider:setPercent(LUserConfigMgr:GetMusicVolume() * 100)
    end
    if bSoundMate then
        self.m_pSoundSlider:setTouchEnabled(false)
        self.m_pSoundSlider:setPercent(0)
    else
        self.m_pSoundSlider:setPercent(LUserConfigMgr:GetEffectVolume() * 100)
    end
end

function SettingUI:ShowShieldSetting()
    -- self.m_pNearRole:setSelected(LUserConfigMgr:getShieldNearoHero() == 1)
    -- self.m_pPK:setSelected(LUserConfigMgr:getShieldQieChuo() == 1)
    -- self.m_pFlower:setSelected(LUserConfigMgr:getShieldXianHuaPar() == 1)
    -- self.m_pVIP:setSelected(LUserConfigMgr:getShieldVIP() == 1)
    -- self.m_pTitle:setSelected(LUserConfigMgr:getShieldChengHao() == 1)

 --    --关闭
 --    local function ShieldSettingCallback(sender)
 --        local oldNearHero = LUserConfigMgr:getShieldNearoHero()
 --        local oldVip = LUserConfigMgr:getShieldVIP()
 --        local oldTitle = LUserConfigMgr:getShieldChengHao()
 --        local nSelect = 0
 --        if self.m_pNearRole:isSelected() then
 --            nSelect = 1
 --        end
 --        LUserConfigMgr:setShieldNearoHero(nSelect)

 --        nSelect = 0
 --        if self.m_pPK:isSelected() then
 --            nSelect = 1
 --        end
 --        LUserConfigMgr:setShieldQieChuo(nSelect)

 --        nSelect = 0
 --        if self.m_pFlower:isSelected() then
 --            nSelect = 1
 --        end
 --        LUserConfigMgr:setShieldXianHuaPar(nSelect)

 --        nSelect = 0
 --        if self.m_pVIP:isSelected() then
 --            nSelect = 1
 --        end
 --        LUserConfigMgr:setShieldVIP(nSelect)

 --        nSelect = 0
 --        if self.m_pTitle:isSelected() then
 --            nSelect = 1
 --        end
 --        LUserConfigMgr:setShieldChengHao(nSelect)

 --        self.m_pPopup:setVisible(false)

 --        local newNearHero = LUserConfigMgr:getShieldNearoHero()
 --        local newVip = LUserConfigMgr:getShieldVIP()
 --        local newTitle = LUserConfigMgr:getShieldChengHao()

 --        if oldNearHero ~= newNearHero or oldVip ~= newVip or oldTitle ~= newTitle then
 --            if newNearHero == 1 then
 --                newNearHero = false
 --            else
 --                newNearHero = true
 --            end
 --            if newVip == 1 then
 --                newVip = false
 --            else
 --                newVip = true
 --            end
 --            if newTitle == 1 then
 --                newTitle = false
 --            else
 --                newTitle = true
 --            end
 --            local settingMsg = SceneSettingMsg:new(CEnum.MapEvent.LuaSceneSetting, newNearHero, newVip, newTitle)
 --            self:SendMsg(settingMsg)
 --        end
        
 --    end
 --    self.m_pCloseBtn:addClickEventListener(ShieldSettingCallback)
	-- self:MarkIntaractCObj(self.m_pCloseBtn)
end

return SettingUI
