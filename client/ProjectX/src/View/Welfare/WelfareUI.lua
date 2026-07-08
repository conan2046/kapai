--  ----------------------------------------------
-- 福利UI逻辑

local WelfareUI = LUIBase:New()
WelfareUI.__index = WelfareUI
-- ----------------------------------------------
local _WC = require("View.Welfare.WelfareConfig")
-- ----------------------------------------------
-- 常量区
local ScriptPath = "Welfare.WelfareUI"
local CsbFilePath = "csd/WelfareLayer.csb"

-- ---------------------------------
local _DEBUG = false
-- ----------------------------------------------
-- local function Debug(msg)
--     if not _DEBUG then return end
--     
-- end
-- ----------------------------------------------
local function _ShowImage(image , show)
    local show = show or false 
    image:setVisible(show)
end
-- ----------------------------------------------
local function _DrawTexture(image, texture, type)
    local type = type or ccui.TextureResType.localType
    image:loadTexture(texture, type)
end
-- ----------------------------------------------
local function _DrawText(text, str)
    if text == nil then
        return 
    end
    text:setString(str)
end
-- ----------------------------------------------
local function _ShowTipsWindow(ui, msg)
    LGameMsg.m_scrollTipsMsg:ChangeWithMsgId(LUILogicEvent.ShowSrcollTips, msg)
    ui:SendMsg(LGameMsg.m_scrollTipsMsg)
end
-- ----------------------------------------------
local function _BindClickFunctionToButton(btn,fuc)
    btn:addClickEventListener(fuc)
	WelfareUI:MarkIntaractCObj(btn)
end
-- ----------------------------------------------
function WelfareUI:New(ind)
    local o = LUIBase:New()
    setmetatable(o, WelfareUI)
    o:Init(ind)
    return o
end
-- ----------------------------------------------
function WelfareUI:RegistMsgs()
    self.msgIds = 
    {
        LUIOnlineAwardEvent.KaifuReddotRefresh,
        LUIRedDotEvent.UpdateRedDotState,
    }
    self:RegistSelf(self,self.msgIds)
end
-- ----------------------------------------------
function WelfareUI:ProcessEvent(msg)
    if msg.msgId == LUIOnlineAwardEvent.KaifuReddotRefresh then
        LRedDotCheckMgr:MainWelfareCheck(msg.value)
    elseif msg.msgId == LUIRedDotEvent.UpdateRedDotState then
        local data = msg.value
        if data == nil then
            return
        end
        if data.id >= RedDotDef.ID.FLDengLu and data.id <= RedDotDef.ID.FLZaiXian then
            local typeId = data.id - RedDotDef.ID.FLDengLu + 1
            local ind = _WC:GetIndexByTypeId(typeId)
            --print("ProcessEvent ind", data.id, typeId, ind)
            local _ = self.btns[ind] and self.btns[ind]:getChildByName("Prompt"):setVisible(data.isShow)
        end
    end
end
-- -----------------------------------
function WelfareUI:onExit()
    self:Destory()
    self.m_pUILayer = nil
    self.rpanel = nil
    self.lpanel = nil
    self.m_pSubLayer = nil
end
-- ----------------------------------------------
function WelfareUI:RegisterQuik()
    local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)

    -- function closeCallback()
    --     LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, ScriptPath)
    --     self:SendMsg(LGameMsg.m_initUIMsg)
    -- end
    -- LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.SetCloseCallback, closeCallback)
    -- self:SendMsg(LGameMsg.m_baseMsgWithOne)
end
-- ----------------------------------------------
function WelfareUI:Init(ind)
    self.m_initTab = ind or 1
    self.m_initTab = math.max(self.m_initTab, 1)
    self:RegistMsgs()
    self:InitViewSize()
    self:InitUIControl()
    self:RegisterQuik()
    self:DrawWindowTitle()
    self:changeSelect(self.m_initTab)

    LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.AddTabBtn, nil)
    self:SendMsg(LGameMsg.m_baseMsgWithOne)
end
-- -----------------------------------
function WelfareUI:DrawWindowTitle()
    -- LGameMsg.m_baseMsgWithOne:Change(LUIFClassBgEvent.SetTitle, GUITips.UI_WELFARE_TITLE)
    -- self:SendMsg(LGameMsg.m_baseMsgWithOne)
end
-- ----------------------------------------------
function WelfareUI:InitViewSize()
    self.m_pUILayer = cc.CSLoader:createNode(CsbFilePath)
    local RootPanel = self.m_pUILayer:getChildByName("WelfareUI")
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)
end
-- ----------------------------------------------
function WelfareUI:InitUIControl()
    self:InitLeftPanel()
    self:InitRightPanel()

    -- ========================
    -- 关闭
    local rootnode = self.m_pUILayer:getChildByName("WelfareUI")
    local closebtn = rootnode:getChildByName("Bg"):getChildByName("btn_Close")
    
    local function OnCloseButtonClick(btn)
        LGameMsg.m_initUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, ScriptPath)
        self:SendMsg(LGameMsg.m_initUIMsg)
    end 
    _BindClickFunctionToButton(closebtn, OnCloseButtonClick)
end
local rpanel_tv_tagid = 1886
-- ----------------------------------------------
function WelfareUI:InitLeftPanel()
    local rp = self.m_pUILayer:getChildByName("WelfareUI")
    if self.lpanel == nil then self.lpanel = {} end
    self.lpanel.list_view = rp:getChildByName("ListView")
    self.lpanel.list_view:setScrollBarEnabled(false)
    self.lpanel.lv_cell_template = rp:getChildByName("Item")
    self.lpanel.lv_cell_template:setSelected(false)
    --self.lpanel.cur_type_id = _WC.WelfareTypeInfos[1].type_id
    self.lpanel.cur_type_id = 0
    self.btns = {}
    -- ===============================
    -- 添加按钮
    -- _WC:Init()
    -- if _WC:GetIndexByTypeId(self.m_initTab) == 0 then
    --     self.m_initTab = _WC.WelfareTypeInfos[1].type_id
    -- end
    for i = 1, #_WC.WelfareTypeInfos do
        local type_id = _WC.WelfareTypeInfos[i].type_id
        local t = self.lpanel.lv_cell_template
        local b = t:clone()
        if self.m_lastBtn == nil then
            self.m_lastBtn = b
            self.m_lastBtn:setSelected(true)
        end
        b:setTag(rpanel_tv_tagid + type_id)
        local name = _WC.WelfareTypeInfos[i].type_name
        b:getChildByName("Name"):setString(name)
        local func = self:SwapButtonClickFunc(type_id)
        b:addEventListener(func)
        
        local index = _WC:GetIndexByTypeId(type_id)
        self.btns[index] = b
        local show = LRedDotCheckMgr:MainWelfareCheck(type_id)
        b:getChildByName("Prompt"):setVisible(show)
    end

    for i=1, #self.btns do
        self.lpanel.list_view:pushBackCustomItem(self.btns[i])
    end
    if self.m_initTab == 5 or self.m_initTab == 8 then
       self.lpanel.list_view:jumpToBottom() 
    end
end
-- ----------------------------------------------
function WelfareUI:changeSelect(type_id)
    self.m_lastBtn:setSelected(false)
    local index = _WC:GetIndexByTypeId(type_id)
    self.m_lastBtn = self.btns[index]
    self.m_lastBtn:setSelected(true)
    if type_id == 1 then--登录礼包
        self:OnLoginClicked(type_id)
    elseif type_id == 2 then--等级礼包
        self:OnLevelClicked(type_id)
    elseif type_id == 3 then--每日签到
        self:OnDailySignClicked(type_id)
    elseif type_id == 4 then--白金会员
        self:OnPlatiNumClicked(type_id)
    -- elseif type_id == 5 then--离线经验
    --     self:OnOfflineClicked(type_id)
    elseif type_id == 6 then--资源找回
        print("======================================================>")
        LRoleDataMgr.m_resRecoveryClicked = true
        local _ = self.btns[type_id] and self.btns[type_id]:getChildByName("Prompt"):setVisible(false)
        self:OnOfflineClicked(type_id)
    elseif type_id == 7 then--在线奖励
        self:OnOnLineClicked(type_id)
    elseif type_id == 8 then--兑换奖励
        self:OnOnLineClicked(type_id)
    end
end
-- ----------------------------------------------
function WelfareUI:SwapButtonClickFunc(btn_type)
    return function(btn)
        local type_id = btn:getTag() - rpanel_tv_tagid
        --dump(type_id, "type_id--->")
        self:changeSelect(type_id)
    end
end
-- ----------------------------------------------
function WelfareUI:OnOnLineClicked(type_id)
    if type_id == self.lpanel.cur_type_id then 
        --Debug("重复显示内容")
        return
    end
    self:HidCurrneSubUI(type_id)
    if self.m_pSubLayer[type_id] == nil then
        self:DelayLoadSubUI(type_id)
    else
        self.m_pSubLayer[type_id].m_pUILayer:setVisible(true)
    end
end
-- ----------------------------------------------
function WelfareUI:OnOfflineClicked(type_id)
    if type_id == self.lpanel.cur_type_id then 
        --Debug("重复显示内容")
        return
    end
    self:HidCurrneSubUI(type_id)
    if self.m_pSubLayer[type_id] == nil then
        self:DelayLoadSubUI(type_id)
    else
        self.m_pSubLayer[type_id].m_pUILayer:setVisible(true)
    end
end
-- ----------------------------------------------
function WelfareUI:OnPlatiNumClicked(type_id)
    if type_id == self.lpanel.cur_type_id then 
        --Debug("重复显示内容")
        return
    end
    self:HidCurrneSubUI(type_id)
    if self.m_pSubLayer[type_id] == nil then
        self:DelayLoadSubUI(type_id)
    else
        self.m_pSubLayer[type_id].m_pUILayer:setVisible(true)
    end
end
-- ----------------------------------------------
function WelfareUI:OnDailySignClicked(type_id)
    if type_id == self.lpanel.cur_type_id then 
        --Debug("重复显示内容")
        return
    end
    self:HidCurrneSubUI(type_id)
    if self.m_pSubLayer[type_id] == nil then
        self:DelayLoadSubUI(type_id)
    else
        self.m_pSubLayer[type_id].m_pUILayer:setVisible(true)
    end
end
-- ----------------------------------------------
function WelfareUI:HidCurrneSubUI(type_id)
    local tid = self.lpanel.cur_type_id
    if  self.m_pSubLayer[tid] then  
        self.m_pSubLayer[tid].m_pUILayer:setVisible(false)
    end 
    self.lpanel.cur_type_id = type_id
end
-- ----------------------------------------------
function WelfareUI:DelayLoadSubUI(type_id)
    local uiscript = _WC:GetConfByTypeId(type_id).uiscript
    if uiscript == "" then 
        --Debug("找不到ui脚本,检查福利配置文件")
        return 
    end

    local delay = cc.DelayTime:create(0.1)
    local function loadSubUI()
        self.m_pSubLayer[type_id] = require(uiscript):New()
        self.m_pUILayer:addChild(self.m_pSubLayer[type_id].m_pUILayer)
    end
    local func = cc.CallFunc:create(loadSubUI)
    local sequence = cc.Sequence:create(delay, func)
    self.m_pUILayer:runAction(sequence)
end
-- ----------------------------------------------
function WelfareUI:InitRightPanel()
    if self.m_pSubLayer == nil then self.m_pSubLayer = {} end
end
-- ----------------------------------------------
function WelfareUI:OnLevelClicked(type_id)
    if type_id == self.lpanel.cur_type_id then 
        --Debug("重复显示内容")
        return
    end
    self:HidCurrneSubUI(type_id)
    if self.m_pSubLayer[type_id] == nil then
        self:DelayLoadSubUI(type_id)
    else
        self.m_pSubLayer[type_id].m_pUILayer:setVisible(true)
    end
end
-- ----------------------------------------------
function WelfareUI:OnLoginClicked(type_id)
    if type_id == self.lpanel.cur_type_id then 
        --Debug("重复显示内容")
        return
    end
    self:HidCurrneSubUI(type_id)
    if self.m_pSubLayer[type_id] == nil then
        self:DelayLoadSubUI(type_id)
    else
        self.m_pSubLayer[type_id].m_pUILayer:setVisible(true)
    end
end
-- ----------------------------------------------
return WelfareUI



