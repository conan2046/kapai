--[[
lua里面的游戏逻辑控制
]]
local TimerLabelUI = require("View.Common.TimerLabelUI")
local RoleAttrUI = LUIBase:New()
RoleAttrUI.__index = RoleAttrUI
--local this = LTcpSocket
function RoleAttrUI:New()
	local o = LUIBase:New()
	setmetatable(o,RoleAttrUI)	
    o:Init()
	return o
end


function RoleAttrUI:Init()
    --self.m_pNode = cc.Node:create()

    self.m_pUILayer = cc.CSLoader:createNode("csd/zhujue/RoleLayer.csb")
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)
   -- self:addChild(self.m_pUILayer)
   local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    LuaNetSendMsg:SendXunBaoInfoReq()
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
    self:RegistMsgs()
    self:InitData()
    self:AddTouchEvt()
    self:ShowAttr()
end

--[[
注册UI消息
]]
function RoleAttrUI:RegistMsgs()
    self.msgIds = 
    {
        LUITitleEvent.updateShowMedelSuc,
        LUILogicEvent.changeNameSuc,
        LUIRoleDataChangeEvent.TiliChanged,
        LUIRoleDataChangeEvent.TongBaoChanged,
    }
    self:RegistSelf(self,self.msgIds)
end

function RoleAttrUI:ProcessEvent(msg)
    if msg.msgId == LUILogicEvent.changeNameSuc then
        self:ShowRoleName()
    elseif msg.msgId == LUITitleEvent.updateShowMedelSuc then
        self:ShowTitle()
    elseif msg.msgId == LUIRoleDataChangeEvent.TiliChanged then
        self:ShowTiliCnt()
    elseif msg.msgId == LUIXunBaoEvent.UpdateCntUI then
        self:ShowXunBaoCnt()
    elseif msg.msgId == LUIRoleDataChangeEvent.TongBaoChanged then
        self:ShowMoneys()
    end
end

function RoleAttrUI:onExit()
    self:Destory()
    self.m_pUILayer = nil
    self.m_pIdLabel = nil
    self.m_pLvLabel = nil
    self.m_pFunctionLabel = nil
    --self.m_pHpBar = nil
    --self.m_pHpLabel = nil
    self.m_pExpBar = nil
    self.m_pNameLabel = nil
    self.m_pPowerLabel = nil
end

function RoleAttrUI:InitData()
    local panel = self.m_pUILayer:getChildByName("Panel_12")
    local attrPanel = panel:getChildByName("RoleAttribute")
    local baseAttrPanel = attrPanel:getChildByName("Attribute1")
    self.m_pIdLabel = baseAttrPanel:getChildByName("IDNum")
    self.m_pLvLabel = baseAttrPanel:getChildByName("RoleLevelNum")
    --self.m_pZhiyeImg = baseAttrPanel:getChildByName("RoleCareer")
    --self.m_pZhiyeLabel = baseAttrPanel:getChildByName("CareerName")
    self.m_pFunctionLabel = baseAttrPanel:getChildByName("GuildName")
    -- local hpPanel = baseAttrPanel:getChildByName("RoleLife")
    -- self.m_pHpBar = hpPanel:getChildByName("LifeBar")
    -- self.m_pHpLabel = hpPanel:getChildByName("LifeNum")
    local copyBtn = self.m_pIdLabel:getChildByName("Button_copy")
    copyBtn:setTouchEnabled(true)
    copyBtn:addClickEventListener(function(sender)
        --拷贝ID
        local id = LRoleDataMgr.MyHeroInfo.id
        local app = cc.Application:getInstance()
        app:copyToClipboard(""..id)
        Utils:ShowScrollTips(GUITips.UI_Text_Copy)
    end)
    local expPanel = baseAttrPanel:getChildByName("RoleEXP")
    self.m_pExpBar = expPanel:getChildByName("ExpBar")
    self.m_pExpLabel = expPanel:getChildByName("ExpNum")
    self.m_titleParent = baseAttrPanel:getChildByName("chenghao_layer")
    self.m_titleImg = self.m_titleParent:getChildByName("TitleImage")
    
    local rightPanel = panel:getChildByName("Panel_right")
    --右上
    self.m_moneyListView = rightPanel:getChildByName("huobi_layer")
    self.m_moneyCell = self.m_moneyListView:getChildByName("huobi_list")
    self.m_moneyCell:retain()
    self.m_moneyCell:removeFromParent(false)

    --右下
    local cntPanel = rightPanel:getChildByName("cishu_layer")
    local tiliPanel = cntPanel:getChildByName("huobi_list_1"):getChildByName("Panel_1")
    self.m_tiliLabel = tiliPanel:getChildByName("Text_1"):getChildByName("value")
    self.m_timeLabel1 = tiliPanel:getChildByName("Text_2"):getChildByName("vaule")
    local tiliAddBtn = tiliPanel:getChildByName("AddBtn")
    tiliAddBtn:addClickEventListener(function (sender)
        Utils:OpenUseUI(500,1)
    end)
    local xunbaoPanel = cntPanel:getChildByName("huobi_list_2"):getChildByName("Panel_1")
    self.m_xunbaoLabel = xunbaoPanel:getChildByName("Text_1"):getChildByName("value")
    self.m_timeLabel2 = xunbaoPanel:getChildByName("Text_2"):getChildByName("vaule")
    local xbAddBtn = xunbaoPanel:getChildByName("AddBtn")
    xbAddBtn:addClickEventListener(function (sender)
        Utils:OpenUseUI(402,1)
    end)

    --左上信息
    local equipPanel = panel:getChildByName("RoleEquip")
    local rolePanel = equipPanel:getChildByName("Role")
    self.m_pNameLabel = rolePanel:getChildByName("RoleName"):getChildByName("Name")
    self.m_pPowerLabel = equipPanel:getChildByName("RolePower"):getChildByName("RolePowerBase"):getChildByName("PowerNum")
    self.m_headImg = rolePanel:getChildByName("Icon_zhujue")
    self.m_vipLabel =  rolePanel:getChildByName("bg_VIP"):getChildByName("Value")

    local gaiMingBtn = rolePanel:getChildByName("btn_gaiming")--改名
    gaiMingBtn:addClickEventListener(function(sender)
        Utils:InitUI("Role.GaiMingUI", AppDef.UIType.PopWindow, 1)
    end)
    local changeHeadBtn = rolePanel:getChildByName("Button_genghuan")--换头像
    changeHeadBtn:addClickEventListener(function(sender)
        Utils:ShowScrollTips(GUITips.RSI_GMN_TIP1)
    end)

    self.m_moneyCells = {}
end

function RoleAttrUI:helpButtonCallback(num)
    -- local type = num
    -- local str
    -- if type == 1 then 
    --     str = GUITips.UI_Role_Base_Attr1..GUITips.UI_Role_High_Attr1 
    -- elseif type == 2 then
    --     str = string.format("%s%s%s%s%s%s", GUITips.UI_Role_Msg3, GUITips.UI_Role_Msg4, GUITips.UI_Role_Msg5, GUITips.UI_Role_Msg6, GUITips.UI_Role_Msg7, GUITips.UI_Role_Msg8) 
    -- end
    -- local function OKCallback()
    -- end
    -- local msgData = {
    --     okCallback = OKCallback,
    --     desc = str
    -- }
    -- LGameMsg.m_baseMsgWithOne:Change(LUIMsgBoxEvent.ShowMsgBox, msgData)
    -- self:SendMsg(LGameMsg.m_baseMsgWithOne)
end


function RoleAttrUI:AddTouchEvt()

end

function RoleAttrUI:ShowAttr()
    self:ShowBaseInfo()
    self:ShowMoneys()
    self:ShowCnts()
end


function RoleAttrUI:ShowBaseInfo()
    self:ShowRoleName()
    self:ShowPower()
    self:ShowRoleId()
    --self:ShowRoleZhiye()
    self:ShowRoleLv()
    self:ShowRoleFaction()
    self:ShowRoleExp()
    self:ShowTitle()
    self:ShowVipLv()
    self:ShowHead()
end

function RoleAttrUI:ShowCnts()
    self:ShowTiliCnt()
    self:ShowXunBaoCnt()
    
end

function RoleAttrUI:ShowTiliCnt()
    local value = {}
    local cfg = JsonConfig.m_config.getDefByID(6)
    if cfg ~= nil then
        value = json.decode(cfg.value)
    end
    local tili = LRoleDataMgr.MyHeroInfo.DetailData:getTili()
    local max = tonumber(value[1]) or 100 
    local val = tonumber(value[3]) or 0
    local tmp = max
    -- if tili > max then
    --     tmp = tili
    -- end
    self.m_tiliLabel:setString(""..tili.."/"..tmp)

    if tili >= max then
        self.m_timeLabel1:getParent():setVisible(false)
        return
    end
    local sec = (max-tili)*val- PetkaPaiManager.m_TiLiTime
    self.m_timeLabel1:getParent():setVisible(true)
    local str = Utils:timeString(sec)
    self.m_timeLabel1:setString(str)
    self:StartTili(sec)
end


function RoleAttrUI:StartTili(second)
    print("执行秒数",second)
    if self.m_Timer ~=nil then
        self.m_Timer:stop()
    end
    self.m_Timer = TimerLabelUI:New(self.m_timeLabel1,second, function()
            end,nil,false)
    self.m_Timer:start()
end

function RoleAttrUI:ShowXunBaoCnt()
    local value = {}
    local cfg = JsonConfig.m_config.getDefByID(17)
    if cfg ~= nil then
        value = json.decode(cfg.value)
    end
    local max = tonumber(value[3]) or 30
    local data = LActivityManager:GetXunBaoData()
    local cnt = data.m_cnt or 0
    local val = tonumber(value[2]) or 30 --恢复一点需要的分钟
    local val = val*60--秒
    local tmp = max
    -- if cnt > max then
    --     tmp = cnt
    -- end
    self.m_xunbaoLabel:setString(""..cnt.."/"..tmp)
    if cnt >= max then
        self.m_timeLabel2:getParent():setVisible(false)
        return
    end
    print("剩余寻宝时间")
    local sec = (max-cnt-1)*val+PetkaPaiManager.m_XunBaoTime  --秒
    self.m_timeLabel2:getParent():setVisible(true)
    local str = Utils:timeString(sec)
    self.m_timeLabel2:setString(str)
    self:StartXunBao(sec)
end
function RoleAttrUI:StartXunBao(second)
    print("执行秒数StartXunBao",second)
    if self.m_TimerXunBao ~=nil then
        self.m_TimerXunBao:stop()
    end
    self.m_TimerXunBao = TimerLabelUI:New(self.m_timeLabel2,second, function()

            end,nil,false)
    self.m_TimerXunBao:start()
end
function RoleAttrUI:ShowMoneys()
    local moneyIds = {60000,60001}
    local max = math.ceil(#moneyIds/2)
    for i=1,max do
        local idx = (i-1)*2
        if self.m_moneyCells[i] == nil then
            self.m_moneyCells[i] = self.m_moneyCell:clone()
            self.m_moneyListView:pushBackCustomItem(self.m_moneyCells[i])
        end
        local panel1 = self.m_moneyCells[i]:getChildByName("Panel_1")
        local panel2 = self.m_moneyCells[i]:getChildByName("Panel_2")
        self:ShowMoneyInfo(moneyIds[idx+1],panel1)
        self:ShowMoneyInfo(moneyIds[idx+2],panel2)
    end
end

function RoleAttrUI:ShowMoneyInfo(id,cell)
    if cell == nil then
        return
    end
    if id == nil then
        cell:setVisible(false)
        return
    end
    local cfg = JsonConfig.m_Item.getDefByID(id)
    if cfg == nil then
        return
    end 
    local num = LRoleDataMgr:GetMoney(id)
    local iconImg = cell:getChildByName("icon")
    local nameLabel = cell:getChildByName("Text")
    local numLabel = nameLabel:getChildByName("value")
    local path = "item/equip"..cfg.pic..".png"
    Utils:SafeLoadTexture(iconImg,path,ccui.TextureResType.localType)
    nameLabel:setString(cfg.name..": ")
    numLabel:setString(""..num)
    numLabel:setPositionX(nameLabel:getAutoRenderSize().width+5)
end

function RoleAttrUI:ShowHead()
    local head = LRoleDataMgr.MyHeroInfo:GetHead()
    --print("RoleAttrUI:ShowHead",head)
    local strImage = Utils:GetHeroIconRes(head, AppDef.HeadIconResType.Square)
    Utils:SafeLoadTexture(self.m_headImg,strImage,ccui.TextureResType.localType)
end

function RoleAttrUI:ShowVipLv()
    local vipLv = 0
    local vipInfo = LRoleDataMgr.MyHeroInfo.MyVIPInfo
    if vipInfo ~= nil then
        vipLv = vipInfo.vipLevel
    end
    self.m_vipLabel:setString(""..vipLv)
end

function RoleAttrUI:ShowRoleName()
    self.m_pNameLabel:setString(LRoleDataMgr.MyHeroInfo.name)
end

function RoleAttrUI:ShowPower()
    self.m_pPowerLabel:setString(Utils:getPowerStr(LRoleDataMgr.MyHeroInfo.zhanDouLiInAll))
end

function RoleAttrUI:ShowRoleFaction()
    if LRoleDataMgr.Faction.Info.id == 0 then
        self.m_pFunctionLabel:setString(GUITips.Common_None)
    else
        self.m_pFunctionLabel:setString(LRoleDataMgr.Faction.Info.name)
    end
end

function RoleAttrUI:ShowRoleId()
    local id = LRoleDataMgr.MyHeroInfo.id
    self.m_pIdLabel:setString("" .. id)
end

-- function RoleAttrUI:ShowRoleZhiye()
--     local zhiye  = LRoleDataMgr.MyHeroInfo.professional

--     AppDef:ShowHeroProAttrImg(self.m_pZhiyeImg, zhiye)

--     local str = AppDef:GetHeroProfessionalName(zhiye)
--     self.m_pZhiyeLabel:setString(str)
-- end

function RoleAttrUI:ShowRoleLv()
    local lv = LRoleDataMgr.MyHeroInfo.level
    self.m_pLvLabel:setString("" .. lv)
end

function RoleAttrUI:ShowRoleHp()
    local data = LRoleDataMgr.MyHeroInfo
    if data.DetailData == nil or data.DetailData.attrs == nil then
        self.m_pHpLabel:setString("0/0")
        self.m_pHpBar:setPercent(0)
        return
    end
    local maxHp = data.DetailData.attrs [AppDef.EAttrType.EAT_HP]
    if maxHp == nil or maxHp == 0 then
        self.m_pHpLabel:setString(""..data.DetailData.hp.."/0")
        self.m_pHpBar:setPercent(0)
        return
    end
    local hpRate = data.DetailData.hp/data.DetailData.attrs [AppDef.EAttrType.EAT_HP]
    if hpRate < 0 or hpRate > 1 then
        hpRate = 0
    end
    hpRate = hpRate * 100
    self.m_pHpBar:setPercent(hpRate)
    --hpRate = math.floor(hpRate*100)
    local hp = string.format("%d/%d", data.DetailData.hp, data.DetailData.attrs [AppDef.EAttrType.EAT_HP])
    -- local len = string.len(tmp07) 
    -- if len > 12 then
    --     tmp07 = string.format("%d\n/%d", data.DetailData.hp, data.DetailData.hpMax)
    -- end    

    self.m_pHpLabel:setString(hp)
end

function RoleAttrUI:ShowRoleExp()
    local data = LRoleDataMgr.MyHeroInfo

    local nextExp = LDataConstMgr:GetHeroLevelUpExp(data.level)
    local expRate = data.DetailData.exp/nextExp
    if expRate < 0 or expRate > 1 then
        expRate = 0
    end
    expRate = expRate * 100
    self.m_pExpBar:setPercent(expRate)
    local hp = string.format("%d/%d", data.DetailData.exp, nextExp)   
    self.m_pExpLabel:setString(hp)
end

function RoleAttrUI:ShowTitle()
    local id = LRoleDataMgr.MyHeroInfo.MedalId
    --print("RoleAttrUI:ShowTitle",id)
    if id == 0 then
        self.m_titleImg:setVisible(false)
        return
    end
    self.m_titleImg:setVisible(true)
    local strImage = "res/UI/cm_chenghao/chenghao".. id ..".png"
    Utils:SafeLoadTexture(self.m_titleImg,strImage,ccui.TextureResType.plistType)
end
-- ShowVersion()
--     local panel = self.m_pUILayer:getChildByName("UI_Login")
--     local versionLabel = panel:getChildByName("Versions")


--     local url = "Manifest/ad"..GameSdk.ChannelId.."/version.manifest"
--     local str = cc.FileUtils:getInstance():getStringFromFile(url)
--     local versionManifest = json.decode(str,1)

--     local verStr = string.format(GUITips.Version, versionManifest["showVersion"])
--     versionLabel:setString(verStr)
-- end

return RoleAttrUI