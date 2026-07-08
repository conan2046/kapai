local XueZhanAttrSelectUI = LUIBase:New()
XueZhanAttrSelectUI.__index = XueZhanAttrSelectUI
XueZhanAttrSelectUI.IsHideInBattle = true
function XueZhanAttrSelectUI:New(userData)
    local o = LUIBase:New()
    setmetatable(o,XueZhanAttrSelectUI) 
    o:Init(userData)
    return o
end

function XueZhanAttrSelectUI:Init(userData)
    self.Script = "XueZhan.XueZhanAttrSelectUI"
    self:CreateUINode("csd/xuezhan/Xuezhanshuxingxuanze.csb")
    -- self.m_pUILayer = cc.CSLoader:createNode("csd/xuezhan/Xuezhanshuxingxuanze.csb")
    local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)
    self:InitData(userData)
    self:ShowInfo()
    self:ShowAttr()

    --Utils:SendMsg(LUIFClassBgEvent.SetTitle, GUITips.UI_Title_XueZhan)
    --Utils:SendMsg(LUIRoleDataChangeEvent.BGVisible, false)
    --Utils:SendMsg(LUIFClassBgEvent.SetCloseCallback,handler(self,XueZhanAttrSelectUI.CloseUI))
end

function XueZhanAttrSelectUI:InitData(userData)
    self.m_op = userData or 10
    self.m_bufs = nil
    self.m_startLabel = self.m_pUILayer:getChildByName("shuxingxuanzeUI"):getChildByName("Tips"):getChildByName("Star"):getChildByName("Num")
    self.m_starLabels = {}
    self.m_attrLabels = {}
    self.m_attrTypeLabels = {}
    self.m_attrValLabels = {}
    for i=1,3 do
        local btn = self.m_pUILayer:getChildByName("shuxing"..i)
        btn.userObject = i
        btn:addClickEventListener(handler(self, XueZhanAttrSelectUI.OnClick))

        self.m_starLabels[i] = btn:getChildByName("Star"):getChildByName("Num")
        local itemPanel = btn:getChildByName("Item")
        --self.m_attrLabels[i] = itemPanel:getChildByName("shuxingicon"):getChildByName("Name")
        self.m_attrTypeLabels[i] = itemPanel:getChildByName("shuxing")
        self.m_attrValLabels[i] = self.m_attrTypeLabels[i]:getChildByName("Value")
    end

    --已有buff显示
    self.m_attrPanel = self.m_pUILayer:getChildByName("Info")
    self.m_attrPanel:setVisible(false)
    self.m_typeLabels = {}
    self.m_valLabels = {}
    for i=1,10 do
        self.m_typeLabels[i] = self.m_attrPanel:getChildByName("jichu"):getChildByName("Attribute_"..i)
        self.m_valLabels[i] = self.m_typeLabels[i]:getChildByName("Value")
    end
end

function XueZhanAttrSelectUI:OnClick(sender)
    local idx = sender.userObject
    if idx == nil or idx < 1 or idx > 3 then
        return
    end
    --print("XueZhanAttrSelectUI:OnClick",idx)
    local data = LActivityManager:GetXueZhanData()
    if self.m_bufs[idx].star > self.m_curStar and idx > 1 then
        local str = GUITips.RSI_XUEZHAN_TIP20
        Utils:ShowScrollTips(str)
        return
    end
    LuaNetSendMsg:SendXueZhanBuffReq(self.m_op,idx)
    --选择
    self:CloseUI()
end

function XueZhanAttrSelectUI:ShowInfo()
    local data = LActivityManager:GetXueZhanData()
    if self.m_bufs == nil then
        self.m_bufs = data.m_bufs
        if self.m_op == 14 and data.m_sweepInfo ~= nil then
            self.m_bufs = data.m_sweepInfo.bufs or {}
        end
    end
    local max = math.max(3,#self.m_bufs)
    for i=1,max do
        if self.m_bufs[i] ~= nil then
            self.m_starLabels[i]:setString(self.m_bufs[i].star)
            --self.m_attrLabels[i]:setString(GUIAttrAd[self.m_bufs[i].attrType])
            self.m_attrTypeLabels[i]:setString(self:GetAttrTypeStr(self.m_bufs[i].attrType))
            self.m_attrValLabels[i]:setString("+"..self:GetAttrValStr(self.m_bufs[i].attrType,self.m_bufs[i].attrVal)) 
            local posX = self.m_attrTypeLabels[i]:getAutoRenderSize().width
            self.m_attrValLabels[i]:setPositionX(posX+3)
        else
            self.m_starLabels[i]:setString("")
            --self.m_attrLabels[i]:setString("")
            self.m_attrTypeLabels[i]:setString("")
            self.m_attrValLabels[i]:setString("")
        end   
    end
    self:ShowCurStart()
end

function XueZhanAttrSelectUI:ShowCurStart()
    local data = LActivityManager:GetXueZhanData()
    local star = data.m_curStar or 0
    if self.m_op == 14 then
        --print("ShowCurStart ShowCurStart ShowCurStart star1==>",star,data.m_sweepLevelId)
        local stars = {}
        local val = 3
        local max = 9
        local configData = JsonConfig.m_config.getDefByID(3)
        if configData ~= nil then
            val = tonumber(configData.value)
        end
        configData = JsonConfig.m_config.getDefByID(2)
        if configData ~= nil then
            stars = json.decode(configData.value)
        end
        if #stars > 0 then
            max = stars[#stars]
        end
        local levelId = data.m_sweepLevelId%100
        local cnt = math.floor(levelId/val)
        local num = levelId%val
        star = star-((cnt-data.m_sweepInfo.bufIdx-1)*val+num)*max
        --print("ShowCurStart ShowCurStart ShowCurStart star2==>",star,levelId,cnt,num,data.m_sweepInfo.bufIdx)
        if star < 0 then
            star = 0
        end
    end
    self.m_startLabel:setString(star)
    self.m_curStar = star
end

function XueZhanAttrSelectUI:ShowAttr()
    local data = LActivityManager:GetXueZhanData()
    if data.m_attrs == nil or #data.m_attrs == 0 then
        return
    end
    self.m_attrPanel:setVisible(true)
    for i=1,10 do
        local attr = data.m_attrs[i]
        if attr == nil then
            self.m_typeLabels[i]:setString("")
            self.m_valLabels[i]:setString("")
        else
            self.m_typeLabels[i]:setString(GUIAttrAd[attr.type]..":")
            self.m_valLabels[i]:setString("+"..self:GetAttrValStr(attr.type,attr.val))
            local posX = self.m_typeLabels[i]:getAutoRenderSize().width
            self.m_valLabels[i]:setPositionX(posX+2)
        end 
    end
end

function XueZhanAttrSelectUI:GetAttrTypeStr(attrType)
    local attrData = LDataConstMgr:GetAttrConfigData(attrType)
    if attrData == nil then
        return ""
    end
    return attrData.attrName
end

function XueZhanAttrSelectUI:GetAttrValStr(attrType,attrVal)
    if attrVal == nil then
        return ""
    end
    local ratio = false
    if attrType ~= nil and attrType > AppDef.EAttrType.EAT_RESISIT_CRIT then
        ratio = true
    end
    
    local attrValueStr = ""
    if ratio then
        attrValueStr = tostring(attrVal / 100) .. "%"
    else
        attrValueStr = tostring(attrVal)
    end
    return attrValueStr
end

function XueZhanAttrSelectUI:CloseUI()
    LGameMsg.m_deleteUIMsg:ChangeWithMsgId(LUILogicEvent.DeleteUI, "XueZhan.XueZhanAttrSelectUI")
    self:SendMsg(LGameMsg.m_deleteUIMsg)
end

function XueZhanAttrSelectUI:onExit()
    self:Destory()
    self.m_pUILayer = nil
    self.m_pNode = nil
    self.Script  = nil
end

return XueZhanAttrSelectUI