--[[
lua里面的游戏逻辑控制
]]

local ProFirstClassBg = LUIBase:New()
ProFirstClassBg.__index = ProFirstClassBg
--local this = LTcpSocket
ProFirstClassBg.BtnFontColor = 
{
    Selected = cc.c3b(0xbe,0x63,0x3a),
    UnSelected = cc.c3b(0x78,0x53,0x3f),
    Disable = cc.c3b(0x4d,0x4d,0x4d), 
}
function ProFirstClassBg:New()
	local o = LUIBase:New()
	setmetatable(o,ProFirstClassBg)	
    o:Init()
	return o
end

function ProFirstClassBg:Init()
    --self.m_pNode = cc.Node:create()

    self.m_pUILayer = cc.CSLoader:createNode("csd/shop/shop_bg.csb")
    self.m_pUILayer:setContentSize(AppDef.frameSize)
    ccui.Helper:doLayout(self.m_pUILayer)
   -- self:addChild(self.m_pUILayer)
   local function onNodeEvent(event)        
        if "exit" == event then
            self:onExit()
        end
    end
    self.m_pUILayer:registerScriptHandler(onNodeEvent)

    -- local imd = ImodAnim:createWithFileSync("item/equipLight")
    -- self.m_pUILayer:addChild(imd)
    -- imd:PlayActionRepeat(0,0.1)
    
    self:InitData()
    self:RegistMsgs()
    --self:ShowVersion()
    ------------------------------------------------------------------------
end

function ProFirstClassBg:CloseCallback(sender)
    self.m_pHelpBtn:setVisible(false)
    if self.m_pClassCallback then
        local func = self.m_pClassCallback
        self.m_pClassCallback = nil
        local _ = func and (type(func) == 'function') and func()
    end

end

function ProFirstClassBg:InitData()
    local panel = self.m_pUILayer:getChildByName("shopBg")
    local Popup = panel:getChildByName("Popup")
    local titlePanel = Popup:getChildByName("Title")
    local closeBtn = Popup:getChildByName("Btn_close")
    self.m_pCloseBtn = closeBtn
    closeBtn:addClickEventListener(handler(self, ProFirstClassBg.CloseCallback))
	--self:MarkIntaractCObj(closeBtn)

    self.m_pTitleLabel = titlePanel:getChildByName("Title")
    self.m_pHelpBtn= self.m_pTitleLabel:getChildByName("Button_1")

    self._Image1 = Popup:getChildByName("bg"):getChildByName("Image1")

    self.m_pTabBtnList = panel:getChildByName("Btn_ListView")
	self.m_pTabBtnList:setTouchEnabled(true)
    self.m_pTabBtn = self.m_pTabBtnList:getChildByName("Panel_1")
    self.m_pTabBtn:retain()
    self.m_pTabBtn:removeFromParent()
    self.m_pTabBtns = {}
    self.m_pTabFunc = nil
    -- self.m_pTabTailImg = self.m_pTabBtnList:getChildByName("ImageTitle3")
    -- self.m_pTabTailImg:retain()
    -- self.m_pTabTailImg:removeFromParent()

    self.m_curTabInd = 0
    self.m_strTitle = ""
    self.m_pTabValues = nil
end

function ProFirstClassBg:setCashValue( ... )
    -- body
    local myMoney = Utils:getGoldStr()
    self._coin:setString(myMoney)

    local myGold = LRoleDataMgr.MyHeroInfo.DetailData:GetTongBao()
    self._Gold:setString(myGold)

    local myTili = LRoleDataMgr.MyHeroInfo:GetDetailData():getTili()
    self._TiLi:setString(myTili)
end

function ProFirstClassBg:SetBgVisible(visible, clearData, isCheckMainUI)
    if clearData == nil then
        clearData = true
    end
    if isCheckMainUI == nil then
        isCheckMainUI = true
    end
    self.m_pUILayer:setVisible(visible)
    if visible == false and clearData == true then
        self.m_pClassCallback = nil
        self.m_pTitleLabel:setString("")
        self:ClearTabBtns()
    end
    if isCheckMainUI == false then
        return
    end
    local msg = LMsgBase:New()
    if visible then
        msg:ChangeEventId(LUIMainEvent.HideUI)
        self:SendMsg(msg)
    else
        msg:ChangeEventId(LUIMainEvent.ShowUI)
        self:SendMsg(msg)
    end
    msg = nil
end

function ProFirstClassBg:ClearTabBtns()
    
    -- for i = 1,#self.m_pTabBtns do
    --     self.m_pTabBtns[i]:removeFromParent()
    -- end
    self.m_pTabBtnList:removeAllItems()
    if self.m_pTabValues ~= nil then
        Utils:FreeTable(self.m_pTabBtns)
    end
    if self.m_pTabValues ~= nil then
        Utils:FreeTable(self.m_pTabValues)
    end
    self.m_pTabBtns = {}
    -- self.m_pTabTailImg:removeFromParent()
    self.m_curTabInd = 0
    --
    self.m_pTabValues = nil
    self.m_pTabFunc = nil
end

function ProFirstClassBg:touchTab(ind)
    if self.m_pTabFunc then
        local result = self.m_pTabFunc(ind)
        print("ProFirstClassBg:touchTab ==>", result)
        if result == nil or result == true then
            self:SetSelectedTab(ind)
        end
        
    end
end

function ProFirstClassBg:RemoveTabBtn()
    self.m_pTabValues = nil
    self.m_pTabBtns = {}
end
function ProFirstClassBg:AddTabBtn(tabValues)
    --[[
    {tabName1,tabName2,...},
    callback
    ]]
    self:ClearTabBtns()
    if tabValues == nil or #tabValues == 0 then
        self.m_pTabValues = nil
        self.m_pTabBtns = {}
        return
    end
    self.m_pTabValues = tabValues
    self.m_curTabInd = 0
    self.m_pTabFunc = tabValues[2]

    local function tablefunc(sender)
        local ind = sender:getTag()
        self:touchTab(ind)
    end

    for i = 1,#tabValues[1] do
        local tab = self.m_pTabBtn:clone()
        local btn = tab:getChildByName("Button")
        btn:setTag(i)
        local label = btn:getChildByName("BtnName")
        label:setColor(ProFirstClassBg.BtnFontColor.UnSelected)
        -- label:setVisible(false)
        label:setString(tabValues[1][i])

        local chooseBg = btn:getChildByName("ChooseBg")
        local chooseName = chooseBg:getChildByName("BtnName")
        chooseName:setString(tabValues[1][i])
        chooseBg:setVisible(false)

        local redPoint = btn:getChildByName("Prompt")
        redPoint:setVisible(false)

        btn:addClickEventListener(tablefunc)
		--self:MarkIntaractCObj(btn)
        self.m_pTabBtnList:pushBackCustomItem(tab)

        table.insert(self.m_pTabBtns,tab)
    end
    -- self.m_pTabBtnList:pushBackCustomItem(self.m_pTabTailImg)
end

--[[
注册UI消息
]]
function ProFirstClassBg:RegistMsgs()
    self.msgIds = 
    {
        LUIPopFClassBgEvent.SetTitle,
        LUIPopFClassBgEvent.SetCloseCallback,
        LUIPopFClassBgEvent.AddTabBtn,
        LUIPopFClassBgEvent.RemoveTabBtn,
        LUIPopFClassBgEvent.SelectTab,
        LUIPopFClassBgEvent.ChangeTab,
        LUIPopFClassBgEvent.RedDotState,
        LUIPopFClassBgEvent.GetTabBtn,
        LUIPopFClassBgEvent.GetCloseBtn,
        LUIPopFClassBgEvent.RegisterCloseGuide,
        LUIPopFClassBgEvent.RegisterTabGuide,
        LUIPopFClassBgEvent.HelpBtn,
        -- LUILoginEvent.RecvServerList,
        -- LUILoginEvent.RecvRoleServerList,
        -- LUILoginEvent.LoginSuccess,
        LUIRoleDataChangeEvent.MoneyChanged,
        LUIRoleDataChangeEvent.TongBaoChanged,
        LUIRoleDataChangeEvent.TiliChanged,
        LUIRoleDataChangeEvent.BGVisible,
        LUIPopFClassBgEvent.ChangeBg,
        LUIPopFClassBgEvent.ResetBg,
    }
    self:RegistSelf(self,self.msgIds)
end

-- function ProFirstClassBg:ClearBgData()
--     self.m_pTabValues = nil
--     --self.m_strTitle,self.m_pClassCallback,tableValues,self.m_curTabInd
-- end

function ProFirstClassBg:GetBgData()
    local tableValues = nil
    local tableRedPointFlags = nil
    if self.m_pTabValues ~= nil then
        tableValues = {{},self.m_pTabValues[2]}
        tableRedPointFlags = {}
        for i = 1,#self.m_pTabValues[1] do
            table.insert(tableValues[1], self.m_pTabValues[1][i])

            if self.m_pTabBtns[i] ~= nil then
                local btn = self.m_pTabBtns[i]:getChildByName("Button")
                table.insert(tableRedPointFlags, btn:getChildByName("Prompt"):isVisible())
            else
                table.insert(tableRedPointFlags, false)
            end
        end
    else
        tableValues = {}
        tableRedPointFlags = {}
    end
   
    return self.m_strTitle,self.m_pClassCallback,tableValues,tableRedPointFlags, self.m_curTabInd
end

function ProFirstClassBg:ResetBgData(data)

    self:SetTitle(data[1])
    self:AddCloseBtnCallback(data[2])
    self:AddTabBtn(data[3])
    self:SetTabBtnRedPoint(data[4])
    self:SetSelectedTab(data[5])
end

function ProFirstClassBg:SetTabBtnRedPoint(redPointFlags)
    if redPointFlags and type(redPointFlags) == 'table' then
        for i = 1,#redPointFlags do
            if self.m_pTabBtns[i] ~= nil then
                if redPointFlags[i] then
                    local btn = self.m_pTabBtns[i]:getChildByName("Button")
                    if btn ~= nil then
                        btn:getChildByName("Prompt"):setVisible(redPointFlags[i])
                    end
                end
            end
        end
    end
end

function ProFirstClassBg:ProcessEvent(msg)
    if msg.msgId == LUIPopFClassBgEvent.SetTitle then
        --[[
        默认设置title的时候重置tab页签数据，
        所以这个事件必须在LUIPopFClassBgEvent.AddTabBtn前发过来
        ]]
        self:SetTitle(msg.value)
    elseif msg.msgId == LUIPopFClassBgEvent.SetCloseCallback then
        self:AddCloseBtnCallback(msg.value)
    elseif msg.msgId == LUIPopFClassBgEvent.AddTabBtn then
        self:AddTabBtn(msg.value)
    elseif msg.msgId == LUIPopFClassBgEvent.RemoveTabBtn then
        self:RemoveTabBtn()
    elseif msg.msgId == LUIPopFClassBgEvent.SelectTab then
        self:SetSelectedTab(msg.value)
     elseif msg.msgId == LUIPopFClassBgEvent.ChangeTab then
        self:SetSelectedTab(msg.value)
        self:touchTab(msg.value)
    elseif msg.msgId == LUIPopFClassBgEvent.RedDotState then
        self:SetRedDotState(msg.value)
    elseif msg.msgId == LUIPopFClassBgEvent.GetTabBtn then
        self:getTabBtns(msg.value)
    elseif msg.msgId == LUIPopFClassBgEvent.GetCloseBtn then
        self:getCloseBtn(msg.value)
    elseif msg.msgId == LUIPopFClassBgEvent.RegisterCloseGuide then
        self:RegisterCloseGuide(msg.value)
    elseif msg.msgId == LUIPopFClassBgEvent.RegisterTabGuide then
        self:RegisterTabGuide(msg.value)
    elseif msg.msgId == LUIRoleDataChangeEvent.MoneyChanged then
        -- local myMoney = LRoleDataMgr.MyHeroInfo.DetailData:getMoney()
        -- self._coin:setString(myMoney)
    elseif msg.msgId == LUIRoleDataChangeEvent.TongBaoChanged then
        -- local myGold = LRoleDataMgr.MyHeroInfo.DetailData:GetTongBao()
        -- self._Gold:setString(myGold)
    elseif msg.msgId == LUIRoleDataChangeEvent.TiliChanged then
        -- local myTili = LRoleDataMgr.MyHeroInfo:GetDetailData():getTili()
        -- self._TiLi:setString(Utils:getTiliStr(myTili))
    elseif msg.msgId == LUIRoleDataChangeEvent.BGVisible then
        -- self.m_pUILayer:getChildByName("Panel_1"):getChildByName("Bg"):setVisible(msg.value)
        -- self.m_pTabBtnList:setVisible(msg.value)
    elseif msg.msgId==LUIPopFClassBgEvent.HelpBtn then
        self:initHelpBtn(msg.value)
    elseif msg.msgId== LUIPopFClassBgEvent.ChangeBg then

        local newImage = self._Image1:clone()
        newImage:setScale9Enabled(false)
        local filePath = msg.value.filePath
        local type = msg.value.resType
        print("================ 11111111111 >>>>", filePath, type)
        -- Utils:SafeLoadTexture(self._Image1,"res/UI/ui_bg/bg_shenjiangtujian.png", ccui.TextureResType.localType)
        Utils:SafeLoadTexture(newImage, filePath, type)
        self._Image1:getParent():addChild(newImage)
        newImage:setTag(0xf5)
        self._Image1:setVisible(false)
    elseif msg.msgId== LUIPopFClassBgEvent.ResetBg then
        self._Image1:setVisible(true)
        self._Image1:getParent():removeChildByTag(0xf5)
    end
end


function ProFirstClassBg:initHelpBtn(callback)
    self.m_pHelpBtn:setVisible(true)
    self.m_pHelpBtn:addClickEventListener(callback)
end

function ProFirstClassBg:SetSelectedTab(ind)

    if self.m_pTabBtns == nil then
        return
    end

    if ind == nil or ind > #self.m_pTabBtns or ind <= 0 then 
        return
    end
    if self.m_curTabInd == ind then
        return
    end
    
    if self.m_curTabInd > 0 and self.m_curTabInd <=  #self.m_pTabBtns then
        local btn =  self.m_pTabBtns[self.m_curTabInd]:getChildByName("Button")
        --btn:setBright(true)
        btn:setEnabled(true)

        local chooseBg = btn:getChildByName("ChooseBg")
        chooseBg:setVisible(false)

        -- local label = btn:getChildByName("BtnName")
        -- label:setColor(ProFirstClassBg.BtnFontColor.UnSelected)
    end
    self.m_curTabInd = ind
    local btn =  self.m_pTabBtns[self.m_curTabInd]:getChildByName("Button")
    btn:setEnabled(false)
    --btn:setBright(false)
    local chooseBg = btn:getChildByName("ChooseBg")
    chooseBg:setVisible(true)

    -- local label = btn:getChildByName("BtnName")
    -- label:setColor(ProFirstClassBg.BtnFontColor.Selected)

end

function ProFirstClassBg:SetRedDotState(value)
    local ind = value[1]
    local show = value[2]
    if self.m_pTabBtns[ind] == nil then return end
    local btn = self.m_pTabBtns[ind]:getChildByName("Button")
    if btn ~= nil then
        btn:getChildByName("Prompt"):setVisible(show)
    end
end

function ProFirstClassBg:SetTitle(title)
    if title == nil then
        return
    end
    if "string" == type(title) then
        self.m_strTitle = title
        self.m_pTitleLabel:setString(title)
    end
end

function ProFirstClassBg:AddCloseBtnCallback(func)
    self.m_pClassCallback = func
end

function ProFirstClassBg:onExit()
    self:Destory()
    self.m_pUILayer = nil
end

-- function ProFirstClassBg:ShowVersion()
--     local panel = self.m_pUILayer:getChildByName("UI_Login")
--     local versionLabel = panel:getChildByName("Versions")


--     local url = "Manifest/ad"..GameSdk.ChannelId.."/version.manifest"
--     local str = cc.FileUtils:getInstance():getStringFromFile(url)
--     local versionManifest = json.decode(str,1)

--     local verStr = string.format(GUITips.Version, versionManifest["showVersion"])
--     versionLabel:setString(verStr)
-- end

function ProFirstClassBg:getTabBtns(ret)
    ret = ret or {}
    for i=1,#self.m_pTabBtns do
        table.insert(ret, self.m_pTabBtns[i])
    end
end

function ProFirstClassBg:getCloseBtn(ret)
    ret = ret or {}
    ret.node = self.m_pCloseBtn
end

function ProFirstClassBg:RegisterCloseGuide(stepId)
    Utils:RegisterGuide(stepId, self.m_pCloseBtn, handler(self, ProFirstClassBg.CloseCallback), nil, true)
end

function ProFirstClassBg:RegisterTabGuide(msg)
    local stepId = msg.stepId
    local tabIndex = msg.tabIndex
    local callback = msg.callback

    if stepId == nil or tabIndex > #self.m_pTabBtns then
        return
    end
    if callback == nil then
        callback = function()
            self:touchTab(tabIndex)
        end
    end
    Utils:RegisterGuide(stepId, self.m_pTabBtns[tabIndex], callback, nil, true)
end

return ProFirstClassBg