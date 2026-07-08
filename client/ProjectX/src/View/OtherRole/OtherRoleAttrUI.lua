--[[
lua里面的游戏逻辑控制
]]

local OtherRoleAttrUI = LUIBase:New()
OtherRoleAttrUI.__index = OtherRoleAttrUI
--local this = LTcpSocket
function OtherRoleAttrUI:New()
	local o = LUIBase:New()
	setmetatable(o,OtherRoleAttrUI)	
    o:Init()
	return o
end


function OtherRoleAttrUI:Init()
    --self.m_pNode = cc.Node:create()

    self.m_pUILayer = cc.CSLoader:createNode("csd/zhujue/RoleShowLayer.csb")
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)
   -- self:addChild(self.m_pUILayer)
   local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
    self:RegistMsgs()
    self:InitData()
    self:ShowInfo()
end

--[[
注册UI消息
]]
function OtherRoleAttrUI:RegistMsgs()
    self.msgIds = 
    {
    }
    self:RegistSelf(self,self.msgIds)
end

function OtherRoleAttrUI:ProcessEvent(msg)
end

function OtherRoleAttrUI:onExit()
    self:Destory()
    self.m_pUILayer = nil
    self.m_petIconImgs = nil
    self.m_petNameLabels = nil
end

function OtherRoleAttrUI:InitData()
    local panel = self.m_pUILayer:getChildByName("Panel_12")
    --右上
    local attrPanel = panel:getChildByName("RoleAttribute")
    local baseAttrPanel = attrPanel:getChildByName("Attribute1")
    self.m_pIdLabel = baseAttrPanel:getChildByName("IDNum")
    self.m_pLvLabel = baseAttrPanel:getChildByName("RoleLevelNum")
    self.m_titleImg = baseAttrPanel:getChildByName("chenghao_layer"):getChildByName("TitleImage")
    
    self.m_pFunctionLabel = baseAttrPanel:getChildByName("GuildName")
    local expPanel = baseAttrPanel:getChildByName("RoleEXP")
    self.m_pExpBar = expPanel:getChildByName("ExpBar")
    self.m_pExpLabel = expPanel:getChildByName("ExpNum")
    local copyBtn = self.m_pIdLabel:getChildByName("Button_copy")
    copyBtn:addClickEventListener(function (sender)
        local id = LRoleDataMgr.OtherHeroInfo.id
        local app = cc.Application:getInstance()
        app:copyToClipboard(""..id)
    end)

    --右下
    local petPanel = panel:getChildByName("shenjiang_layer"):getChildByName("Attribute1")
    self.m_pPowerLabel = petPanel:getChildByName("RolePower"):getChildByName("RolePowerBase"):getChildByName("PowerNum")
    self.m_petNameLabels = {}
    self.m_petBtns = {}
    for i=1,5 do
        self.m_petBtns[i] = petPanel:getChildByName("bg_Head"..i)
        self.m_petBtns[i].userObject = i
        self.m_petBtns[i]:setTouchEnabled(true)
        self.m_petBtns[i]:addClickEventListener(handler(self,OtherRoleAttrUI.OpenPetUI))
        self.m_petNameLabels[i] = self.m_petBtns[i] :getChildByName("Name")
    end

    --左边
    local leftPanel = panel:getChildByName("Panel_left")
    self.m_pRoleNode = leftPanel:getChildByName("Node_1"):getChildByName("Node")
    self.m_pNameLabel = leftPanel:getChildByName("Name")
    self.m_pVipLabel = leftPanel:getChildByName("bg_VIP"):getChildByName("Value")

    self.m_btn1 = leftPanel:getChildByName("Button_1")
    self.m_btn2 = leftPanel:getChildByName("Button_2")
    self.m_btn3 = leftPanel:getChildByName("Button_3")
    self.m_btn4 = leftPanel:getChildByName("Button_4")
    self.m_btn1:addClickEventListener(handler(self,OtherRoleAttrUI.AddFriendCallBack))--加好友
    self.m_btn2:addClickEventListener(handler(self,OtherRoleAttrUI.ChatCallBack))--私聊
    self.m_btn3:addClickEventListener(handler(self,OtherRoleAttrUI.BlockCallBack))--拉黑
    self.m_btn4:addClickEventListener(handler(self,OtherRoleAttrUI.FightCallBack))--切磋

    self.m_starCell = petPanel:getChildByName("Star")

end

function OtherRoleAttrUI:ShowInfo( ... )
    self:ShowBaseInfo()
    self:ShowPetList()
    self:ShowButton()
end

function OtherRoleAttrUI:ShowBaseInfo()
    self:ShowRoleModel()
    self:ShowRoleName()
    self:ShowPower()
    self:ShowRoleId()
    self:ShowRoleLv()
    self:ShowRoleFaction()
    self:ShowRoleExp()
    self:ShowVip()
    self:ShowTitle()
end

function OtherRoleAttrUI:ShowRoleModel()
    local data = LRoleDataMgr.OtherHeroInfo
    -- local weaponId = data:GetWeaponId()
    -- local horseId = data:GetHorseId()
    -- local shenqiId = data:GetShenQiId()
    local sign = false
    if self.m_pRoleModel == nil then
        sign = true
    end
    self.m_pRoleModel = Utils:CreateBigRoleModel(data:GetModel(),self.m_pRoleModel)
    if sign then
        self.m_pRoleNode:addChild(self.m_pRoleModel)
        self.m_pRoleNode:setScale(0.7)
    end
end

function OtherRoleAttrUI:ShowRoleName()
    --print("OtherRoleAttrUI:ShowRoleName",LRoleDataMgr.OtherHeroInfo.name)
    self.m_pNameLabel:setString(LRoleDataMgr.OtherHeroInfo.name)
end

function OtherRoleAttrUI:ShowPower()
    self.m_pPowerLabel:setString(LRoleDataMgr.OtherHeroInfo.zhanDouLi)
end

function OtherRoleAttrUI:ShowRoleFaction()
    if LRoleDataMgr.OtherHeroInfo.DetailData.gongName == "" then
        self.m_pFunctionLabel:setString(GUITips.Common_None)
    else
        self.m_pFunctionLabel:setString(LRoleDataMgr.OtherHeroInfo.DetailData.gongName)
    end
end

function OtherRoleAttrUI:ShowRoleId()
    local id = LRoleDataMgr.OtherHeroInfo.id
    self.m_pIdLabel:setString("" .. id)
end


function OtherRoleAttrUI:ShowRoleLv()
    local lv = LRoleDataMgr.OtherHeroInfo.level
    self.m_pLvLabel:setString("" .. lv)
end

function OtherRoleAttrUI:ShowRoleExp()
    local data = LRoleDataMgr.OtherHeroInfo

    local nextExp = LDataConstMgr:GetHeroLevelUpExp(data.level)
    local expRate = data.DetailData.exp/nextExp
    if expRate < 0 or expRate > 1 then
        expRate = 0
    end
    expRate = expRate * 100
    self.m_pExpBar:setPercent(expRate)
    local hp = tostring(data.DetailData.exp).."/"..tostring(nextExp) 
    self.m_pExpLabel:setString(hp)
end

function OtherRoleAttrUI:ShowVip()
    local vipLv = LRoleDataMgr.OtherHeroInfo.vipLevel or 0
    self.m_pVipLabel:setString(""..vipLv)
end

function OtherRoleAttrUI:ShowTitle()
    local id = 0
    if LRoleDataMgr.OtherHeroInfo.MedalAddition ~= nil then
        id = LRoleDataMgr.OtherHeroInfo.MedalAddition.id or 0
    end
    --print("RoleAttrUI:ShowTitle",id)
    self.m_titleImg:setVisible(false)
    if id == 0 then
        return
    end
    self.m_titleImg:setVisible(true)
    local strImage = "res/UI/cm_chenghao/chenghao".. id ..".png"
    Utils:SafeLoadTexture(self.m_titleImg,strImage,ccui.TextureResType.plistType)
end

function OtherRoleAttrUI:ShowPetList()
    local info = LRoleDataMgr.OtherHeroInfo.VecFightPet
    --dump(info)
    if info == nil then
        return
    end
    for  i=1, 5 do
        data = info[i]
        self:ShowPet(i,data)
    end
end

function OtherRoleAttrUI:ShowPet(idx,data)
    if idx == nil or idx < 1 or idx > 5 then
        return
    end
    self.m_petBtns[idx]:setVisible(false)
    if data == nil or data.id == 0 then
        return
    end
    local cfg = LDataConstMgr:GetPetData(data.id)
    if cfg == nil then
        return
    end
    local headImg = self.m_petBtns[idx]:getChildByName("Icon")
    local colorImg = self.m_petBtns[idx]:getChildByName("Color")
    local lvLabel = self.m_petBtns[idx]:getChildByName("Value")
    local starList = self.m_petBtns[idx]:getChildByName("Stars")
    local listView = Utils:CreateListView(starList,LISTVIEW_DIR_HORIZONTAL,1)
    starList:setVisible(false)

    self.m_petBtns[idx]:setVisible(true)
    self.m_petNameLabels[idx]:setString(data.name)


    Utils:ShowPetHeadImg(headImg, cfg.pic, colorImg, cfg.quality)
    lvLabel:setString(""..data.level)
    --print("star",data.name,data.star)
    for i=1,data.star do
        local cell = self.m_starCell:clone()
        listView:pushBackCustomItem(cell)
    end
end

function OtherRoleAttrUI:OpenPetUI(sender)
    local idx = sender.userObject
    if idx == nil or idx < 1 or idx > 5 then
        return
    end
    LRoleDataMgr.OtherHeroInfo.m_PetIdx = idx
    LGameMsg.m_baseMsgWithOne:Change(LUILogicEvent.ChangeOtherTab, 2)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)
end

--加好友
function OtherRoleAttrUI:AddFriendCallBack(sender)
    local data = LRoleDataMgr.OtherHeroInfo
    if data == nil or data.id == nil or data.id == 0 or data.roleType == 1 then
        return
    end

    if LRoleDataMgr.Social:IsMyFriend(LRoleDataMgr.OtherHeroInfo.id) then

        local msg = GUITips.RSI_SOCIAL_DELETE_TIPS
        local okBtnName = GUITips.RSI_GS_TIP_RECOVERY_SURE;
        local cancelBtnName = GUITips.UI_Btn_Cancel;
        local function okFunc()
            LuaNetSendMsg:QuertDelFriend(data.id)
            LRoleDataMgr.Social:delFriend(data.id);
            self:ShowButton();
        end

        local function cancelFunc()
        end
        Utils:ShowDialogOKCancel(msg,okFunc,cancelFunc,okBtnName,cancelBtnName);
    elseif LRoleDataMgr.Social:IsInBlack(LRoleDataMgr.OtherHeroInfo.id) then
        LuaNetSendMsg:QueryDelBlack(data.id)
        LRoleDataMgr.Social:DelBlack(data.id);
        self:ShowButton();
    else
        LuaNetSendMsg:QueryAddFriend(data.id)
    end
    
end

--私聊
function OtherRoleAttrUI:ChatCallBack(sender)
    --打开私聊面板
    local data = LRoleDataMgr.OtherHeroInfo
    if data == nil or data.id == nil or data.id == 0 or data.roleType == 1 then
        return
    end
    Utils:SendMsg(LUIChatEvent.OpenPrivateChat, data)
    Utils:SendMsg(LUILogicEvent.DeleteUI, AppDef.FuncUI[AppDef.EModuleID.EMID_OTHER_ROLE_INFO].lua)
    Utils:SendMsg(LUILogicEvent.DeleteUI, AppDef.FuncUI[AppDef.EModuleID.EMID_FRIEND].lua)
end

--拉黑
function OtherRoleAttrUI:BlockCallBack(sender)
    local data = LRoleDataMgr.OtherHeroInfo
    if data == nil or data.id == nil or data.id == 0 or data.roleType == 1 then
        return
    end
    LuaNetSendMsg:QueryAddBlack(data.id);
    LRoleDataMgr.Social:delFriend(data.id);
    self:ShowButton();
end

--切磋
function OtherRoleAttrUI:FightCallBack(sender)
    local data = LRoleDataMgr.OtherHeroInfo
    if data == nil or data.id == nil or data.id == 0 or data.roleType == 1 then
        return
    end
    Utils:ShowScrollTips(string.format(GUITips.RSI_MACTH_TIPS,data.name))
    LuaNetSendMsg:QueryMatchWithPlayer(0, 1, data.id)
end

function OtherRoleAttrUI:ShowButton()
    for i=1,4 do
        self["m_btn"..i]:setVisible(false)
    end
    local data = LRoleDataMgr.OtherHeroInfo
    if data == nil or data.id == nil or data.id == 0 or data.roleType == 1 then
        return
    end
    for i=1,4 do
        self["m_btn"..i]:setVisible(true)
    end

    if LRoleDataMgr.Social:IsMyFriend(LRoleDataMgr.OtherHeroInfo.id) then
        self.m_btn1:getChildByName("Text"):setString(GUITips.RSI_SOCIAL_DELETE);
        self.m_btn3:setVisible(true);
    else
        self.m_btn1:getChildByName("Text"):setString(GUITips.RSI_SOCIAL_ADD);
        self.m_btn3:setVisible(true);
    end
end

return OtherRoleAttrUI