--[[
lua里面的游戏逻辑控制
]]

local FirstClassBg = LUIBase:New()
FirstClassBg.__index = FirstClassBg
--local this = LTcpSocket
FirstClassBg.BtnFontColor = 
{
    Selected = cc.c3b(0xbe,0x63,0x3a),
    UnSelected = cc.c3b(0x78,0x53,0x3f),
    Disable = cc.c3b(0x4d,0x4d,0x4d), 
}
function FirstClassBg:New()
	local o = LUIBase:New()
	setmetatable(o,FirstClassBg)	
    o:Init()
	return o
end

function FirstClassBg:Init()
    --self.m_pNode = cc.Node:create()

    self.m_pUILayer = cc.CSLoader:createNode("csd/OneLevelLayer.csb")
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
    -- 元宝 金币 体力
    local GoldCheck = self.m_pUILayer:getChildByName("GoldCheck")
    self._cash = GoldCheck:findChildByName("GoldIcon4/GoldNumBg/Num")
    local cashAddBtn = GoldCheck:findChildByName("GoldIcon4/AddBtn")
    cashAddBtn:setEnabled(false)
    

    self._Gold =  GoldCheck:findChildByName("GoldIcon3/GoldNumBg/Num")
    local goldAddBtn = GoldCheck:findChildByName("GoldIcon3/AddBtn")
    goldAddBtn:addClickEventListener(function ( sender )
        Utils:OpenFunction(AppDef.EModuleID.EMID_SCCHANGYONG)
    end)



    self._TiLi = GoldCheck:findChildByName("GoldIcon1/GoldNumBg/Num")
    local tiliAddBtn = GoldCheck:findChildByName("GoldIcon1/AddBtn")
    tiliAddBtn:addClickEventListener(function ( sender )
        Utils:OpenUseUI(500,1)
    end)

    if LRoleDataMgr then
        local myMoney = LRoleDataMgr.MyHeroInfo.DetailData:GetTongBao()
        self._cash:setString(myMoney)
        local myGold = Utils:getGoldStr();
        self._Gold:setString(myGold)
        local tili = LRoleDataMgr.MyHeroInfo:GetDetailData():getTili()
        self._TiLi:setString(Utils:getTiliStr(tili))
    end
    
end

function FirstClassBg:CloseCallback(sender)
    self.m_pHelpBtn:setVisible(false)
    self:ShowDefaultBg()
    print("self.m_pClassCallback ==>", self.m_pClassCallback)
    if self.m_pClassCallback then
        local func = self.m_pClassCallback
        self.m_pClassCallback = nil
        local _ = func and (type(func) == 'function') and func()
    end
    print("FirstClassBg:CloseCallback(sender)")
	Utils:SendMsg(LUIFClassBgEvent.ResumeResourceData)
end

function FirstClassBg:InitData()
    local panel = self.m_pUILayer:getChildByName("Panel_12")
    local titlePanel = panel:getChildByName("Title")
    local closeBtn = titlePanel:getChildByName("CloseBtn")

	self.bg = self.m_pUILayer:getChildByName("Bg")
    self.bg:setTouchEnabled(true)

    self.bgResourceData = self.bg:getRenderFile();
    self.m_pCloseBtn = closeBtn
    closeBtn:addClickEventListener(handler(self, FirstClassBg.CloseCallback))
	--self:MarkIntaractCObj(closeBtn)

    self.m_pTitleLabel = titlePanel:getChildByName("TitleName")
    self.m_pHelpBtn=self.m_pTitleLabel:getChildByName("Button_1")
     self.m_pHelpBtn:addClickEventListener(handler(self,FirstClassBg.HelpClicked))
	panel:getChildByName("SubBtnList"):setTouchEnabled(false)
	self.m_pSecondTabBtnList = panel:getChildByName("SubBtnList"):getChildByName("ListView")
    self.m_pBg= panel:getChildByName("Bg")
	self.m_pTabBtnList = self.m_pBg:getChildByName("Btn_ListView")
    self.m_pTabBtn = self.m_pTabBtnList:getChildByName("Panel_10")
    self.m_pTabBtn:retain()
    self.m_pTabBtn:removeFromParent()
	self.m_pSecondTabBtn = self.m_pSecondTabBtnList:getChildByName("CheckBox")
	self.m_pSecondTabBtn:retain()
    self.m_pSecondTabBtn:removeFromParent()
    self.m_pTabBtns = {}
    self.m_pTabFunc = nil
    -- self.m_pTabTailImg = self.m_pTabBtnList:getChildByName("ImageTitle3")
    -- self.m_pTabTailImg:retain()
    -- self.m_pTabTailImg:removeFromParent()

    self.m_curTabInd = 0
    self.m_strTitle = ""
    self.m_pTabValues = nil

    self.m_pSecondTabBtns = {}
    self.m_pSecondTabFunc = nil
    -- self.m_pTabTailImg = self.m_pTabBtnList:getChildByName("ImageTitle3")
    -- self.m_pTabTailImg:retain()
    -- self.m_pTabTailImg:removeFromParent()

    self.m_curSecondTabInd = 0
    self.m_pSecondTabValues = nil
end

function FirstClassBg:ChangeBg(imgpath)
	Utils:SafeLoadTexture(self.bg,imgpath,ccui.TextureResType.localType)
end
function FirstClassBg:HelpClicked(sender) 
    Utils:ShowDialogOKCancel(self.m_pHelpText)
end
function FirstClassBg:SetBgVisible(visible, clearData, isCheckMainUI)
    if clearData == nil then
        clearData = true
    end
    if isCheckMainUI == nil then
        isCheckMainUI = true
    end
	-- if visible == false then
	-- 	Utils:SafeLoadTexture(self.bg,"res/UI/ui_common_new/ui_bg.png",ccui.TextureResType.localType)
	-- end
    self.m_pUILayer:setVisible(visible)
    if visible == false and clearData == true then
        self.m_pClassCallback = nil
        self.m_pTitleLabel:setString("")
        self:ClearTabBtns()
		self:ClearSecondTabBtns()
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

function FirstClassBg:ShowDefaultBg()
    self.bg:setVisible(true)
    self.m_pUILayer:getChildByName("Panel_12"):getChildByName("Bg"):setVisible(true)
    self.m_pTabBtnList:setVisible(true)
    if not self.bgResourceData then
        return
    end
    Utils:SafeLoadTexture(self.bg,self.bgResourceData.file,ccui.TextureResType.localType)
	self.m_pUILayer:getChildByName("Panel_12"):getChildByName("SubBtnList"):setVisible(false)
end

function FirstClassBg:ClearTabBtns()
    
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

function FirstClassBg:ClearSecondTabBtns()
    
    self.m_pSecondTabBtnList:removeAllItems()
    if self.m_pSecondTabValues ~= nil then
        Utils:FreeTable(self.m_pSecondTabBtns)
    end
    if self.m_pSecondTabValues ~= nil then
        Utils:FreeTable(self.m_pSecondTabValues)
    end
    self.m_pSecondTabBtns = {}
    self.m_curSecondTabInd = 0

    self.m_pSecondTabValues = nil
    self.m_pSecondTabFunc = nil
end

function FirstClassBg:touchTab(ind)
    if self.m_pTabFunc then
        local result = self.m_pTabFunc(ind)
        if result == nil or result == true then
            self:SetSelectedTab(ind)
        end
    end
end

function FirstClassBg:secondTouchTab(ind)
    self:SetSecondSelectedTab(ind)
    if self.m_pSecondTabFunc then
        self.m_pSecondTabFunc(ind)
    end
end

function FirstClassBg:RemoveTabBtn()
    self.m_pTabValues = nil
    self.m_pTabBtns = {}
end

function FirstClassBg:RemoveSecondTabBtn()
    self.m_pSecondTabValues = nil
    self.m_pSecondTabBtns = {}
end
function FirstClassBg:AddTabBtn(tabValues)
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
        local btn = tab:getChildByName("Button1")
        btn:setTag(i)
        local label = btn:getChildByName("BtnName")
        --label:setColor(FirstClassBg.BtnFontColor.UnSelected)
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
    self.m_pUILayer:getChildByName("Panel_12"):getChildByName("Bg"):setVisible(true)
    self.m_pTabBtnList:setVisible(true)
end

function FirstClassBg:AddSecondTabBtn(tabValues)
	self:ClearSecondTabBtns()
    if tabValues == nil or #tabValues == 0 then
        self.m_pSecondTabValues = nil
        self.m_pSecondTabBtns = {}
        return
    end
    self.m_pSecondTabValues = tabValues
    self.m_curSecondTabInd = 0
    self.m_pSecondTabFunc = tabValues[2]

    local function tablefunc(sender)
		local ind = sender:getTag()
		self:secondTouchTab(ind)
    end

    for i = 1,#tabValues[1] do
        local tab = self.m_pSecondTabBtn:clone()
        tab:setTag(i)
        local label = tab:getChildByName("Text")
        label:setColor(FirstClassBg.BtnFontColor.UnSelected)
        label:setString(tabValues[1][i])
		tab:getChildByName("Choose"):setVisible(false)
        tab:addClickEventListener(tablefunc)
        self.m_pSecondTabBtnList:pushBackCustomItem(tab)

        table.insert(self.m_pSecondTabBtns,tab)
    end
    self.m_pUILayer:getChildByName("Panel_12"):getChildByName("SubBtnList"):setVisible(true)
end

--[[
注册UI消息
]]
function FirstClassBg:RegistMsgs()
    self.msgIds = 
    {
        LUIFClassBgEvent.SetTitle,
        LUIFClassBgEvent.SetCloseCallback,
        LUIFClassBgEvent.AddTabBtn,
        LUIFClassBgEvent.IsHideBgAndBtn,
        LUIFClassBgEvent.RemoveTabBtn,
        LUIFClassBgEvent.SelectTab,
        LUIFClassBgEvent.RedDotState,
        LUIFClassBgEvent.GetTabBtn,
        LUIFClassBgEvent.GetCloseBtn,
        LUIFClassBgEvent.RegisterCloseGuide,
        LUIFClassBgEvent.RegisterTabGuide,
        -- LUILoginEvent.RecvServerList,
        -- LUILoginEvent.RecvRoleServerList,
        -- LUILoginEvent.LoginSuccess,
        LUIRoleDataChangeEvent.MoneyChanged,
        LUIRoleDataChangeEvent.TongBaoChanged,
        LUIRoleDataChangeEvent.TiliChanged,
        LUIRoleDataChangeEvent.BGVisible,
		LUIFClassBgEvent.BGChange,
		LUIFClassBgEvent.AddSecondTabBtn,
		LUIFClassBgEvent.SelectSecondTab,
		LUIFClassBgEvent.RemoveSecondTabBtn,
        LUIFClassBgEvent.HelpBtn,
    }
    self:RegistSelf(self,self.msgIds)
end

-- function FirstClassBg:ClearBgData()
--     self.m_pTabValues = nil
--     --self.m_strTitle,self.m_pClassCallback,tableValues,self.m_curTabInd
-- end

function FirstClassBg:GetBgData()
    local tableValues = nil
    local tableRedPointFlags = nil
    if self.m_pTabValues ~= nil then
        tableValues = {{},self.m_pTabValues[2]}
        tableRedPointFlags = {}
        for i = 1,#self.m_pTabValues[1] do
            table.insert(tableValues[1], self.m_pTabValues[1][i])

            if self.m_pTabBtns[i] ~= nil then
                local btn = self.m_pTabBtns[i]:getChildByName("Button1")
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

function FirstClassBg:ResetBgData(data)
    self:SetTitle(data[1])
    self:AddCloseBtnCallback(data[2])
    self:AddTabBtn(data[3])
    self:SetTabBtnRedPoint(data[4])
    self:SetSelectedTab(data[5])
end

function FirstClassBg:SetTabBtnRedPoint(redPointFlags)
    if redPointFlags and type(redPointFlags) == 'table' then
        for i = 1,#redPointFlags do
            if self.m_pTabBtns[i] ~= nil then
                if redPointFlags[i] then
                    local btn = self.m_pTabBtns[i]:getChildByName("Button1")
                    if btn ~= nil then
                        btn:getChildByName("Prompt"):setVisible(redPointFlags[i])
                    end
                end
            end
        end
    end
end

function FirstClassBg:ProcessEvent(msg)
    if msg.msgId == LUIFClassBgEvent.SetTitle then
        --[[
        默认设置title的时候重置tab页签数据，
        所以这个事件必须在LUIFClassBgEvent.AddTabBtn前发过来
        ]]
        self:SetTitle(msg.value)
    elseif msg.msgId == LUIFClassBgEvent.SetCloseCallback then
        self:AddCloseBtnCallback(msg.value)
    elseif msg.msgId == LUIFClassBgEvent.AddTabBtn then
        self:AddTabBtn(msg.value)
    elseif msg.msgId == LUIFClassBgEvent.RemoveTabBtn then
        self:RemoveTabBtn()
    elseif msg.msgId == LUIFClassBgEvent.SelectTab then
        self:SetSelectedTab(msg.value)
    elseif msg.msgId == LUIFClassBgEvent.RedDotState then
        self:SetRedDotState(msg.value)
    elseif msg.msgId == LUIFClassBgEvent.GetTabBtn then
        self:getTabBtns(msg.value)
    elseif msg.msgId == LUIFClassBgEvent.GetCloseBtn then
        self:getCloseBtn(msg.value)
    elseif msg.msgId == LUIFClassBgEvent.RegisterCloseGuide then
        self:RegisterCloseGuide(msg.value)
    elseif msg.msgId == LUIFClassBgEvent.RegisterTabGuide then
        self:RegisterTabGuide(msg.value)
    elseif msg.msgId == LUIRoleDataChangeEvent.MoneyChanged then
        local myMoney = Utils:getGoldStr()
        self._Gold:setString(myMoney)
    elseif msg.msgId == LUIRoleDataChangeEvent.TongBaoChanged then
        local myGold = LRoleDataMgr.MyHeroInfo.DetailData:GetTongBao()
        self._cash:setString(myGold)
    elseif msg.msgId == LUIRoleDataChangeEvent.TiliChanged then
        local myTili = LRoleDataMgr.MyHeroInfo:GetDetailData():getTili()
        print("LUIRoleDataChangeEvent.TiliChanged myTili ==>", myTili)
        self._TiLi:setString(Utils:getTiliStr(myTili))
    elseif msg.msgId == LUIRoleDataChangeEvent.BGVisible then
        print("LUIRoleDataChangeEvent.BGVisible ========>", msg.value)
        self.m_pUILayer:getChildByName("Panel_12"):getChildByName("Bg"):setVisible(msg.value)
        self.m_pTabBtnList:setVisible(msg.value)
	elseif msg.msgId == LUIFClassBgEvent.BGChange then
        self:ChangeBg(msg.value)
    elseif msg.msgId==  LUIFClassBgEvent.IsHideBgAndBtn then
        self:SetBtnAndBgVisible(msg.value)
	elseif msg.msgId == LUIFClassBgEvent.AddSecondTabBtn then
		self:AddSecondTabBtn(msg.value)
	elseif msg.msgId == LUIFClassBgEvent.SelectSecondTab then
		self:SetSecondSelectedTab(msg.value)
	elseif msg.msdId == LUIFClassBgEvent.RemoveSecondTabBtn then
		self:RemoveSecondTabBtn()
	elseif msg.msgId ==LUIFClassBgEvent.HelpBtn then
        self.m_pHelpBtn:setVisible(true)
        self.m_pHelpText=GUITips[msg.value]
    end
end

function FirstClassBg:SetBtnAndBgVisible(isShow)
    self.m_pTabBtnList:setVisible(isShow)
    self.m_pBg:setVisible(isShow)
end

function FirstClassBg:SetSelectedTab(ind)

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
        local btn =  self.m_pTabBtns[self.m_curTabInd]:getChildByName("Button1")
        --btn:setBright(true)
        btn:setEnabled(true)

        local chooseBg = btn:getChildByName("ChooseBg")
        chooseBg:setVisible(false)

        -- local label = btn:getChildByName("BtnName")
        -- label:setColor(FirstClassBg.BtnFontColor.UnSelected)
    end
    self.m_curTabInd = ind
    local btn =  self.m_pTabBtns[self.m_curTabInd]:getChildByName("Button1")
    btn:setEnabled(false)
    --btn:setBright(false)
    local chooseBg = btn:getChildByName("ChooseBg")
    chooseBg:setVisible(true)

    -- local label = btn:getChildByName("BtnName")
    -- label:setColor(FirstClassBg.BtnFontColor.Selected)

end

function FirstClassBg:SetSecondSelectedTab(ind)

    if self.m_pSecondTabBtns == nil then
        return
    end

    if ind == nil or ind > #self.m_pSecondTabBtns or ind <= 0 then 
        return
    end
    if self.m_curSecondTabInd == ind then
        return
    end
    
    if self.m_curSecondTabInd > 0 and self.m_curSecondTabInd <=  #self.m_pSecondTabBtns then
        self.m_pSecondTabBtns[self.m_curSecondTabInd]:getChildByName("Choose"):setVisible(false)
    end
    self.m_curSecondTabInd = ind
    self.m_pSecondTabBtns[self.m_curSecondTabInd]:getChildByName("Choose"):setVisible(true)

end

function FirstClassBg:SetRedDotState(value)
    local ind = value[1]
    local show = value[2]
    if self.m_pTabBtns[ind] == nil then return end
    local btn = self.m_pTabBtns[ind]:getChildByName("Button1")
    if btn ~= nil then
        btn:getChildByName("Prompt"):setVisible(show)
    end
end

function FirstClassBg:SetTitle(title)
    if title == nil then
        return
    end
    if "string" == type(title) then
        self.m_strTitle = title
        self.m_pTitleLabel:setString(title)
    end
end

function FirstClassBg:AddCloseBtnCallback(func)
    self.m_pClassCallback = func
end

function FirstClassBg:onExit()
    self:Destory()
    self.m_pUILayer = nil
end

-- function FirstClassBg:ShowVersion()
--     local panel = self.m_pUILayer:getChildByName("UI_Login")
--     local versionLabel = panel:getChildByName("Versions")


--     local url = "Manifest/ad"..GameSdk.ChannelId.."/version.manifest"
--     local str = cc.FileUtils:getInstance():getStringFromFile(url)
--     local versionManifest = json.decode(str,1)

--     local verStr = string.format(GUITips.Version, versionManifest["showVersion"])
--     versionLabel:setString(verStr)
-- end

function FirstClassBg:getTabBtns(ret)
    ret = ret or {}
    for i=1,#self.m_pTabBtns do
        table.insert(ret, self.m_pTabBtns[i])
    end
end

function FirstClassBg:getCloseBtn(ret)
    ret = ret or {}
    ret.node = self.m_pCloseBtn
end

function FirstClassBg:RegisterCloseGuide(stepId)
    Utils:RegisterGuide(stepId, self.m_pCloseBtn, handler(self, FirstClassBg.CloseCallback), nil, true)
end

function FirstClassBg:RegisterTabGuide(msg)
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

return FirstClassBg