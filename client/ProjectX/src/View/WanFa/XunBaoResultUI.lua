local XunBaoResultUI = LUIBase:New()
XunBaoResultUI.__index = XunBaoResultUI
--local this = LTcpSocket
function XunBaoResultUI:New(userData)
	local o = LUIBase:New()
	setmetatable(o,XunBaoResultUI)	
    o:Init(userData)
	return o
end

--注册事件
-- -----------------------------------
function XunBaoResultUI:RegistMsgs()
    self.msgIds = 
    {
    }
    self:RegistSelf(self,self.msgIds)
end

-- -----------------------------------
function XunBaoResultUI:ProcessEvent(msg)

end

function XunBaoResultUI:Init(userData)

    self.m_pUILayer = cc.CSLoader:createNode("csd/wanfa/Xunbao_souxunLayer.csb")
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)

   local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
    self:RegistMsgs()
    self:InitData(userData)
    self:InitControlUI()
    self:UpdateUI()
    self:RegisterGuide()
end

function XunBaoResultUI:InitData( data )
    self.m_resultData = data[1] or {}
    self.m_isOneKey = data[2] or 0
    self.m_faBaoId = data[3] or 0
    self.m_suiId = data[4] or 0
end

function XunBaoResultUI:InitControlUI()
    -- body
    local panel = self.m_pUILayer:getChildByName("Souxun")

    self.m_listView = panel:getChildByName("Popup"):getChildByName("ListView")
    self.m_listView:setDirection(LISTVIEW_DIR_VERTICAL)
    self.m_cellResult = panel:getChildByName("Reward")
    self.m_cellItem = panel:getChildByName("Item")
    self.m_closeBtn = panel:getChildByName("Button_1")
    self.m_closeBtn:addClickEventListener(handler(self,XunBaoResultUI.BtnCallBack))
    self.m_btnLabel = self.m_closeBtn:getChildByName("Text")
    
    Utils:SendMsg(LUISecondClassBgEvent.SetCloseCallback, handler(self,XunBaoResultUI.ColseUI))
    Utils:SendMsg(LUISecondClassBgEvent.SetTitle, GUITips.RSI_XUNBAO_TIPS1)
end

function XunBaoResultUI:UpdateUI()
    self:ShowBtnText()
    self.m_curAddNum = 1
    self.m_listView:removeAllItems()
    self:AddSchedule()
end

function XunBaoResultUI:CheckOneKey()
    if self.m_faBaoId == 0 then
        return false
    end
    local cfg = JsonConfig.GetHeChengCfg(8,self.m_faBaoId) 
    if cfg == nil then
        return false
    end
    for i=1,cfg.item do
        local id = cfg.item[i][1]
        local num = LRoleDataMgr.Equip:CountItemNumById(id)
        if num < cfg.item[i][3] then
            return true
        end
    end
end

function XunBaoResultUI:CheckNomarl()
    if self.m_suiId == 0 then
        return false
    end
    local num = LRoleDataMgr.Equip:CountItemNumById(self.m_suiId)
    if num < 1 then
        return true
    end
    return false
end

function XunBaoResultUI:ShowBtnText()
    local str = GUITips.RSI_XUNBAO_TIPS2
    if self.m_isOneKey == 1 then
        if self:CheckOneKey() then
            str = GUITips.RSI_XUNBAO_TIPS3
        end
    else
        if self:CheckNomarl() then
            str = GUITips.RSI_XUNBAO_TIPS3
        end
    end
    self.m_btnLabel:setString(str)
end

function XunBaoResultUI:AddResult()
    -- body
    local resultData = self.m_resultData[self.m_curAddNum]
    local cell = self.m_cellResult:clone()
    cell.userObject = self.m_curAddNum
    self:ShowOneResult(cell,resultData)
    self.m_listView:pushBackCustomItem(cell)
    self.m_listView:jumpToBottom()
end

function XunBaoResultUI:ShowOneResult(sender,data)
    local idx = sender.userObject
    local cntLabel = sender:getChildByName("TitleBg"):getChildByName("Times")
    local tipsLabel = cntLabel:getChildByName("Text")
    cntLabel:setString(string.format(GUITips.RSI_FUBENMAP_RES16,idx))
    local listView = sender:getChildByName("ListView")
    listView:setTouchEnabled(false)
    listView:removeAllItems()
    if data == nil then
        return
    end
    local names = ""
    for i=1,#data.items do
        local cell = self.m_cellItem:clone()
        listView:pushBackCustomItem(cell)
        Utils:ShowItemByConfigData(data.items[i], cell, nil, false, isResize)

        local id = data.items[i][1]
        local num = data.items[i][3]
        local cfg = JsonConfig.m_Item.getDefByID(id)
        if cfg ~= nil and cfg.type == AppDef.ItemType.FaBaoFrag then
            local str = ""
            if #names > 0 then
                str = str..","
            end
            str = str..cfg.name.."x"..num
            names = names..str
        end
    end 
    if #names == 0 then
        tipsLabel:setString(GUITips.RSI_XUNBAO_TIPS4)
        return
    end
    tipsLabel:setString(string.format(GUITips.RSI_XUNBAO_TIPS5,names))
end

function XunBaoResultUI:DeleteSchedule()
    if self.m_refreshHandler ~= nil then
        Utils:unschedule(nil, self.m_refreshHandler)
        self.m_refreshHandler = nil
    end
end

function XunBaoResultUI:AddSchedule()
    self:DeleteSchedule()
    local function RefreshCallback(dt)
        if self.m_curAddNum <= #self.m_resultData then
            self:AddResult()
            self.m_curAddNum = self.m_curAddNum + 1
        elseif self.m_curAddNum == #self.m_resultData + 1 then
            self:DeleteSchedule() 
        end
    end
    self.m_refreshHandler = Utils:schedule(nil, RefreshCallback, 0.3, false)
end

function XunBaoResultUI:BtnCallBack()
    local sign = false
    if self.m_isOneKey == 1 then
        sign = self:CheckOneKey() 
    else
        sign = self:CheckNomarl() 
    end
    self:ColseUI()
    if sign then
        --打开次数道具购买界面
        local data = LActivityManager:GetXunBaoData()
        local cnt = data.m_buyCnt or 0
        Utils:OpenUseUI(402,1)--,"arenabuy"
    end
end

function XunBaoResultUI:ColseUI()
    Utils:DeleteUI("WanFa.XunBaoResultUI")
end

function XunBaoResultUI:onExit()
    Utils:SendMsg(LUIGuideEvent.UnRegisterStep,GuideDef.StepId.Guide_XunBao_5)
    self.m_pUILayer = nil
    self:DeleteSchedule()
    self:Destory()
    local data = LActivityManager:GetXunBaoData()
    data.m_records = {}
    Utils:CheckGuide(GuideDef.StepId.Guide_XunBao_6,true)
end

function XunBaoResultUI:RegisterGuide()
    Utils:SendMsg(LUISecondClassBgEvent.RegisterCloseGuide,GuideDef.StepId.Guide_XunBao_5)
end 

return XunBaoResultUI